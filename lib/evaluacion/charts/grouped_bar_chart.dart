import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GroupedBarChart extends StatelessWidget {
  final Map<String, List<double>> data;
  final double minY;
  final double maxY;
  final bool isDetail;

  const GroupedBarChart({
    super.key,
    required this.data,
    required this.minY,
    required this.maxY,
    this.isDetail = false,
  });

  static const labels = [
    'Soporte',
    'Reconocer',
    'Comunidad',
    'Liderazgo de Servidor',
    'Valorar',
    'Empoderar',
    'Mentalidad',
    'Estructura',
    'Reflexionar',
    'Análisis',
    'Colaborar',
    'Comprender',
    'Diseño',
    'Atribución',
    'A Prueba de Errores',
    'Propiedad',
    'Conectar',
    'Ininterrumpido',
    'Demanda',
    'Eliminar',
    'Optimizar',
    'Impacto',
    'Alinear',
    'Aclarar',
    'Comunicar',
    'Relación',
    'Valor',
    'Medida',
  ];

  String _wrapLabel(String label) {
    if (label.contains(' ')) {
      final words = label.split(' ');
      if (words.length == 2) {
        return '${words[0]}\n${words[1]}';
      } else {
        final lines = <String>[];
        int perLine = (words.length / 3).ceil();
        for (int i = 0; i < words.length; i += perLine) {
          lines.add(words.sublist(i, min(i + perLine, words.length)).join(' '));
        }
        return lines.join('\n');
      }
    } else {
      const step = 7;
      if (label.length <= step) return label;
      final buf = StringBuffer();
      for (int i = 0; i < label.length; i++) {
        buf.write(label[i]);
        final rest = label.length - (i + 1);
        if ((i + 1) % step == 0 && rest > 2) {
          buf.write('\u200B');
        }
      }
      return buf.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    const barWidth = 16.0;
    const barsSpace = 0.0;
    const minBoxWidth = 90.0;

    final labelBoxWidths = labels.map((label) {
      final wordCount = label.split(' ').length;
      final baseWidth = label.length * 6.0 + wordCount * 4;
      return max(minBoxWidth, baseWidth);
    }).toList();

    final totalChartWidth = labelBoxWidths.reduce((a, b) => a + b + 20);

    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = max(totalChartWidth, constraints.maxWidth);

              return ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: true),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: BarChart(
                      BarChartData(
                        minY: minY,
                        maxY: maxY + 0.5,
                        alignment: BarChartAlignment.spaceAround,
                        groupsSpace: 24,
                        barGroups: List.generate(labels.length, (i) {
                          final valores = data[labels[i]] ?? const [0.0, 0.0, 0.0];
                          return BarChartGroupData(
                            x: i,
                            barsSpace: barsSpace,
                            barRods: [
                              BarChartRodData(
                                toY: valores[0],
                                color: Colors.orange,
                                width: barWidth,
                                borderRadius: BorderRadius.zero,
                              ),
                              BarChartRodData(
                                toY: valores[1],
                                color: Colors.green,
                                width: barWidth,
                                borderRadius: BorderRadius.zero,
                              ),
                              BarChartRodData(
                                toY: valores[2],
                                color: Colors.blue,
                                width: barWidth,
                                borderRadius: BorderRadius.zero,
                              ),
                            ],
                          );
                        }),
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 70,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                final label = _wrapLabel(labels[index]);

                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 6,
                                  child: SizedBox(
                                    width: labelBoxWidths[index],
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 0.5, // 👈 Mostramos .5, 1.0, 1.5, ...
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
                          rightTitles:  AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 0.5, // 👈 Líneas cada 0.5
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withAlpha(77),
                            strokeWidth: 1,
                          ),
                          drawVerticalLine: true,
                          getDrawingVerticalLine: (value) => FlLine(
                            color: Colors.grey.withAlpha(40),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Colors.grey.shade600,
                            width: 1,
                          ),
                        ),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                rod.toY.toStringAsFixed(2),
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
