import 'package:flutter/material.dart';
import 'package:applensys/evaluacion/models/asociado.dart';
import 'package:applensys/evaluacion/models/calificacion.dart';

/// Provider especializado para clasificar evaluaciones por asociado según su nivel/cargo
class AsociadoEvaluacionProvider extends ChangeNotifier {
  // Almacén principal de evaluaciones clasificadas por asociado
  final Map<String, AsociadoEvaluacion> _evaluacionesPorAsociado = {};
  
  // Cache para cargos normalizados
  final Map<String, String> _cargoNormalizadoCache = {};

  /// Obtiene todas las evaluaciones de un asociado específico
  AsociadoEvaluacion? getEvaluacionAsociado(String asociadoId) {
    return _evaluacionesPorAsociado[asociadoId];
  }

  /// Obtiene todas las evaluaciones clasificadas por nivel
  Map<String, List<AsociadoEvaluacion>> getEvaluacionesPorNivel() {
    final Map<String, List<AsociadoEvaluacion>> clasificadas = {
      'Ejecutivo': [],
      'Gerente': [],
      'Miembro': [],
    };

    for (final evaluacion in _evaluacionesPorAsociado.values) {
      final nivel = _normalizarCargo(evaluacion.asociado.cargo);
      if (clasificadas.containsKey(nivel)) {
        clasificadas[nivel]!.add(evaluacion);
      }
    }

    return clasificadas;
  }

  /// Normaliza el cargo a uno de los tres niveles principales
  String _normalizarCargo(String cargoRaw) {
    if (_cargoNormalizadoCache.containsKey(cargoRaw)) {
      return _cargoNormalizadoCache[cargoRaw]!;
    }

    final cargoLower = cargoRaw.toLowerCase().trim();
    String nivelNormalizado;

    if (cargoLower.contains('ejecutivo') || 
        cargoLower.contains('director') || 
        cargoLower.contains('gerente general') ||
        cargoLower.contains('presidente') ||
        cargoLower.contains('ceo') ||
        cargoLower.contains('chief')) {
      nivelNormalizado = 'Ejecutivo';
    } else if (cargoLower.contains('gerente') || 
               cargoLower.contains('manager') ||
               cargoLower.contains('supervisor') ||
               cargoLower.contains('coordinador') ||
               cargoLower.contains('jefe')) {
      nivelNormalizado = 'Gerente';
    } else {
      nivelNormalizado = 'Miembro';
    }

    _cargoNormalizadoCache[cargoRaw] = nivelNormalizado;
    return nivelNormalizado;
  }

  /// Agrega o actualiza una calificación para un asociado específico
  void actualizarCalificacionAsociado({
    required Asociado asociado,
    required Calificacion calificacion,
    required String principio,
    required String dimension,
  }) {
    final asociadoId = asociado.id;
    
    // Crear evaluación del asociado si no existe
    if (!_evaluacionesPorAsociado.containsKey(asociadoId)) {
      _evaluacionesPorAsociado[asociadoId] = AsociadoEvaluacion(
        asociado: asociado,
        calificacionesPorDimension: {},
        progresoGeneral: 0.0,
      );
    }

    final evaluacion = _evaluacionesPorAsociado[asociadoId]!;
    
    // Inicializar dimensión si no existe
    if (!evaluacion.calificacionesPorDimension.containsKey(dimension)) {
      evaluacion.calificacionesPorDimension[dimension] = DimensionEvaluacion(
        nombre: dimension,
        principios: {},
        promedioGeneral: 0.0,
      );
    }

    final dimEvaluacion = evaluacion.calificacionesPorDimension[dimension]!;
    
    // Inicializar principio si no existe
    if (!dimEvaluacion.principios.containsKey(principio)) {
      dimEvaluacion.principios[principio] = PrincipioEvaluacion(
        nombre: principio,
        comportamientos: {},
        promedioGeneral: 0.0,
      );
    }

    final principioEval = dimEvaluacion.principios[principio]!;
    
    // Agregar/actualizar comportamiento
    principioEval.comportamientos[calificacion.comportamiento] = calificacion;
    
    // Recalcular promedios
    _recalcularPromedios(evaluacion);
    
    notifyListeners();
  }

  /// Recalcula todos los promedios de una evaluación de asociado
  void _recalcularPromedios(AsociadoEvaluacion evaluacion) {
    double sumaGeneral = 0.0;
    int conteoGeneral = 0;

    for (final dimEval in evaluacion.calificacionesPorDimension.values) {
      double sumaDimension = 0.0;
      int conteoDimension = 0;

      for (final principioEval in dimEval.principios.values) {
        double sumaPrincipio = 0.0;
        int conteoPrincipio = 0;

        for (final calificacion in principioEval.comportamientos.values) {
          if (calificacion.puntaje > 0) {
            sumaPrincipio += calificacion.puntaje;
            conteoPrincipio++;
          }
        }

        principioEval.promedioGeneral = conteoPrincipio > 0 ? sumaPrincipio / conteoPrincipio : 0.0;
        
        if (principioEval.promedioGeneral > 0) {
          sumaDimension += principioEval.promedioGeneral;
          conteoDimension++;
        }
      }

      dimEval.promedioGeneral = conteoDimension > 0 ? sumaDimension / conteoDimension : 0.0;
      
      if (dimEval.promedioGeneral > 0) {
        sumaGeneral += dimEval.promedioGeneral;
        conteoGeneral++;
      }
    }

    evaluacion.progresoGeneral = conteoGeneral > 0 ? sumaGeneral / conteoGeneral : 0.0;
  }

  /// Obtiene estadísticas agregadas por nivel
  Map<String, EstadisticasNivel> getEstadisticasPorNivel() {
    final evaluacionesPorNivel = getEvaluacionesPorNivel();
    final Map<String, EstadisticasNivel> estadisticas = {};

    for (final entry in evaluacionesPorNivel.entries) {
      final nivel = entry.key;
      final evaluaciones = entry.value;

      if (evaluaciones.isEmpty) {
        estadisticas[nivel] = EstadisticasNivel(
          nombreNivel: nivel,
          totalAsociados: 0,
          promedioGeneral: 0.0,
          promediosPorDimension: {},
        );
        continue;
      }

      // Calcular promedios por dimensión
      final Map<String, double> promediosDimensiones = {};
      final Map<String, int> conteosDimensiones = {};

      for (final evaluacion in evaluaciones) {
        for (final entry in evaluacion.calificacionesPorDimension.entries) {
          final dimNombre = entry.key;
          final dimEval = entry.value;
          
          if (dimEval.promedioGeneral > 0) {
            promediosDimensiones[dimNombre] = (promediosDimensiones[dimNombre] ?? 0.0) + dimEval.promedioGeneral;
            conteosDimensiones[dimNombre] = (conteosDimensiones[dimNombre] ?? 0) + 1;
          }
        }
      }

      // Promediar por dimensión
      final Map<String, double> promediosFinales = {};
      for (final dimNombre in promediosDimensiones.keys) {
        final suma = promediosDimensiones[dimNombre]!;
        final conteo = conteosDimensiones[dimNombre]!;
        promediosFinales[dimNombre] = conteo > 0 ? suma / conteo : 0.0;
      }

      // Promedio general del nivel
      final promedioGeneralNivel = evaluaciones
          .where((e) => e.progresoGeneral > 0)
          .map((e) => e.progresoGeneral)
          .fold(0.0, (a, b) => a + b) / evaluaciones.where((e) => e.progresoGeneral > 0).length;

      estadisticas[nivel] = EstadisticasNivel(
        nombreNivel: nivel,
        totalAsociados: evaluaciones.length,
        promedioGeneral: promedioGeneralNivel.isNaN ? 0.0 : promedioGeneralNivel,
        promediosPorDimension: promediosFinales,
      );
    }

    return estadisticas;
  }

  /// Limpia todos los datos
  void limpiarDatos() {
    _evaluacionesPorAsociado.clear();
    _cargoNormalizadoCache.clear();
    notifyListeners();
  }

  /// Obtiene el total de asociados por nivel
  Map<String, int> getTotalAsociadosPorNivel() {
    final evaluacionesPorNivel = getEvaluacionesPorNivel();
    return evaluacionesPorNivel.map((nivel, evaluaciones) => 
      MapEntry(nivel, evaluaciones.length));
  }

  /// Obtiene el progreso de evaluacion por asociado
  Map<String, double> getProgresoEvaluacionPorAsociado() {
    return _evaluacionesPorAsociado.map((asociadoId, evaluacion) => 
      MapEntry(asociadoId, evaluacion.progresoGeneral));
  }
}

/// Clase que representa la evaluación completa de un asociado
class AsociadoEvaluacion {
  final Asociado asociado;
  final Map<String, DimensionEvaluacion> calificacionesPorDimension;
  double progresoGeneral;

  AsociadoEvaluacion({
    required this.asociado,
    required this.calificacionesPorDimension,
    required this.progresoGeneral,
  });
}

/// Evaluación de una dimensión específica
class DimensionEvaluacion {
  final String nombre;
  final Map<String, PrincipioEvaluacion> principios;
  double promedioGeneral;

  DimensionEvaluacion({
    required this.nombre,
    required this.principios,
    required this.promedioGeneral,
  });
}

/// Evaluación de un principio específico
class PrincipioEvaluacion {
  final String nombre;
  final Map<String, Calificacion> comportamientos;
  double promedioGeneral;

  PrincipioEvaluacion({
    required this.nombre,
    required this.comportamientos,
    required this.promedioGeneral,
  });
}

/// Estadísticas agregadas por nivel organizacional
class EstadisticasNivel {
  final String nombreNivel;
  final int totalAsociados;
  final double promedioGeneral;
  final Map<String, double> promediosPorDimension;

  EstadisticasNivel({
    required this.nombreNivel,
    required this.totalAsociados,
    required this.promedioGeneral,
    required this.promediosPorDimension,
  });
}