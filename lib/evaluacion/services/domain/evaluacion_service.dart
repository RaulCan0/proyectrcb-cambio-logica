import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/models/evaluacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class EvaluacionService {
  final SupabaseClient _client = Supabase.instance.client;

  static const _mapaTotales = {'1': 6, '2': 14, '3': 8};

  // Evaluación CRUD
  Future<List<Evaluacion>> getEvaluaciones() async {
    final res = await _client.from('detalles_evaluacion').select();
    return (res as List).map((e) => Evaluacion.fromMap(e)).toList();
  }

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

  Future<void> updateEvaluacion(String id, Evaluacion evaluacion) async {
    await _client.from('detalles_evaluacion').update(evaluacion.toMap()).eq('id', id);
  }

  Future<void> deleteEvaluacion(String id) async {
    await _client.from('detalles_evaluacion').delete().eq('id', id);
  }

  Future<Evaluacion?> buscarEvaluacionExistente(String empresaId, String asociadoId) async {
    final res = await _client
        .from('evaluaciones')
        .select()
        .eq('empresa_id', empresaId)
        .eq('asociado_id', asociadoId)
        .maybeSingle();
    return res != null ? Evaluacion.fromMap(res) : null;
  }

  Future<Evaluacion> crearEvaluacionSiNoExiste(String empresaId, String asociadoId) async {
    final existente = await buscarEvaluacionExistente(empresaId, asociadoId);
    if (existente != null) return existente;
    final nueva = Evaluacion(
      id: const Uuid().v4(),
      empresaId: empresaId,
      asociadoId: asociadoId,
      fecha: DateTime.now(),
    );
    await _client.from('evaluaciones').insert(nueva.toMap());
    return nueva;
  }

  Future<void> guardarEvaluacionDraft(String evaluacionId) async {
    await _client.from('evaluaciones').update({'finalizada': false}).eq('id', evaluacionId);
  }

  Future<void> finalizarEvaluacion(String evaluacionId) async {
    await _client.from('detalles_evaluacion').update({'finalizada': true}).eq('id', evaluacionId);
  }

  // Calificaciones
  Future<void> addCalificacion(Calificacion calificacion) async {
    await _client.from('calificaciones').insert(calificacion.toMap());
  }

  Future<void> updateCalificacion(String id, int puntaje) async {
    await _client.from('calificaciones').update({'puntaje': puntaje}).eq('id', id);
  }

  Future<void> updateCalificacionFull(Calificacion calificacion) async {
    await _client.from('calificaciones').update(calificacion.toMap()).eq('id', calificacion.id);
  }

  Future<void> deleteCalificacion(String id) async {
    await _client.from('calificaciones').delete().eq('id', id);
  }

  Future<List<Calificacion>> getCalificacionesPorAsociado(String idAsociado) async {
    final res = await _client
        .from('calificaciones')
        .select('id, id_asociado, id_empresa, id_dimension, comportamiento, puntaje, fecha_evaluacion, observaciones, sistemas, evidencia_url')
        .eq('id_asociado', idAsociado);
    return (res as List).map((e) => Calificacion.fromMap(e)).toList();
  }

  Future<Calificacion?> getCalificacionExistente({
    required String idAsociado,
    required String idEmpresa,
    required int idDimension,
    required String comportamiento,
  }) async {
    final res = await _client
        .from('calificaciones')
        .select()
        .eq('id_asociado', idAsociado)
        .eq('id_empresa', idEmpresa)
        .eq('id_dimension', idDimension)
        .eq('comportamiento', comportamiento)
        .maybeSingle();
    return res != null ? Calificacion.fromMap(res) : null;
  }
Future<Map<String, double>> obtenerProgresoDimensionPorCargo({
  required String empresaId,
  required String dimensionId,
  required String cargo,
}) async {
  final supabase = Supabase.instance.client;

  try {
    debugPrint('=== DEBUG obtenerProgresoDimensionPorCargo ===');
    debugPrint('empresaId: $empresaId');
    debugPrint('dimensionId: $dimensionId');
    debugPrint('cargo: $cargo');

    // Primero obtener los asociados de la empresa con el cargo específico
    final asociadosRes = await supabase
        .from('asociados')
        .select('id')
        .eq('empresa_id', empresaId)
        .ilike('cargo', '%$cargo%'); // Usar ilike para búsqueda más flexible

    debugPrint('asociadosRes: $asociadosRes');

    if ((asociadosRes as List).isEmpty) {
      debugPrint('No se encontraron asociados para el cargo: $cargo');
      return {cargo: 0.0};
    }

    final asociadosIds = (asociadosRes).map((e) => e['id'] as String).toList();
    debugPrint('asociadosIds encontrados: $asociadosIds');

    // Obtener calificaciones de esos asociados en esa dimensión
    final calificacionesRes = await supabase
        .from('calificaciones')
        .select('comportamiento, id_asociado')
        .inFilter('id_asociado', asociadosIds)
        .eq('id_dimension', int.tryParse(dimensionId) ?? 1)
        .eq('id_empresa', empresaId);

    debugPrint('calificacionesRes: $calificacionesRes');

    final totalCalificaciones = (calificacionesRes as List).length;
    debugPrint('totalCalificaciones: $totalCalificaciones');

    // Definir el total de comportamientos por dimensión basado en tu lógica de negocio
    const mapaTotales = {'1': 6, '2': 14, '3': 8}; // Ajusta estos valores según tu sistema
    final totalComportamientos = mapaTotales[dimensionId] ?? 1;
    final totalEsperado = totalComportamientos * asociadosIds.length;

    debugPrint('totalComportamientos: $totalComportamientos');
    debugPrint('totalEsperado: $totalEsperado');

    final progreso = totalEsperado == 0 ? 0.0 : totalCalificaciones / totalEsperado;
    debugPrint('progreso calculado: $progreso');

    return {cargo: progreso.clamp(0.0, 1.0)};
  } catch (e) {
    debugPrint('Error en obtenerProgresoDimensionPorCargo: $e');
    return {cargo: 0.0};
  }
}

  // Progreso Global de una Dimensión
  Future<double> obtenerProgresoDimension(String empresaId, String dimensionId) async {
    try {
      final response = await _client
          .from('calificaciones')
          .select('id')
          .eq('id_empresa', empresaId)
          .eq('id_dimension', int.tryParse(dimensionId) ?? -1);
      final total = (response as List).length;
      final totalDimension = _mapaTotales[dimensionId] ?? 1;
      return (total / totalDimension).clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Error en obtenerProgresoDimension: $e');
      return 0.0;
    }
  }
}
