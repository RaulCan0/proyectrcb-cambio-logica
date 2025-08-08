
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
            color: r.esTotal ? WidgetStateProperty.all(Colors.blue[100]) : null,
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
