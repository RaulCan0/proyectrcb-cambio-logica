// 🛠 TablasDimensionScreen corregida y completa

import 'package:applensys/evaluacion/services/caladap.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/evaluacion/models/empresa.dart';
import 'package:applensys/evaluacion/screens/dashboard_screen.dart';
import 'package:applensys/evaluacion/screens/detalles_evaluacion.dart';
import 'package:applensys/evaluacion/widgets/drawer_lensys.dart';

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

  /// Guardar/actualizar en memoria + cache + Supabase
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
    String? observaciones,
    String? evidenciaUrl,
    DateTime? fechaEvaluacion,
  }) async {
    final tablaDim = tablaDatos.putIfAbsent(dimension, () => {});
    final lista = tablaDim.putIfAbsent(evaluacionId, () => []);

    final i = lista.indexWhere((item) =>
        item['principio'] == principio &&
        item['comportamiento'] == comportamiento &&
        item['cargo_raw'] == cargo &&
        item['dimension_id'] == dimensionId &&
        item['asociado_id'] == asociadoId);

    final base = {
      'principio': principio,
      'comportamiento': comportamiento,
      'cargo': cargo.trim().capitalize(),
      'cargo_raw': cargo,
      'valor': valor,
      'sistemas': sistemas,
      'dimension_id': dimensionId,
      'asociado_id': asociadoId,
      'observaciones': observaciones ?? '',
      'evidencia_url': evidenciaUrl,
      'fecha_evaluacion': (fechaEvaluacion ?? DateTime.now()).toIso8601String(),
    };

    if (i != -1) {
      lista[i].addAll(base);
    } else {
      lista.add(base);
    }

    // Data is automatically synchronized with Supabase through providers

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final empresaIdJwt =
        (user?.userMetadata?['empresa_id']?.toString()) ??
        (user?.appMetadata['empresa_id']?.toString()) ??
        (user?.id ?? '');

    await supabase.from('calificaciones').upsert({
      'id_evaluacion': evaluacionId,
      'id_dimension': int.tryParse(dimensionId) ?? dimensionId,
      'id_asociado': asociadoId,
      'id_empresa': empresaIdJwt,
      'principio': principio,
      'comportamiento': comportamiento,
      'cargo': cargo,
      'puntaje': valor,
      'sistemas': sistemas,
      'observaciones': observaciones ?? '',
      'evidencia_url': evidenciaUrl,
      'fecha_evaluacion': (fechaEvaluacion ?? DateTime.now()).toIso8601String(),
    });

    dataChanged.value = !dataChanged.value;
  }

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();
}

class _TablasDimensionScreenState extends State<TablasDimensionScreen>
    with TickerProviderStateMixin {
  final Map<String, String> dimensionInterna = const {
    'IMPULSORES CULTURALES': 'Dimensión 1',
    'MEJORA CONTINUA': 'Dimensión 2',
    'ALINEAMIENTO EMPRESARIAL': 'Dimensión 3',
  };

  List<String> dimensiones = [];
  RealtimeChannel? _channel;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    TablasDimensionScreen.dataChanged.addListener(_onDataChanged);
    _cargarDatosIniciales();
    _suscribirseASupabase();
  }

  @override
  void dispose() {
    TablasDimensionScreen.dataChanged.removeListener(_onDataChanged);
    _channel?.unsubscribe();
    _channel = null;
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Load data directly from Supabase through providers
      await _recargarDesdeSupabase();
      dimensiones = dimensionInterna.keys.toList();
    } catch (e) {
      _error = 'Error al cargar datos: $e';
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _suscribirseASupabase() {
    final supabase = Supabase.instance.client;

    _channel?.unsubscribe();
    _channel = supabase
        .channel('calificaciones-${widget.empresaId}-${widget.evaluacionId}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'calificaciones',
        callback: (payload) async {
          final record = payload.newRecord;
          final empresaId = (record['id_empresa'] ?? '').toString();
          final evalId = (record['id_evaluacion'] ?? '').toString();

          if (empresaId == widget.empresaId && evalId == widget.evaluacionId) {
            await _recargarDesdeSupabase();
          }
        },
      )
      ..subscribe();
  }

  Future<void> _recargarDesdeSupabase() async {
    final supabase = Supabase.instance.client;

    try {
      final datos = await supabase
          .from('calificaciones')
          .select()
          .eq('id_empresa', widget.empresaId)
          .eq('id_evaluacion', widget.evaluacionId);

      final nuevaTabla =
          CalificacionAdapter.toTablaDatos(List<Map<String, dynamic>>.from(datos));

      if (mounted) {
        setState(() {
          TablasDimensionScreen.tablaDatos = nuevaTabla;
        });
      } else {
        TablasDimensionScreen.tablaDatos = nuevaTabla;
      }

      // Data is automatically synchronized with Supabase
      TablasDimensionScreen.dataChanged.value =
          !TablasDimensionScreen.dataChanged.value;
    } catch (e) {
      debugPrint("❌ Error recargando supabase: $e");
    }
  }

  String _normalizeNivel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('miembro')) return 'Miembro';
    if (lower.contains('gerente')) return 'Gerente';
    return 'Ejecutivo';
  }

  @override
  Widget build(BuildContext context) {
    dimensiones = dimensionInterna.keys.toList();
    return DefaultTabController(
      length: dimensiones.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF003056),
          title: Center(
            child: Text('Resultados empresa ${widget.empresa.nombre}',
                style: const TextStyle(color: Colors.white)),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.assessment, color: Colors.white),
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
        endDrawer: const DrawerLensys(),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Builder(
                            builder: (tabContext) => ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003056),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _irADetalles(tabContext),
                              child: const Text('Ver detalles y avance'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: dimensiones.map((dimension) {
                              final keyInterna = dimensionInterna[dimension]!;
                              final evalMap =
                                  TablasDimensionScreen.tablaDatos[keyInterna];
                              final filas = evalMap != null
                                  ? evalMap.values.expand((l) => l).toList()
                                  : <Map<String, dynamic>>[];
                              if (filas.isEmpty) {
                                return const Center(
                                    child: Text('No hay datos para mostrar'));
                              }
                              return _buildDataTable(filas);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> filas) {
    return InteractiveViewer(
      constrained: false,
      scaleEnabled: false,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: DataTable(
            columnSpacing: 36,
            headingRowColor: WidgetStateProperty.resolveWith(
              (_) => const Color(0xFF003056),
            ),
            dataRowColor: WidgetStateProperty.all(
              Colors.grey.shade200,
            ),
            border: TableBorder.all(color: const Color(0xFF003056)),
            columns: const [
              DataColumn(
                  label: Text('Principio',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Comportamiento',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Ejecutivo',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Gerente',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Miembro',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Ejecutivo Sistemas',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Gerente Sistemas',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Miembro Sistemas',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Ejecutivo observaciones',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Gerente observaciones',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Miembro observaciones',
                      style: TextStyle(color: Colors.white))),
            ],
            rows: _buildRowsPrincipioPromedio(filas),
          ),
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
      final evalMap = TablasDimensionScreen.tablaDatos[keyInterna];
      final filas =
          evalMap != null ? evalMap.values.expand((l) => l).toList() : <Map<String, dynamic>>[];

      final sumasNivel = {'Ejecutivo': 0.0, 'Gerente': 0.0, 'Miembro': 0.0};
      final conteosNivel = {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0};
      final sistemasPromedio = SistemasPromedio();

      for (var f in filas) {
        final nivel = _normalizeNivel(f['cargo_raw'] ?? '');
        final valor = (f['valor'] ?? 0).toDouble();
        final sistemas =
            (f['sistemas'] as List?)?.whereType<String>().toList() ?? [];
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
      promediosNivel['General'] =
          double.parse((totalProm / sumasNivel.length).toStringAsFixed(2));
      promediosNivel['Sistemas'] =
          double.parse(sistemasPromedio.promedio().toStringAsFixed(2));
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

  List<DataRow> _buildRowsPrincipioPromedio(List<Map<String, dynamic>> filas) {
    final sumas = <String, Map<String, Map<String, int>>>{};
    final conteos = <String, Map<String, Map<String, int>>>{};
    final sistemasPorNivel = <String, Map<String, Map<String, Set<String>>>>{};
    final observacionesPorNivel =
        <String, Map<String, Map<String, List<String>>>>{};

    for (var f in filas) {
      final principio = f['principio'] ?? '';
      final comportamiento = f['comportamiento'] ?? '';
      final nivel = _normalizeNivel(f['cargo_raw'] ?? '');
      final int valor = ((f['valor'] ?? 0) as num).toInt();
      final sistemas =
          (f['sistemas'] as List?)?.whereType<String>().toList() ?? [];
      final observacion = f['observaciones'] ?? '';

      sumas.putIfAbsent(principio, () => {});
      sumas[principio]!.putIfAbsent(comportamiento,
          () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      conteos.putIfAbsent(principio, () => {});
      conteos[principio]!.putIfAbsent(comportamiento,
          () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
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

    final niveles = ['Ejecutivo', 'Gerente', 'Miembro'];
    final rows = <DataRow>[];

    for (final e in sumas.entries) {
      final p = e.key;
      for (final cEntry in e.value.entries) {
        final c = cEntry.key;
        rows.add(
          DataRow(
            cells: [
              DataCell(
                  Text(p, style: const TextStyle(color: Color(0xFF003056)))),
              DataCell(
                  Text(c, style: const TextStyle(color: Color(0xFF003056)))),
              ...niveles.map((n) {
                final suma = e.value[c]![n] ?? 0;
                final count = conteos[p]![c]![n]!;
                final txt = count > 0 ? (suma / count).toStringAsFixed(2) : '-';
                return DataCell(
                    Text(txt, style: const TextStyle(color: Color(0xFF003056))));
              }),
              ...niveles.map((n) {
                final sistemas = sistemasPorNivel[p]![c]![n]!;
                final txt = sistemas.isEmpty ? '-' : sistemas.join(', ');
                return DataCell(
                    Text(txt, style: const TextStyle(color: Color(0xFF003056))));
              }),
              ...niveles.map((n) {
                final obs = observacionesPorNivel[p]![c]![n]!;
                final txt = obs.isNotEmpty ? obs.join(' | ') : '-';
                return DataCell(
                    Text(txt, style: const TextStyle(color: Color(0xFF003056))));
              }),
            ],
          ),
        );
      }
    }

    return rows;
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
    final totalSistemas =
        _sistemasPorNivel.values.fold<int>(0, (sum, set) => sum + set.length);
    final nivelesConSistemas =
        _sistemasPorNivel.values.where((set) => set.isNotEmpty).length;
    return nivelesConSistemas == 0
        ? 0.0
        : totalSistemas / _sistemasPorNivel.length;
  }
}

class AuxTablaService {
  static const Map<String, String> dimensionInterna = {
    'IMPULSORES CULTURALES': 'Dimensión 1',
    'MEJORA CONTINUA': 'Dimensión 2',
    'ALINEAMIENTO EMPRESARIAL': 'Dimensión 3',
  };

  static const Map<String, String> dimensionId = {
    'Dimensión 1': '1',
    'Dimensión 2': '2',
    'Dimensión 3': '3',
  };

  static Map<String, Map<String, double>> obtenerPromediosPorDimensionYCargo() {
    final Map<String, Map<String, double>> resultado = {};

    for (final entry in dimensionInterna.entries) {
      final keyInterna = entry.value;
      final id = dimensionId[keyInterna]!;

      final evalMap = TablasDimensionScreen.tablaDatos[keyInterna];
      final filas =
          evalMap != null ? evalMap.values.expand((l) => l).toList() : <Map<String, dynamic>>[];

      final suma = {'Ejecutivo': 0.0, 'Gerente': 0.0, 'Miembro': 0.0};
      final conteo = {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0};

      for (final fila in filas) {
        final cargo = _normalizarNivel(fila['cargo_raw'] ?? '');
        final valor = (fila['valor'] ?? 0).toDouble();
        if (suma.containsKey(cargo)) {
          suma[cargo] = suma[cargo]! + valor;
          conteo[cargo] = conteo[cargo]! + 1;
        }
      }

      resultado[id] = {
        'EJECUTIVOS': conteo['Ejecutivo']! > 0
            ? suma['Ejecutivo']! / conteo['Ejecutivo']!
            : 0.0,
        'GERENTES': conteo['Gerente']! > 0
            ? suma['Gerente']! / conteo['Gerente']!
            : 0.0,
        'MIEMBROS DE EQUIPO': conteo['Miembro']! > 0
            ? suma['Miembro']! / conteo['Miembro']!
            : 0.0,
      };
    }

    return resultado;
  }

  static String _normalizarNivel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('miembro')) return 'Miembro';
    if (lower.contains('gerente')) return 'Gerente';
    return 'Ejecutivo';
  }

  static double obtenerTotalPuntosGlobal() {
    final promedios = obtenerPromediosPorDimensionYCargo();
    final config = {
      '1': {'EJECUTIVOS': 125.0, 'GERENTES': 75.0, 'MIEMBROS DE EQUIPO': 50.0},
      '2': {'EJECUTIVOS': 70.0, 'GERENTES': 105.0, 'MIEMBROS DE EQUIPO': 175.0},
      '3': {'EJECUTIVOS': 110.0, 'GERENTES': 60.0, 'MIEMBROS DE EQUIPO': 30.0},
    };

    double total = 0;
    for (final id in promedios.keys) {
      final cargos = promedios[id]!;
      final pesos = config[id]!;
      cargos.forEach((cargo, prom) {
        total += (prom / 5.0) * pesos[cargo]!;
      });
    }
    return total; // Máximo 800
  }
}
