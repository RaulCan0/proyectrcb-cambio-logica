import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/evaluacion/models/empresa.dart';

/// Servicio para gestión de empresas
class EmpresaService {
  /// Devuelve la empresa actual (ejemplo: la última creada por el usuario actual)
  Future<Empresa> getEmpresaActual() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final res = await Supabase.instance.client
        .from('empresas')
        .select()
        .eq('usuario_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (res == null) throw Exception('No hay empresa actual');
    return Empresa.fromMap(res);
  }

  /// Devuelve los asociados de la empresa actual
  Future<List<String>> getAsociadosEmpresaActual() async {
    final empresa = await getEmpresaActual();
    return empresa.empleadosAsociados;
  }
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Empresa>> getEmpresas() async {
    final res = await _client.from('empresas').select();
    return (res as List).map((e) => Empresa.fromMap(e)).toList();
  }

  Future<void> addEmpresa(Empresa empresa) async {
    await _client.from('empresas').insert(empresa.toMap());
  }

  Future<void> updateEmpresa(String id, Empresa empresa) async {
    await _client.from('empresas').update(empresa.toMap()).eq('id', id);
  }

  Future<void> deleteEmpresa(String id) async {
    await _client.from('empresas').delete().eq('id', id);
  }
}
