import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MultiRingChart extends StatelessWidget {
  final Map<String, double> puntosObtenidos; // e.g. {'Impulsores Culturales': 180, ...}
  final bool isDetail;

  const MultiRingChart({
    super.key,
    required this.puntosObtenidos,
    this.isDetail = false,
  });

  static const Map<String, double> puntosTotales = {
    'Impulsores Culturales': 250,
    'Mejora Continua': 350,
    'Alineamiento Empresarial': 200,
  };

  static const Map<String, Color> coloresPorDimension = {
    'Impulsores Culturales': Color(0xFF00BCD4),   // azul claro
    'Mejora Continua': Color.fromARGB(255, 22, 23, 80),         // verde lima
    'Alineamiento Empresarial': Color.fromARGB(255, 51, 28, 87),// gris
  };

  @override
  Widget build(BuildContext context) {
    final List<String> dimensiones = puntosTotales.keys.toList();
    final int n = dimensiones.length;

    final double chartSize = isDetail ? 360 : 260;
    final double maxRadius = isDetail ? 120 : 90;
    final double ringWidth = maxRadius / n;

    return SizedBox(
      width: chartSize,
      height: chartSize,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(n, (index) {
          final nombre = dimensiones[index];
          final double total = puntosTotales[nombre]!;
          final double obtenido = puntosObtenidos[nombre] ?? 0;
          final double porcentaje = (obtenido / total).clamp(0.0, 1.0);

          final double outerRadius = maxRadius - index * ringWidth;

          return PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: outerRadius - ringWidth,
              sections: [
                PieChartSectionData(
                  value: porcentaje * total,
                  color: coloresPorDimension[nombre],
                  radius: outerRadius,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (1 - porcentaje) * total,
                  color: Colors.grey.shade200,
                  radius: outerRadius,
                  showTitle: false,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
