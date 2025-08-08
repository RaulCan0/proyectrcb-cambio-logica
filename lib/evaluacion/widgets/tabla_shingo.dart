import 'package:applensys/evaluacion/screens/shingo_result.dart';
import 'package:flutter/material.dart';

/// Widget que muestra la tabla con 5 filas y termómetro abajo.
class TablaResultadosShingo extends StatelessWidget {
  final Map<String, ShingoResultData> resultados;
  const TablaResultadosShingo({super.key, required this.resultados});

  static const List<String> labels = [
    'seguridad/medio/ambiente/moral',
    'satisfacción del cliente',
    'calidad',
    'costo/productividad',
    'entregas',
  ];

  // convierte 0–5 a 0–40
  double _toPoints(double cal) => (cal / 5) * 40;

  @override
  Widget build(BuildContext context) {
    double totalRaw = 0;
    final rows = <DataRow>[];
    for (var lbl in labels) {
      final cal = resultados[lbl]?.calificacion.toDouble() ?? 0;
      final pts = _toPoints(cal);
      totalRaw += pts;
      rows.add(DataRow(cells: [
        DataCell(Text(lbl, style: const TextStyle(color: Color(0xFF003056)))),
        DataCell(const Text('20%', style: TextStyle(color: Color(0xFF003056)))),
        DataCell(Text('${pts.toStringAsFixed(0)} / 40', style: const TextStyle(color: Color(0xFF003056)))),
      ]));
    }

    // escalamos raw 0–200 a termómetro 0–1000
    final thermValue = (totalRaw / 200) * 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF003056)),
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          border: TableBorder.all(color: const Color(0xFF003056)),
          columns: const [
            DataColumn(label: Text('Resultado')),
            DataColumn(label: Text('Peso')),
            DataColumn(label: Text('Obtenido')),
          ],
          rows: rows,
        ),
        const SizedBox(height: 16),
        const Text(
          'EVALUACION SHINGO-PRIZE',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          '${thermValue.toStringAsFixed(0)} / 1000 pts',
          style: const TextStyle(color: Colors.black87),
        ),
        const SizedBox(height: 8),
        _RectangularThermometer(value: thermValue, max: 1000),
      ],
    );
  }
}

/// Termómetro rectangular horizontal de rojo a verde con indicador en círculo blanco y Tooltip
class _RectangularThermometer extends StatelessWidget {
  final double value;
  final double max;
  const _RectangularThermometer({required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    final fill = (value / max).clamp(0.0, 1.0);
    final barWidth = MediaQuery.of(context).size.width - 32; // padding 16*2
    final indicatorX = barWidth * fill;

    return Container(
      height: 24,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.red,Colors.yellow, Colors.green],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Fill
          Positioned(
            left: 0,
            width: indicatorX,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Indicator circle with Tooltip
          Positioned(
            left: (indicatorX - 12).clamp(0.0, barWidth - 24),
            top: 0,
            bottom: 0,
            child: Center(
              child: Tooltip(
                message: '${value.toStringAsFixed(0)} / ${max.toStringAsFixed(0)} pts',
                textStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                waitDuration: const Duration(milliseconds: 200),
                showDuration: const Duration(seconds: 2),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
