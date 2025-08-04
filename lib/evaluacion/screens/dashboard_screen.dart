// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'package:applensys/evaluacion/charts/multiring.dart';
import 'package:applensys/evaluacion/services/helpers/reporte_utils_final.dart';
import 'package:flutter/material.dart';
import 'package:applensys/evaluacion/widgets/chat_screen.dart';
import 'package:applensys/evaluacion/widgets/drawer_lensys.dart';
import 'package:applensys/evaluacion/models/empresa.dart';
import 'package:applensys/evaluacion/utils/evaluacion_chart_data.dart';
import 'package:applensys/evaluacion/models/dimension.dart';
import 'package:applensys/evaluacion/models/principio.dart';
import 'package:applensys/evaluacion/models/comportamiento.dart';
import 'package:applensys/evaluacion/services/local/evaluacion_cache_service.dart';
import 'package:applensys/evaluacion/charts/scatter_bubble_chart.dart';
import 'package:applensys/evaluacion/charts/grouped_bar_chart.dart';
import 'package:applensys/evaluacion/charts/horizontal_bar_systems_chart.dart';
import 'package:open_file/open_file.dart';
import 'package:applensys/evaluacion/custom/table_names.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:applensys/evaluacion/models/level_averages.dart';

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
  'Medición',
  'Involucramiento',
  'Reconocimiento',
  'Desarrollo de Personas',
  'Seguridad',
  'Ambiental',
  'EHS',
  'Compromiso',
  'Sistemas de Mejora',
  'Solución de Problemas',
  'Gestión Visual',
  'Comunicación',
  'Desarrollo de personas',
  'Despliegue de estrategia',
  'Gestion visual',
  'Medicion',
  'Mejora y alineamiento estratégico',
  'Mejora y gestion visual',
  'Planificacion',
  'Programacion y de mejora',
  'Voz de cliente',
  'Visitas al Gemba',
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
        // Para calcular el promedio del principio, necesitamos sumar TODOS los valores 
        // del principio y dividir por el total de calificaciones
        double sumaTotalPrincipio = 0;
        int conteoTotalPrincipio = 0;

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
            
            // Sumar al total del principio TODOS los valores válidos
            if (valor > 0) {
              sumaTotalPrincipio += valor;
              conteoTotalPrincipio++;
            }
            
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
        });

        // Calcular el promedio del principio basado en TODOS los valores de calificación
        final double promedioPri =
            (conteoTotalPrincipio > 0) ? (sumaTotalPrincipio / conteoTotalPrincipio) : 0.0;

        // Debug: Imprimir información del cálculo del principio
        debugPrint('Principio: $priNombre');
        debugPrint('  Total valores: $conteoTotalPrincipio, Suma total: $sumaTotalPrincipio');
        debugPrint('  Promedio calculado: $promedioPri');

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

  /// Datos para el gráfico MultiRing (promedio general por dimensión).
  Map<String, double> _buildMultiringData() {
    const nombresDimensiones = {
      '1': 'IMPULSORES CULTURALES',
      '2': 'MEJORA CONTINUA',
      '3': 'ALINEAMIENTO EMPRESARIAL',
    };
    
    final Map<String, double> data = {};
    
    for (final dim in _dimensiones) {
      final nombre = nombresDimensiones[dim.id] ?? dim.nombre;
      data[nombre] = dim.promedioGeneral;
    }
    
    return data;
  }

  
  /// Construye ScatterData solo con promedios > 0 y usando orElse que
  /// devuelve un Principio vacío en lugar de null.
List<ScatterData> _buildScatterData() {
  // Radio fijo para cada punto
  const double dotRadius = 8.0;

  // Extraemos la lista de Principio en orden natural
  final principios =
      EvaluacionChartData.extractPrincipios(_dimensiones).cast<Principio>();

  final List<ScatterData> list = [];

  for (var pri in principios) { // Cambiado el bucle para no depender de 'i' directamente para yIndex
    // Encontrar el índice del principio actual en la lista de nombres del gráfico
    int yRawIndex = ScatterBubbleChart.principleNames.indexOf(pri.nombre);

    // Si el principio no está en la lista de nombres del gráfico, lo omitimos.
    // Podrías manejar esto de otra manera si es necesario (ej. log, error, valor por defecto).
    if (yRawIndex == -1) {
      debugPrint('Principio "${pri.nombre}" no encontrado en ScatterBubbleChart.principleName. Omitiendo del gráfico.');
      continue;
    }
    
    final double yIndex = (yRawIndex + 1).toDouble(); // El índice base 0 se convierte a base 1 para el gráfico

    // CORREGIDO: Calcular promedios por nivel usando los datos crudos directamente
    double sumaEj = 0, sumaGe = 0, sumaMi = 0;
    int cuentaEj = 0, cuentaGe = 0, cuentaMi = 0;

    // Buscar en los datos crudos todas las calificaciones de este principio
    for (final row in _dimensionesRaw) {
      final principioNombre = (row['principio'] as String?) ?? '';
      if (principioNombre == pri.nombre) {
        final valor = (row['valor'] as num?)?.toDouble() ?? 0.0;
        final cargoRaw = (row['cargo_raw'] as String?)?.toLowerCase().trim() ?? '';
        
        if (valor > 0) {
          if (cargoRaw.contains('ejecutivo')) {
            sumaEj += valor;
            cuentaEj++;
          } else if (cargoRaw.contains('gerente')) {
            sumaGe += valor;
            cuentaGe++;
          } else if (cargoRaw.contains('miembro')) {
            sumaMi += valor;
            cuentaMi++;
          }
        }
      }
    }

    final double promEj = (cuentaEj > 0) ? (sumaEj / cuentaEj) : 0.0;
    final double promGe = (cuentaGe > 0) ? (sumaGe / cuentaGe) : 0.0;
    final double promMi = (cuentaMi > 0) ? (sumaMi / cuentaMi) : 0.0;

    // Debug: Imprimir información del cálculo por cargo
    debugPrint('ScatterChart - Principio: ${pri.nombre}');
    debugPrint('  Ejecutivo: $cuentaEj calificaciones, suma: $sumaEj, promedio: $promEj');
    debugPrint('  Gerente: $cuentaGe calificaciones, suma: $sumaGe, promedio: $promGe');
    debugPrint('  Miembro: $cuentaMi calificaciones, suma: $sumaMi, promedio: $promMi');

    // Añadimos un ScatterData por cada serie, si tiene valor > 0
    if (promEj > 0) {
      list.add(
        ScatterData(
          x: promEj.clamp(0.0, 5.0),
          y: yIndex, // Usar el yIndex calculado
          color: Colors.orange,
          radius: dotRadius,
          seriesName: 'Ejecutivo',
          principleNames: pri.nombre,
        ),
      );
    }
    if (promGe > 0) {
      list.add(
        ScatterData(
          x: promGe.clamp(0.0, 5.0),
          y: yIndex, // Usar el yIndex calculado
          color: Colors.green,
          radius: dotRadius,
          seriesName: 'Gerente',
          principleNames: pri.nombre, 
      ),
      );
    }
    if (promMi > 0) {
      list.add(
        ScatterData(
          x: promMi.clamp(0.0, 5.0),
          y: yIndex, // Usar el yIndex calculado
          color: Colors.blue,
          radius: dotRadius,
          seriesName: 'Miembro',
          principleNames: pri.nombre,
        ),
      );
    }
  }

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
    // Mapas para acumular sumas y conteos
    final Map<String, Map<String, double>> sumasPorSistemaNivel = {};
    final Map<String, Map<String, int>> conteosPorSistemaNivel = {};

    // Inicializar mapas para todos los sistemas ordenados y niveles
    for (final sistemaNombre in _sistemasOrdenados) {
      sumasPorSistemaNivel[sistemaNombre] = {'E': 0.0, 'G': 0.0, 'M': 0.0};
      conteosPorSistemaNivel[sistemaNombre] = {'E': 0, 'G': 0, 'M': 0};
    }

    for (final row in _dimensionesRaw) {
      String? nivelKey;
      if (row.containsKey('cargo_raw') && row['cargo_raw'] != null) {
        final cargoRaw = row['cargo_raw'].toString().toLowerCase().trim();
        if (cargoRaw.contains('ejecutivo')) {
          nivelKey = 'E';
        } else if (cargoRaw.contains('gerente')) {
          nivelKey = 'G';
        } else if (cargoRaw.contains('miembro')) {
          nivelKey = 'M';
        }
      } else if (row.containsKey('nivel') && row['nivel'] != null) {
        final nivel = row['nivel'].toString().toUpperCase();
        if (['E', 'G', 'M'].contains(nivel)) {
          nivelKey = nivel;
        }
      }

      if (nivelKey == null) {
        // Si no se puede determinar el nivel, saltar esta fila
        continue;
      }

      // Obtener el valor de la calificación para este row
      final double valorCalificacion = (row['valor'] as num?)?.toDouble() ?? 0.0;

      final listaSistemasEnFila = (row['sistemas'] as List<dynamic>?)
              ?.map((s) => s.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          <String>[];

      for (final sistemaNombre in listaSistemasEnFila) {
        // Asegura que el sistema procesado esté en nuestra lista ordenada
        // y por lo tanto en los mapas de sumas y conteos.
        if (sumasPorSistemaNivel.containsKey(sistemaNombre) && conteosPorSistemaNivel.containsKey(sistemaNombre)) {
          // Acumular suma
          sumasPorSistemaNivel[sistemaNombre]![nivelKey] =
              (sumasPorSistemaNivel[sistemaNombre]![nivelKey] ?? 0.0) + valorCalificacion;
          // Incrementar conteo
          conteosPorSistemaNivel[sistemaNombre]![nivelKey] =
              (conteosPorSistemaNivel[sistemaNombre]![nivelKey] ?? 0) + 1;
        }
      }
    }

    // Calcular promedios
    final Map<String, Map<String, double>> promediosData = {};
    for (final sistemaNombre in _sistemasOrdenados) {
      promediosData[sistemaNombre] = {'E': 0.0, 'G': 0.0, 'M': 0.0};
      for (final nivelKey in ['E', 'G', 'M']) {
        final double suma = sumasPorSistemaNivel[sistemaNombre]![nivelKey]!;
        final int conteo = conteosPorSistemaNivel[sistemaNombre]![nivelKey]!;
        if (conteo > 0) {
          promediosData[sistemaNombre]![nivelKey] = suma / conteo;
        } else {
          promediosData[sistemaNombre]![nivelKey] = 0.0;
        }
      }
    }
    // debugPrint('Datos de PROMEDIOS para HorizontalBarSystemsChart: $promediosData');
    return promediosData;
  }

  /// Callback al presionar “Generar Excel/Word”
  Future<void> _onGenerarDocumentos() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando archivos Excel y Word...')),
    );
    try {
      final List<LevelAverages> behaviorAverages = [];
      int id = 1;
      for (final dim in _dimensiones) {
        for (final pri in dim.principios) {
          for (final comp in pri.comportamientos) {
            behaviorAverages.add(LevelAverages(
              id: id++,
              nombre: comp.nombre,
              ejecutivo: comp.promedioEjecutivo,
              gerente: comp.promedioGerente,
              miembro: comp.promedioMiembro,
              dimensionId: int.tryParse(dim.id),
              nivel: '',
            ));
          }
        }
      }
      final sistemasData = _buildHorizontalBarsData();
      final List<LevelAverages> systemAverages = [];
      sistemasData.forEach((sistema, niveles) {
        systemAverages.add(LevelAverages(
          id: id++,
          nombre: sistema,
          ejecutivo: (niveles['E'] ?? 0).toDouble(),
          gerente: (niveles['G'] ?? 0).toDouble(),
          miembro: (niveles['M'] ?? 0).toDouble(),
          dimensionId: null,
          nivel: '',
        ));
      });
     
      final t1 = await _loadJsonAsset('assets/t1.json');
      final t2 = await _loadJsonAsset('assets/t2.json');
      final t3 = await _loadJsonAsset('assets/t3.json');
     
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar archivos: ${e.toString()}')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadJsonAsset(String path) async {
    final data = await DefaultAssetBundle.of(context).loadString(path);
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

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
      drawer: SizedBox(
        width: screenSize.width * 0.8,
        child: const ChatWidgetDrawer(),
      ),

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
          style: const TextStyle(color: Colors.white, fontSize: 20),
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

                // Generar Excel/Word
                IconButton(
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  onPressed: _onGenerarDocumentos,
                  tooltip: 'Generar prereporte Excel/Word',
                ),
                const SizedBox(height: 16),

                // Generar y abrir Excel
                IconButton(
                  icon: const Icon(Icons.table_chart, color: Colors.green),
                  onPressed: () async {
                    try {
                      final List<LevelAverages> behaviorAverages = [];
                      int id = 1;
                      for (final dim in _dimensiones) {
                        for (final pri in dim.principios) {
                          for (final comp in pri.comportamientos) {
                            behaviorAverages.add(LevelAverages(
                              id: id++,
                              nombre: comp.nombre,
                              ejecutivo: comp.promedioEjecutivo,
                              gerente: comp.promedioGerente,
                              miembro: comp.promedioMiembro,
                              dimensionId: int.tryParse(dim.id),
                              nivel: '',
                            ));
                          }
                        }
                      }
                      final sistemasData = _buildHorizontalBarsData();
                      final List<LevelAverages> systemAverages = [];
                      sistemasData.forEach((sistema, niveles) {
                        systemAverages.add(LevelAverages(
                          id: id++,
                          nombre: sistema,
                          ejecutivo: (niveles['E'] ?? 0).toDouble(),
                          gerente: (niveles['G'] ?? 0).toDouble(),
                          miembro: (niveles['M'] ?? 0).toDouble(),
                          dimensionId: null,
                          nivel: '',
                        ));
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al generar Excel: ${e.toString()}')),
                      );
                    }
                  },
                  tooltip: 'Abrir Excel',
                ),
                IconButton(
                  icon: const Icon(Icons.description, color: Colors.blue),
                  onPressed: () async {
                    try {
                      final t1 = await _loadJsonAsset('assets/t1.json');
                      final t2 = await _loadJsonAsset('assets/t2.json');
                      final t3 = await _loadJsonAsset('assets/t3.json');
                      final String wordPath =
                          await ReporteUtils.exportReporteWordUnificado(
                        _dimensionesRaw,
                        t1,
                        t2,
                        t3,
                      );
                      if (wordPath.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pudo generar Word.')),
                        );
                        return;
                      }
                      await OpenFile.open(wordPath);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al abrir Word: ${e.toString()}')),
                      );
                    }
                  },
                  tooltip: 'Abrir Word',
                ),
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
            // Encabezado interno (subtítulo) con fondo blanco
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              
            ),

            // Espacio para el gráfico (alto fijo de 240px)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                height: 420,
                child: child,
              ),
            ),
          ],
        ),
      );    
  }
}