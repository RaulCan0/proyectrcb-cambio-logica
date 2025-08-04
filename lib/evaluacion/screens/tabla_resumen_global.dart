import 'package:flutter/material.dart';
import '../models/empresa.dart';
import '../services/shingo_result_service.dart';
import '../services/helpers/score_calculator_service.dart';

class TablaScoreGlobal extends StatefulWidget {
  final Empresa empresa;
  final String evaluacionId;

  const TablaScoreGlobal({
    super.key,
    required this.empresa,
    required this.evaluacionId,
  });

  @override
  State<TablaScoreGlobal> createState() => _TablaScoreGlobalState();
}

class _TablaScoreGlobalState extends State<TablaScoreGlobal> {
  Map<String, dynamic>? scoreData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarScores();
  }

  Future<void> _cargarScores() async {
    try {
      final calculator = ScoreCalculatorService();
      final data = await calculator.calcularScoreShingo(widget.evaluacionId);
      setState(() {
        scoreData = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando scores: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Score Global - ${widget.empresa.nombre}'),
          backgroundColor: const Color(0xFF003056),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (scoreData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Score Global - ${widget.empresa.nombre}'),
          backgroundColor: const Color(0xFF003056),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text('No se pudieron cargar los datos de evaluación'),
        ),
      );
    }

    final scores = scoreData!['scoresPorDimension'] as Map<String, dynamic>;
    final puntajeTotalObtenido = scoreData!['puntajeTotalObtenido'] as int;
    final puntajeTotalPosible = scoreData!['puntajeTotalPosible'] as int;
    final porcentajeTotal = scoreData!['porcentajeTotal'] as double;
    
    final calculator = ScoreCalculatorService();
    final nivelShingo = calculator.determinarNivelShingo(puntajeTotalObtenido.toDouble());

    // Definir estructura de datos con información real
    final dimensiones = [
      {
        'nombre': 'Impulsores Culturales',
        'key': 'Dimensión 1',
        'puntosMaximos': 250,
        'color': const Color.fromARGB(255, 122, 141, 245),
      },
      {
        'nombre': 'Mejora Continua',
        'key': 'Dimensión 2', 
        'puntosMaximos': 350,
        'color': Colors.indigo,
      },
      {
        'nombre': 'Alineamiento Empresarial',
        'key': 'Dimensión 3',
        'puntosMaximos': 200,
        'color': const Color.fromARGB(255, 14, 24, 78),
      },
    ];

    // Construir filas de la tabla principal
    final rows = <DataRow>[];
    
    for (var dim in dimensiones) {
      final dimKey = dim['key'] as String;
      final dimData = scores[dimKey] as Map<String, dynamic>?;
      
      if (dimData == null) continue;
      
      final totalDim = dimData['totalDimension'] as Map<String, dynamic>;
      
      // Fila de encabezado de dimensión
      rows.add(DataRow(
        color: WidgetStateProperty.all(dim['color'] as Color),
        cells: [
          DataCell(Text(
            '${dim['nombre']} (${dim['puntosMaximos']} pts)',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          )),
          const DataCell(Text('Ejecutivo', style: TextStyle(color: Colors.white))),
          const DataCell(Text('Gerente', style: TextStyle(color: Colors.white))),
          const DataCell(Text('Miembro', style: TextStyle(color: Colors.white))),
          const DataCell(Text('Total', style: TextStyle(color: Colors.white))),
        ],
      ));
      
      // Fila de puntos máximos
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('Puntos posibles', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${dimData['Ejecutivo']['puntosMaximos']}', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${dimData['Gerente']['puntosMaximos']}', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${dimData['Miembro']['puntosMaximos']}', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${totalDim['puntosMaximos']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003056)))),
        ],
      ));
      
      // Fila de porcentajes obtenidos
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('% Obtenido', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${dimData['Ejecutivo']['porcentaje'].toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${dimData['Gerente']['porcentaje'].toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${dimData['Miembro']['porcentaje'].toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${totalDim['porcentaje'].toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003056)))),
        ],
      ));
      
      // Fila de puntos obtenidos
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('Puntos obtenidos', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${dimData['Ejecutivo']['puntosObtenidos']}', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${dimData['Gerente']['puntosObtenidos']}', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${dimData['Miembro']['puntosObtenidos']}', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${totalDim['puntosObtenidos']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003056)))),
        ],
      ));
      
      // Separador
      rows.add(const DataRow(cells: [
        DataCell(Text('')),
        DataCell(Text('')), 
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
      ]));
    }

    // Etiquetas y valores para la tabla auxiliar
    // Tabla auxiliar para Shingo Results (5 resultados)
    const auxLabels = [
      'seguridad/medio ambiente/moral',
      'satisfacción del cliente',
      'calidad',
      'costo/productividad',
      'entregas',
    ];
    
    final shingoService = ShingoResultService();
    final auxRows = auxLabels.map((label) {
      final calif = shingoService.getCalificacion(label) ?? 0;
      return DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          DataCell(Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(calif.toString(), style: const TextStyle(color: Color(0xFF003056)))),
          const DataCell(Text('Obtenido', style: TextStyle(color: Color(0xFF003056)))),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Score Global - ${widget.empresa.nombre}'),
        backgroundColor: const Color(0xFF003056),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen total
            Card(
              color: _getColorForScore(porcentajeTotal),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'PUNTAJE TOTAL SHINGO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$puntajeTotalObtenido / $puntajeTotalPosible puntos',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${porcentajeTotal.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        nivelShingo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tabla principal de evaluación comportamental
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EVALUACIÓN COMPORTAMENTAL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columnSpacing: 20,
                              border: TableBorder.all(color: Colors.grey),
                              columns: const [
                                DataColumn(label: Text('Dimensión')),
                                DataColumn(label: Text('Ejecutivo')),
                                DataColumn(label: Text('Gerente')),
                                DataColumn(label: Text('Miembro')),
                                DataColumn(label: Text('Total')),
                              ],
                              rows: rows,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tabla de resultados Shingo
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RESULTADOS SHINGO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Navegar a ShingoResultsScreen para editar
                              Navigator.pushNamed(context, '/shingo-results');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003056),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Editar Resultados'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: DataTable(
                          columnSpacing: 20,
                          border: TableBorder.all(color: Colors.grey),
                          columns: const [
                            DataColumn(label: Text('Resultado')),
                            DataColumn(label: Text('Calificación')),
                            DataColumn(label: Text('Estado')),
                          ],
                          rows: auxRows,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForScore(double porcentaje) {
    if (porcentaje >= 90) return Colors.green.shade700;      // Shingo Prize
    if (porcentaje >= 80) return Colors.blue.shade700;       // Silver Medallion
    if (porcentaje >= 70) return Colors.orange.shade700;     // Bronze Medallion
    if (porcentaje >= 50) return Colors.purple.shade700;     // Recognition
    return Colors.red.shade700;                              // Needs Improvement
  }
}
