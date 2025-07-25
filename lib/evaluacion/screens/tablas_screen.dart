// ignore_for_file: use_build_context_synchronously

import 'package:applensys/evaluacion/models/empresa.dart';
import 'package:applensys/evaluacion/screens/dashboard_screen.dart';
import 'package:applensys/evaluacion/screens/detalles_evaluacion.dart';
import 'package:applensys/evaluacion/services/local/evaluacion_cache_service.dart';
import 'package:applensys/evaluacion/widgets/drawer_lensys.dart';
import 'package:flutter/material.dart';

extension CapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

class TablasDimensionScreen extends StatefulWidget {
  static Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };

  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  static Future<void> cargarDatosPersistidos() async {
    final data = await EvaluacionCacheService().cargarTablas();
    if (data.isNotEmpty) {
      tablaDatos = data;
      dataChanged.value = !dataChanged.value;
    }
  }

  static Future<void> actualizarDato(
    String evaluacionId, {
    required String dimension,
    required String principio,
    required String comportamiento,
    required String cargo,
    required int valor,
    required List<String> sistemas,
    required String dimensionId,
    required String asociadoId,
    required String observaciones,
  }) async {
    final tablaDim = tablaDatos.putIfAbsent(dimension, () => {});
    final lista = tablaDim.putIfAbsent(evaluacionId, () => []);

    final idx = lista.indexWhere((item) =>
        item['principio'] == principio &&
        item['comportamiento'] == comportamiento &&
        item['cargo_raw'] == cargo &&
        item['dimension_id'] == dimensionId &&
        item['asociado_id'] == asociadoId);

    if (idx != -1) {
      lista[idx]['valor'] = valor;
      lista[idx]['sistemas'] = sistemas;
      lista[idx]['observaciones'] = observaciones;
    } else {
      lista.add({
        'principio': principio,
        'comportamiento': comportamiento,
        'cargo': cargo.trim().capitalize(),
        'cargo_raw': cargo,
        'valor': valor,
        'sistemas': sistemas,
        'dimension_id': dimensionId,
        'asociado_id': asociadoId,
        'observaciones': observaciones,
      });
    }

    await EvaluacionCacheService().guardarTablas(tablaDatos);
    dataChanged.value = !dataChanged.value;
  }

  final Empresa empresa;
  final String evaluacionId;
  final String asociadoId;
  final String empresaId;
  final String dimension;

  const TablasDimensionScreen({
    super.key,
    required this.empresa,
    required this.evaluacionId,
    required this.asociadoId,
    required this.empresaId,
    required this.dimension,
  });

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();
}

class _TablasDimensionScreenState extends State<TablasDimensionScreen> {
  final Map<String, String> dimensionInterna = {
    'IMPULSORES CULTURALES': 'Dimensión 1',
    'MEJORA CONTINUA': 'Dimensión 2',
    'ALINEAMIENTO EMPRESARIAL': 'Dimensión 3',
  };

  List<String> dimensiones = [];

  @override
  void initState() {
    super.initState();
    TablasDimensionScreen.dataChanged.addListener(_onDataChanged);
    _cargarDesdeCache();
  }

  @override
  void dispose() {
    TablasDimensionScreen.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => setState(() {});

  Future<void> _cargarDesdeCache() async {
    final data = await EvaluacionCacheService().cargarTablas();
    if (data.values.any((m) => m.isNotEmpty)) {
      setState(() => TablasDimensionScreen.tablaDatos = data);
    }
    setState(() {
      dimensiones = dimensionInterna.keys.toList();
    });
  }

  String _normalizeNivel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('miembro')) return 'Miembro';
    if (lower.contains('gerente')) return 'Gerente';
    return 'Ejecutivo';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dimensiones = dimensionInterna.keys.toList();

    return DefaultTabController(
      length: dimensiones.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF003056),
          title: const Text('Resultados en tiempo real', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.assessment, color: Colors.white),
              tooltip: 'Ver Dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(
                      evaluacionId: widget.evaluacionId,
                      empresa: widget.empresa,
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.grey.shade300,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade300,
            tabs: dimensiones.map((d) => Tab(child: Text(d))).toList(),
          ),
        ),
        endDrawer: const DrawerLensys(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003056),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final currentIndex = DefaultTabController.of(context).index;
                    final dimensionActual = dimensiones[currentIndex];
                    final keyInterna = dimensionInterna[dimensionActual] ?? dimensionActual;
                    final filas = TablasDimensionScreen.tablaDatos[keyInterna]?.values.expand((l) => l).toList() ?? [];

                    final sumas = {'Ejecutivo': 0.0, 'Gerente': 0.0, 'Miembro': 0.0};
                    final conteos = {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0};

                    for (var f in filas) {
                      final nivel = _normalizeNivel(f['cargo_raw'] ?? '');
                      final valor = (f['valor'] ?? 0).toDouble();
                      sumas[nivel] = sumas[nivel]! + valor;
                      conteos[nivel] = conteos[nivel]! + 1;
                    }

                    final promedio = <String, double>{};
                    sumas.forEach((nivel, suma) {
                      final count = conteos[nivel]!;
                      promedio[nivel] = count > 0 ? double.parse((suma / count).toStringAsFixed(2)) : 0.0;
                    });

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetallesEvaluacionScreen(
                          dimensionesPromedios: {dimensionActual: promedio},
                          empresa: widget.empresa,
                          evaluacionId: widget.evaluacionId,
                          dimension: dimensionActual,
                          promedios: promedio,
                          initialTabIndex: currentIndex,
                        ),
                      ),
                    );
                  },
                  child: const Text('Ver detalles y avance'),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: dimensiones.map((dimension) {
                  final key = dimensionInterna[dimension] ?? dimension;
                  final filas = TablasDimensionScreen.tablaDatos[key]?.values.expand((l) => l).toList() ?? [];

                  if (filas.isEmpty) {
                    return const Center(child: Text('No hay datos para mostrar para esta evaluación'));
                  }

                  return InteractiveViewer(
                    constrained: false,
                    scaleEnabled: false,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      child: DataTable(
                        columnSpacing: 36,
                        headingRowColor: WidgetStateProperty.all(isDark ? Colors.grey.shade800 : const Color(0xFF003056)),
                        dataRowColor: WidgetStateProperty.all(isDark ? Colors.black26 : Colors.grey.shade200),
                        border: TableBorder.all(color: const Color(0xFF003056)),
                        columns: const [
                          DataColumn(label: Text('Principio', style: TextStyle(color: Colors.white))),
                          DataColumn(label: Text('Comportamiento', style: TextStyle(color: Colors.white))),
                          DataColumn(label: Text('Ejecutivo', style: TextStyle(color: Colors.white))),
                          DataColumn(label: Text('Gerente', style: TextStyle(color: Colors.white))),
                          DataColumn(label: Text('Miembro', style: TextStyle(color: Colors.white))),
                          DataColumn(label: Text('Ejecutivo Sistemas', style: TextStyle(color: Colors.white))),
                          DataColumn(label: Text('Gerente Sistemas', style: TextStyle(color: Colors.white))),
                          DataColumn(label: Text('Miembro Equipo Sistemas', style: TextStyle(color: Colors.white))),
                          DataColumn(label: Text('Observaciones Ejecutivo', style: TextStyle(color: Colors.white))),
                          DataColumn(label: Text('Observaciones Gerente', style: TextStyle(color: Colors.white))),
                          DataColumn(label: Text('Observaciones Miembro Equipo', style: TextStyle(color: Colors.white))),
                        ],
                        rows: _buildRows(filas, isDark),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }



  List<DataRow> _buildRows(List<Map<String, dynamic>> filas, bool isDark) {
    final rows = <DataRow>[];
    // Agrupar por principio y comportamiento
    final Map<String, Map<String, Map<String, Map<String, dynamic>>>> agrupado = {};
    for (var f in filas) {
      final p = f['principio'] ?? '';
      final c = f['comportamiento'] ?? '';
      final nivel = _normalizeNivel(f['cargo_raw'] ?? '');
      agrupado.putIfAbsent(p, () => {});
      agrupado[p]!.putIfAbsent(c, () => {});
      agrupado[p]![c]![nivel] = f;
    }
    final niveles = ['Ejecutivo', 'Gerente', 'Miembro'];
    agrupado.forEach((principio, comps) {
      comps.forEach((comp, nivelesData) {
        final cells = <DataCell>[
          DataCell(Text(principio, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF003056)))),
          DataCell(Text(comp, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF003056)))),
          ...niveles.map((n) => DataCell(Text(
            nivelesData[n]?['valor']?.toString() ?? '-',
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF003056)),
          ))),
          ...niveles.map((n) => DataCell(Text(
            (nivelesData[n]?['sistemas'] is List && (nivelesData[n]?['sistemas'] as List).isNotEmpty)
                ? (nivelesData[n]?['sistemas'] as List).join(', ')
                : '-',
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF003056)),
          ))),
          ...niveles.map((n) => DataCell(Text(
            nivelesData[n]?['observaciones']?.toString() ?? '-',
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF003056)),
          ))),
        ];
        rows.add(DataRow(cells: cells));
      });
    });
    return rows;
  }
}
