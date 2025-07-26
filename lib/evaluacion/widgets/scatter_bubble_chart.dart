import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ScatterData {
  final double x;
  final double y;
  final Color color;
  final String seriesName;
  final String principleName;
  final double radius;

  const ScatterData({
    required this.x,
    required this.y,
    required this.color,
    required this.seriesName,
    required this.principleName,
    required this.radius,
  });
}

class ScatterBubbleChart extends StatelessWidget {
  final List<ScatterData> data;
  final bool isDetail;

  const ScatterBubbleChart({
    super.key,
    required this.data,
    this.isDetail = false,
  });

  static const List<String> principleNames = [
    'Respetar a Cada Individuo',
    'Liderar con Humildad',
    'Buscar la Perfección',
    'Abrazar el Pensamiento Científico',
    'Enfocarse en el Proceso',
    'Asegurar la Calidad en la Fuente',
    'Mejorar el Flujo y Jalón de Valor',
    'Pensar Sistémicamente',
    'Crear Constancia de Propósito',
    'Crear Valor para el Cliente',
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos disponibles para mostrar.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    const minX = 0.0;
    const maxX = 5.0;
    const minY = 1.0;
    const maxY = 10.0;
    const offset = 0.2;
    final dotRadius = isDetail ? 30.0 : 20.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 600, // Puedes ajustar esto dinámicamente según el número de datos
        height: 400,
        child: ScatterChart(
          ScatterChartData(
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                bottom: BorderSide(color: Colors.black, width: 2),
                left: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 180, // Espacio suficiente para textos largos
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 1 && index <= principleNames.length) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          principleNames[index - 1],
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.visible, // Asegura que se vea completo
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 0.5,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            scatterSpots: data.map((d) {
              double xPos = d.x;
              if (d.seriesName == 'Ejecutivo') {
                xPos = (d.x - offset).clamp(minX, maxX);
              } else if (d.seriesName == 'Miembro') {
                xPos = (d.x + offset).clamp(minX, maxX);
              }
              return ScatterSpot(
                xPos,
                d.y,
                dotPainter: FlDotCirclePainter(
                  radius: d.radius > 0 ? d.radius : dotRadius,
                  color: d.color,
                  strokeWidth: 0,
                ),
              );
            }).toList(),
            scatterTouchData: ScatterTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              touchTooltipData: ScatterTouchTooltipData(
                getTooltipItems: (spot) => ScatterTooltipItem(
                  'Valor: ${spot.x.toStringAsFixed(2)}',
                  textStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
