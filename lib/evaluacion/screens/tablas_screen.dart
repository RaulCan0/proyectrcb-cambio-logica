import 'package:applensys/evaluacion/screens/dashboard_screen.dart';
import 'package:applensys/evaluacion/services/evaluacion_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:applensys/evaluacion/screens/detalles_evaluacion.dart';
import 'package:applensys/evaluacion/widgets/drawer_lensys.dart';
import 'package:applensys/evaluacion/models/empresa.dart';

class TablasDimensionScreen extends StatefulWidget {
  static Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };

  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  static String nivel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('miembro')) return 'Miembro';
    if (lower.contains('gerente')) return 'Gerente';
    return 'Ejecutivo';
  }

  const TablasDimensionScreen({super.key, required this.evaluacionId, required this.empresa});

  final String evaluacionId;
  final Empresa empresa;

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
  }) async {
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
      lista[indiceExistente]['observaciones'] = observaciones ?? '';
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
        'observaciones': observaciones ?? '',
      });
    }

    await EvaluacionCacheService().guardarTablas(tablaDatos);
    dataChanged.value = !dataChanged.value;
  }

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
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
    if (mounted) {
      setState(() {
        dimensiones = dimensionInterna.keys.toList();
      });
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
          title: const Center(
            child: Text(
              'Resultados en tiempo real',
              style: TextStyle(color: Colors.white),
            ),
          ),
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
                  onPressed: () => _irADetalles(context),
                  child: const Text('Ver detalles y avance'),
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

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(label: Text('Principio')),
                        DataColumn(label: Text('Comportamiento')),
                        DataColumn(label: Text('Ejecutivo')),
                        DataColumn(label: Text('Gerente')),
                        DataColumn(label: Text('Miembro')),
                        DataColumn(label: Text('Ejecutivo Sistemas')),
                        DataColumn(label: Text('Gerente Sistemas')),
                        DataColumn(label: Text('Miembro Sistemas')),
                        DataColumn(label: Text('Ejecutivo Observaciones')),
                        DataColumn(label: Text('Gerente Observaciones')),
                        DataColumn(label: Text('Miembro Observaciones')),
                      ],
                      rows: _buildRowsPrincipioPromedio(filas),
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
// ... (resto del código sin cambios anteriores)

  void _irADetalles(BuildContext context) {
    final currentIndex = DefaultTabController.of(context).index;
    final dimensionActual = dimensiones[currentIndex];
    final promediosPorDimension = <String, Map<String, double>>{};

    for (final dim in dimensiones) {
      final keyInterna = dimensionInterna[dim] ?? dim;
      final evalMap = TablasDimensionScreen.tablaDatos[keyInterna];
      final filas = evalMap != null ? evalMap.values.expand((l) => l).toList() : <Map<String, dynamic>>[];

      final sumasNivel = {'Ejecutivo': 0.0, 'Gerente': 0.0, 'Miembro': 0.0};
      final conteosNivel = {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0};
      final sistemasSet = {'Ejecutivo': <String>{}, 'Gerente': <String>{}, 'Miembro': <String>{}};

      for (var f in filas) {
        final nivel = _normalizeNivel(f['cargo_raw'] ?? f['cargo'] ?? '');
        final valor = (f['valor'] ?? 0).toDouble();
        final sistemas = (f['sistemas'] as List?)?.whereType<String>().toList() ?? [];

        sumasNivel[nivel] = sumasNivel[nivel]! + valor;
        conteosNivel[nivel] = conteosNivel[nivel]! + 1;
        sistemasSet[nivel]?.addAll(sistemas);
      }

      final promediosNivel = <String, double>{};
      double totalProm = 0;
      for (final nivel in ['Ejecutivo', 'Gerente', 'Miembro']) {
        final suma = sumasNivel[nivel]!;
        final count = conteosNivel[nivel]!;
        final prom = count > 0 ? suma / count : 0;
        promediosNivel[nivel] = double.parse(prom.toStringAsFixed(2));
        totalProm += prom;
      }

      promediosNivel['General'] = double.parse((totalProm / 3).toStringAsFixed(2));
      promediosNivel['Sistemas'] = double.parse((sistemasSet.values.fold(0, (p, e) => p + e.length) / 3).toStringAsFixed(2));

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

// ... (resto del código permanece igual)

  List<DataRow> _buildRowsPrincipioPromedio(List<Map<String, dynamic>> filas) {
    final niveles = ['Ejecutivo', 'Gerente', 'Miembro'];
    final Map<String, Map<String, Map<String, List<String>>>> observaciones = {};
    final Map<String, Map<String, Map<String, Set<String>>>> sistemas = {};
    final Map<String, Map<String, Map<String, int>>> sumas = {};
    final Map<String, Map<String, Map<String, int>>> conteos = {};

    for (var f in filas) {
      final principio = f['principio'] ?? '-';
      final comportamiento = f['comportamiento'] ?? '-';
      final nivel = _normalizeNivel(f['cargo_raw'] ?? f['cargo'] ?? '');
      final valor = ((f['valor'] ?? 0) as num).toInt();
      final obs = (f['observacion'] ?? '').toString();
      final sis = (f['sistemas'] as List?)?.whereType<String>().toList() ?? [];

      sumas.putIfAbsent(principio, () => {});
      sumas[principio]!.putIfAbsent(comportamiento, () => {});
      sumas[principio]![comportamiento]!.putIfAbsent(nivel, () => 0);
      sumas[principio]![comportamiento]![nivel] =
          sumas[principio]![comportamiento]![nivel]! + valor;

      conteos.putIfAbsent(principio, () => {});
      conteos[principio]!.putIfAbsent(comportamiento, () => {});
      conteos[principio]![comportamiento]!.putIfAbsent(nivel, () => 0);
      conteos[principio]![comportamiento]![nivel] =
          conteos[principio]![comportamiento]![nivel]! + 1;

      observaciones.putIfAbsent(principio, () => {});
      observaciones[principio]!.putIfAbsent(comportamiento, () => {});
      observaciones[principio]![comportamiento]!.putIfAbsent(nivel, () => []);
      if (obs.isNotEmpty) {
        observaciones[principio]![comportamiento]![nivel]!.add(obs);
      }

      sistemas.putIfAbsent(principio, () => {});
      sistemas[principio]!.putIfAbsent(comportamiento, () => {});
      sistemas[principio]![comportamiento]!.putIfAbsent(nivel, () => <String>{});
      sistemas[principio]![comportamiento]![nivel]!.addAll(sis);
    }

    final rows = <DataRow>[];
    for (final p in sumas.keys) {
      for (final c in sumas[p]!.keys) {
        final cells = <DataCell>[];
        cells.add(DataCell(Text(p)));
        cells.add(DataCell(Text(c)));

        for (final n in niveles) {
          final s = sumas[p]![c]![n] ?? 0;
          final ctn = conteos[p]![c]![n] ?? 0;
          final prom = ctn > 0 ? (s / ctn).toStringAsFixed(2) : '-';
          cells.add(DataCell(Text(prom)));
        }

        for (final n in niveles) {
          final sisList = sistemas[p]![c]![n]?.toList() ?? [];
          final joined = sisList.join(', ');
          cells.add(DataCell(Text(joined.isEmpty ? '-' : joined)));
        }

        for (final n in niveles) {
          final obsList = observaciones[p]![c]![n] ?? [];
          final joined = obsList.join(' | ');
          cells.add(DataCell(Text(joined.isEmpty ? '-' : joined)));
        }

        rows.add(DataRow(cells: cells));
      }
    }
    return rows;
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
        final cargo = TablasDimensionScreen.nivel(fila['cargo_raw'] ?? fila['cargo'] ?? '');
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
