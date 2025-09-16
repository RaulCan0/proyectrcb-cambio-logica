import 'package:applensys/evaluacion/models/emplado_evaluacion.dart';
import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/models/principio_json.dart';
import 'package:applensys/evaluacion/screens/tablas_screen.dart' as tablas_screen;
import 'package:applensys/evaluacion/services/json_service.dart';
import 'package:applensys/evaluacion/services/supabase_service.dart';
import 'package:flutter/material.dart';
import '../models/empresa.dart';

import 'comportamiento_evaluacion_screen.dart';

class PrincipiosScreen extends StatefulWidget {
  final Empresa nombreEmpresa;
  final String evaluacionId;
  final EmpleadoEvaluacion empleadoEvaluacion;
  final String dimensionId; // Add this field

  const PrincipiosScreen({
    super.key,
    required this.evaluacionId,
    required this.nombreEmpresa,
    required this.empleadoEvaluacion,
    required this.dimensionId,  
  });

  @override
  State<PrincipiosScreen> createState() => _PrincipiosScreenState();
}

class _PrincipiosScreenState extends State<PrincipiosScreen> {
  Map<String, List<PrincipioJson>> principiosUnicos = {};
  List<String> comportamientosEvaluados = [];
  Map<String, CalificacionComportamiento> calificacionesExistentes = {}; 
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
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    try {
      final List<dynamic> datosJson = await JsonService.cargarJson('t${widget.dimensionId}.json');
      if (datosJson.isEmpty) throw Exception('El archivo JSON de principios está vacío.');

      final todosLosPrincipios = datosJson.map((e) => PrincipioJson.fromJson(e)).toList();
      final principiosFiltrados = todosLosPrincipios
          .where((p) => p.nivel.toLowerCase().contains(widget.empleadoEvaluacion.cargo.toLowerCase()))
          .toList();

      final agrupados = <String, List<PrincipioJson>>{};
      for (var p in principiosFiltrados) {
        agrupados.putIfAbsent(p.nombre.trim(), () => []).add(p);
      }
      agrupados.removeWhere((key, value) => value.isEmpty);

      final todasLasCalificacionesDelAsociado = await _supabaseService.getCalificacionesPorAsociado(widget.asociado.id);

      final tempComportamientosEvaluados = <String>[];
      final tempCalificacionesExistentes = <String, CalificacionComportamiento>{};

      for (var cal in todasLasCalificacionesDelAsociado) {
        if (cal.idDimension == widget.dimensionId) {
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => tablas_screen.TablasDimensionScreen(
                  
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
              : ListView.builder(
                  itemCount: principiosUnicos.length,
                  itemBuilder: (context, index) {
                    final entry = principiosUnicos.entries.elementAt(index);
                    return ExpansionTile(
                      title: Text(entry.key),
                      children: entry.value.map((principio) {
                        final comportamientoNombre = principio.benchmarkComportamiento.split(":").first.trim();
                        final calificacionActual = calificacionesExistentes[comportamientoNombre];

                        return ListTile(
                          title: Text(comportamientoNombre),
                          subtitle: Text(principio.benchmarkComportamiento.split(":").last.trim()),
                          trailing: const Icon(Icons.arrow_forward_ios),
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
                                  dimensionNombre: widget.dimensionId,
                                  calificacionExistente: calificacionActual,
                                ),
                              ),
                            );
                            if (resultado != null) cargarDatos();
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
    );
  }
}
