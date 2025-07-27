// ignore_for_file: use_build_context_synchronously

import 'package:applensys/evaluacion/models/empresa.dart';
import 'package:applensys/evaluacion/screens/dashboard_screen.dart';
import 'package:applensys/evaluacion/screens/detalles_evaluacion.dart';
import 'package:applensys/evaluacion/services/local/calificaciones_sync_service.dart';
// ignore: unused_import
import 'package:applensys/evaluacion/services/domain/supabase_service.dart';
import 'package:applensys/evaluacion/widgets/drawer_lensys.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension CapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

class TablasDimensionScreen extends StatefulWidget {
  // Método estático para actualizar datos y sincronizar
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
    try {
      final tablaDim = tablaDatos.putIfAbsent(dimension, () => {});
      final lista = tablaDim.putIfAbsent(evaluacionId, () => []);
      final indiceExistente = lista.indexWhere((item) =>
        item['principio'] == principio &&
        item['comportamiento'] == comportamiento &&
        item['cargo_raw'] == cargo &&
        item['dimension_id'] == dimensionId &&
        item['asociado_id'] == asociadoId);
      if (indiceExistente != -1) {
        lista[indiceExistente]['valor'] = valor;
        lista[indiceExistente]['sistemas'] = sistemas;
        lista[indiceExistente]['observaciones'] = observaciones;
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
      // Guardar y sincronizar
      final syncService = CalificacionesSyncService();
      await syncService.guardarTablas(tablaDatos);
      await syncService.sincronizarCacheASupabase();
      dataChanged.value = !dataChanged.value;
    } catch (e) {
      debugPrint('Error al guardar: $e');
    }
  }
  // Variables estáticas públicas para acceso global
  static Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {};
  static ValueNotifier<bool> dataChanged = ValueNotifier(false);

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


class _TablasDimensionScreenState extends State<TablasDimensionScreen> with TickerProviderStateMixin {
  final CalificacionesSyncService syncService = CalificacionesSyncService();
  bool isLoading = true;
  String errorMsg = '';
  final Map<String, String> dimensionInterna = {
    'IMPULSORES CULTURALES': 'Dimensión 1',
    'MEJORA CONTINUA': 'Dimensión 2',
    'ALINEAMIENTO EMPRESARIAL': 'Dimensión 3',
  };
  List<String> dimensiones = [
    'IMPULSORES CULTURALES',
    'MEJORA CONTINUA',
    'ALINEAMIENTO EMPRESARIAL',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { isLoading = true; errorMsg = ''; });
    try {
      await syncService.sincronizarDesdeSupabase();
      TablasDimensionScreen.tablaDatos = await syncService.cargarTablas();
    } catch (e) {
      errorMsg = 'Error al cargar datos: $e';
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  String _normalizeNivel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('miembro')) return 'Miembro';
    if (lower.contains('gerente')) return 'Gerente';
    return 'ejecutivo';
  }

  @override
  Widget build(BuildContext context) {
    // Variable 'dims' eliminada porque no se utiliza

    return DefaultTabController(
      length: dimensiones.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF003056),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Resultados en tiempo real', style: TextStyle(color: Colors.white)),
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
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.grey.shade300,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade300,
            tabs: dimensiones.map((d) => Tab(child: Text(d))).toList(),
          ),
        ),
        drawer: const DrawerLensys(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Center(
                child: Builder(
                  builder: (innerContext) => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003056),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _irADetalles(innerContext),
                    child: const Text('Ver detalles y avance'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: dimensiones.map((dimension) {
                  final keyInterna = dimensionInterna[dimension] ?? dimension;
                  final filas = TablasDimensionScreen.tablaDatos[keyInterna]?.values.expand((l) => l).toList() ?? [];

                  if (filas.isEmpty) {
                    return const Center(child: Text('No hay datos para mostrar para esta evaluación'));
                  }

                  return ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      scrollbars: true,
                      physics: ClampingScrollPhysics(),
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        child: DataTable(
                          columnSpacing: 36,
                          headingRowColor: WidgetStateProperty.resolveWith(
                            (states) => Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : const Color(0xFF003056),
                          ),
                          dataRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                          border: TableBorder.all(color: const Color(0xFF003056)),
                          columns: const [
                            DataColumn(label: Text('Principio', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Comportamiento', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Ejecutivo', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Gerente', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Miembro', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Ejecutivo Sistemas', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Gerente Sistemas', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Miembro Sistemas', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Ejecutivo Observaciones', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Gerente Observaciones', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Miembro Observaciones', style: TextStyle(color: Colors.white))),
                          ],
                          rows: _buildRows(filas),
                        ),
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

  void _irADetalles(BuildContext context) {
    final currentIndex = DefaultTabController.of(context).index;
    final dimensionActual = dimensiones[currentIndex];

    final promediosPorDimension = <String, Map<String, double>>{};
    for (final dim in dimensiones) {
      final keyInterna = dimensionInterna[dim] ?? dim;
      final filas = TablasDimensionScreen.tablaDatos[keyInterna]?.values.expand((l) => l).toList() ?? [];

      final sumasNivel = {'Ejecutivo': 0.0, 'Gerente': 0.0, 'Miembro': 0.0};
      final conteosNivel = {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0};
      final sistemasPromedio = SistemasPromedio();

      for (var f in filas) {
        final nivel = _normalizeNivel(f['cargo_raw'] ?? '');
        final valor = (f['valor'] ?? 0).toDouble();
        final sistemas = (f['sistemas'] as List?)?.whereType<String>().toList() ?? [];
        sumasNivel[nivel] = sumasNivel[nivel]! + valor;
        conteosNivel[nivel] = conteosNivel[nivel]! + 1;
        sistemasPromedio.agregar(nivel, sistemas);
      }

      final promediosNivel = <String, double>{};
      double totalProm = 0;
      sumasNivel.forEach((nivel, suma) {
        final cnt = conteosNivel[nivel]!;
        final prom = cnt > 0 ? suma / cnt : 0;
        promediosNivel[nivel] = double.parse(prom.toStringAsFixed(2));
        totalProm += prom;
      });
      promediosNivel['General'] = double.parse((totalProm / sumasNivel.length).toStringAsFixed(2));
      promediosNivel['Sistemas'] = double.parse(sistemasPromedio.promedio().toStringAsFixed(2));
      promediosPorDimension[dim] = promediosNivel;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallesEvaluacionScreen(
          dimensionesPromedios: promediosPorDimension,
          empresa: widget.empresa,
          evaluacionId: widget.evaluacionId,
          promedios: promediosPorDimension[dimensionActual],
          dimension: dimensionActual,
          initialTabIndex: currentIndex,
        ),
      ),
    );
  }

  List<DataRow> _buildRows(List<Map<String, dynamic>> filas) {
    final sumas = <String, Map<String, Map<String, int>>>{};
    final conteos = <String, Map<String, Map<String, int>>>{};
    final sistemasPorNivel = <String, Map<String, Map<String, Set<String>>>>{};
    final observacionesPorNivel = <String, Map<String, Map<String, List<String>>>>{};

    for (var f in filas) {
      final principio = f['principio'] ?? '';
      final comportamiento = f['comportamiento'] ?? '';
      final nivel = _normalizeNivel(f['cargo_raw'] ?? '');
      final int valor = ((f['valor'] ?? 0) as num).toInt();
      final sistemas = (f['sistemas'] as List?)?.whereType<String>().toList() ?? [];
      final observacion = (f['observaciones'] ?? '').toString();

      sumas.putIfAbsent(principio, () => {});
      sumas[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      conteos.putIfAbsent(principio, () => {});
      conteos[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      sistemasPorNivel.putIfAbsent(principio, () => {});
      sistemasPorNivel[principio]!.putIfAbsent(comportamiento, () => {
        'Ejecutivo': <String>{},
        'Gerente': <String>{},
        'Miembro': <String>{},
      });
      observacionesPorNivel.putIfAbsent(principio, () => {});
      observacionesPorNivel[principio]!.putIfAbsent(comportamiento, () => {
        'Ejecutivo': <String>[],
        'Gerente': <String>[],
        'Miembro': <String>[],
      });

      sumas[principio]![comportamiento]![nivel] =
          sumas[principio]![comportamiento]![nivel]! + valor;
      conteos[principio]![comportamiento]![nivel] =
          conteos[principio]![comportamiento]![nivel]! + 1;
      for (var s in sistemas) {
        sistemasPorNivel[principio]![comportamiento]![nivel]!.add(s);
      }
      if (observacion.isNotEmpty) {
        observacionesPorNivel[principio]![comportamiento]![nivel]!.add(observacion);
      }
    }

    return sumas.entries.expand((e) {
      final p = e.key;
      return e.value.entries.map((cEntry) {
        final c = cEntry.key;
        final nivelVals = cEntry.value;
        final niveles = ['Ejecutivo', 'Gerente', 'Miembro'];
        return DataRow(cells: [
          DataCell(Text(p, style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(c, style: const TextStyle(color: Color(0xFF003056)))),
          ...niveles.map((n) {
            final suma = nivelVals[n] ?? 0;
            final count = conteos[p]![c]![n]!;
            return DataCell(Text(
              count > 0 ? (suma / count).toStringAsFixed(2) : '-',
              style: const TextStyle(color: Color(0xFF003056)),
            ));
          }),
          ...niveles.map((n) {
            final sistemas = sistemasPorNivel[p]![c]![n]!;
            return DataCell(Text(
              sistemas.isEmpty ? '-' : sistemas.join(', '),
              style: const TextStyle(color: Color(0xFF003056)),
            ));
          }),
          ...niveles.map((n) {
            final obsList = observacionesPorNivel[p]![c]![n]!;
            return DataCell(Text(
              obsList.isEmpty ? '-' : obsList.join(' | '),
              style: const TextStyle(color: Color(0xFF003056)),
            ));
          }),
        ]);
      });
    }).toList();
  }
}

class SistemasPromedio {
  final Map<String, Set<String>> _sistemasPorNivel = {
    'Ejecutivo': <String>{},
    'Gerente': <String>{},
    'Miembro': <String>{},
  };

  void agregar(String nivel, List<String> sistemas) {
    final key = nivel.capitalize();
    if (_sistemasPorNivel.containsKey(key)) {
      _sistemasPorNivel[key]!.addAll(sistemas);
    }
  }

  double promedio() {
    if (_sistemasPorNivel.isEmpty) return 0.0;
    final totalSistemas = _sistemasPorNivel.values.fold<int>(0, (sum, set) => sum + set.length);
    final nivelesConSistemas = _sistemasPorNivel.values.where((set) => set.isNotEmpty).length;
    return nivelesConSistemas == 0 ? 0.0 : totalSistemas / _sistemasPorNivel.length;
  }

}

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<void> insertarOActualizarCalificacion({
    required String evaluacionId,
    required String principio,
    required String comportamiento,
    required String cargo,
    required int valor,
    required List<String> sistemas,
    required int dimensionId,
    required String asociadoId,
    required String observaciones,
  }) async {
    try {
      await supabase
          .from('calificaciones')
          .upsert(
            {
              'evaluacion_id': evaluacionId,
              'principio': principio,
              'comportamiento': comportamiento,
              'cargo': cargo,
              'calificacion': valor,
              'sistemas': sistemas,
              'dimension_id': dimensionId,
              'asociado_id': asociadoId,
              'observaciones': observaciones,
            },
            onConflict: 'evaluacion_id,principio,comportamiento,cargo,dimension_id,asociado_id',
          )
          .select();
    } catch (e) {
      throw Exception('Error al insertar/actualizar calificación: $e');
    }
  }
}