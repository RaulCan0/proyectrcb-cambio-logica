import 'package:applensys/evaluacion/services/local/evaluacion_cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalificacionesSyncService {
  final SupabaseClient _client = Supabase.instance.client;
  final EvaluacionCacheService _cacheService = EvaluacionCacheService();

  /// Descarga todas las calificaciones desde Supabase y actualiza la cache local.
  Future<void> sincronizarDesdeSupabase() async {
    await _cacheService.init();
    final List<dynamic> res = await _client.from('calificaciones').select();

    // Estructura cacheada esperada: Map<String, Map<String, List<Map<String, dynamic>>>>
    // Aquí agrupamos por dimension, luego por evaluacionId
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

  /// Sube todas las calificaciones cacheadas a Supabase.
  /// Opcional: puedes evitar duplicados o solo subir cambios nuevos.
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

    // Puedes limpiar la tabla antes de insertar todo, o hacer upserts inteligentes.
    if (items.isNotEmpty) {
      await _client.from('calificaciones').upsert(items, onConflict: 'id');
    }
  }
}