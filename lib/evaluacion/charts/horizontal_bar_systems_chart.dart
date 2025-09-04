import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class SistemasRolScreen extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final double minY;
  final double maxY;

  const SistemasRolScreen({
    super.key,
    required this.data,
    this.minY = 0.0,
    this.maxY = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EVALUACION SISTEMAS-ROL'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24), // 👈 Espacio entre título y gráfico
          Expanded(
            child: HorizontalBarSystemsChart(
              data: data,
              minY: minY,
              maxY: maxY,
            ),
          ),
        ],
      ),
    );
  }
}

class HorizontalBarSystemsChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final double minY;
  final double maxY;
  final List<String> sistemasOrdenados;

  static const List<String> _sistemasOrdenados = [
    'Ambiental',
    'Compromiso',
    'Comunicación',
    'Despliegue de Estrategia',
    'Desarrollo de Personas',
    'EHS',
    'Gestión Visual',
    'Involucramiento',
    'Medición',
    'Planificación y Programación',
    'Recompensas',
    'Reconocimiento',
    'Seguridad',
    'Sistemas de Mejora',
    'Solución de Problemas',
    'Voz del Cliente',
    'Visitas al Gemba',
  ];

  const HorizontalBarSystemsChart({
    super.key,
    required this.data,
    required this.minY,
    required this.maxY,
    this.sistemasOrdenados = const [],
  });

  @override
  Widget build(BuildContext context) {
    final sistemas = sistemasOrdenados.isNotEmpty ? sistemasOrdenados : _sistemasOrdenados;
    if (sistemas.isEmpty) {
      return const Center(child: Text('No hay datos'));
    }

    final barGroups = sistemas.asMap().entries.map((entry) {
      final index = entry.key;
      final sistema = entry.value;
      final levels = data[sistema] ?? {'E': 0.0, 'G': 0.0, 'M': 0.0};

      return BarChartGroupData(
        x: index,
        barsSpace: 0,
        barRods: [
          BarChartRodData(
            toY: levels['E'] ?? 0,
            width: 16,
            color: Colors.orange,
            borderRadius: BorderRadius.zero,
          ),
          BarChartRodData(
            toY: levels['G'] ?? 0,
            width: 16,
            color: Colors.green,
            borderRadius: BorderRadius.zero,
          ),
          BarChartRodData(
            toY: levels['M'] ?? 0,
            width: 16,
            color: Colors.blue,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = max(sistemas.length * 140.0, constraints.maxWidth);
        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(scrollbars: true),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.only(top: 16), // 👈 Más espacio aún por seguridad
              child: SizedBox(
                width: chartWidth,
                child: BarChart(
                  BarChartData(
                    minY: minY,
                    maxY: maxY,
                    barGroups: barGroups,
                    groupsSpace: 80,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: 0.5,
                          getTitlesWidget: (value, meta) {
                            if (value >= minY && value <= maxY) {
                              return Text(
                                value.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 16,
                          getTitlesWidget: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                      rightTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 100,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < sistemas.length) {
                              final sistema = sistemas[index];
                              final formattedLabel = formatLabel(sistema);

                              return SideTitleWidget(
                                meta: meta,
                                space: 12,
                                child: SizedBox(
                                  width: 120,
                                  child: Text(
                                    formattedLabel,
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 0.5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withAlpha(77),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final valor = rod.toY;
                          return BarTooltipItem(
                            valor.toStringAsFixed(2),
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        direction: TooltipDirection.auto,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String formatLabel(String label) {
    final parts = label.split(' ');
    if (parts.length == 1) return label;
    if (parts.length == 2) return '${parts[0]}\n${parts[1]}';

    final buffer = StringBuffer();
    final maxLines = 3;
    int wordsPerLine = (parts.length / maxLines).ceil();
    for (int i = 0; i < parts.length; i++) {
      buffer.write(parts[i]);
      if ((i + 1) % wordsPerLine == 0 && i != parts.length - 1) {
        buffer.write('\n');
      } else if (i != parts.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}
