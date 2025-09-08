import 'package:applensys/evaluacion/models/asociado.dart';
import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/models/empresa.dart';
import 'package:applensys/evaluacion/models/principio_json.dart';
import 'package:applensys/evaluacion/screens/tablas_screen.dart' as tablas_screen;
import 'package:applensys/evaluacion/services/json_service.dart';
import 'package:applensys/evaluacion/services/supabase_service.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'comportamiento_evaluacion_screen.dart';

class PrincipiosScreen extends StatefulWidget {
  final Empresa empresa;
  final Asociado asociado;
  final String dimensionId;
  final String evaluacionId;

  const PrincipiosScreen({
    super.key,
    required this.empresa,
    required this.asociado,
    required this.dimensionId,
    required this.evaluacionId,
  });

  @override
  State<PrincipiosScreen> createState() => _PrincipiosScreenState();
}

class _PrincipiosScreenState extends State<PrincipiosScreen> {
  Map<String, List<PrincipioJson>> principiosUnicos = {};
  List<String> comportamientosEvaluados = [];
  Map<String, Calificacion> calificacionesExistentes = {}; 
  bool cargando = true;

  final SupabaseService _supabaseService = SupabaseService();

  String nombreDimension(String id) {
    switch (id) {
      case '1': return 'IMPULSORES CULTURALES';
      case '2': return 'MEJORA CONTINUA';
      case '3': return 'ALINEAMIENTO EMPRESARIAL';
      default: return 'DIMENSIÓN DESCONOCIDA';
    }
  }

  String obtenerNombreDimensionInterna(String id) {
    // Puedes adaptar esto según tus necesidades internas de nombres
    switch (id) {
      case '1': return 'impulsores_culturales';
      case '2': return 'mejora_continua';
      case '3': return 'alineamiento_empresarial';
      default: return 'desconocida';
    }
  }

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    try {
      // Cargar principios desde JSON
      final List<dynamic> datosJson = await JsonService.cargarJson('t${widget.dimensionId}.json');
      if (datosJson.isEmpty) throw Exception('El archivo JSON de principios está vacío.');

      final todosLosPrincipios = datosJson.map((e) => PrincipioJson.fromJson(e)).toList();
      final principiosFiltrados = todosLosPrincipios
          .where((p) => p.nivel.toLowerCase().contains(widget.asociado.cargo.toLowerCase()))
          .toList();

      final agrupados = <String, List<PrincipioJson>>{};
      for (var p in principiosFiltrados) {
        agrupados.putIfAbsent(p.nombre, () => []).add(p);
      }

      // Cargar calificaciones existentes
      final todasLasCalificacionesDelAsociado = await _supabaseService.getCalificacionesPorAsociado(widget.asociado.id);

      final tempComportamientosEvaluados = <String>[];
      final tempCalificacionesExistentes = <String, Calificacion>{};
      final int dimensionIdActual = int.tryParse(widget.dimensionId) ?? 1;

      for (var cal in todasLasCalificacionesDelAsociado) {
        if (cal.idDimension == dimensionIdActual) {
          tempComportamientosEvaluados.add(cal.comportamiento);
          tempCalificacionesExistentes[cal.comportamiento] = cal;
        }
      }

      setState(() {
        principiosUnicos = agrupados;
        comportamientosEvaluados = tempComportamientosEvaluados;
        calificacionesExistentes = tempCalificacionesExistentes;
        cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            nombreDimension(widget.dimensionId),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFF003056),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment, color: Colors.white),
            onPressed: () {
              String nombreDimensionInternaActual = obtenerNombreDimensionInterna(widget.dimensionId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => tablas_screen.TablasDimensionScreen(
                    empresa: widget.empresa,
                    evaluacionId: widget.evaluacionId,
                    asociadoId: widget.asociado.id,
                    empresaId: widget.empresa.id,
                    dimension: nombreDimensionInternaActual,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : principiosUnicos.isEmpty
              ? const Center(child: Text('No hay principios para este nivel'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'EVALUANDO A: ${widget.asociado.nombre}\n'
                              'Nivel Organizacional: ${widget.asociado.cargo.toLowerCase() == 'miembro' ? 'MIEMBRO DE EQUIPO' : widget.asociado.cargo.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: principiosUnicos.length,
                          itemBuilder: (context, index) {
                            final entry = principiosUnicos.entries.elementAt(index);
                            return StatefulBuilder(
                              builder: (context, setStateTile) {
                                final totalComportamientos = entry.value.length;
                                final evaluados = entry.value.where((p) {
                                  final comportamientoNombre = p.benchmarkComportamiento.split(":").first.trim();
                                  return comportamientosEvaluados.contains(comportamientoNombre);
                                }).length;
                                final progreso = totalComportamientos == 0 ? 0.0 : evaluados / totalComportamientos;

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Color.lerp(const Color(0x00000000), const Color(0xFF9ADA9C), progreso),
                                    border: Border.all(
                                      color: const Color(0xFF000000),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        // ignore: deprecated_member_use
                                        color: const Color.fromARGB(255, 196, 199, 195).withOpacity(0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: EdgeInsets.symmetric(
                                        horizontal: screenSize.width * 0.04, vertical: screenSize.height * 0.02),
                                    childrenPadding: const EdgeInsets.only(bottom: 10),
                                    iconColor: Colors.black,
                                    collapsedIconColor: Colors.black,
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          entry.key,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$evaluados de $totalComportamientos comportamientos evaluados',
                                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    children: entry.value.map((principio) {
                                      final comportamientoNombre = principio.benchmarkComportamiento.split(":").first.trim();
                                      final calificacionActual = calificacionesExistentes[comportamientoNombre];

                                      return ListTile(
                                        title: Text(
                                          comportamientoNombre,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: comportamientosEvaluados.contains(comportamientoNombre)
                                                ? const Color(0xFF4F6D50)
                                                : Colors.black,
                                            fontWeight: comportamientosEvaluados.contains(comportamientoNombre)
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: Text(
                                          principio.benchmarkComportamiento.split(":").last.trim(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.black),
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.black,
                                        ),
                                        onTap: () async {
                                          final resultado = await Navigator.push<String>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ComportamientoEvaluacionScreen(
                                                principio: principio,
                                                cargo: widget.asociado.cargo,
                                                evaluacionId: widget.evaluacionId,
                                                dimensionId: widget.dimensionId,
                                                empresaId: widget.empresa.id,
                                                asociadoId: widget.asociado.id,
                                                dimension: widget.dimensionId,
                                                calificacionExistente: calificacionActual,
                                              ),
                                            ),
                                          );
                                          if (resultado != null) {
                                            cargarDatos(); // Recarga todos los datos tras evaluación
                                          }
                                        },
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
class ProgresoAsociado {
  static final Map<String, Set<String>> _map = {};
  static void marcarComoEvaluado(String id, String comp) {
    _map.putIfAbsent(id, () => {}).add(comp);
  }

  static bool estaEvaluado(String id, String comp) => _map[id]?.contains(comp) ?? false;
}

extension ProgresoSupabase on SupabaseService {
  Future<void> registrarComportamientoEvaluado({
    required String empresaId,
    required String asociadoId,
    required String dimensionId,
    required String comportamiento,
  }) async {
    final response = await Supabase.instance.client
        .from('calificaciones')
        .select('id')
        .eq('id_asociado', asociadoId)
        .eq('id_empresa', empresaId)
        .eq('id_dimension', int.tryParse(dimensionId) ?? 0)
        .eq('comportamiento', comportamiento);

    if (response.isEmpty) {
      await Supabase.instance.client.from('calificaciones').insert({
        'id': const Uuid().v4(),
        'id_asociado': asociadoId,
        'id_empresa': empresaId,
        'id_dimension': int.tryParse(dimensionId),
        'comportamiento': comportamiento,
        'puntaje': 0,
      });
    }
  }
}

