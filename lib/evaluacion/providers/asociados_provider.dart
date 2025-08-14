import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/empresa_service.dart';
import '../models/asociado.dart';

final asociadosProvider = FutureProvider<List<Asociado>>((ref) async {
  final service = EmpresaService();
  final empresa = await service.getEmpresaActual();
  final supabase = Supabase.instance.client;
  final res = await supabase
      .from('asociados')
      .select()
      .eq('empresa_id', empresa.id);
  return (res as List).map((e) => Asociado.fromMap(e)).toList();
});
