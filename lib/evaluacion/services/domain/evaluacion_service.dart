import 'package:applensys/evaluacion/models/evaluacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Microservicio para gestión de evaluaciones
/// Maneja todas las operaciones CRUD, finalización y cálculo de promedios
class EvaluacionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todas las evaluaciones
  Future<List<Evaluacion>> getEvaluaciones() async {
    final response = await _client.from('detalles_evaluacion').select();
    return (response as List).map((e) => Evaluacion.fromMap(e)).toList();
  }

  /// Obtiene evaluaciones por empresa
  Future<List<Evaluacion>> getEvaluacionesPorEmpresa(String empresaId) async {
    final response = await _client
        .from('detalles_evaluacion')
        .select()
        .eq('empresa_id', empresaId);
    return (response as List).map((e) => Evaluacion.fromMap(e)).toList();
  }

  /// Agrega una nueva evaluación
  Future<Evaluacion> addEvaluacion(Evaluacion evaluacion) async {
    if (evaluacion.id.isEmpty ||
        evaluacion.empresaId.isEmpty ||
        evaluacion.asociadoId.isEmpty) {
      throw Exception('Todos los IDs son obligatorios');
    }

    final data = await _client
        .from('detalles_evaluacion')
        .insert(evaluacion.toMap())
        .select()
        .single();

    return Evaluacion.fromMap(data);
  }

  /// Actualiza una evaluación
  Future<void> updateEvaluacion(String id, Evaluacion evaluacion) async {
    await _client
        .from('detalles_evaluacion')
        .update(evaluacion.toMap())
        .eq('id', id);
  }

  /// Elimina una evaluación
  Future<void> deleteEvaluacion(String id) async {
    await _client.from('detalles_evaluacion').delete().eq('id', id);
  }

  /// Obtiene una evaluación por ID
  Future<Evaluacion?> getEvaluacionById(String id) async {
    try {
      final response = await _client
          .from('detalles_evaluacion')
          .select()
          .eq('id', id)
          .single();
      return Evaluacion.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Marca una evaluación como no finalizada
  Future<void> marcarNoFinalizada(String evaluacionId) async {
    await _client
        .from('evaluaciones')
        .update({'finalizada': false})
        .eq('id', evaluacionId);
  }

  /// Finaliza una evaluación
  Future<void> finalizarEvaluacion(String evaluacionId) async {
    await _client
        .from('detalles_evaluacion')
        .update({'finalizada': true})
        .eq('id', evaluacionId);
  }

  /// Obtiene evaluaciones finalizadas
  Future<List<Evaluacion>> getEvaluacionesFinalizadas() async {
    final response = await _client
        .from('detalles_evaluacion')
        .select()
        .eq('finalizada', true);
    return (response as List).map((e) => Evaluacion.fromMap(e)).toList();
  }

  /// Obtiene evaluaciones pendientes
  Future<List<Evaluacion>> getEvaluacionesPendientes() async {
    final response = await _client
        .from('detalles_evaluacion')
        .select()
        .eq('finalizada', false);
    return (response as List).map((e) => Evaluacion.fromMap(e)).toList();
  }

  /// Limpia datos de evaluaciones (si es necesario)
  Future<void> limpiarDatosEvaluacion() async {
    // Implementar lógica específica si es necesaria
  }
}