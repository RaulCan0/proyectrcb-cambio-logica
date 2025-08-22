import 'package:applensys/evaluacion/models/asociado.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Microservicio para gestión de asociados
/// Maneja todas las operaciones CRUD y lógica de negocio relacionada con asociados
class AsociadoService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todos los asociados de una empresa
  Future<List<Asociado>> getAsociadosPorEmpresa(String empresaId) async {
    final response = await _client
        .from('asociados')
        .select()
        .eq('empresa_id', empresaId);
    return (response as List).map((e) => Asociado.fromMap(e)).toList();
  }

  /// Obtiene todos los asociados
  Future<List<Asociado>> getAllAsociados() async {
    final response = await _client.from('asociados').select();
    return (response as List).map((e) => Asociado.fromMap(e)).toList();
  }

  /// Agrega un nuevo asociado
  Future<void> addAsociado(Asociado asociado) async {
    await _client.from('asociados').insert(asociado.toMap());
  }

  /// Actualiza un asociado existente
  Future<void> updateAsociado(String id, Asociado asociado) async {
    await _client.from('asociados').update(asociado.toMap()).eq('id', id);
  }

  /// Elimina un asociado
  Future<void> deleteAsociado(String id) async {
    await _client.from('asociados').delete().eq('id', id);
  }

  /// Obtiene un asociado por ID
  Future<Asociado?> getAsociadoById(String id) async {
    try {
      final response = await _client
          .from('asociados')
          .select()
          .eq('id', id)
          .single();
      return Asociado.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene asociados por nivel jerárquico
  Future<List<Asociado>> getAsociadosPorNivel(String empresaId, String nivel) async {
    final response = await _client
        .from('asociados')
        .select()
        .eq('empresa_id', empresaId)
        .eq('nivel', nivel);
    return (response as List).map((e) => Asociado.fromMap(e)).toList();
  }
}