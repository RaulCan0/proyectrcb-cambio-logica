import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applensys/evaluacion/models/sistema_asociado.dart';
import 'package:applensys/evaluacion/services/domain/sistema_asociado_service.dart';

/// Provider para el servicio de sistemas asociados
final sistemaAsociadoServiceProvider = Provider<SistemaAsociadoService>((ref) {
  return SistemaAsociadoService();
});

/// Provider para obtener todos los sistemas asociados
final allSistemasAsociadosProvider = FutureProvider<List<SistemaAsociado>>((ref) async {
  final sistemaAsociadoService = ref.watch(sistemaAsociadoServiceProvider);
  return sistemaAsociadoService.getAllSistemasAsociados();
});

/// Provider para obtener sistemas asociados por empresa
final sistemasAsociadosPorEmpresaProvider = FutureProvider.family<List<SistemaAsociado>, String>((ref, empresaId) async {
  final sistemaAsociadoService = ref.watch(sistemaAsociadoServiceProvider);
  return sistemaAsociadoService.getSistemasAsociadosPorEmpresa(empresaId);
});

/// Provider para obtener sistemas asociados por asociado
final sistemasAsociadosPorAsociadoProvider = FutureProvider.family<List<SistemaAsociado>, String>((ref, asociadoId) async {
  final sistemaAsociadoService = ref.watch(sistemaAsociadoServiceProvider);
  return sistemaAsociadoService.getSistemasAsociadosPorAsociado(asociadoId);
});

/// Provider para obtener un sistema asociado específico por ID
final sistemaAsociadoByIdProvider = FutureProvider.family<SistemaAsociado?, String>((ref, id) async {
  final sistemaAsociadoService = ref.watch(sistemaAsociadoServiceProvider);
  return sistemaAsociadoService.getSistemaAsociadoById(id);
});

/// Provider para obtener sistemas asociados por comportamiento
final sistemasAsociadosPorComportamientoProvider = FutureProvider.family<List<SistemaAsociado>, ({String empresaId, String comportamiento})>((ref, params) async {
  final sistemaAsociadoService = ref.watch(sistemaAsociadoServiceProvider);
  return sistemaAsociadoService.getSistemasAsociadosPorComportamiento(params.empresaId, params.comportamiento);
});

/// Provider para gestionar el estado del sistema asociado seleccionado
final selectedSistemaAsociadoProvider = StateProvider<SistemaAsociado?>((ref) => null);