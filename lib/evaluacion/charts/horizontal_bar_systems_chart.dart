import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HorizontalBarSystemsChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final double minY;
  final double maxY;
  final List<String> sistemasOrdenados;

  // Lista interna de sistemas ordenados
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
    'Reconocimientos',
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
    this.sistemasOrdenados = const [], // Hacerlo opcional con lista vacía por defecto
  });

  @override
  Widget build(BuildContext context) {
    if (_sistemasOrdenados.isEmpty) {
      return const Center(child: Text('No hay datos'));
    }

    // Dividir sistemas en 2 filas
    final int mitad = (_sistemasOrdenados.length / 2).ceil();
    final List<String> primeraFila = _sistemasOrdenados.take(mitad).toList();
    final List<String> segundaFila = _sistemasOrdenados.skip(mitad).toList();

    return Column(
      children: [
        // Primera fila de gráficos
        Expanded(
          child: _buildChartRow(primeraFila, 'Fila 1'),
        ),
        const SizedBox(height: 16),
        // Segunda fila de gráficos
        Expanded(
          child: _buildChartRow(segundaFila, 'Fila 2'),
        ),
      ],
    );
  }

  Widget _buildChartRow(List<String> sistemas, String label) {
    final barGroups = sistemas.asMap().entries.map((entry) {
      final index = entry.key;
      final sistema = entry.value;
      final levels = data[sistema] ?? {'E': 0.0, 'G': 0.0, 'M': 0.0};

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: levels['E'] ?? 0,
            width: 24, // 3 veces más gruesa (era 8, ahora 24)
            color: Colors.orange,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: levels['G'] ?? 0,
            width: 24, // 3 veces más gruesa (era 8, ahora 24)
            color: Colors.green,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: levels['M'] ?? 0,
            width: 24, // 3 veces más gruesa (era 8, ahora 24)
            color: Colors.blue,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        barsSpace: 2, // Más juntas (era 4, ahora 2)
      );
    }).toList();

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: true),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: sistemas.length * 120, // Un poco más ancho para acomodar barras más gruesas
          height: 180, // Altura reducida para cada fila
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: minY,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < sistemas.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            sistemas[index],
                            style: const TextStyle(fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barTouchData: const BarTouchData(enabled: true),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }
}
