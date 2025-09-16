import 'package:applensys/evaluacion/models/calificacion.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class CalificacionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Agregar una nueva calificación de comportamiento
  Future<void> addCalificacion(CalificacionComportamiento calificacion) async {
    await _client.from('calificaciones').insert(calificacion.toJson());
  }

  /// Editar solo el puntaje de una calificación (por ID)
  Future<void> updateCalificacion(String id, int nuevoPuntaje) async {
    await _client.from('calificaciones').update({
      'puntaje': nuevoPuntaje,
    }).eq('id', id);
  }

  /// Editar solo campos permitidos (puntaje, observación, evidencia, sistemas)
  Future<void> updateEditableCalificacionFields({
    required String id,
    required int puntaje,
    String? observacion,
    List<String>? sistemasAsociados,
    String? evidenciaUrl,
  }) async {
    await _client.from('calificaciones').update({
      'puntaje': puntaje,
      'observacion': observacion,
      'sistemas_asociados': sistemasAsociados,
      'evidencia_url': evidenciaUrl,
    }).eq('id', id);
  }

  /// Eliminar una calificación por ID
  Future<void> deleteCalificacion(String id) async {
    await _client.from('calificaciones').delete().eq('id', id);
  }

  /// Obtener todas las calificaciones de un empleado
  Future<List<CalificacionComportamiento>> getCalificacionesPorAsociado(String idEmpleado) async {
    final res = await _client.from('calificaciones').select().eq('empleado_id', idEmpleado);
    return (res as List).map((e) => CalificacionComportamiento.fromJson(e)).toList();
  }

  /// Obtener todas las calificaciones de una evaluación
  Future<List<CalificacionComportamiento>> getCalificacionesPorEvaluacion(String evaluacionId) async {
    final res = await _client.from('calificaciones').select().eq('evaluacion_id', evaluacionId);
    return (res as List).map((e) => CalificacionComportamiento.fromJson(e)).toList();
  }
}
