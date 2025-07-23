import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HorizontalBarSystemsChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final double minY;
  final double maxY;
  final List<String> sistemasOrdenados;

  const HorizontalBarSystemsChart({
    super.key,
    required this.data,
    required this.minY,
    required this.maxY,
    required this.sistemasOrdenados,
  });

  @override
  Widget build(BuildContext context) {
    if (sistemasOrdenados.isEmpty) {
      return const Center(child: Text('No hay datos'));
    }

    final barGroups = sistemasOrdenados.asMap().entries.map((entry) {
      final index = entry.key;
      final sistema = entry.value;
      final levels = data[sistema] ?? {'E': 0.0, 'G': 0.0, 'M': 0.0};

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: levels['E'] ?? 0,
            width: 8,
            color: Colors.orange,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: levels['G'] ?? 0,
            width: 8,
            color: Colors.green,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: levels['M'] ?? 0,
            width: 8,
            color: Colors.blue,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: true),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: sistemasOrdenados.length * 100,
          height: 400,
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
                      if (index >= 0 && index < sistemasOrdenados.length) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            sistemasOrdenados[index],
                            style: const TextStyle(fontSize: 10),
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
