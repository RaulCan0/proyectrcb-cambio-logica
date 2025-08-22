import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applensys/evaluacion/models/empresa.dart';
import 'package:applensys/evaluacion/services/domain/empresa_service.dart';

/// Provider para el servicio de empresas
final empresaServiceProvider = Provider<EmpresaService>((ref) {
  return EmpresaService();
});

/// Provider para obtener todas las empresas
final empresasProvider = FutureProvider<List<Empresa>>((ref) async {
  final empresaService = ref.watch(empresaServiceProvider);
  return empresaService.getEmpresas();
});

/// Provider para obtener una empresa específica por ID
final empresaByIdProvider = FutureProvider.family<Empresa?, String>((ref, id) async {
  final empresaService = ref.watch(empresaServiceProvider);
  return empresaService.getEmpresaById(id);
});

/// Provider para gestionar el estado de la empresa seleccionada
final selectedEmpresaProvider = StateProvider<Empresa?>((ref) => null);