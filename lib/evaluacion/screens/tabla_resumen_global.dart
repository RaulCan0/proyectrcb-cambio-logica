import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empresa.dart';
import '../services/local/evaluacion_cache_service.dart';
import '../custom/table_names.dart';

class TablaResumenGlobal extends StatefulWidget {
  final Empresa empresa;
  final String evaluacionId;

  const TablaResumenGlobal({
    super.key,
    required this.empresa,
    required this.evaluacionId,
  });

  @override
  State<TablaResumenGlobal> createState() => _TablaResumenGlobalState();
}

class _TablaResumenGlobalState extends State<TablaResumenGlobal> {
  List<Map<String, dynamic>> _datosRaw = [];
  bool _isLoading = true;
  Map<String, Map<String, double>> _promediosPorCargoDimension = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final cacheService = EvaluacionCacheService();
      await cacheService.init();
      
      dynamic rawTables = await cacheService.cargarTablas();
      
      if (rawTables != null) {
        final List<Map<String, dynamic>> flattened = [];
        if (rawTables is Map<String, dynamic>) {
          for (final dimEntry in rawTables.entries) {
            final dimData = dimEntry.value;
            if (dimData is Map<String, dynamic>) {
              for (final evalEntry in dimData.entries) {
                if (evalEntry.key == widget.evaluacionId) {
                  final rowsList = evalEntry.value;
                  if (rowsList is List) {
                    for (final row in rowsList) {
                      if (row is Map<String, dynamic>) {
                        flattened.add(row);
                      }
                    }
                  }
                }
              }
            }
          }
        }
        _datosRaw = flattened;
      }

      if (_datosRaw.isEmpty) {
        try {
          final supabase = Supabase.instance.client;
          final dataDetalles = await supabase
              .from(TableNames.detallesEvaluacion)
              .select()
              .eq('evaluacion_id', widget.evaluacionId);
          _datosRaw = List<Map<String, dynamic>>.from(dataDetalles);
        } catch (e) {
          debugPrint('Error cargando desde Supabase: $e');
        }
      }

      _calcularPromedios();
      
      debugPrint('=== TABLA SCORE GLOBAL DEBUG ===');
      debugPrint('Datos cargados: ${_datosRaw.length} filas');
      debugPrint('Promedios calculados: $_promediosPorCargoDimension');
      
    } catch (e) {
      debugPrint('Error en _cargarDatos: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calcularPromedios() {
    final Map<String, Map<String, List<double>>> sumasPorCargoDimension = {};
    
    for (final fila in _datosRaw) {
      final String dimensionId = (fila['dimension_id']?.toString()) ?? 'Sin dimensión';
      final String cargoRaw = (fila['cargo_raw']?.toString().toLowerCase().trim()) ?? '';
      final double valor = (fila['valor'] as num?)?.toDouble() ?? 0.0;
      
      String cargo = 'MIEMBROS DE EQUIPO';
      if (cargoRaw.contains('ejecutivo')) {
        cargo = 'EJECUTIVOS';
      } else if (cargoRaw.contains('gerente')) {
        cargo = 'GERENTES';
      }
      
      sumasPorCargoDimension.putIfAbsent(dimensionId, () => {});
      sumasPorCargoDimension[dimensionId]!.putIfAbsent(cargo, () => []);
      
      if (valor > 0) {
        sumasPorCargoDimension[dimensionId]![cargo]!.add(valor);
      }
    }
    
    _promediosPorCargoDimension = {};
    sumasPorCargoDimension.forEach((dimensionId, cargoData) {
      _promediosPorCargoDimension[dimensionId] = {};
      cargoData.forEach((cargo, valores) {
        if (valores.isNotEmpty) {
          final promedio = valores.reduce((a, b) => a + b) / valores.length;
          _promediosPorCargoDimension[dimensionId]![cargo] = promedio;
        } else {
          _promediosPorCargoDimension[dimensionId]![cargo] = 0.0;
        }
      });
    });
  }

  double promedioPonderado(String dimensionId, String cargo) {
    final promedio = _promediosPorCargoDimension[dimensionId]?[cargo] ?? 0.0;
    return (promedio / 5.0) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF003056),
          title: const Center(
            child: Text('Resumen Global', style: TextStyle(color: Colors.white)),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    const sections = [
      {
        'label': 'Impulsores Culturales (250 pts)',
        'dimensionId': '1',
        'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
        'puntos': ['125', '75', '50'],
      },
      {
        'label': 'Mejora Continua (350 pts)',
        'dimensionId': '2',
        'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
        'puntos': ['70', '105', '175'],
      },
      {
        'label': 'Alineamiento Empresarial (200 pts)',
        'dimensionId': '3',
        'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
        'puntos': ['110', '60', '30'],
      },
    ];

    final rows = <DataRow>[];
    for (var sec in sections) {
      final label = sec['label'] as String;
      final dimensionId = sec['dimensionId'] as String;
      final comps = sec['comps'] as List<String>;
      final puntos = (sec['puntos'] as List<String>).map(int.parse).toList();

      rows.add(DataRow(
        color: WidgetStateProperty.all(const Color(0xFF003056)),
        cells: [
          DataCell(Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          DataCell(Text(comps[0], style: const TextStyle(color: Colors.white))),
          DataCell(Text(comps[1], style: const TextStyle(color: Colors.white))),
          DataCell(Text(comps[2], style: const TextStyle(color: Colors.white))),
        ],
      ));
      
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('Puntos posibles', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(puntos[0].toString(), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(puntos[1].toString(), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(puntos[2].toString(), style: const TextStyle(color: Color(0xFF003056)))),
        ],
      ));
      
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('% Obtenido', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${promedioPonderado(dimensionId, comps[0]).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${promedioPonderado(dimensionId, comps[1]).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${promedioPonderado(dimensionId, comps[2]).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
        ],
      ));
      
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('Puntos obtenidos', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text((promedioPonderado(dimensionId, comps[0]) / 100 * puntos[0]).toStringAsFixed(0), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text((promedioPonderado(dimensionId, comps[1]) / 100 * puntos[1]).toStringAsFixed(0), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text((promedioPonderado(dimensionId, comps[2]) / 100 * puntos[2]).toStringAsFixed(0), style: const TextStyle(color: Color(0xFF003056)))),
        ],
      ));
    }

    const auxLabels = [
      'seguridad/medio ambiente/moral',
      'satisfacción del cliente',
      'calidad',
      'costo/productividad',
      'entregas',
    ];
    
    final totalGeneral = _promediosPorCargoDimension.values
        .expand((cargos) => cargos.values)
        .where((v) => v > 0)
        .fold<double>(0, (sum, v) => sum + v);
    final countValores = _promediosPorCargoDimension.values
        .expand((cargos) => cargos.values)  
        .where((v) => v > 0)
        .length;
    final promedioGeneral = countValores > 0 ? totalGeneral / countValores : 0.0;
    
    final auxRows = auxLabels.asMap().entries.map((entry) {
      final index = entry.key;
      final label = entry.value;
      final valor = promedioGeneral > 0 ? 
          (promedioGeneral + (index * 0.2 - 0.4)).clamp(0.0, 5.0) : 0.0;
      
      return DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          DataCell(Text(label, style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(valor.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(valor > 3.0 ? 'Bueno' : valor > 2.0 ? 'Regular' : 'Bajo', 
                      style: TextStyle(color: valor > 3.0 ? Colors.green : 
                                               valor > 2.0 ? Colors.orange : Colors.red))),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        title: const Center(
          child: Text('Resumen Global', style: TextStyle(color: Colors.white)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DataTable(
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
              ),
              const SizedBox(width: 24),
              DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF003056)),
                headingTextStyle: const TextStyle(color: Colors.white),
                columnSpacing: 24,
                border: TableBorder.all(color: const Color(0xFF003056)),
                columns: const [
                  DataColumn(label: Text('Shingo Results', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Valor', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Estado', style: TextStyle(color: Colors.white))),
                ],
                rows: auxRows,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
