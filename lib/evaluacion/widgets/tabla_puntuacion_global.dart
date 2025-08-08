import 'package:flutter/material.dart';

class TablaPuntuacionGlobal extends StatelessWidget {
  final Map<String, Map<String, double>> promediosPorDimension;

  const TablaPuntuacionGlobal({
    super.key,
    required this.promediosPorDimension,
  });

  // Configuración de secciones con puntos máximos
  static const List<Map<String, dynamic>> sections = [
    {
      'label': 'Impulsores Culturales (250 pts)',
      'dimensionId': '1',
      'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
      'compsText': ['EJECUTIVOS 50%', 'GERENTES 30%', 'MIEMBROS DE EQUIPO 20%'],
      'puntos': [125, 75, 50],
    },
    {
      'label': 'Mejora Continua (350 pts)',
      'dimensionId': '2',
      'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
      'compsText': ['EJECUTIVOS 20%', 'GERENTES 30%', 'MIEMBROS DE EQUIPO 50%'],
      'puntos': [70, 105, 175],
    },
    {
      'label': 'Alineamiento Empresarial (200 pts)',
      'dimensionId': '3',
      'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
      'compsText': ['EJECUTIVOS 55%', 'GERENTES 30%', 'MIEMBROS DE EQUIPO 15%'],
      'puntos': [110, 60, 30],
    },
  ];

  double _calcularPorcentaje(String dimensionId, String cargo) {
    final promedio = promediosPorDimension[dimensionId]?[cargo] ?? 0.0;
    return (promedio / 5.0) * 100;
  }

  int _calcularPuntosObtenidos(String dimensionId, String cargo, int puntosPosibles) {
    final porcentaje = _calcularPorcentaje(dimensionId, cargo);
    return (porcentaje / 100 * puntosPosibles).round();
  }

  @override
  Widget build(BuildContext context) {
    final rows = <DataRow>[];
    int totalPuntosObtenidos = 0;
    int totalPuntosPosibles = 0;

    for (final section in sections) {
      final label = section['label'] as String;
      final dimensionId = section['dimensionId'] as String;
      final comps = section['comps'] as List<String>;
      final compsText = section['compsText'] as List<String>;
      final puntos = section['puntos'] as List<int>;

      int sectionPuntosObtenidos = 0;
      int sectionPuntosPosibles = 0;

      // Fila de encabezado de sección
      rows.add(DataRow(
        color: WidgetStateProperty.all(const Color(0xFF003056)),
        cells: [
          DataCell(
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          DataCell(Text(compsText[0], style: const TextStyle(color: Colors.white))),
          DataCell(Text(compsText[1], style: const TextStyle(color: Colors.white))),
          DataCell(Text(compsText[2], style: const TextStyle(color: Colors.white))),
        ],
      ));

      // Fila de puntos posibles
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(
            Text(
              'Puntos posibles',
              style: TextStyle(color: Color(0xFF003056)),
            ),
          ),
          DataCell(
            Text(
              puntos[0].toString(),
              style: const TextStyle(color: Color(0xFF003056)),
            ),
          ),
          DataCell(
            Text(
              puntos[1].toString(),
              style: const TextStyle(color: Color(0xFF003056)),
            ),
          ),
          DataCell(
            Text(
              puntos[2].toString(),
              style: const TextStyle(color: Color(0xFF003056)),
            ),
          ),
        ],
      ));

      // Fila de porcentaje obtenido
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(
            Text(
              '% Obtenido',
              style: TextStyle(color: Color(0xFF003056)),
            ),
          ),
          DataCell(
            Text(
              '${_calcularPorcentaje(dimensionId, comps[0]).toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFF003056)),
            ),
          ),
          DataCell(
            Text(
              '${_calcularPorcentaje(dimensionId, comps[1]).toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFF003056)),
            ),
          ),
          DataCell(
            Text(
              '${_calcularPorcentaje(dimensionId, comps[2]).toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFF003056)),
            ),
          ),
        ],
      ));

      // Calculamos los puntos obtenidos para esta sección
      for (int i = 0; i < comps.length; i++) {
        final puntosObtenidos = _calcularPuntosObtenidos(dimensionId, comps[i], puntos[i]);
        sectionPuntosObtenidos += puntosObtenidos;
        sectionPuntosPosibles += puntos[i];
      }

      // Sumamos al total general
      totalPuntosObtenidos += sectionPuntosObtenidos;
      totalPuntosPosibles += sectionPuntosPosibles;

      // Fila de puntos obtenidos
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(
            Text(
              'Puntos obtenidos',
              style: TextStyle(color: Color(0xFF003056)),
            ),
          ),
          DataCell(
            Text(
              _calcularPuntosObtenidos(dimensionId, comps[0], puntos[0]).toString(),
              style: const TextStyle(color: Color(0xFF003056)),
            ),
          ),
          DataCell(
            Text(
              _calcularPuntosObtenidos(dimensionId, comps[1], puntos[1]).toString(),
              style: const TextStyle(color: Color(0xFF003056)),
            ),
          ),
          DataCell(
            Text(
              _calcularPuntosObtenidos(dimensionId, comps[2], puntos[2]).toString(),
              style: const TextStyle(color: Color(0xFF003056)),
            ),
          ),
        ],
      ));
    }

    // Fila de Total
    rows.add(DataRow(
      color: WidgetStateProperty.all(const Color(0xFF003056)),
      cells: [
        const DataCell(
          Text(
            'TOTAL',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        DataCell(
          Text(
            '$totalPuntosObtenidos / $totalPuntosPosibles',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
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
