import '../models/asociado.dart';
import '../models/principio_json.dart';
import '../screens/tablas_screen.dart' as tablas_screen;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/empresa.dart';
import '../services/json_service.dart';
import '../services/supabase_service.dart';
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
  bool cargando = true;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    cargarPrincipios();
    cargarComportamientosEvaluados();
  }

  Future<void> cargarPrincipios() async {
    try {
      final List<dynamic> datos = await JsonService.cargarJson('t${widget.dimensionId}.json');
      if (datos.isEmpty) throw Exception('El archivo JSON está vacío.');

      final todos = datos.map((e) => PrincipioJson.fromJson(e)).toList();
      final filtrados = todos.where((p) => p.nivel.toLowerCase().contains(widget.asociado.cargo.toLowerCase())).toList();

      final agrupados = <String, List<PrincipioJson>>{};
      for (var p in filtrados) {
        agrupados.putIfAbsent(p.nombre, () => []).add(p);
      }

      setState(() {
        principiosUnicos = agrupados;
        cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar JSON: $e');
    }
  }

  void cargarComportamientosEvaluados() async {
    try {
      final calificaciones = await _supabaseService.getCalificacionesPorAsociado(widget.asociado.id);
      setState(() {
        comportamientosEvaluados = calificaciones
            .where((c) => c.idDimension.toString() == widget.dimensionId)
            .map((c) => c.comportamiento)
            .toList();
      });
    } catch (e) {
      debugPrint('Error al cargar comportamientos evaluados: $e');
    }
  }

  void agregarComportamientoEvaluado(String comportamiento) {
    if (!comportamientosEvaluados.contains(comportamiento)) {
      setState(() {
        comportamientosEvaluados.add(comportamiento);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Dimensión ${widget.dimensionId.toUpperCase()} - ASOCIADO: ${widget.asociado.nombre}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFF003056),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => tablas_screen.TablasDimensionScreen(
                    empresaId: widget.empresa.id,
                    dimension: '',
                    empresa: widget.empresa,
                    evaluacionId: '', asociadoId: '',
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
                          child: Text(
                            'Nivel: ${widget.asociado.cargo.toUpperCase()}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ExpansionTile(
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: progreso,
                                          backgroundColor: Colors.grey[300],
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('$evaluados de $totalComportamientos comportamientos evaluados'),
                                      ],
                                    ),
                                    children: entry.value.map((principio) {
                                      final comportamientoNombre = principio.benchmarkComportamiento.split(":").first.trim();

                                      return ListTile(
                                        title: Text(
                                          comportamientoNombre,
                                          style: TextStyle(
                                            color: comportamientosEvaluados.contains(comportamientoNombre)
                                                ? const Color.fromARGB(255, 133, 190, 135)
                                                : Colors.black,
                                            fontWeight: comportamientosEvaluados.contains(comportamientoNombre)
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: const Text('Ir a evaluación'),
                                        trailing: const Icon(Icons.arrow_forward_ios),
                                        onTap: () async {
                                          final resultado = await Navigator.push<String>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ComportamientoEvaluacionScreen(
                                                principio: principio,
                                                cargo: widget.asociado.cargo,
                                                evaluacionId: const Uuid().v4(),
                                                dimensionId: widget.dimensionId,
                                                empresaId: widget.empresa.id,
                                                asociadoId: widget.asociado.id,
                                              ),
                                            ),
                                          );
                                          if (resultado != null && !comportamientosEvaluados.contains(resultado)) {
                                            setState(() {
                                              comportamientosEvaluados.add(resultado);
                                            });
                                            setStateTile(() {});
                                            await _supabaseService.registrarComportamientoEvaluado(
                                              empresaId: widget.empresa.id,
                                              asociadoId: widget.asociado.id,
                                              dimensionId: widget.dimensionId,
                                              comportamiento: resultado,
                                            );
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

extension EditarCalificacionSupabase on SupabaseService {
  Future<void> actualizarPuntajeComportamiento({
    required String empresaId,
    required String asociadoId,
    required String dimensionId,
    required String comportamiento,
    required int nuevoPuntaje,
  }) async {
    await Supabase.instance.client
        .from('calificaciones')
        .update({'puntaje': nuevoPuntaje})
        .eq('id_asociado', asociadoId)
        .eq('id_empresa', empresaId)
        .eq('id_dimension', int.tryParse(dimensionId) ?? 0)
        .eq('comportamiento', comportamiento);
  }
}
