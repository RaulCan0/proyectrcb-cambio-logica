import 'package:flutter/material.dart';
import 'package:applensys/evaluacion/screens/shingo_result.dart';
import 'package:applensys/evaluacion/widgets/tabla_shingo.dart';

class TablaTotales extends StatelessWidget {
  /// promediosPorDimension:
  /// {
  ///   '1': {'EJECUTIVOS': 4.2, 'GERENTES': 3.8, 'MIEMBROS DE EQUIPO': 3.5}, // escala 0..5
  ///   '2': {...},
  ///   '3': {...},
  /// }
  final Map<String, Map<String, double>> promediosPorDimension;
  final Map<String, ShingoResultData> resultadosShingo;

  const TablaTotales({
    super.key,
    required this.promediosPorDimension,
    required this.resultadosShingo,
  });

  // --- configuración por dimensión (suma 800) ---
  static const _sections = [
    {
      'dimensionId': '1',
      'maxDim': 250.0,
      'puntos': [125.0, 75.0, 50.0], // E, G, M
      'cargos': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
    },
    {
      'dimensionId': '2',
      'maxDim': 350.0,
      'puntos': [70.0, 105.0, 175.0],
      'cargos': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
    },
    {
      'dimensionId': '3',
      'maxDim': 200.0,
      'puntos': [110.0, 60.0, 30.0],
      'cargos': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
    },
  ];

  String _normCargo(String c) {
    final up = c.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (up == 'MIEMBRO' || up == 'MIEMBRO DE EQUIPO' || up == 'MIEMBROS') {
      return 'MIEMBROS DE EQUIPO';
    }
    return up;
  }

  double _valor0a5(String dimensionId, String cargo) {
    final mapa = promediosPorDimension[dimensionId];
    if (mapa == null) return 0.0;
    final objetivo = _normCargo(cargo);
    for (final e in mapa.entries) {
      if (_normCargo(e.key) == objetivo) return e.value.clamp(0.0, 5.0);
    }
    return 0.0;
  }

  /// puntos obtenidos por cargo en una dimensión (convierte 0..5 a % y aplica a puntos posibles)
  double _puntosCargo(String dimensionId, String cargo, double puntosPosibles) {
    final v = _valor0a5(dimensionId, cargo);
    final pct = (v / 5.0); // 0..1
    return pct * puntosPosibles;
  }

  /// calcula puntos obtenidos por cada una de las 3 dimensiones (ya ponderado por cargo)
  List<double> _puntosPorDimension() {
    final res = <double>[];
    for (final s in _sections) {
      final id = s['dimensionId'] as String;
      final puntos = (s['puntos'] as List).cast<double>();
      final cargos = (s['cargos'] as List).cast<String>();
      final p0 = _puntosCargo(id, cargos[0], puntos[0]);
      final p1 = _puntosCargo(id, cargos[1], puntos[1]);
      final p2 = _puntosCargo(id, cargos[2], puntos[2]);
      res.add(p0 + p1 + p2); // total dimensión
    }
    return res;
  }

  /// total shingo: usa el TOTAL de ShingoResumenService (200 pts máx)
  double _totalShingoObtenido() {
    final resumen = ShingoResumenService.generarResumen(resultadosShingo);
    final totalRow = resumen.firstWhere((r) => r.esTotal, orElse: () => resumen.last);
    return totalRow.puntos; // ya viene sumado (0..200)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txt = theme.textTheme.bodyMedium;

    // Dimensiones (800)
    final puntosDims = _puntosPorDimension();         // [d1, d2, d3]
    final totalDims = puntosDims.fold(0.0, (a, b) => a + b);
    const maxDims = 800.0;
    final pctDims = (totalDims / maxDims * 100).clamp(0.0, 100.0);

    // Shingo (200)
    final totalShingo = _totalShingoObtenido();
    const maxShingo = 200.0;
    final pctShingo = (totalShingo / maxShingo * 100).clamp(0.0, 100.0);

    // Global (1000)
    final totalGlobal = totalDims + totalShingo;
    const maxGlobal = maxDims + maxShingo; // 1000
    final pctGlobal = (totalGlobal / maxGlobal * 100).clamp(0.0, 100.0);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
          columns: const [
            DataColumn(label: Text('EVALUACION')),
            DataColumn(label: Text('PUNTAJE OBTENIDO')),
            DataColumn(label: Text('% OBTENIDO')),
          ],
          rows: [
            DataRow(cells: [
              DataCell(Text('Dimensiones (800 pts)', style: txt)),
              DataCell(Text('${totalDims.toStringAsFixed(1)} / ${maxDims.toStringAsFixed(0)}', style: txt)),
              DataCell(Text('${pctDims.toStringAsFixed(1)}%', style: txt)),
            ]),
            DataRow(cells: [
              DataCell(Text('Shingo (200 pts)', style: txt)),
              DataCell(Text('${totalShingo.toStringAsFixed(1)} / ${maxShingo.toStringAsFixed(0)}', style: txt)),
              DataCell(Text('${pctShingo.toStringAsFixed(1)}%', style: txt)),
            ]),
            DataRow(
              color: WidgetStateProperty.all(const Color(0xFF081D2E)),
              cells: [
                const DataCell(Text('TOTAL (1000 pts)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataCell(Text(
                  '${totalGlobal.toStringAsFixed(1)} / ${maxGlobal.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )),
                DataCell(Text(
                  '${pctGlobal.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
