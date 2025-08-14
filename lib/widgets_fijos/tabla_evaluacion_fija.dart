import 'package:flutter/material.dart';

/// Widget fijo para mostrar la estructura de la tabla de evaluación.
class TablaEvaluacionFija extends StatelessWidget {
  final List<DataRow> rows;
  final List<DataColumn> columns;
  final String titulo;

  const TablaEvaluacionFija({
    super.key,
    required this.rows,
    required this.columns,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns,
              rows: rows,
              headingRowColor: WidgetStateProperty.resolveWith(
                (_) => const Color(0xFF003056),
              ),
              dataRowColor: WidgetStateProperty.all(
                Colors.grey.shade200,
              ),
              border: TableBorder.all(color: const Color(0xFF003056)),
            ),
          ),
        ],
      ),
    );
  }
}
