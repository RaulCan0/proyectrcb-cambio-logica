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
    final double ringWidth = (isDetail ? 18 : 12); // Más delgado
    final double separation = (isDetail ? 10 : 7); // Separación entre anillos

    // Sumatoria total obtenida
    final double sumatoria = puntosObtenidos.values.fold(0.0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.only(top: 48.0), // Espacio superior extra
      child: SizedBox(
        width: chartSize,
        height: chartSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (int index = 0; index < n; index++)
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: separation,
                  centerSpaceRadius: maxRadius - (index + 1) * (ringWidth + separation),
                  sections: [
                    PieChartSectionData(
                      value: puntosObtenidos[dimensiones[index]]?.clamp(0.0, puntosTotales[dimensiones[index]]!) ?? 0.0,
                      color: coloresPorDimension[dimensiones[index]],
                      radius: maxRadius - index * (ringWidth + separation),
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: (puntosTotales[dimensiones[index]]! - (puntosObtenidos[dimensiones[index]] ?? 0.0)).clamp(0.0, puntosTotales[dimensiones[index]]!),
                      color: Colors.grey.shade200,
                      radius: maxRadius - index * (ringWidth + separation),
                      showTitle: false,
                    ),
                  ],
                ),
              ),
            // Mostrar la sumatoria en el centro
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sumatoria.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: isDetail ? 38 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total puntos',
                      style: TextStyle(
                        fontSize: isDetail ? 16 : 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
