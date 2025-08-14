import 'package:flutter/material.dart';

class TablaTotales extends StatelessWidget {
  /// Mapa con los valores obtenidos por fila. Ejemplo:
  /// {
  ///   'IMPULSORES CULTURALES': 210,
  ///   'MEJORA CONTINUA': 180,
  ///   ...
  /// }
  final Map<String, num> valores;

  const TablaTotales({
    super.key,
    this.valores = const {},
  });

  static const List<String> _filas = [
    'IMPULSORES CULTURALES',
    'MEJORA CONTINUA',
    'ALINEAMIENTO EMPRESARIAL',
    'RESULTADOS',
    'SEGURIDAD',
    'SEGURIDAD-MEDIO',
    'SEGURIDAD-AMBIENTE',
    'SEGURIDAD-MORAL',
    'SATISFACCION AL CLIENTE',
    'CALIDAD',
    'COSTO',
    'COSTO-PRODUCTIVIDAD',
    'ENTREGAS',
    'MAXIMO =1000',
  ];

  String _fmt(num? n) {
    if (n == null) return '—';
    final v = n.toDouble();
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 42,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 48,
              columnSpacing: 28,
              headingTextStyle: textStyle?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              columns: const [
                DataColumn(label: Text('NOMBRE')),
                DataColumn(label: Text('OBTENIDO'), numeric: true),
              ],
              rows: _filas.map((nombre) {
                final valor = nombre == 'MAXIMO =1000'
                    ? 1000
                    : valores[nombre];
                return DataRow(
                  cells: [
                    DataCell(Text(nombre)),
                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(_fmt(valor)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
