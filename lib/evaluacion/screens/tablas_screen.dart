import 'package:applensys/evaluacion/screens/dashboard_screen.dart';
import 'package:applensys/evaluacion/services/evaluacion_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:applensys/evaluacion/screens/detalles_evaluacion.dart';
import 'package:applensys/evaluacion/widgets/drawer_lensys.dart';
import 'package:applensys/evaluacion/models/empresa.dart';

// Extensión para capitalizar cadenas
extension CapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

// Mapeo de nombre visible a clave interna
const Map<String, String> dimensionInterna = {
  'Dimensión 1': 'Dimensión 1',
  'Dimensión 2': 'Dimensión 2',
  'Dimensión 3': 'Dimensión 3',
};

class TablasDimensionScreen extends StatefulWidget {
  static Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };

  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  final Empresa empresa;
  final String evaluacionId;

  const TablasDimensionScreen({
    super.key,
    required this.empresa,
    required this.evaluacionId,
    required String empresaId,
    required String dimension,
    required String idAsociado,
  });

  /// Agrega un nuevo registro y notifica cambio
  static Future<void> actualizarDato(
    String evaluacionId, {
    required String dimension,
    required String principio,
    required String comportamiento,
    required String cargo,
    required int valor,
    required List<String> sistemas,
    String? observaciones,
  }) async {
    final tablaDim = tablaDatos.putIfAbsent(dimension, () => {});
    final lista = tablaDim.putIfAbsent(evaluacionId, () => []);
    lista.add({
      'principio': principio,
      'comportamiento': comportamiento,
      'cargo': cargo.trim().capitalize(),
      'valor': valor,
      'sistemas': sistemas,
      'observaciones': observaciones ?? '', // Siempre agrega observaciones
    });
    await EvaluacionCacheService().guardarTablas(tablaDatos);
    dataChanged.value = !dataChanged.value;
  }

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();
}

class _TablasDimensionScreenState extends State<TablasDimensionScreen> {
  final List<String> dimensiones = ['Dimensión 1', 'Dimensión 2', 'Dimensión 3'];

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
  }

  String _normalizeNivel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('miembro')) return 'Miembro';
    if (lower.contains('gerente')) return 'Gerente';
    return 'Ejecutivo';
  }

  @override
  Widget build(BuildContext context) {
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
            indicatorColor: Colors.white,
            tabs: dimensiones.map((d) => Tab(text: d)).toList(),
          ),
        ),
        endDrawer: const DrawerLensys(),
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
                  final keyInterna = dimensionInterna[dimension]!;
                  final filas = TablasDimensionScreen.tablaDatos[keyInterna]
                          ?.values
                          .expand((l) => l)
                          .toList() ?? [];
                  if (filas.isEmpty) {
                    return const Center(child: Text('No hay datos para mostrar'));
                  }
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
                          headingRowColor: WidgetStateProperty.all(const Color(0xFF003056)),
                          dataRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                          border: TableBorder.all(color: const Color(0xFF003056)),
                          columns: const [
                            DataColumn(label: Text('Principio', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Comportamiento', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Ejecutivos', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Gerentes', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Miembros', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Ejecutivo Sistemas', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Gerente Sistemas', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Miembro Sistemas', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Ejecutivo observaciones', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Gerente observaciones', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Miembro observaciones', style: TextStyle(color: Colors.white))),
                          ],
                          rows: _buildRowsPrincipioPromedio(filas),
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

  /// Fila de promedio PRINCIPIO para cada nivel, luego filas normales de comportamiento
  List<DataRow> _buildRowsPrincipioPromedio(List<Map<String, dynamic>> filas) {
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
      final observacion = f['observaciones'] ?? '';

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

      sumas[principio]![comportamiento]![nivel] = sumas[principio]![comportamiento]![nivel]! + valor;
      conteos[principio]![comportamiento]![nivel] = conteos[principio]![comportamiento]![nivel]! + 1;
      for (var s in sistemas) {
        sistemasPorNivel[principio]![comportamiento]![nivel]!.add(s);
      }
      // Acumular observaciones en lugar de sobrescribir
      if (observacion.isNotEmpty) {
        observacionesPorNivel[principio]![comportamiento]![nivel]!.add(observacion);
      }
    }

    // Calcular promedios de principios para uso interno (sin mostrar en UI)
    // Los cálculos se mantienen para posible uso futuro pero no se muestran
    final principioPromedios = <String, Map<String, double>>{};
    for (var principioEntry in sumas.entries) {
      final principio = principioEntry.key;
      final comportamientos = principioEntry.value.keys.toList();
      final niveles = ['Ejecutivo', 'Gerente', 'Miembro'];
      
      final promediosPorNivel = <String, double>{};
      for (var nivel in niveles) {
        double sumaProms = 0;
        int cuentaProms = 0;
        for (var c in comportamientos) {
          final suma = sumas[principio]![c]![nivel] ?? 0;
          final count = conteos[principio]![c]![nivel] ?? 0;
          if (count > 0) {
            sumaProms += suma / count;
            cuentaProms++;
          }
        }
        promediosPorNivel[nivel] = cuentaProms > 0 ? (sumaProms / cuentaProms) : 0.0;
      }
      principioPromedios[principio] = promediosPorNivel;
    }

    // Solo filas de comportamiento (sin filas separadas de principios)
    final comportamientoRows = sumas.entries.expand((e) {
      final p = e.key;
      return e.value.entries.map((cEntry) {
        final c = cEntry.key;
        final nivelVals = cEntry.value;
        final niveles = ['Ejecutivo', 'Gerente', 'Miembro'];
        return DataRow(cells: [
          DataCell(Text(p, style: const TextStyle(color: Color(0xFF003056)))), // Mostrar principio en la primera columna
          DataCell(Text(c, style: const TextStyle(color: Color(0xFF003056)))),
          ...niveles.map((n) {
            final suma = nivelVals[n] ?? 0;
            final count = conteos[p]![c]![n]!;
            return DataCell(Text(count > 0 ? (suma / count).toStringAsFixed(2) : '-', style: const TextStyle(color: Color(0xFF003056))));
          }),
          ...niveles.map((n) {
            final sistemas = sistemasPorNivel[p]![c]![n]!;
            return DataCell(Text(sistemas.isEmpty ? '-' : sistemas.join(', '), style: const TextStyle(color: Color(0xFF003056))));
          }),
          ...niveles.map((n) {
            final obs = observacionesPorNivel[p]![c]![n]!;
            final obsText = obs.isNotEmpty ? obs.join(' | ') : '-';
            return DataCell(Text(obsText, style: const TextStyle(color: Color(0xFF003056))));
          }),
        ]);
      });
    });

    return comportamientoRows.toList();
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
}class AuxTablaService {
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
      final nombre = entry.key;
      final keyInterna = entry.value;
      final id = dimensionId[keyInterna]!;

      final filas = TablasDimensionScreen.tablaDatos[keyInterna]?.values.expand((l) => l).toList() ?? [];

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
        'EJECUTIVOS': conteo['Ejecutivo']! > 0 ? suma['Ejecutivo']! / conteo['Ejecutivo']! : 0.0,
        'GERENTES': conteo['Gerente']! > 0 ? suma['Gerente']! / conteo['Gerente']! : 0.0,
        'MIEMBROS DE EQUIPO': conteo['Miembro']! > 0 ? suma['Miembro']! / conteo['Miembro']! : 0.0,
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
  }}