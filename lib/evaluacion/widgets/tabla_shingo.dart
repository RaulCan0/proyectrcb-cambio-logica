
import 'package:flutter/material.dart';
import '../screens/shingo_result.dart';

class TablaResultadosShingo extends StatelessWidget {
  final Map<String, ShingoResultData> resultados;

  const TablaResultadosShingo({super.key, required this.resultados});

  @override
  Widget build(BuildContext context) {
    final resumen = ShingoResumenService.generarResumen(resultados);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Pts obtenidos')),
          DataColumn(label: Text('% obtenido')),
        ],
        rows: resumen.map((r) {
          return DataRow(
            color: r.esTotal ? WidgetStateProperty.all(const Color.fromARGB(255, 8, 29, 46)) : null,
            cells: [
              DataCell(Text(r.categoria)),
              DataCell(Text(r.puntos.toStringAsFixed(0))),
              DataCell(Text('${r.porcentaje.toStringAsFixed(1)}%')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class ShingoResumenService {
  static List<ResumenCategoria> generarResumen(Map<String, ShingoResultData> hojas) {
    final List<ResumenCategoria> resumen = [];
    double totalPts = 0;

    for (final entry in hojas.entries) {
      final nombre = entry.key;
      final cal = entry.value.calificacion;
      final puntos = cal * 8;
      final porcentaje = puntos / 40 * 100;
      totalPts += puntos;

      resumen.add(ResumenCategoria(
        categoria: nombre,
        puntos: puntos.toDouble(),
        porcentaje: porcentaje,
        esTotal: false,
      ));
    }

    resumen.add(ResumenCategoria(
      categoria: 'TOTAL',
      puntos: totalPts,
      porcentaje: totalPts / 200 * 100,
      esTotal: true,
    ));

    return resumen;
  }
}

class ResumenCategoria {
  final String categoria;
  final double puntos;
  final double porcentaje;
  final bool esTotal;

  ResumenCategoria({
    required this.categoria,
    required this.puntos,
    required this.porcentaje,
    this.esTotal = false,
  });
}
