import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/services/domain/calificacion_service.dart';

/// Provider para el servicio de calificaciones
final calificacionServiceProvider = Provider<CalificacionService>((ref) {
  return CalificacionService();
});

/// Provider para obtener calificaciones por asociado
final calificacionesPorAsociadoProvider = FutureProvider.family<List<Calificacion>, String>((ref, idAsociado) async {
  final calificacionService = ref.watch(calificacionServiceProvider);
  return calificacionService.getCalificacionesPorAsociado(idAsociado);
});

/// Provider para obtener calificaciones por empresa
final calificacionesPorEmpresaProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, empresaId) async {
  final calificacionService = ref.watch(calificacionServiceProvider);
  return calificacionService.getCalificacionesPorEmpresa(empresaId);
});

/// Provider para obtener todas las calificaciones
final allCalificacionesProvider = FutureProvider<List<Calificacion>>((ref) async {
  final calificacionService = ref.watch(calificacionServiceProvider);
  return calificacionService.getAllCalificaciones();
});

/// Provider para obtener suma por dimensión
final sumaPorDimensionProvider = FutureProvider.family<Map<String, double>, String>((ref, empresaId) async {
  final calificacionService = ref.watch(calificacionServiceProvider);
  return calificacionService.getSumaPorDimension(empresaId);
});

/// Provider para calcular progreso de dimensión global
final progresoDimensionGlobalProvider = FutureProvider.family<double, ({String empresaId, String dimensionId})>((ref, params) async {
  final calificacionService = ref.watch(calificacionServiceProvider);
  return calificacionService.calcularProgresoDimensionGlobal(params.empresaId, params.dimensionId);
});

/// Provider para gestionar el estado de la calificación actual
final currentCalificacionProvider = StateProvider<Calificacion?>((ref) => null);