import 'package:flutter/material.dart';

class IcoButtonMenuReportes extends StatelessWidget {
    final void Function(String formato) onSelected;

    const IcoButtonMenuReportes({super.key, required this.onSelected});

    @override
    Widget build(BuildContext context) {
        return PopupMenuButton<String>(
            icon: Icon(Icons.insert_drive_file, size: 32),
            tooltip: 'SELECCIONA EL FORMATO DEL REPORTE',
            onSelected: onSelected,
            itemBuilder: (context) => [
                PopupMenuItem(
                    value: 'Reporte en formato WORD',
                    child: Row(
                        children: [
                            Icon(Icons.description, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Word'),
                        ],
                    ),
                ),
                PopupMenuItem(
                    value: 'Reporte en formato PDF',
                    child: Row(
                        children: [
                            Icon(Icons.picture_as_pdf, color: Colors.red),
                            SizedBox(width: 8),
                            Text('PDF'),
                        ],
                    ),
                ),
                PopupMenuItem(
                    value: 'Reporte en formato EXCEL',
                    child: Row(
                        children: [
                            Icon(Icons.table_chart, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Excel'),
                        ],
                    ),
                ),
            ],
        );
    }
}