/*import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/evaluacion_cache_service.dart';
import '../services/supabase_service.dart';


final cacheServiceProvider = Provider((ref) => EvaluacionCacheService());
final supabaseServiceProvider = Provider((ref) => SupabaseService());


final tablasProvider = StateNotifierProvider<TablasController, Map<String, dynamic>>((ref) {
return TablasController(
ref.read(cacheServiceProvider),
ref.read(supabaseServiceProvider),
);
});


class TablasController extends StateNotifier<Map<String, dynamic>> {
final EvaluacionCacheService _cache;
final SupabaseService _sb;
Timer? _timer;


TablasController(this._cache, this._sb) : super({});


/// Carga inicial: 1) cache inmediato 2) merge remoto → guarda en cache
Future<void> init(String empresaId) async {
// 1) Cache inmediato para que la UI muestre algo sin parpadeo
final local = await _cache.loadTablaDatos();
if (local.isNotEmpty) state = local;


// 2) Remoto (si existe) y merge ligero (remoto gana si trae claves nuevas)
final remoto = await _sb.fetchTablaDatos(empresaId);
if (remoto != null && remoto.isNotEmpty) {
final merged = {...state, ...remoto};
state = merged;
await _cache.saveTablaDatos(state);
}


// 3) Arrancar sync periódico de pendientes (cada 30s; ajusta si quieres)
_timer?.cancel();
_timer = Timer.periodic(const Duration(seconds: 30), (_) => syncPendientes(empresaId));
}


/// Setea/actualiza una calificación local y persiste inmediatamente (sin borrar nada).
Future<void> setCalificacion({
required String dimensionId,
required String principioId,
required String comportamientoId,
required String asociadoId,
required int valor, // 0-5
}) async {
final dim = Map<String, dynamic>.from(state);
dim.putIfAbsent(dimensionId, () => <String, dynamic>{});
final prin = Map<String, dynamic>.from(dim[dimensionId] as Map<String, dynamic>);
prin.putIfAbsent(principioId, () => <String, dynamic>{});
final compMap = Map<String, dynamic>.from(prin[principioId] as Map<String, dynamic>);


// Estructura de guardado por comportamiento y asociado (ultimo valor)
final key = '${comportamientoId}__${asociadoId}';
compMap[key] = valor;


prin[principioId] = compMap;
dim[dimensionId] = prin;
state = dim;


// Persistencia inmediata en cache
await _cache.saveTablaDatos(state);


// Encolar pendiente para Supabase
}*/