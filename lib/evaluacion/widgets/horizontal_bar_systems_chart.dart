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
      final valores = [
        data[sistema]?['E'] ?? 0.0,
        data[sistema]?['G'] ?? 0.0,
        data[sistema]?['M'] ?? 0.0,
      ];

      return BarChartGroupData(
        x: index,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: valores[0],
            color: Colors.orange,
            width: 16,
            borderRadius: BorderRadius.zero,
          ),
          BarChartRodData(
            toY: valores[1],
            color: Colors.green,
            width: 16,
            borderRadius: BorderRadius.zero,
          ),
          BarChartRodData(
            toY: valores[2],
            color: Colors.blue,
            width: 16,
            borderRadius: BorderRadius.zero,
          ),
        ],
      );
    }).toList();

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: true),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: sistemasOrdenados.length * 80,
          height: 400,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: minY,
              barGroups: barGroups,
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 30,
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
                            overflow: TextOverflow.ellipsis,
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
