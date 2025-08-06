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

  // Para promedios, el máximo es 5.0
  static const Map<String, double> puntosTotales = {
    'IMPULSORES CULTURALES': 5.0,
    'MEJORA CONTINUA': 5.0,
    'ALINEAMIENTO EMPRESARIAL': 5.0,
  };

  static const Map<String, Color> coloresPorDimension = {
    'IMPULSORES CULTURALES': Color.fromARGB(255, 122, 141, 245),   // azul
    'MEJORA CONTINUA':Color.fromARGB(255, 67, 78, 141),          // azul oscuro
    'ALINEAMIENTO EMPRESARIAL': Color.fromARGB(255, 14, 24, 78),   // azul más oscuro
  };

  @override
  Widget build(BuildContext context) {
    final List<String> dimensiones = puntosTotales.keys.toList();
    final int n = dimensiones.length;

    final double chartSize = isDetail ? 360 : 260;
    final double maxRadius = isDetail ? 120 : 90;
    final double ringWidth = (maxRadius * 0.6) / n; // Hacer los anillos más delgados
    final double centerRadius = maxRadius * 0.3; // Espacio central fijo

    // Log para depuración
    debugPrint('MultiRingChart recibió datos: $puntosObtenidos');

    return Column(
      children: [
        // Espacio superior para centrar el gráfico
        const SizedBox(height: 40),
        
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
              final double innerRadius = outerRadius - ringWidth;
              
              // Asegurar que el anillo más interno tenga un espacio central
              final double actualCenterRadius = index == n - 1 ? centerRadius : innerRadius;

              return PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 0,
                  centerSpaceRadius: actualCenterRadius,
                  sections: [
                    PieChartSectionData(
                      value: porcentaje * total,
                      color: coloresPorDimension[nombre],
                      radius: outerRadius,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: (1 - porcentaje) * total,
                      color: Colors.white,
                      radius: outerRadius,
                      showTitle: false,
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        
        // Más espacio entre el gráfico y la leyenda para empujar los textos hacia abajo
        const SizedBox(height: 32),
        
        // Leyenda
        _buildLegend(),
        
        // Espacio inferior adicional
        const SizedBox(height: 16),
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
            border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
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
                      color: Color.fromARGB(255, 0, 0, 0),
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
