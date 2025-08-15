import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EvaluacionCacheService {
  // 🔹 Claves de almacenamiento
  static const _keyEvaluacionPendiente       = 'evaluacion_pendiente';
  static const _keyTablaDatos                = 'tabla_datos';
  static const _keyEvaluacionAsociados       = 'evaluacion_asociados';
  static const _keyEvaluacionPrincipios      = 'evaluacion_principios';
  static const _keyEvaluacionComportamientos = 'evaluacion_comportamientos';
  static const _keyEvaluacionDetalles        = 'evaluacion_detalles';

  SharedPreferences? _prefs;

  /// Inicializa SharedPreferences y carga datos si es necesario
  Future<void> init() async {
    await _initPrefs();
    await cargarTablas(); // precarga la tabla en memoria si quieres
  }

  // 🔹 Inicialización privada
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // -------------------------------------------------------------
  // 🔹 Gestión de Evaluación Pendiente
  // -------------------------------------------------------------

  Future<void> guardarPendiente(String evaluacionId) async {
    await _initPrefs();
    await _prefs!.setString(_keyEvaluacionPendiente, evaluacionId);
  }

  Future<String?> obtenerPendiente() async {
    await _initPrefs();
    return _prefs!.getString(_keyEvaluacionPendiente);
  }

  Future<void> eliminarPendiente() async {
    await _initPrefs();
    await _prefs!.remove(_keyEvaluacionPendiente);
  }

  // -------------------------------------------------------------
  // 🔹 Tablas de Evaluación
  // -------------------------------------------------------------

  /// Guarda las tablas completas de progreso
  Future<void> guardarTablas(
    Map<String, Map<String, List<Map<String, dynamic>>>> data
  ) async {
    await _initPrefs();
    try {
      final encoded = jsonEncode(data);
      await _prefs!.setString(_keyTablaDatos, encoded);
    } catch (e) {
      // Maneja error si quieres loguearlo
    }
  }

  /// Carga las tablas desde cache, si falla retorna estructura vacía
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> cargarTablas() async {
    await _initPrefs();
    final raw = _prefs!.getString(_keyTablaDatos);

    if (raw == null || raw.isEmpty) {
      return _estructuraVacia();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((dim, map) {
        final sub = (map as Map<String, dynamic>).map((id, filas) =>
          MapEntry(
            id,
            List<Map<String, dynamic>>.from(
              (filas as List).map((e) => Map<String, dynamic>.from(e)),
            ),
          ),
        );
        return MapEntry(dim, sub);
      });
    } catch (_) {
      return _estructuraVacia();
    }
  }

  /// Elimina solo los datos de la tabla
  Future<void> limpiarCacheTablaDatos() async {
    await _initPrefs();
    await _prefs!.remove(_keyTablaDatos);
  }

  // -------------------------------------------------------------
  // 🔹 Limpieza Completa
  // -------------------------------------------------------------

  Future<void> limpiarEvaluacionCompleta() async {
    await _initPrefs();
    await Future.wait([
      _prefs!.remove(_keyEvaluacionPendiente),
      _prefs!.remove(_keyTablaDatos),
      _prefs!.remove(_keyEvaluacionAsociados),
      _prefs!.remove(_keyEvaluacionPrincipios),
      _prefs!.remove(_keyEvaluacionComportamientos),
      _prefs!.remove(_keyEvaluacionDetalles),
    ]);
  }

  // -------------------------------------------------------------
  // 🔹 Helper
  // -------------------------------------------------------------

  Map<String, Map<String, List<Map<String, dynamic>>>> _estructuraVacia() {
    return {
      'Dimensión 1': {},
      'Dimensión 2': {},
      'Dimensión 3': {},
    };
  }
}
