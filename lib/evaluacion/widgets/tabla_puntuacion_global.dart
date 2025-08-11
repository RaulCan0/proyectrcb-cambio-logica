import 'package:flutter/material.dart';

class TablaPuntuacionGlobal extends StatelessWidget {
 
  final Map<String, Map<String, double>> promediosPorDimension;

  const TablaPuntuacionGlobal({
    super.key,
    required this.promediosPorDimension,
  });

  // Configuración (suma total = 800)
  static const List<Map<String, dynamic>> sections = [
    {
      'label': 'Impulsores Culturales (250 pts)',
      'dimensionId': '1',
      'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
      'compsText': ['EJECUTIVOS 50%', 'GERENTES 30%', 'MIEMBROS DE EQUIPO 20%'],
      'puntos': [125.0, 75.0, 50.0],
      'maxDim': 250.0,
    },
    {
      'label': 'Mejora Continua (350 pts)',
      'dimensionId': '2',
      'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
      'compsText': ['EJECUTIVOS 20%', 'GERENTES 30%', 'MIEMBROS DE EQUIPO 50%'],
      'puntos': [70.0, 105.0, 175.0],
      'maxDim': 350.0,
    },
    {
      'label': 'Alineamiento Empresarial (200 pts)',
      'dimensionId': '3',
      'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
      'compsText': ['EJECUTIVOS 55%', 'GERENTES 30%', 'MIEMBROS DE EQUIPO 15%'],
      'puntos': [110.0, 60.0, 30.0],
      'maxDim': 200.0,
    },
  ];

  double _porcentajeCargo(String dimensionId, String cargo) {
  // Permitir ambas variantes de clave
  final cargos = promediosPorDimension[dimensionId] ?? {};
  double prom = cargos[cargo] ?? cargos['MIEMBRO'] ?? cargos['MIEMBROS DE EQUIPO'] ?? 0.0;
  return (prom.clamp(0.0, 5.0) / 5.0) * 100.0;
  }

  double _puntosCargo(String dimensionId, String cargo, double puntosPosibles) {
  return _porcentajeCargo(dimensionId, cargo) / 100.0 * puntosPosibles;
  }

  double _promedioGeneralDimension(String dimensionId) {
    final cargos = promediosPorDimension[dimensionId];
    if (cargos == null || cargos.isEmpty) return 0.0;
    double suma = 0.0;
    int count = 0;
    for (final key in cargos.keys) {
      // Solo sumar los cargos relevantes
      if (key == 'EJECUTIVOS' || key == 'GERENTES' || key == 'MIEMBRO DE EQUIPO' || key == 'MIEMBRO') {
        suma += cargos[key] ?? 0.0;
        count++;
      }
    }
    return count > 0 ? suma / count : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final rows = <DataRow>[];
    double totalPuntosObtenidos = 0.0;
    double totalPuntosPosibles = 0.0;

    for (final section in sections) {
      final label = section['label'] as String;
      final dimensionId = section['dimensionId'] as String;
      final comps = (section['comps'] as List).cast<String>();
      final compsText = (section['compsText'] as List).cast<String>();
      final puntos = (section['puntos'] as List).cast<double>();
      final maxDim = section['maxDim'] as double;

      // Encabezado de sección
      rows.add(DataRow(
        color: WidgetStateProperty.all(const Color(0xFF003056)),
        cells: [
          DataCell(Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          DataCell(Text(compsText[0], style: const TextStyle(color: Colors.white))),
          DataCell(Text(compsText[1], style: const TextStyle(color: Colors.white))),
          DataCell(Text(compsText[2], style: const TextStyle(color: Colors.white))),
        ],
      ));

      // Puntos posibles por cargo
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('Puntos posibles', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(puntos[0].toStringAsFixed(0), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(puntos[1].toStringAsFixed(0), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(puntos[2].toStringAsFixed(0), style: const TextStyle(color: Color(0xFF003056)))),
        ],
      ));

      // Total de la dimensión (usando promedio simple de cargos)
      final promDim = _promedioGeneralDimension(dimensionId).clamp(0.0, 5.0);
      final ptsDim = (promDim / 5.0) * maxDim;
      final pctDim = (promDim / 5.0) * 100.0;
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('Total Dimensión', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003056)))),
          DataCell(Text('${ptsDim.toStringAsFixed(1)} pts', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${pctDim.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
          const DataCell(Text('')),
        ],
      ));

      // % obtenido por cargo
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('% Obtenido por cargo', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${_porcentajeCargo(dimensionId, comps[0]).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${_porcentajeCargo(dimensionId, comps[1]).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${_porcentajeCargo(dimensionId, comps[2]).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
        ],
      ));

      // Puntos obtenidos por cargo
      final p0 = _puntosCargo(dimensionId, comps[0], puntos[0]);
      final p1 = _puntosCargo(dimensionId, comps[1], puntos[1]);
      final p2 = _puntosCargo(dimensionId, comps[2], puntos[2]);
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('Puntos obtenidos por cargo', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(p0.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(p1.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(p2.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF003056)))),
        ],
      ));

      totalPuntosObtenidos += (p0 + p1 + p2);
      totalPuntosPosibles += (puntos[0] + puntos[1] + puntos[2]); // suma sección (250/350/200)
    }

    // TOTAL (debe ser 0..800)
    rows.add(DataRow(
      color: WidgetStateProperty.all(const Color(0xFF003056)),
      cells: [
        const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
        DataCell(Text('${totalPuntosObtenidos.toStringAsFixed(1)} / ${totalPuntosPosibles.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
        const DataCell(Text('')),
        const DataCell(Text('')),
      ],
    ));

    return DataTable(
      headingRowHeight: 0,
      showBottomBorder: false,
      columnSpacing: 36,
      border: TableBorder.all(color: const Color(0xFF003056)),
      columns: const [
        DataColumn(label: SizedBox.shrink()),
        DataColumn(label: SizedBox.shrink()),
        DataColumn(label: SizedBox.shrink()),
        DataColumn(label: SizedBox.shrink()),
      ],
      rows: rows,
    );
  }
}
