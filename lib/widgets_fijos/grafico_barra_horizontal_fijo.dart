import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget fijo para mostrar un gráfico de barras horizontales.
class GraficoBarraHorizontalFijo extends StatelessWidget {
  final List<BarChartGroupData> barGroups;
  final List<String> labels;
  final String titulo;

  const GraficoBarraHorizontalFijo({
    super.key,
    required this.barGroups,
    required this.labels,
    this.titulo = 'Gráfico de Barras',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        return idx >= 0 && idx < labels.length
                            ? Text(labels[idx])
                            : const SizedBox.shrink();
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
