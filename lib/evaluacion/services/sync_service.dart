import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'evaluacion_cache_service.dart';

class CalificacionesSyncService extends ChangeNotifier {
  /// Calcula el progreso de un asociado en una dimensión y evaluación
  double calcularProgresoAsociado({
    required String evaluacionId,
    required String asociadoId,
    required String dimensionId,
    required int totalComportamientos,
  }) {
    final dimensionKey = 'Dimensión $dimensionId';
    final evalMap = tablaDatos[dimensionKey];
    if (evalMap == null || !evalMap.containsKey(evaluacionId)) return 0.0;
    final calificaciones = evalMap[evaluacionId]!
      .where((c) => c['asociado_id'] == asociadoId)
      .toList();
    if (totalComportamientos == 0) return 0.0;
    return calificaciones.length / totalComportamientos;
  }
  // Estructura local: Dimensión -> evaluacionId -> lista de calificaciones
  Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };

  final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);
  RealtimeChannel? _channel;
  String? _empresaId;

  Future<void> cargarDatosIniciales(String empresaId) async {
    _empresaId = empresaId;

    // 1) cache primero
    final cache = await EvaluacionCacheService().cargarTablas();
    if (cache.isNotEmpty) {
      tablaDatos = cache;
      dataChanged.value = !dataChanged.value;
      notifyListeners();
    }

    // 2) Supabase después
    await cargarTodasCalificaciones(empresaId);
  }

  Future<void> cargarTodasCalificaciones(String empresaId) async {
    final supabase = Supabase.instance.client;
    final rows = await supabase
        .from('calificaciones')
        .select('id_asociado, cargo, puntaje, comportamiento, id_dimension, id_empresa, id_evaluacion')
        .eq('id_empresa', empresaId);

    final nuevaTabla = <String, Map<String, List<Map<String, dynamic>>>>{
      'Dimensión 1': {},
      'Dimensión 2': {},
      'Dimensión 3': {},
    };

    for (final item in rows) {
      final dimId = (item['id_dimension'] ?? '').toString();
      final dimensionKey = 'Dimensión $dimId';
      final evaluacionId = (item['id_evaluacion'] ?? '').toString();

      nuevaTabla.putIfAbsent(dimensionKey, () => {});
      nuevaTabla[dimensionKey]!.putIfAbsent(evaluacionId, () => []);
      nuevaTabla[dimensionKey]![evaluacionId]!.add({
        'asociado_id': item['id_asociado'],
        'cargo': item['cargo'],
        'valor': item['puntaje'],
        'comportamiento': item['comportamiento'],
      });
    }

    tablaDatos = nuevaTabla;
    await EvaluacionCacheService().guardarTablas(tablaDatos);
    dataChanged.value = !dataChanged.value;
    notifyListeners();
  }

  void suscribirseASupabase(String empresaId) {
    _empresaId = empresaId;
    final supabase = Supabase.instance.client;

    // Realtime filtrado por empresa (requiere Supabase Flutter >=2.3)
    _channel?.unsubscribe();
    _channel = supabase.channel('calificaciones-empresa-$empresaId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'calificaciones',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'empresa_id',
          value: empresaId,
        ),
        callback: (payload) async {
          // Recarga sólo los datos de esta empresa
          if (_empresaId == null) return;
          await cargarTodasCalificaciones(_empresaId!);
        },
      )
      ..subscribe();
  }

  void cancelarSuscripcion() {
    _channel?.unsubscribe();
    _channel = null;
  }
  Future<void> actualizarDato(
    String evaluacionId, {
    required String dimension,      // 'Dimensión 1' | 'Dimensión 2' | ...
    required String principio,
    required String comportamiento,
    required String cargo,          // 'EJECUTIVO'|'GERENTE'|'MIEMBRO'
    required int valor,
    required List<String> sistemas, // se recomienda columna jsonb
    required String dimensionId,    // '1' | '2' | '3'
    required String asociadoId,     // usuario/empleado
    String? observaciones,
    required String empresaId,
  }) async {
    // 1) memoria
    final tablaDim = tablaDatos.putIfAbsent(dimension, () => {});
    final lista = tablaDim.putIfAbsent(evaluacionId, () => []);
    final idx = lista.indexWhere((it) =>
      it['principio'] == principio &&
      it['comportamiento'] == comportamiento &&
      it['cargo'] == cargo &&
      (it['dimension_id']?.toString() ?? '') == dimensionId &&
      (it['asociado_id']?.toString() ?? '') == asociadoId
    );

    if (idx != -1) {
      lista[idx] = {
        ...lista[idx],
        'valor': valor,
        'sistemas': sistemas,
        'observaciones': observaciones ?? '',
      };
    } else {
      lista.add({
        'evaluacion_id': evaluacionId,
        'dimension_id': dimensionId,
        'asociado_id': asociadoId,
        'principio': principio,
        'comportamiento': comportamiento,
        'cargo': cargo,
        'valor': valor,
        'sistemas': sistemas,
        'observaciones': observaciones ?? '',
        'empresa_id': empresaId,
      });
    }
    await EvaluacionCacheService().guardarTablas(tablaDatos);
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('calificaciones').upsert({
        'empresa_id': empresaId,
        'evaluacion_id': evaluacionId,
        'dimension_id': dimensionId,
        'asociado_id': asociadoId,
        'principio': principio,
        'comportamiento': comportamiento,
        'cargo': cargo,
        'valor': valor,
        'sistemas': sistemas,
        'observaciones': observaciones ?? '',
      });
    } catch (e) {
  
      debugPrint('Error upsert calificacion: $e');
    }
    dataChanged.value = !dataChanged.value;
    notifyListeners();
  }
}
/*// lib/services/evaluacion_preferences.dart
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../models/calificacion.dart';

class EvaluacionPreferences {
  static final EvaluacionPreferences _instance = EvaluacionPreferences._internal();
  factory EvaluacionPreferences() => _instance;
  EvaluacionPreferences._internal();

  SharedPreferences? _prefs;
  final SupabaseService _supabase = SupabaseService();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Si detecta Wi-Fi en cualquier momento, intenta sincronizar
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.wifi)) {
        syncPending();
      }
    });
    // Al iniciar la app, intenta sincronizar si ya hay Wi-Fi
    final current = await _connectivity.checkConnectivity();
    if (current.contains(ConnectivityResult.wifi)) syncPending();
  }

  Future<void> savePending(Calificacion cal) async {
    final list = _prefs?.getStringList('pending_calificaciones') ?? [];
    // Serializa el objeto Calificacion como JSON string
    list.add(jsonEncode(cal.toMap()));
    await _prefs?.setStringList('pending_calificaciones', list);
  }

  Future<void> syncPending() async {
    final list = _prefs?.getStringList('pending_calificaciones') ?? [];
    final success = <String>[];
    for (final jsonStr in list) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final cal = Calificacion.fromMap(map);
        await _supabase.addCalificacion(
          cal,
          id: cal.id,
          idAsociado: cal.idAsociado,
        );
        success.add(jsonStr);
      } catch (_) {
        // Si falla, lo dejamos pendiente
      }
    }
    if (success.isNotEmpty) {
      list.removeWhere((item) => success.contains(item));
      await _prefs?.setStringList('pending_calificaciones', list);
    }
  }

  void dispose() => _subscription?.cancel();
}
/**/ */