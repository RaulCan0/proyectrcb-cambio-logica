// lib/services/evaluacion_preferences.dart
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
