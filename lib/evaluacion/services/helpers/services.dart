import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCalificacionesService {
  final _client = Supabase.instance.client;

  Future<void> guardarCalificacion(Map<String, dynamic> data) async {
    await _client.from('calificaciones').upsert(data);
  }

  Future<List<Map<String, dynamic>>> obtenerCalificaciones(String evaluacionId) async {
    final res = await _client
        .from('calificaciones')
        .select()
        .eq('evaluacion_id', evaluacionId);
    return List<Map<String, dynamic>>.from(res);
  }
}
