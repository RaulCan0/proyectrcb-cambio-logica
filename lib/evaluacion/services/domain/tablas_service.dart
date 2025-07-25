import 'package:applensys/evaluacion/services/local/evaluacion_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TablaService {
  final EvaluacionCacheService _cacheService;
  // final SupabaseClient _supabase; // Removed unused field
  final Connectivity _connectivity;

  TablaService({
    SupabaseClient? supabaseClient,
    Connectivity? connectivity,
    EvaluacionCacheService? cacheService,
  })  : _connectivity = connectivity ?? Connectivity(),
        _cacheService = cacheService ?? EvaluacionCacheService();

  /// Obtiene tablaDatos offline‑first:
  /// - Si hay red, carga de Supabase y refresca cache.
  /// - Si no, devuelve lo que haya en cache.
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> fetchTablas(
      String evaluacionId) async {
    final status = await _connectivity.checkConnectivity();
    // ignore: unrelated_type_equality_checks
    final online = status != ConnectivityResult.none;

    if (online) {
      try {
        final supaData =
            await _cacheService.cargarCalificacionesDesdeSupabase(evaluacionId);
        await _cacheService.guardarTablas(supaData);
        return supaData;
      } catch (e) {
        debugPrint('Error Supabase, usando cache: $e');
      }
    }

    return await _cacheService.cargarTablas();
  }
}
