import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget fijo para mostrar un gráfico de anillos múltiples.
class GraficoMultiAnilloFijo extends StatelessWidget {
  final List<PieChartSectionData> sections;
  final String titulo;

  const GraficoMultiAnilloFijo({
    super.key,
    required this.sections,
    this.titulo = 'Gráfico Multi-Anillo',
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
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
