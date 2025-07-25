import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EvaluacionCacheService {
  static const _keyEvaluacionPendiente       = 'evaluacion_pendiente';
  static const _keyTablaDatos                = 'tabla_datos';
  static const _keyEvaluacionAsociados       = 'evaluacion_asociados';
  static const _keyEvaluacionPrincipios      = 'evaluacion_principios';
  static const _keyEvaluacionComportamientos = 'evaluacion_comportamientos';
  static const _keyEvaluacionDetalles        = 'evaluacion_detalles';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> guardarPendiente(String evaluacionId) async {
    await init();
    await _prefs!.setString(_keyEvaluacionPendiente, evaluacionId);
  }

  Future<String?> obtenerPendiente() async {
    await init();
    return _prefs!.getString(_keyEvaluacionPendiente);
  }

  Future<void> eliminarPendiente() async {
    await init();
    await _prefs!.remove(_keyEvaluacionPendiente);
  }

  /// Guarda la estructura completa de tablas
  Future<void> guardarTablas(
      Map<String, Map<String, List<Map<String, dynamic>>>> data) async {
    await init();
    final encoded = jsonEncode(data);
    await _prefs!.setString(_keyTablaDatos, encoded);
  }

  /// Carga la estructura completa de tablas
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> cargarTablas() async {
    await init();
    final raw = _prefs!.getString(_keyTablaDatos);
    if (raw == null || raw.isEmpty) {
      return {
        'Dimensión 1': {},
        'Dimensión 2': {},
        'Dimensión 3': {},
      };
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((dim, map) {
        final sub = (map as Map<String, dynamic>).map((id, filas) {
          return MapEntry(
            id,
            List<Map<String, dynamic>>.from(
              (filas as List).map((e) => Map<String, dynamic>.from(e)),
            ),
          );
        });
        return MapEntry(dim, sub);
      });
    } catch (e) {
      debugPrint('Error parseando cache: $e');
      return {
        'Dimensión 1': {},
        'Dimensión 2': {},
        'Dimensión 3': {},
      };
    }
  }

  Future<void> limpiarCacheTablaDatos() async {
    await init();
    await _prefs!.remove(_keyTablaDatos);
  }

  Future<void> limpiarEvaluacionCompleta() async {
    await init();
    await _prefs!.remove(_keyEvaluacionPendiente);
    await _prefs!.remove(_keyTablaDatos);
    await _prefs!.remove(_keyEvaluacionAsociados);
    await _prefs!.remove(_keyEvaluacionPrincipios);
    await _prefs!.remove(_keyEvaluacionComportamientos);
    await _prefs!.remove(_keyEvaluacionDetalles);
  }

  /// Crea un listado de promedios por sistema basándose en el cache
  Future<List<Map<String, dynamic>>> cargarPromediosSistemas() async {
    final tabla = await cargarTablas();
    final Map<String, List<double>> acumulador = {};
    tabla.forEach((_, submap) {
      submap.values.expand((rows) => rows).forEach((item) {
        final sistemasRaw = item['sistemas'] as List<dynamic>? ?? [];
        final sistemas = sistemasRaw.map((e) => e.toString()).toList();
        final valorRaw = item['valor'];
        final valor = valorRaw is num
            ? valorRaw.toDouble()
            : double.tryParse(valorRaw.toString()) ?? 0.0;
        for (final s in sistemas) {
          acumulador.putIfAbsent(s, () => []).add(valor);
        }
      });
    });
    final List<Map<String, dynamic>> resultados = [];
    acumulador.forEach((sistema, valores) {
      if (valores.isNotEmpty) {
        final prom = valores.reduce((a, b) => a + b) / valores.length;
        resultados.add({
          'sistema': sistema,
          'promedio': prom,
          'cantidad': valores.length,
        });
      }
    });
    resultados.sort((a, b) =>
        (b['promedio'] as double).compareTo(a['promedio'] as double));
    return resultados;
  }

  /// NUEVO: carga todas las calificaciones de Supabase en la misma estructura de tablaDatos
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> cargarCalificacionesDesdeSupabase(
      String evaluacionId) async {
    await init();
    final client = Supabase.instance.client;
    final dataRaw = await client
        .from('calificaciones')
        .select()
        .eq('evaluacion_id', evaluacionId);
    final items = List<Map<String, dynamic>>.from(dataRaw as List<dynamic>);
    final Map<String, Map<String, List<Map<String, dynamic>>>> result = {
      'Dimensión 1': {},
      'Dimensión 2': {},
      'Dimensión 3': {},
    };
    for (final item in items) {
      final dim = item['dimension']?.toString().trim() ?? '';
      if (dim.isEmpty) continue;
      final mapDim = result.putIfAbsent(dim, () => <String, List<Map<String, dynamic>>>{});
      final lista = mapDim.putIfAbsent(evaluacionId, () => <Map<String, dynamic>>[]);
      lista.add({
        'principio': item['principio'],
        'comportamiento': item['comportamiento'],
        'cargo': item['cargo'],
        'cargo_raw': item['cargo'],
        'valor': item['valor'],
        'sistemas': List<String>.from(item['sistemas'] as List<dynamic>? ?? []),
        'dimension_id': item['dimension_id'],
        'asociado_id': item['asociado_id'],
        'observaciones': item['observaciones'],
      });
    }
    return result;
  }
}
