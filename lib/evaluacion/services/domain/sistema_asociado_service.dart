import 'package:applensys/evaluacion/models/sistema_asociado.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Microservicio para gestión de sistemas asociados
/// Maneja todas las operaciones CRUD relacionadas con sistemas asociados
class SistemaAsociadoService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todos los sistemas asociados
  Future<List<SistemaAsociado>> getAllSistemasAsociados() async {
    final response = await _client.from('sistemas_asociados').select();
    return (response as List).map((e) => SistemaAsociado.fromMap(e)).toList();
  }

  /// Obtiene sistemas asociados por empresa
  Future<List<SistemaAsociado>> getSistemasAsociadosPorEmpresa(String empresaId) async {
    final response = await _client
        .from('sistemas_asociados')
        .select()
        .eq('empresa_id', empresaId);
    return (response as List).map((e) => SistemaAsociado.fromMap(e)).toList();
  }

  /// Obtiene sistemas asociados por asociado
  Future<List<SistemaAsociado>> getSistemasAsociadosPorAsociado(String asociadoId) async {
    final response = await _client
        .from('sistemas_asociados')
        .select()
        .eq('asociado_id', asociadoId);
    return (response as List).map((e) => SistemaAsociado.fromMap(e)).toList();
  }

  /// Agrega un nuevo sistema asociado
  Future<void> addSistemaAsociado(SistemaAsociado sistemaAsociado) async {
    await _client.from('sistemas_asociados').insert(sistemaAsociado.toMap());
  }

  /// Actualiza un sistema asociado
  Future<void> updateSistemaAsociado(String id, SistemaAsociado sistemaAsociado) async {
    await _client
        .from('sistemas_asociados')
        .update(sistemaAsociado.toMap())
        .eq('id', id);
  }

  /// Elimina un sistema asociado
  Future<void> deleteSistemaAsociado(String id) async {
    await _client.from('sistemas_asociados').delete().eq('id', id);
  }

  /// Obtiene un sistema asociado por ID
  Future<SistemaAsociado?> getSistemaAsociadoById(String id) async {
    try {
      final response = await _client
          .from('sistemas_asociados')
          .select()
          .eq('id', id)
          .single();
      return SistemaAsociado.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene sistemas asociados por comportamiento
  Future<List<SistemaAsociado>> getSistemasAsociadosPorComportamiento(
      String empresaId, String comportamiento) async {
    final response = await _client
        .from('sistemas_asociados')
        .select()
        .eq('empresa_id', empresaId)
        .eq('comportamiento', comportamiento);
    return (response as List).map((e) => SistemaAsociado.fromMap(e)).toList();
  }
}