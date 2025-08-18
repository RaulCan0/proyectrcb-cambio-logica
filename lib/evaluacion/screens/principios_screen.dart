import 'package:applensys/evaluacion/models/asociado.dart';
import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/models/principio_json.dart';
import 'package:applensys/evaluacion/screens/tablas_screen.dart' as tablas_screen;
import 'package:applensys/evaluacion/services/json_service.dart';
import 'package:applensys/evaluacion/services/supabase_service.dart';
import 'package:flutter/material.dart';
import '../models/empresa.dart';

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

  String nombreDimension(String id) {
    switch (id) {
      case '1':
        return 'IMPULSORES CULTURALES';
      case '2':
        return 'MEJORA CONTINUA';
      case '3':
        return 'ALINEAMIENTO EMPRESARIAL';
      default:
        return 'DIMENSIÓN DESCONOCIDA';
    }
  }

  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    cargarDatos(); // Llama a una nueva función que carga todo
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    try {
      // Cargar principios y calificaciones en paralelo
      final resultados = await Future.wait([
        JsonService.cargarJson('t${widget.dimensionId}.json'),
        _supabaseService.getCalificacionesPorAsociado(widget.asociado.id),
      ]);
      final List<dynamic> datosJson = resultados[0];
      final List<Calificacion> todasLasCalificacionesDelAsociado = resultados[1] as List<Calificacion>;

      if (datosJson.isEmpty) throw Exception('El archivo JSON de principios está vacío.');
      final todosLosPrincipios = datosJson.map((e) => PrincipioJson.fromJson(e)).toList();
      final principiosFiltrados = todosLosPrincipios
          .where((p) => p.nivel.toLowerCase().contains(widget.asociado.cargo.toLowerCase()))
          .toList();
      final agrupados = <String, List<PrincipioJson>>{};
      for (var p in principiosFiltrados) {
        agrupados.putIfAbsent(p.nombre.trim(), () => []).add(p);
      }
      agrupados.removeWhere((key, value) => value.isEmpty);
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

  void agregarComportamientoEvaluado(String comportamiento, Calificacion calificacion) {
    if (!comportamientosEvaluados.contains(comportamiento)) {
      setState(() {
        comportamientosEvaluados.add(comportamiento);
        calificacionesExistentes[comportamiento] = calificacion; // Guardar la calificación completa
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            ' ${nombreDimension(widget.dimensionId)}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFF003056),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment, color: Colors.white),
            onPressed: () {
              final nombreDimInt = obtenerNombreDimensionInterna(widget.dimensionId);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => tablas_screen.TablasDimensionScreen(
                    empresa: widget.empresa,
                    evaluacionId: widget.evaluacionId,
                    asociadoId: widget.asociado.id,
                    empresaId: widget.empresa.id,
                    dimension: nombreDimInt,
                    ),
                  ),
                );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: cargando
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
                            child: Column(
                              children: [
                                Text(
                                  'EVALUANDO A: ${widget.asociado.nombre}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Nivel Organizacional: ${widget.asociado.cargo.toLowerCase() == 'miembro' ? 'MIEMBRO DE EQUIPO' : widget.asociado.cargo.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Puesto: ${widget.asociado.puesto}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
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
                                    color: Color.lerp(const Color.fromARGB(255, 184, 179, 179), const Color.fromARGB(255, 154, 218, 156), progreso),
                                     border: Border.all(
                                      color: const Color.fromARGB(255, 0, 0, 0), // color del contorno
                                       width: 2,),
                                    boxShadow: [
                                      // ignore: deprecated_member_use
                                      BoxShadow(color: const Color.fromARGB(255, 199, 194, 194).withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04, vertical: screenSize.height * 0.02),
                                    childrenPadding: const EdgeInsets.only(bottom: 10),
                                    iconColor: Colors.black, 
                                    collapsedIconColor: Colors.black, // Añade esta línea para el estado colapsado
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center, // Centra el contenido de la columna
                                      children: [
                                        Text(
                                          entry.key,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,  // Siempre negro
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$evaluados de $totalComportamientos comportamientos evaluados',
                                          style: const TextStyle(fontSize: 14, color: Colors.black87), // Siempre gris oscuro
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
                                          textAlign: TextAlign.center, // Centrar título
                                          style: TextStyle(
                                            color: comportamientosEvaluados.contains(comportamientoNombre) ? const Color.fromARGB(255, 79, 109, 80) : Colors.black,
                                            fontWeight: comportamientosEvaluados.contains(comportamientoNombre) ? FontWeight.bold : FontWeight.normal,
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
                                         

                                          final String evaluacionIdGeneral = widget.asociado.id; // Placeholder, ajusta según tu lógica de ID de evaluación.

                                          final resultado = await Navigator.push<String>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ComportamientoEvaluacionScreen(
                                                principio: principio,
                                                cargo: widget.asociado.cargo,
                                                evaluacionId: evaluacionIdGeneral, // Usar el ID de evaluación general
                                                dimensionId: widget.dimensionId,
                                                empresaId: widget.empresa.id,
                                                asociadoId: widget.asociado.id,
                                                dimension: widget.dimensionId, // Este parámetro 'dimension' en ComportamientoEvaluacionScreen parece redundante si ya tienes dimensionId
                                                calificacionExistente: calificacionActual,
                                              ),
                                            ),
                                          );
                                          // Después de volver, recargar los datos para reflejar cualquier cambio.
                                          if (resultado != null) {
                                            cargarDatos(); // Recargar todos los datos para asegurar consistencia
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
    ));
  }

  @override
  void dispose() {
    super.dispose();
  }
}