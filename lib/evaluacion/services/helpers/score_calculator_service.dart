// Servicio para calcular puntajes Shingo basado en datos reales de evaluación
import '../local/evaluacion_cache_service.dart';

class ScoreCalculatorService {
  static final ScoreCalculatorService _instance = ScoreCalculatorService._internal();
  factory ScoreCalculatorService() => _instance;
  ScoreCalculatorService._internal();

  /// Estructura de ponderación Shingo
  static const Map<String, Map<String, double>> ponderacionShingo = {
    'Dimensión 1': { // Impulsores Culturales - 250 pts
      'Ejecutivo': 0.50,   // 125 pts
      'Gerente': 0.30,     // 75 pts  
      'Miembro': 0.20,     // 50 pts
    },
    'Dimensión 2': { // Mejora Continua - 350 pts
      'Ejecutivo': 0.20,   // 70 pts
      'Gerente': 0.30,     // 105 pts
      'Miembro': 0.50,     // 175 pts
    },
    'Dimensión 3': { // Alineamiento Empresarial - 200 pts
      'Ejecutivo': 0.55,   // 110 pts
      'Gerente': 0.30,     // 60 pts
      'Miembro': 0.15,     // 30 pts
    },
  };

  static const Map<String, int> puntosPorDimension = {
    'Dimensión 1': 250,  // Impulsores Culturales
    'Dimensión 2': 350,  // Mejora Continua  
    'Dimensión 3': 200,  // Alineamiento Empresarial
  };

  /// Calcula el score Shingo basado en datos reales de evaluación
  Future<Map<String, dynamic>> calcularScoreShingo(String evaluacionId) async {
    final cacheService = EvaluacionCacheService();
    await cacheService.init();
    
    // Cargar datos de evaluación desde caché
    final data = await cacheService.cargarTablas();
    
    final Map<String, Map<String, double>> promediosPorDimensionNivel = {};
    final Map<String, Map<String, int>> conteosPorDimensionNivel = {};
    
    // Procesar datos para calcular promedios por dimensión y nivel
    data.forEach((dimension, evaluaciones) {
      promediosPorDimensionNivel[dimension] = {
        'Ejecutivo': 0.0,
        'Gerente': 0.0, 
        'Miembro': 0.0,
      };
      conteosPorDimensionNivel[dimension] = {
        'Ejecutivo': 0,
        'Gerente': 0,
        'Miembro': 0,
      };
      
      // Sumar todas las calificaciones por nivel
      evaluaciones.forEach((evalId, filas) {
        if (evalId == evaluacionId) {
          for (var fila in filas) {
            final nivel = _normalizeNivel(fila['cargo_raw'] ?? '');
            final valor = (fila['valor'] as num?)?.toDouble() ?? 0.0;
            
            if (valor > 0) {
              promediosPorDimensionNivel[dimension]![nivel] = 
                  promediosPorDimensionNivel[dimension]![nivel]! + valor;
              conteosPorDimensionNivel[dimension]![nivel] = 
                  conteosPorDimensionNivel[dimension]![nivel]! + 1;
            }
          }
        }
      });
      
      // Calcular promedios finales
      for (var nivel in ['Ejecutivo', 'Gerente', 'Miembro']) {
        final suma = promediosPorDimensionNivel[dimension]![nivel]!;
        final conteo = conteosPorDimensionNivel[dimension]![nivel]!;
        promediosPorDimensionNivel[dimension]![nivel] = 
            conteo > 0 ? suma / conteo : 0.0;
      }
    });
    
    // Calcular puntajes Shingo
    final Map<String, Map<String, dynamic>> scoresPorDimension = {};
    double puntajeTotalObtenido = 0;
    double puntajeTotalPosible = 800; // Suma de todos los puntos posibles
    
    promediosPorDimensionNivel.forEach((dimension, promedios) {
      final puntosMaxDimension = puntosPorDimension[dimension] ?? 0;
      final ponderacion = ponderacionShingo[dimension] ?? {};
      
      final Map<String, dynamic> scoreDimension = {};
      double puntajeDimensionObtenido = 0;
      
      promedios.forEach((nivel, promedio) {
        final ponderacionNivel = ponderacion[nivel] ?? 0.0;
        final puntosMaxNivel = (puntosMaxDimension * ponderacionNivel).round();
        
        // Calcular porcentaje (promedio/5 * 100)
        final porcentajeObtenido = (promedio / 5.0) * 100;
        
        // Calcular puntos obtenidos
        final puntosObtenidos = (porcentajeObtenido / 100) * puntosMaxNivel;
        
        scoreDimension[nivel] = {
          'promedio': promedio,
          'porcentaje': porcentajeObtenido,
          'puntosMaximos': puntosMaxNivel,
          'puntosObtenidos': puntosObtenidos.round(),
        };
        
        puntajeDimensionObtenido += puntosObtenidos;
      });
      
      scoreDimension['totalDimension'] = {
        'puntosMaximos': puntosMaxDimension,
        'puntosObtenidos': puntajeDimensionObtenido.round(),
        'porcentaje': (puntajeDimensionObtenido / puntosMaxDimension) * 100,
      };
      
      scoresPorDimension[dimension] = scoreDimension;
      puntajeTotalObtenido += puntajeDimensionObtenido;
    });
    
    return {
      'scoresPorDimension': scoresPorDimension,
      'puntajeTotalObtenido': puntajeTotalObtenido.round(),
      'puntajeTotalPosible': puntajeTotalPosible.round(),
      'porcentajeTotal': (puntajeTotalObtenido / puntajeTotalPosible) * 100,
      'fechaCalculo': DateTime.now().toIso8601String(),
    };
  }
  
  String _normalizeNivel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('miembro')) return 'Miembro';
    if (lower.contains('gerente')) return 'Gerente';
    return 'Ejecutivo';
  }
  
  /// Determina el nivel de premio Shingo basado en el puntaje
  String determinarNivelShingo(double puntajeTotal) {
    if (puntajeTotal >= 720) return 'Shingo Prize'; // 90%+
    if (puntajeTotal >= 640) return 'Silver Medallion'; // 80%+
    if (puntajeTotal >= 560) return 'Bronze Medallion'; // 70%+
    if (puntajeTotal >= 400) return 'Recognition'; // 50%+
    return 'Needs Improvement'; // <50%
  }
}
