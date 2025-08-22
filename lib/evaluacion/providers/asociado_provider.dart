import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applensys/evaluacion/models/asociado.dart';
import 'package:applensys/evaluacion/services/domain/asociado_service.dart';

/// Provider para el servicio de asociados
final asociadoServiceProvider = Provider<AsociadoService>((ref) {
  return AsociadoService();
});

/// Provider para obtener asociados por empresa
final asociadosPorEmpresaProvider = FutureProvider.family<List<Asociado>, String>((ref, empresaId) async {
  final asociadoService = ref.watch(asociadoServiceProvider);
  return asociadoService.getAsociadosPorEmpresa(empresaId);
});

/// Provider para obtener todos los asociados
final allAsociadosProvider = FutureProvider<List<Asociado>>((ref) async {
  final asociadoService = ref.watch(asociadoServiceProvider);
  return asociadoService.getAllAsociados();
});

/// Provider para obtener un asociado específico por ID
final asociadoByIdProvider = FutureProvider.family<Asociado?, String>((ref, id) async {
  final asociadoService = ref.watch(asociadoServiceProvider);
  return asociadoService.getAsociadoById(id);
});

/// Provider para obtener asociados por nivel
final asociadosPorNivelProvider = FutureProvider.family<List<Asociado>, ({String empresaId, String nivel})>((ref, params) async {
  final asociadoService = ref.watch(asociadoServiceProvider);
  return asociadoService.getAsociadosPorNivel(params.empresaId, params.nivel);
});

/// Provider para gestionar el estado del asociado seleccionado
final selectedAsociadoProvider = StateProvider<Asociado?>((ref) => null);