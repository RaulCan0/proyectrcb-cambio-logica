import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Microservicio para gestión de calificaciones
/// Maneja todas las operaciones CRUD, lógica de sincronización y cálculo de promedios
class CalificacionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todas las calificaciones de un asociado
  Future<List<Calificacion>> getCalificacionesPorAsociado(String idAsociado) async {
    final response = await _client
        .from('calificaciones')
        .select()
        .eq('id_asociado', idAsociado);
    return (response as List).map((e) => Calificacion.fromMap(e)).toList();
  }

  /// Obtiene todas las calificaciones de una empresa
  Future<List<Map<String, dynamic>>> getCalificacionesPorEmpresa(String empresaId) async {
    if (empresaId.isEmpty) return [];
    const String selectColumns = 'id, id_asociado, id_empresa, id_dimension, comportamiento, puntaje, fecha_evaluacion, observaciones, sistemas, evidencia_url';
    final res = await _client
        .from('calificaciones')
        .select(selectColumns)
        .eq('id_empresa', empresaId)
        .order('fecha_evaluacion', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Obtiene todas las calificaciones
  Future<List<Calificacion>> getAllCalificaciones() async {
    final response = await _client.from('calificaciones').select();
    return (response as List).map((e) => Calificacion.fromMap(e)).toList();
  }

  /// Agrega una nueva calificación
  Future<void> addCalificacion(Calificacion calificacion, {required String id, required String idAsociado}) async {
    try {
      if (calificacion.id.isEmpty) {
        throw Exception("ID de calificación vacío");
      }
      if (calificacion.idAsociado.isEmpty) {
        throw Exception("ID de asociado vacío");
      }
      if (calificacion.idEmpresa.isEmpty) {
        throw Exception("ID de empresa vacío");
      }

      await _client.from('calificaciones').insert(calificacion.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza una calificación (solo puntaje)
  Future<void> updateCalificacion(String id, int nuevoPuntaje) async {
    await _client
        .from('calificaciones')
        .update({'puntaje': nuevoPuntaje})
        .eq('id', id);
  }

  /// Actualiza una calificación completa
  Future<void> updateCalificacionCompleta(Calificacion calificacion) async {
    try {
      await _client
          .from('calificaciones')
          .update(calificacion.toMap())
          .eq('id', calificacion.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Elimina una calificación
  Future<void> deleteCalificacion(String id) async {
    await _client.from('calificaciones').delete().eq('id', id);
  }

  /// Obtiene una calificación existente
  Future<Calificacion?> getCalificacionExistente({
    required String idAsociado,
    required String idEmpresa,
    required int idDimension,
    required String comportamiento,
  }) async {
    final lista = await getCalificacionesPorAsociado(idAsociado);
    return lista.cast<Calificacion?>().firstWhere(
      (c) => c != null &&
             c.idEmpresa == idEmpresa &&
             c.idDimension == idDimension &&
             c.comportamiento == comportamiento,
      orElse: () => null,
    );
  }

  /// Calcula suma por dimensión para una empresa
  Future<Map<String, double>> getSumaPorDimension(String empresaId) async {
    final response = await _client
        .from('calificaciones')
        .select('id_dimension, calificacion')
        .eq('id_empresa', empresaId);

    if (response.isEmpty) {
      return {};
    }

    final Map<String, double> sumaPorDimension = {};

    for (final item in response) {
      final dimensionId = item['id_dimension'] as String?;
      final calificacion = (item['calificacion'] as num?)?.toDouble() ?? 0.0;

      if (dimensionId != null) {
        sumaPorDimension.update(dimensionId, (value) => value + calificacion,
            ifAbsent: () => calificacion);
      }
    }

    return sumaPorDimension;
  }

  /// Calcula progreso de dimensión global para una empresa
  Future<double> calcularProgresoDimensionGlobal(String empresaId, String dimensionId) async {
    try {
      final response = await _client
          .from('calificaciones')
          .select('comportamiento')
          .eq('id_empresa', empresaId)
          .eq('id_dimension', int.tryParse(dimensionId) ?? -1);

      final evaluados = (response as List).map((e) => e['comportamiento'].toString()).toSet().length;

      const mapaTotales = {'1': 6, '2': 14, '3': 8};
      final totalDimension = mapaTotales[dimensionId] ?? 1;

      return evaluados / totalDimension;
    } catch (e) {
      return 0.0;
    }
  }
}