// lib/services/evaluacion_preferences.dart
import 'dart:async';
import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/services/supabase_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
    list.add(cal.toMap() as String); // Usar el método toJson
    await _prefs?.setStringList('pending_calificaciones', list);
  }

  Future<void> syncPending() async {
    final list = _prefs?.getStringList('pending_calificaciones') ?? [];
    final success = <String>[];
    for (final json in list) {
      final cal = Calificacion.fromMap(json as Map<String, dynamic>); // Usar el método fromJson
      try {
        await _supabase.addCalificacion(
          cal,
          id: cal.id, // Use the correct property name from Calificacion, e.g. 'id'
          idAsociado: cal.idAsociado,
        );
        success.add(json);
      } catch (_) {
        // Si falla, lo dejamos pendiente
      }
    }
    if (success.isNotEmpty) {
      list.removeWhere(success.contains);
      await _prefs?.setStringList('pending_calificaciones', list);
    }
  }

  void dispose() => _subscription?.cancel();
}


