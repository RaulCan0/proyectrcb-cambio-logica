import 'package:applensys/evaluacion/services/local/evaluacion_cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalificacionesSyncService {
  final SupabaseClient _client = Supabase.instance.client;
  final EvaluacionCacheService _cacheService = EvaluacionCacheService();

  Future<void> sincronizarDesdeSupabase() async {
    await _cacheService.init();
    final List<dynamic> res = await _client.from('calificaciones').select();
    final Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {};
    for (final item in res) {
      final dim = item['id_dimension']?.toString() ?? 'Sin dimensión';
      final evalId = item['id_empresa']?.toString() ?? 'Sin empresa';
      tablaDatos.putIfAbsent(dim, () => {});
      tablaDatos[dim]!.putIfAbsent(evalId, () => []);
      tablaDatos[dim]![evalId]!.add(Map<String, dynamic>.from(item));
    }
    await _cacheService.guardarTablas(tablaDatos);
  }

  Future<void> sincronizarCacheASupabase() async {
    await _cacheService.init();
    final tabla = await _cacheService.cargarTablas();
    final List<Map<String, dynamic>> items = [];
    tabla.forEach((_, evals) {
      evals.forEach((_, filas) {
        for (final fila in filas) {
          items.add(Map<String, dynamic>.from(fila));
        }
      });
    });
    if (items.isNotEmpty) {
      await _client.from('calificaciones').upsert(items, onConflict: 'id');
    }
  }

  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> cargarTablas() async {
    await _cacheService.init();
    return await _cacheService.cargarTablas();
  }

  Future<void> guardarTablas(Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos) async {
    await _cacheService.init();
    await _cacheService.guardarTablas(tablaDatos);
  }
}