import 'package:applensys/evaluacion/models/empresa.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Microservicio para gestión de empresas
/// Maneja todas las operaciones CRUD y lógica de negocio relacionada con empresas
class EmpresaService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todas las empresas
  Future<List<Empresa>> getEmpresas() async {
    try {
      final response = await _client.from('empresas').select();
      return response.map((e) => Empresa.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Agrega una nueva empresa
  Future<void> addEmpresa(Empresa empresa) async {
    await _client.from('empresas').insert(empresa.toMap());
  }

  /// Actualiza una empresa existente
  Future<void> updateEmpresa(String id, Empresa empresa) async {
    await _client.from('empresas').update(empresa.toMap()).eq('id', id);
  }

  /// Elimina una empresa
  Future<void> deleteEmpresa(String id) async {
    await _client.from('empresas').delete().eq('id', id);
  }

  /// Obtiene una empresa por ID
  Future<Empresa?> getEmpresaById(String id) async {
    try {
      final response = await _client
          .from('empresas')
          .select()
          .eq('id', id)
          .single();
      return Empresa.fromMap(response);
    } catch (e) {
      return null;
    }
  }
}