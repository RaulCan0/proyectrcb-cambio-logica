import 'package:flutter/material.dart';

import 'package:applensys/evaluacion/models/asociado.dart';
import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/models/principio_json.dart';
import 'package:applensys/evaluacion/models/empresa.dart';

import 'package:applensys/evaluacion/screens/tablas_screen.dart' as tablas_screen;
import 'package:applensys/evaluacion/services/domain/json_service.dart';
import 'package:applensys/evaluacion/services/domain/supabase_service.dart';
import 'comportamiento_evaluacion_screen.dart';

class PrincipiosScreen extends StatefulWidget {
  final Empresa empresa;
  final Asociado asociado;
  final String dimensionId;

  const PrincipiosScreen({
    super.key,
    required this.empresa,
    required this.asociado,
    required this.dimensionId, required String evaluacionId,
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

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

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

  String obtenerNombreDimensionInterna(String id) {
    switch (id) {
      case '1':
        return 'Dimensión 1';
      case '2':
        return 'Dimensión 2';
      case '3':
        return 'Dimensión 3';
      default:
        return 'Dimensión X';
    }
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    try {
      final datosJson = await JsonService.cargarJson('t${widget.dimensionId}.json');
      final todosLosPrincipios = datosJson.map((e) => PrincipioJson.fromJson(e)).toList();
      final principiosFiltrados = todosLosPrincipios
          .where((p) => p.nivel.toLowerCase().contains(widget.asociado.cargo.toLowerCase()))
          .toList();

      final agrupados = <String, List<PrincipioJson>>{};
      for (var p in principiosFiltrados) {
        agrupados.putIfAbsent(p.nombre.trim(), () => []).add(p);
      }
      agrupados.removeWhere((_, v) => v.isEmpty);

      final calificaciones = await _supabaseService.getCalificacionesPorAsociado(widget.asociado.id);
      final tempComps = <String>[];
      final tempCals = <String, Calificacion>{};
      final int dimActual = int.tryParse(widget.dimensionId) ?? 1;

      for (var cal in calificaciones) {
        if (cal.idDimension == dimActual) {
          tempComps.add(cal.comportamiento);
          tempCals[cal.comportamiento] = cal;
        }
      }

      setState(() {
        principiosUnicos = agrupados;
        comportamientosEvaluados = tempComps;
        calificacionesExistentes = tempCals;
        cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
        setState(() => cargando = false);
      }
    }
  }

  void agregarComportamientoEvaluado(String comportamiento, Calificacion calificacion) {
    if (!comportamientosEvaluados.contains(comportamiento)) {
      setState(() {
        comportamientosEvaluados.add(comportamiento);
        calificacionesExistentes[comportamiento] = calificacion;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
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
                final nombreInterno = obtenerNombreDimensionInterna(widget.dimensionId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => tablas_screen.TablasDimensionScreen(
                      empresa: widget.empresa,
                      empresaId: widget.empresa.id,
                      dimension: nombreInterno,
                      evaluacionId: '',
                      asociadoId: '',
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
                      children: [
                        Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'EVALUANDO A: ${widget.asociado.nombre}\nNivel Organizacional: ${widget.asociado.cargo.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
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
                              final total = entry.value.length;
                              final evaluados = entry.value.where((p) {
                                final c = p.benchmarkComportamiento.split(":").first.trim();
                                return comportamientosEvaluados.contains(c);
                              }).length;
                              final progreso = total == 0 ? 0.0 : evaluados / total;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Color.lerp(
                                    const Color(0xFFE4E1E1),
                                    const Color(0xFFB8EEB9),
                                    progreso,
                                  ),
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.symmetric(
                                    horizontal: screenSize.width * 0.04,
                                    vertical: screenSize.height * 0.02,
                                  ),
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
                                        '$evaluados de $total comportamientos evaluados',
                                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  children: entry.value.map((p) {
                                    final nombre = p.benchmarkComportamiento.split(":").first.trim();
                                    final descripcion = p.benchmarkComportamiento.split(":").last.trim();
                                    final yaEvaluado = comportamientosEvaluados.contains(nombre);

                                    return ListTile(
                                      title: Text(
                                        nombre,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: yaEvaluado ? Colors.green : Colors.black,
                                          fontWeight: yaEvaluado ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      subtitle: Text(
                                        descripcion,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios),
                                      onTap: () {
                                        // Buscar la calificación existente para este comportamiento
                                        final calificacionExistente = calificacionesExistentes[nombre];
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ComportamientoEvaluacionScreen(
                                              principio: p,
                                              empresa: widget.empresa,
                                              asociado: widget.asociado,
                                              onEvaluado: agregarComportamientoEvaluado,
                                              calificacionExistente: calificacionExistente,
                                              cargo: widget.asociado.cargo,
                                              evaluacionId: '',
                                              dimensionId: widget.dimensionId,
                                              empresaId: widget.empresa.id,
                                              asociadoId: widget.asociado.id,
                                              dimension: '',
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
