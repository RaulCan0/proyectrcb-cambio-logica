// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:applensys/evaluacion/widgets/chat_screen.dart';
import 'package:applensys/evaluacion/widgets/drawer_lensys.dart';
import 'package:applensys/evaluacion/widgets/grouped_bar_chart.dart';
import 'package:applensys/evaluacion/widgets/horizontal_bar_systems_chart.dart';
import 'package:applensys/evaluacion/widgets/multiring.dart';
import '../services/helpers/reporte_utils_final.dart';
import 'package:flutter/material.dart';
import '../models/empresa.dart';
import '../utils/evaluacion_chart_data.dart';
import '../models/dimension.dart';
import '../models/principio.dart';
import '../models/comportamiento.dart';
import '../services/local/evaluacion_cache_service.dart';
import '../widgets/scatter_bubble_chart.dart';
import 'package:applensys/custom/table_names.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// import 'package:applensys/models/level_averages.dart'; // Comentado o eliminado

class DashboardScreen extends StatefulWidget {
  final String evaluacionId;
  final Empresa empresa;

  const DashboardScreen({
    super.key,
    required this.evaluacionId,
    required this.empresa,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Datos crudos extraídos del cache o Supabase:
  List<Map<String, dynamic>> _dimensionesRaw = [];

  // Modelos procesados para gráficos:
  List<Dimension> _dimensiones = [];

  // Flag para saber si aún estamos cargando
  bool _isLoading = true;

  // Lista ordenada de sistemas para el gráfico de barras horizontales
  // DEBES ACTUALIZAR ESTA LISTA CON TUS SISTEMAS REALES Y EN EL ORDEN DESEADO
 
 final List<String> _sistemasOrdenados = [
  'Ambiental',
  'Compromiso',
  'Comunicación',
  'Despliegue de Estrategia',
  'Desarrollo de Personas',
  'EHS',
  'Gestión Visual',
  'Involucramiento',
  'Medición',
  'Planificación y Programación',
  'Recompensas',
  'Reconocimiento',
  'Seguridad',
  'Sistemas de Mejora',
  'Solución de Problemas',
  'Voz del Cliente',
];

  @override
  void initState() {
    super.initState();
    _loadCachedOrRemoteData();
  }

  Future<void> _loadCachedOrRemoteData() async {
    final cacheService = EvaluacionCacheService();
    await cacheService.init();

    dynamic rawTables = await cacheService.cargarTablas();

    if (rawTables != null) {
      // Si viene un Map<String, Map<String, List<Map<String, dynamic>>>>
      final List<Map<String, dynamic>> flattened = [];
      if (rawTables is Map<String, dynamic>) {
        for (final dimEntry in rawTables.entries) {
          final innerMap = dimEntry.value;
          if (innerMap is Map<String, dynamic>) {
            for (final listEntry in innerMap.entries) {
              final rowsList = listEntry.value;
              if (rowsList is List<dynamic>) {
                for (final row in rowsList) {
                  if (row is Map<String, dynamic>) {
                    flattened.add(row);
                  }
                }
              }
            }
          }
        }
        _dimensionesRaw = flattened;
      }
      // Si rawTables ya era List<Map<String, dynamic>>
      else if (rawTables is List<dynamic>) {
        _dimensionesRaw = rawTables.cast<Map<String, dynamic>>();
      }
    }

    // Si no hay datos en caché, consultamos Supabase
    if (_dimensionesRaw.isEmpty) {
      try {
        final supabase = Supabase.instance.client;
        final data = await supabase
            .from(TableNames.detallesEvaluacion)
            .select()
            .eq('evaluacion_id', widget.evaluacionId);
        _dimensionesRaw =
            List<Map<String, dynamic>>.from(data as List<dynamic>);
      } catch (e) {
        debugPrint('Error cargando datos de Supabase: $e');
        _dimensionesRaw = [];
      }
    }

    if (_dimensionesRaw.isNotEmpty) {
      _procesarDimensionesDesdeRaw(_dimensionesRaw);
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Procesa las filas crudas a modelos [Dimension], [Principio] y [Comportamiento].
  void _procesarDimensionesDesdeRaw(List<Map<String, dynamic>> raw) {
    final Map<String, List<Map<String, dynamic>>> porDimension = {};
    for (final fila in raw) {
      final dimNombre = (fila['dimension_id']?.toString()) ?? 'Sin dimensión';
      porDimension.putIfAbsent(dimNombre, () => []).add(fila);
    }

    final List<Dimension> dimsModel = [];

    porDimension.forEach((dimNombre, filasDim) {
      double sumaGeneralDim = 0;
      int conteoGeneralDim = 0;

      // Agrupar por 'principio'
      final Map<String, List<Map<String, dynamic>>> porPrincipio = {};
      for (final fila in filasDim) {
        final priNombre = (fila['principio'] as String?) ?? 'Sin principio';
        porPrincipio.putIfAbsent(priNombre, () => []).add(fila);
      }

      final List<Principio> principiosModel = [];

      porPrincipio.forEach((priNombre, filasPri) {
        double sumaPri = 0;
        int conteoPri = 0;

        // Agrupar por 'comportamiento'
        final Map<String, List<Map<String, dynamic>>> porComportamiento = {};
        for (final filaP in filasPri) {
          final compNombre =
              (filaP['comportamiento'] as String?) ?? 'Sin comportamiento';
          porComportamiento.putIfAbsent(compNombre, () => []).add(filaP);
        }

        final List<Comportamiento> compsModel = [];

        porComportamiento.forEach((compNombre, filasComp) {
          double sumaEj = 0, sumaGe = 0, sumaMi = 0;
          int countEj = 0, countGe = 0, countMi = 0;

          for (final row in filasComp) {
            final valor = (row['valor'] as num?)?.toDouble() ?? 0.0;
            final cargoRaw =
                (row['cargo_raw'] as String?)?.toLowerCase().trim() ?? '';
            if (cargoRaw.contains('ejecutivo')) {
              sumaEj += valor;
              countEj++;
            } else if (cargoRaw.contains('gerente')) {
              sumaGe += valor;
              countGe++;
            } else if (cargoRaw.contains('miembro')) {
              sumaMi += valor;
              countMi++;
            }
          }

          final double promEj = (countEj > 0) ? (sumaEj / countEj) : 0.0;
          final double promGe = (countGe > 0) ? (sumaGe / countGe) : 0.0;
          final double promMi = (countMi > 0) ? (sumaMi / countMi) : 0.0;

          compsModel.add(
            Comportamiento(
              nombre: compNombre,
              promedioEjecutivo: promEj,
              promedioGerente: promGe,
              promedioMiembro: promMi, sistemas: [], nivel: null, principioId: '', id: '', cargo: null,
            ),
          );

          // Promedio general del comportamiento (solo niveles con datos)
          double sumaPromediosNivel = 0;
          int conteoNiveles = 0;
          if (countEj > 0) {
            sumaPromediosNivel += promEj;
            conteoNiveles++;
          }
          if (countGe > 0) {
            sumaPromediosNivel += promGe;
            conteoNiveles++;
          }
          if (countMi > 0) {
            sumaPromediosNivel += promMi;
            conteoNiveles++;
          }
          if (conteoNiveles > 0) {
            sumaPri += (sumaPromediosNivel / conteoNiveles);
            conteoPri++;
          }
        });

        final double promedioPri =
            (conteoPri > 0) ? (sumaPri / conteoPri) : 0.0;

        principiosModel.add(
          Principio(
            id: priNombre,
            dimensionId: dimNombre,
            nombre: priNombre,
            promedioGeneral: promedioPri,
            comportamientos: compsModel,
          ),
        );

        if (promedioPri > 0) {
          sumaGeneralDim += promedioPri;
          conteoGeneralDim++;
        }
      });

      final double promedioDim =
          (conteoGeneralDim > 0) ? (sumaGeneralDim / conteoGeneralDim) : 0.0;

      dimsModel.add(
        Dimension(
          id: dimNombre,
          nombre: dimNombre,
          promedioGeneral: promedioDim,
          principios: principiosModel,
        ),
      );
    });

    _dimensiones = dimsModel;
    debugPrint('Dimensiones procesadas: ${_dimensiones.length}');
    if (_dimensiones.isNotEmpty) {
      debugPrint(
          'Primera dimensión: ${_dimensiones.first.nombre}, promedio: ${_dimensiones.first.promedioGeneral}');
    }
  }

  /// Datos para el gráfico de Dona (promedio general por dimensión).
  Map<String, double> _buildMultiringData() {
    // Las claves deben coincidir exactamente con las de puntosTotales en MultiRingChart
    const nombresDimensiones = {
      '1': 'Impulsores Culturales',
      '2': 'Mejora Continua',
      '3': 'Alineamiento Empresarial',
    };
    final Map<String, double> data = {
      'Impulsores Culturales': 0,
      'Mejora Continua': 0,
      'Alineamiento Empresarial': 0,
    };
    for (final dim in _dimensiones) {
      final nombre = nombresDimensiones[dim.id] ?? dim.nombre;
      if (data.containsKey(nombre)) {
        data[nombre] = dim.promedioGeneral;
      }
    }
    return data;
  }
List<ScatterData> _buildScatterData() {
  const double dotRadius = 8.0;
  final List<ScatterData> list = [];
  final niveles = {
    'Ejecutivo': Colors.orange,
    'Gerente': Colors.green,
    'Miembro': Colors.blue,
  };

  // Lista fija de principios (1–10)
  final principiosOrdenados = [
    'Respetar a Cada Individuo',
    'Liderar con Humildad',
    'Buscar la Perfección',
    'Abrazar el Pensamiento Científico',
    'Enfocarse en el Proceso',
    'Asegurar la Calidad en la Fuente',
    'Mejorar el Flujo y Jalón de Valor',
    'Pensar Sistémicamente',
    'Crear Constancia de Propósito',
    'Crear Valor para el Cliente',
  ];

  // Recorremos siempre los 10 principios
  principiosOrdenados.asMap().forEach((index, principioNombre) {
    // Buscar principio real
    final principio = _dimensiones
        .expand((dim) => dim.principios)
        .firstWhere(
          (p) => p.nombre == principioNombre,
          orElse: () => Principio(
            id: '',
            dimensionId: '',
            nombre: principioNombre,
            promedioGeneral: 0.0,
            comportamientos: [],
          ),
        );

    double sumaEj = 0, sumaGe = 0, sumaMi = 0;
    int cuentaEj = 0, cuentaGe = 0, cuentaMi = 0;

    for (final comp in principio.comportamientos) {
      if (comp.promedioEjecutivo > 0) {
        sumaEj += comp.promedioEjecutivo;
        cuentaEj++;
      }
      if (comp.promedioGerente > 0) {
        sumaGe += comp.promedioGerente;
        cuentaGe++;
      }
      if (comp.promedioMiembro > 0) {
        sumaMi += comp.promedioMiembro;
        cuentaMi++;
      }
    }

    final double promEj = cuentaEj > 0 ? sumaEj / cuentaEj : 0.0;
    final double promGe = cuentaGe > 0 ? sumaGe / cuentaGe : 0.0;
    final double promMi = cuentaMi > 0 ? sumaMi / cuentaMi : 0.0;

    if (promEj > 0) {
      list.add(ScatterData(
        x: promEj.clamp(0.0, 5.0),
        y: (index + 1).toDouble(),
        color: niveles['Ejecutivo']!,
        radius: dotRadius,
        seriesName: 'Ejecutivo',
        principleName: principioNombre,
      ));
    }
    if (promGe > 0) {
      list.add(ScatterData(
        x: promGe.clamp(0.0, 5.0),
        y: (index + 1).toDouble(),
        color: niveles['Gerente']!,
        radius: dotRadius,
        seriesName: 'Gerente',
        principleName: principioNombre,
      ));
    }
    if (promMi > 0) {
      list.add(ScatterData(
        x: promMi.clamp(0.0, 5.0),
        y: (index + 1).toDouble(),
        color: niveles['Miembro']!,
        radius: dotRadius,
        seriesName: 'Miembro',
        principleName: principioNombre,
      ));
    }
  });

  return list;
}


  Map<String, List<double>> _buildGroupedBarData() {
    final Map<String, List<double>> data = {};
    final comps =
        EvaluacionChartData.extractComportamientos(_dimensiones).cast<Comportamiento>();
    for (final comp in comps) {
      data[comp.nombre] = [
        comp.promedioEjecutivo.clamp(0.0, 5.0),
        comp.promedioGerente.clamp(0.0, 5.0),
        comp.promedioMiembro.clamp(0.0, 5.0),
      ];
    }
    return data;
  }

  Map<String, Map<String, double>> _buildHorizontalBarsData() {
  // Inicializa estructura para sumar valores y contar respuestas por sistema y nivel
  final Map<String, Map<String, double>> sumaPorSistemaNivel = {};
  final Map<String, Map<String, int>> conteoPorSistemaNivel = {};

  for (final sistema in _sistemasOrdenados) {
    sumaPorSistemaNivel[sistema] = {'E': 0.0, 'G': 0.0, 'M': 0.0};
    conteoPorSistemaNivel[sistema] = {'E': 0, 'G': 0, 'M': 0};
  }

  for (final row in _dimensionesRaw) {
    String? nivelKey;
    if (row.containsKey('cargo_raw') && row['cargo_raw'] != null) {
      final cargoRaw = row['cargo_raw'].toString().toLowerCase().trim();
      if (cargoRaw.contains('ejecutivo')) nivelKey = 'E';
      else if (cargoRaw.contains('gerente')) nivelKey = 'G';
      else if (cargoRaw.contains('miembro')) nivelKey = 'M';
    } else if (row.containsKey('nivel') && row['nivel'] != null) {
      final nivel = row['nivel'].toString().toUpperCase();
      if (['E', 'G', 'M'].contains(nivel)) nivelKey = nivel;
    }
    if (nivelKey == null) continue;

    // Manejo robusto de sistemas: puede ser null, String o List
    final sistemasRaw = row['sistemas'];
    List<String> listaSistemasEnFila = [];
    if (sistemasRaw is String && sistemasRaw.trim().isNotEmpty) {
      listaSistemasEnFila = [sistemasRaw.trim()];
    } else if (sistemasRaw is List) {
      listaSistemasEnFila = sistemasRaw
          .where((s) => s != null && s.toString().trim().isNotEmpty)
          .map((s) => s.toString().trim())
          .toList();
    }

    final valor = (row['valor'] as num?)?.toDouble() ?? 0.0;

    for (final sistemaNombre in listaSistemasEnFila) {
      final sistemaNormalizado = sistemaNombre.toLowerCase();
      final sistemaKey = _sistemasOrdenados.firstWhere(
        (s) => s.toLowerCase() == sistemaNormalizado,
        orElse: () => '',
      );
      if (sistemaKey.isNotEmpty) {
        sumaPorSistemaNivel[sistemaKey]![nivelKey] =
            (sumaPorSistemaNivel[sistemaKey]![nivelKey] ?? 0.0) + valor;
        conteoPorSistemaNivel[sistemaKey]![nivelKey] =
            (conteoPorSistemaNivel[sistemaKey]![nivelKey] ?? 0) + 1;
      }
    }
  }

  // Calcula promedios
  final Map<String, Map<String, double>> promedioData = {};
  for (final sistema in _sistemasOrdenados) {
    promedioData[sistema] = {'E': 0.0, 'G': 0.0, 'M': 0.0};
    for (final nivelKey in ['E', 'G', 'M']) {
      final suma = sumaPorSistemaNivel[sistema]![nivelKey] ?? 0.0;
      final conteo = conteoPorSistemaNivel[sistema]![nivelKey] ?? 0;
      promedioData[sistema]![nivelKey] = conteo > 0 ? (suma / conteo) : 0.0;
    }
  }
  return promedioData;
}

  Future<void> _generarReporteWord() async {
  setState(() => _isLoading = true);

  try {
    // Prepara los datos de comportamientos en el formato que espera ReporteUtils
    final List<Map<String, dynamic>> datosComportamientos = [];
    for (final dim in _dimensiones) {
      for (final pri in dim.principios) {
        for (final comp in pri.comportamientos) {
          // Por cada nivel, agrega una fila
          datosComportamientos.add({
            'dimension': dim.id,
            'principio': pri.nombre,
            'comportamiento': comp.nombre,
            'cargo': 'Ejecutivos',
            'calificacion': comp.promedioEjecutivo,
            'sistemas_asociados': [],
            'observacion': '',
          });
          datosComportamientos.add({
            'dimension': dim.id,
            'principio': pri.nombre,
            'comportamiento': comp.nombre,
            'cargo': 'Gerentes',
            'calificacion': comp.promedioGerente,
            'sistemas_asociados': [],
            'observacion': '',
          });
          datosComportamientos.add({
            'dimension': dim.id,
            'principio': pri.nombre,
            'comportamiento': comp.nombre,
            'cargo': 'Miembro',
            'calificacion': comp.promedioMiembro,
            'sistemas_asociados': [],
            'observacion': '',
          });
        }
      }
    }

    // Prepara los benchmarks (t1, t2, t3) desde tus datos crudos
    final t1 = _dimensionesRaw.where((row) => row['dimension_id'] == '1').toList();
    final t2 = _dimensionesRaw.where((row) => row['dimension_id'] == '2').toList();
    final t3 = _dimensionesRaw.where((row) => row['dimension_id'] == '3').toList();

    // Genera el reporte Word (HTML)
    final filePath = await ReporteUtils.exportReporteWordUnificado(
      datosComportamientos,
      t1,
      t2,
      t3,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reporte generado: $filePath')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al generar reporte: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
// Añde esta función auxiliar en la misma clase
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Preparar datos para el gráfico de sistemas
    final horizontalData = _buildHorizontalBarsData();
    // La variable maxSystemCount ya no es necesaria aquí si maxY es fijo (0-5 para promedios)

    return Scaffold(
      key: _scaffoldKey,

      // Drawer izquierdo para chat (80% del ancho)
      drawer: const ChatWidgetDrawer(),

      // EndDrawer derecho normal (sin envolver en SizedBox)
      endDrawer: const DrawerLensys(),

      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Dashboard - ${widget.empresa.nombre}',
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 20,
            fontFamily: 'Arial', // Aplicar la fuente Arial aquí
          ),
        ),
        centerTitle: true,
      ),

      body: Row(
        children: [
          // ► Lado izquierdo: ListView con los 4 gráficos (ocupa todo el espacio restante)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                children: [
                   _buildChartContainer(
                      child: MultiRingChart(
                        puntosObtenidos: _buildMultiringData(),
                        isDetail: false,
                      ), color: const Color.fromARGB(255, 171, 172, 173), title: 'EVALUACION DIMENSION-ROL',
                    ),
              
                  _buildChartContainer(
                    color: const Color.fromARGB(255, 160, 163, 163),
                    child: ScatterBubbleChart(
                      data: _buildScatterData(),
                      isDetail: false, 
                    ),
                    title: 'EVALUACION-PRINCIPIO-ROL',
                  ),

                  _buildChartContainer(
                    color: const Color.fromARGB(255, 231, 220, 187),
                    title: 'EVALUACION COMPORTAMIENTO-ROL',
                    child: GroupedBarChart(
                      data: _buildGroupedBarData(),
                      minY: 0,
                      maxY: 5,
                      isDetail: false,
                    ), 
                  ),

               
                  _buildChartContainer(
                    color: const Color.fromARGB(255, 202, 208, 219),
                    title: 'EVALUACION SISTEMAS ROL',
                    child: HorizontalBarSystemsChart(
                      data: horizontalData, 
                      minY: 0, 
                      maxY: 5, // Adecuado para promedios en escala 0-5
                      sistemasOrdenados: _sistemasOrdenados, 
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            width: 56, // ancho normal de sidebar
            color: const Color(0xFF003056), // mismo color del AppBar
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Chat interno
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  tooltip: 'Chat Interno',
                ),
                IconButton(
  icon: const Icon(Icons.description, color: Colors.white),
  onPressed: _generarReporteWord, // <-- Llama a tu función
  tooltip: 'Generar Reporte Word',
), // El IconButton para generar reportes ha sido eliminado.
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Cada gráfico está dentro de un contenedor redondeado, con encabezado y margen.
  Widget _buildChartContainer({
    required Color color,
    required String title,
    required Widget child,
  }) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          if (title.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF003056),
                  ),
                ),
              ),
            ),
          // Espacio para el gráfico (alto fijo de 500px)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              height: 500,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

}