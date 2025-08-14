import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/empresa_service.dart';
import '../models/empresa.dart';

final empresaProvider = FutureProvider<Empresa>((ref) async {
  final service = EmpresaService();
  return await service.getEmpresaActual();
});
