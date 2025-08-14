import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget fijo para mostrar un gráfico de dispersión (burbujas).
class GraficoDispersionFijo extends StatelessWidget {
  final List<ScatterSpot> spots;
  final String titulo;

  const GraficoDispersionFijo({
    super.key,
    required this.spots,
    this.titulo = 'Gráfico de Dispersión',
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
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: spots,
                  minX: 0,
                  maxX: 100,
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
