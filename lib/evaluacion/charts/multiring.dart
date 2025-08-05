import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MultiRingChart extends StatelessWidget {
  final Map<String, double> puntosObtenidos; // e.g. {'Impulsores Culturales': 3.5, ...}
  final bool isDetail;

  const MultiRingChart({
    super.key,
    required this.puntosObtenidos,
    this.isDetail = false,
  });

  // Máximos corregidos según los valores requeridos
  static const Map<String, double> puntosTotales = {
    'IMPULSORES CULTURALES': 250.0,
    'MEJORA CONTINUA': 350.0,
    'ALINEAMIENTO EMPRESARIAL': 200.0,
  };

  static const Map<String, Color> coloresPorDimension = {
    'IMPULSORES CULTURALES': Color(0xFF00BCD4),   // azul claro
    'MEJORA CONTINUA': Color(0xFF8BC34A),         // verde lima
    'ALINEAMIENTO EMPRESARIAL': Color(0xFF757575),// gris
  };

  @override
  Widget build(BuildContext context) {
    final List<String> dimensiones = puntosTotales.keys.toList();
    final int n = dimensiones.length;

    final double chartSize = isDetail ? 360 : 260;
    final double maxRadius = isDetail ? 120 : 90;
    final double ringWidth = maxRadius / n;

    // Log para depuración
    debugPrint('MultiRingChart recibió datos: $puntosObtenidos');

    return Column(
      children: [
        // Gráfico de anillos
        SizedBox(
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
        ),
        
        const SizedBox(height: 16),
        
        // Leyenda
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: puntosTotales.keys.map((nombre) {
        final obtenido = puntosObtenidos[nombre] ?? 0;
        final total = puntosTotales[nombre]!;
        final porcentaje = ((obtenido / total) * 100).clamp(0.0, 100.0);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de color
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: coloresPorDimension[nombre],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              
              // Texto con nombre y valor
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003056),
                    ),
                  ),
                  Text(
                    '${obtenido.toStringAsFixed(2)}/5.0 (${porcentaje.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
