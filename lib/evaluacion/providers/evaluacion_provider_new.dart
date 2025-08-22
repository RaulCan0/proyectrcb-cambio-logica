import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applensys/evaluacion/models/evaluacion.dart';
import 'package:applensys/evaluacion/services/domain/evaluacion_service.dart';

/// Provider para el servicio de evaluaciones
final evaluacionServiceProvider = Provider<EvaluacionService>((ref) {
  return EvaluacionService();
});

/// Provider para obtener todas las evaluaciones
final allEvaluacionesProvider = FutureProvider<List<Evaluacion>>((ref) async {
  final evaluacionService = ref.watch(evaluacionServiceProvider);
  return evaluacionService.getEvaluaciones();
});

/// Provider para obtener evaluaciones por empresa
final evaluacionesPorEmpresaProvider = FutureProvider.family<List<Evaluacion>, String>((ref, empresaId) async {
  final evaluacionService = ref.watch(evaluacionServiceProvider);
  return evaluacionService.getEvaluacionesPorEmpresa(empresaId);
});

/// Provider para obtener una evaluación específica por ID
final evaluacionByIdProvider = FutureProvider.family<Evaluacion?, String>((ref, id) async {
  final evaluacionService = ref.watch(evaluacionServiceProvider);
  return evaluacionService.getEvaluacionById(id);
});

/// Provider para obtener evaluaciones finalizadas
final evaluacionesFinalizadasProvider = FutureProvider<List<Evaluacion>>((ref) async {
  final evaluacionService = ref.watch(evaluacionServiceProvider);
  return evaluacionService.getEvaluacionesFinalizadas();
});

/// Provider para obtener evaluaciones pendientes
final evaluacionesPendientesProvider = FutureProvider<List<Evaluacion>>((ref) async {
  final evaluacionService = ref.watch(evaluacionServiceProvider);
  return evaluacionService.getEvaluacionesPendientes();
});

/// Provider para gestionar el estado de la evaluación actual
final currentEvaluacionProvider = StateProvider<Evaluacion?>((ref) => null);

/// Provider para gestionar el estado de finalización de evaluación
final evaluacionFinalizadaProvider = StateProvider<bool>((ref) => false);