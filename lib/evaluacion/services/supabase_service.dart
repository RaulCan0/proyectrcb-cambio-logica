import 'dart:typed_data';

import 'package:applensys/evaluacion/models/asociado.dart';
import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/models/empresa.dart';
import 'package:applensys/evaluacion/models/evaluacion.dart';
import 'package:applensys/evaluacion/models/level_averages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // AUTH
  Future<Map<String, dynamic>> register(String email, String password, String telefono) async {
    try {
      await _client.auth.signUp(email: email, password: password, data: {'telefono': telefono});
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Error desconocido: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Error desconocido: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Error desconocido: $e'};
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String? get userId => _client.auth.currentUser?.id;

  // EMPRESAS
  Future<List<Empresa>> getEmpresas() async {
    try {
      final response = await _client.from('empresas').select();
      return response.map((e) => Empresa.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
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

  // ASOCIADOS
  Future<List<Asociado>> getAsociadosPorEmpresa(String empresaId) async {
    if (empresaId.isEmpty) return [];
    final response = await _client
        .from('asociados')
        .select()
        .eq('empresa_id', empresaId);
    return (response as List).map((e) => Asociado.fromMap(e)).toList();
  }

  Future<void> addAsociado(Asociado asociado) async {
    await _client.from('asociados').insert(asociado.toMap());
  }

  Future<void> updateAsociado(String id, Asociado asociado) async {
    await _client.from('asociados').update(asociado.toMap()).eq('id', id);
  }

  Future<void> deleteAsociado(String id) async {
    await _client.from('asociados').delete().eq('id', id);
  }

  // EVALUACIONES
  Future<List<Evaluacion>> getEvaluaciones() async {
    final response = await _client.from('detalles_evaluacion').select();
    return (response as List).map((e) => Evaluacion.fromMap(e)).toList();
  }

  Future<Evaluacion> addEvaluacion(Evaluacion evaluacion) async {
    if (evaluacion.id.isEmpty ||
        evaluacion.empresaId.isEmpty ||
        evaluacion.asociadoId.isEmpty) {
      throw Exception('Todos los IDs son obligatorios');
    }

    final data =
        await _client
            .from('detalles_evaluacion')
            .insert(evaluacion.toMap())
            .select()
            .single();

    return Evaluacion.fromMap(data);
  }

  Future<void> updateEvaluacion(String id, Evaluacion evaluacion) async {
    await _client
        .from('detalles_evaluacion')
        .update(evaluacion.toMap())
        .eq('id', id);
  }

  Future<void> deleteEvaluacion(String id) async {
    await _client.from('detalles_evaluacion').delete().eq('id', id);
  }

  // CALIFICACIONES
  Future<List<Calificacion>> getCalificacionesPorAsociado(
    String idAsociado,
  ) async {
    if (idAsociado.isEmpty) return [];
    // Define las columnas que existen in tu tabla 'calificaciones'
    // Asegúrate de que coincidan con las columnas reales de tu base de datos y el modelo Calificacion.
    const String selectColumns =
        'id, id_asociado, id_empresa, id_dimension, comportamiento, puntaje, fecha_evaluacion, observaciones, sistemas, evidencia_url';

    final response = await _client
        .from('calificaciones')
        .select(selectColumns) // Especificar columnas explícitamente
        .eq('id_asociado', idAsociado);

    // Procesar la respuesta para convertirla en List<Calificacion>
    // La respuesta 'response' ya es una List<Map<String, dynamic>> si la consulta tiene éxito.
    // Si hay un error en la consulta, Postgrest puede lanzar una excepción antes de este punto.
    return response
        .map((item) => Calificacion.fromMap(item))
        .toList();
  }

  Future<void> addCalificacion(Calificacion calificacion, {required String id, required String idAsociado}) async {
    try {
      // Verificación más detallada
      if (calificacion.id.isEmpty) {
        throw Exception("ID de calificación vacío");
      }
      if (calificacion.idAsociado.isEmpty) {
        throw Exception("ID de asociado vacío");
      }
      if (calificacion.idEmpresa.isEmpty) {
        throw Exception("ID de empresa vacío");
      }
      if (calificacion.idDimension == 0) {
        throw Exception("ID de dimensión vacío");
      }

      ("Intentando guardar calificación:");
      ("ID: ${calificacion.id}");
      ("ID Asociado: ${calificacion.idAsociado}");
      ("ID Empresa: ${calificacion.idEmpresa}");
      ("ID Dimensión: ${calificacion.idDimension}");

      // Si todo está correcto, intentar guardar
      await _client.from('calificaciones').insert(calificacion.toMap());
      ("✅ Calificación guardada con éxito");
    } catch (e) {
      ("❌ Error al guardar calificación: $e");
      rethrow; // Re-lanzar para manejar arriba
    }
  }

  Future<void> updateCalificacion(String id, int nuevoPuntaje) async {
    await _client
        .from('calificaciones')
        .update({'puntaje': nuevoPuntaje})
        .eq('id', id);
  }

  Future<void> deleteCalificacion(String id) async {
    await _client.from('calificaciones').delete().eq('id', id);
  }

  Future<List<Calificacion>> getAllCalificaciones() async {
    final response = await _client.from('calificaciones').select();
    return (response as List).map((e) => Calificacion.fromMap(e)).toList();
  }

  Future<void> updateCalificacionFull(Calificacion calificacion) async {
    try {
      await _client
          .from('calificaciones')
          .update(calificacion.toMap()) // Asume que Calificacion.toMap() incluye todos los campos necesarios (puntaje, observaciones, sistemas, evidenciaUrl, etc.)
          .eq('id', calificacion.id);
      // print("✅ Calificación actualizada completamente con éxito: ${calificacion.id}");
    } catch (e) {
      // print("❌ Error al actualizar calificación completa: $e");
      rethrow;
    }
  }

  /// Obtiene todas las calificaciones de una empresa
  Future<List<Map<String, dynamic>>> getCalificacionesPorEmpresa(String empresaId) async {
    if (empresaId.isEmpty) return [];
    const String selectColumns = 'id, id_asociado, id_empresa, id_dimension, comportamiento, puntaje, fecha_evaluacion, observaciones, sistemas, evidencia_url';
    final res = await Supabase.instance.client
      .from('calificaciones')
      .select(selectColumns)
      .eq('id_empresa', empresaId)
      .order('fecha_evaluacion', ascending: true);
    return List<Map<String, dynamic>>.from(res as List);
  }

  // DASHBOARD
  Future<List<Map<String, dynamic>>> getResultadosDashboard({
    String? empresaId,
    int? dimensionId,
  }) async {
    final query = _client.from('resultados_dashboard').select();
    if (empresaId != null) query.eq('empresa_id', empresaId);
    if (dimensionId != null) query.eq('dimension', dimensionId);

    final response = await query;
    return (response as List).map((e) {
      return {
        'titulo': e['dimension'] ?? 'Sin título',
        'promedio': e['promedio_general'] ?? 0.0,
      };
    }).toList();
  }

  Future<void> subirResultadosDashboard(
    List<Map<String, dynamic>> resultados,
  ) async {
    if (resultados.isEmpty) return;

    final inserciones =
        resultados.map((resultado) {
          return {
            'id': const Uuid().v4(),
            'dimension': resultado['dimension'],
            'promedio_ejecutivo': resultado['promedio_ejecutivo'],
            'promedio_gerente': resultado['promedio_gerente'],
            'promedio_miembro': resultado['promedio_miembro'],
            'promedio_general': resultado['promedio_general'],
            'fecha': resultado['fecha'],
            'empresa_id': resultado['empresa_id'] ?? '',
          };
        }).toList();

    await _client.from('resultados_dashboard').insert(inserciones);
  }

  Future<void> subirDetallesComportamiento(
    List<Map<String, dynamic>> detalles,
  ) async {
    if (detalles.isEmpty) return;
    await _client.from('detalles_comportamiento').insert(detalles);
  }

  // PERFIL
  Future<Map<String, dynamic>?> getPerfil() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final response =
        await _client.from('usuarios').select().eq('id', user.id).single();
    return response;
  }

  Future<void> actualizarPerfil(Map<String, dynamic> valores) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("Usuario no autenticado");

    await _client.from('usuarios').update(valores).eq('id', userId);
  }

  Future<void> actualizarContrasena({required String newPassword}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }


  // NUEVO: Buscar evaluacion existente
  Future<Evaluacion?> buscarEvaluacionExistente(String empresaId, String asociadoId) async {
    final response = await _client
        .from('evaluaciones') // Nombre correcto de la tabla
        .select()
        .eq('empresa_id', empresaId)
        .eq('asociado_id', asociadoId)
        .maybeSingle();

    if (response == null) return null;
    return Evaluacion.fromMap(response);
  }

  // NUEVO: Crear evaluacion si no existe
  Future<Evaluacion> crearEvaluacionSiNoExiste(String empresaId, String asociadoId) async {
    final existente = await buscarEvaluacionExistente(empresaId, asociadoId);
    if (existente != null) return existente;

    final nuevaEvaluacion = Evaluacion(
      id: const Uuid().v4(),
      empresaId: empresaId,
      asociadoId: asociadoId,
      fecha: DateTime.now(),
    );
    await _client.from('evaluaciones').insert(nuevaEvaluacion.toMap()); // Nombre correcto de la tabla
    return nuevaEvaluacion;
  }

  Future<void> insertar(String tabla, Map<String, dynamic> valores) async {
    await _client.from(tabla).insert(valores);
  }

  Future<void> subirPromediosCompletos({
    required String evaluacionId,
    required String dimension,
    required List<Map<String, dynamic>> filas,
  }) async {
    final sumas = <String, Map<String, Map<String, int>>>{};
    final conteos = <String, Map<String, Map<String, int>>>{};
    // Corregir la estructura de sistemasPorNivel para que el valor final sea int
    final sistemasPorNivel = <String, Map<String, Map<String, int>>>{};

    for (var f in filas) {
      final principio = f['principio'] as String;
      final comportamiento = f['comportamiento'] as String;
      final nivel = (f['cargo'] as String).trim();
      final valor = f['valor'] as int;
      final sistemas = (f['sistemas'] as List<dynamic>?)?.cast<String>() ?? [];

      sumas.putIfAbsent(principio, () => {});
      sumas[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      conteos.putIfAbsent(principio, () => {});
      conteos[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});

      sumas[principio]![comportamiento]![nivel] =
        (sumas[principio]![comportamiento]![nivel] ?? 0) + valor;
      conteos[principio]![comportamiento]![nivel] =
        (conteos[principio]![comportamiento]![nivel] ?? 0) + 1;

      for (final sistema in sistemas) {
        sistemasPorNivel.putIfAbsent(sistema, () => {});
        sistemasPorNivel[sistema]!.putIfAbsent(nivel, () => {});
        // Asegurarse de que el valor sea un entero antes de sumar
        final currentValue = (sistemasPorNivel[sistema]![nivel]![dimension] ?? 0);
        sistemasPorNivel[sistema]![nivel]![dimension] = currentValue + 1;
      }
    }

    for (final p in sumas.keys) {
      for (final c in sumas[p]!.keys) {
        for (final nivel in ['Ejecutivo', 'Gerente', 'Miembro']) {
          final suma = sumas[p]![c]![nivel]!;
          final count = conteos[p]![c]![nivel]!;
          final promedio = count == 0 ? 0.0 : suma / count;
          await insertar('promedios_comportamientos', {
            'evaluacion_id': evaluacionId,
            'dimension': dimension,
            'principio': p,
            'comportamiento': c,
            'nivel': nivel,
            'valor': double.parse(promedio.toStringAsFixed(2)),
          });
        }
      }
    }

    for (final sistema in sistemasPorNivel.keys) {
      for (final nivel in ['Ejecutivo', 'Gerente', 'Miembro']) {
        // Acceder directamente al conteo, que ahora es un int
        final conteo = (sistemasPorNivel[sistema]?[nivel]?[dimension] ?? 0);
        // Asegurarse de que conteo sea un entero antes de comparar
        if (conteo > 0) { 
          await insertar('promedios_sistemas', {
            'evaluacion_id': evaluacionId,
            'dimension': dimension,
            'sistema': sistema,
            'nivel': nivel,
            'conteo': conteo,
          });
        }
      }
    }
  }

  Future<List<LevelAverages>> getDimensionAverages(String empresaId) async { // Especificar tipo de empresaId
    final res = await _client
        .from('detalle_evaluacion') // Nombre correcto de la tabla
        .select('dimension_id, avg(ejecutivo) as ejecutivo, avg(gerente) as gerente, avg(miembro) as miembro')
        .eq('empresa_id', empresaId);

    return (res as List).map((m) => LevelAverages(
      id: m['dimension_id'] as int,
      nombre: 'Dimensión ${m['dimension_id']}',
      ejecutivo: (m['ejecutivo'] as num?)?.toDouble() ?? 0.0,
      gerente: (m['gerente'] as num?)?.toDouble() ?? 0.0,
      miembro: (m['miembro'] as num?)?.toDouble() ?? 0.0,
      dimensionId: m['dimension_id'] as int,
      general: (((m['ejecutivo'] as num?)?.toDouble() ?? 0.0) +
                ((m['gerente'] as num?)?.toDouble() ?? 0.0) +
                ((m['miembro'] as num?)?.toDouble() ?? 0.0)) / 3,
      nivel: '',
    )).toList();
  }

  Future<List<LevelAverages>> getLevelLineData(String empresaId) async { // Especificar tipo de empresaId
    final res = await _client
        .from('detalle_evaluacion') // Nombre correcto de la tabla
        .select('nivel, avg(calificacion) as promedio') // Asumiendo que 'calificacion' es el campo correcto
        .eq('empresa_id', empresaId);

    return (res as List).map((m) {
      final nivel = (m['nivel'] as String? ?? '').trim(); // Manejar nulos
      final promedio = (m['promedio'] as num?)?.toDouble() ?? 0.0;

      double ejecutivo = 0.0;
      double gerente = 0.0;
      double miembro = 0.0;

      switch (nivel.toLowerCase()) {
        case 'ejecutivo':
          ejecutivo = promedio;
          break;
        case 'gerente':
          gerente = promedio;
          break;
        case 'miembro':
          miembro = promedio;
          break;
      }

      return LevelAverages(
        id: 0, // Considerar si se necesita un ID único aquí
        nombre: nivel,
        ejecutivo: ejecutivo,
        gerente: gerente,
        miembro: miembro,
        dimensionId: 0, // Considerar si se necesita un dimensionId aquí
        general: promedio,
        nivel: nivel,
      );
    }).toList();
  }

  Future<List<LevelAverages>> getPrinciplesAverages(String empresaId) async { // Especificar tipo de empresaId
    final res = await _client
        .from('detalle_evaluacion') // Nombre correcto de la tabla
        .select('principio_id, avg(ejecutivo) as ejecutivo, avg(gerente) as gerente, avg(miembro) as miembro')
        .eq('empresa_id', empresaId);

    return (res as List).map((m) => LevelAverages(
      id: m['principio_id'] as int,
      nombre: 'Principio ${m['principio_id']}',
      ejecutivo: (m['ejecutivo'] as num?)?.toDouble() ?? 0.0,
      gerente: (m['gerente'] as num?)?.toDouble() ?? 0.0,
      miembro: (m['miembro'] as num?)?.toDouble() ?? 0.0,
      dimensionId: 0, // Considerar si se necesita un dimensionId aquí
      general: (((m['ejecutivo'] as num?)?.toDouble() ?? 0.0) +
                ((m['gerente'] as num?)?.toDouble() ?? 0.0) +
                ((m['miembro'] as num?)?.toDouble() ?? 0.0)) / 3,
      nivel: '',
    )).toList();
  }

  Future<List<LevelAverages>> getBehaviorAverages(String empresaId) async { // Especificar tipo de empresaId
    final res = await _client
        .from('detalle_evaluacion') // Nombre correcto de la tabla
        .select('comportamiento_id, avg(ejecutivo) as ejecutivo, avg(gerente) as gerente, avg(miembro) as miembro')
        .eq('empresa_id', empresaId);

    return (res as List).map((m) => LevelAverages(
      id: m['comportamiento_id'] as int,
      nombre: 'Comportamiento ${m['comportamiento_id']}',
      ejecutivo: (m['ejecutivo'] as num?)?.toDouble() ?? 0.0,
      gerente: (m['gerente'] as num?)?.toDouble() ?? 0.0,
      miembro: (m['miembro'] as num?)?.toDouble() ?? 0.0,
      dimensionId: 0, // Considerar si se necesita un dimensionId aquí
      general: (((m['ejecutivo'] as num?)?.toDouble() ?? 0.0) +
                ((m['gerente'] as num?)?.toDouble() ?? 0.0) +
                ((m['miembro'] as num?)?.toDouble() ?? 0.0)) / 3,
      nivel: '',
    )).toList();
  }

  Future<List<LevelAverages>> getSystemAverages(String empresaId) async { // Especificar tipo de empresaId
    final res = await _client
        .from('detalle_sistema') // Nombre correcto de la tabla
        .select('sistema_id, avg(ejecutivo) as ejecutivo, avg(gerente) as gerente, avg(miembro) as miembro')
        .eq('empresa_id', empresaId);

    return (res as List).map((m) => LevelAverages(
      id: m['sistema_id'] as int,
      nombre: 'Sistema ${m['sistema_id']}',
      ejecutivo: (m['ejecutivo'] as num?)?.toDouble() ?? 0.0,
      gerente: (m['gerente'] as num?)?.toDouble() ?? 0.0,
      miembro: (m['miembro'] as num?)?.toDouble() ?? 0.0,
      dimensionId: 0, // Considerar si se necesita un dimensionId aquí
      general: (((m['ejecutivo'] as num?)?.toDouble() ?? 0.0) +
                ((m['gerente'] as num?)?.toDouble() ?? 0.0) +
                ((m['miembro'] as num?)?.toDouble() ?? 0.0)) / 3,
      nivel: '',
    )).toList();
  }

  Future<double> obtenerProgresoAsociado({
    required String evaluacionId,
    required String asociadoId,
    required String dimensionId,
  }) async {
    if (evaluacionId.isEmpty || asociadoId.isEmpty || dimensionId.isEmpty) return 0.0;
    final response = await _client
        .from('calificaciones')
        .select('comportamiento')
        .eq('id_asociado', asociadoId)
        .eq('id_empresa', evaluacionId)
        .eq('id_dimension', int.tryParse(dimensionId) ?? -1);

    final total = (response as List).length;
    final mapaTotales = {'1': 6, '2': 14, '3': 8};
    final totalDimension = mapaTotales[dimensionId] ?? 1;
    return total / totalDimension;
  }

  Future<double> obtenerProgresoDimension(String empresaId, String dimensionId) async {
    try {
      final response = await _client
          .from('calificaciones')
          .select('comportamiento')
          .eq('id_empresa', empresaId)
          .eq('id_dimension', int.tryParse(dimensionId) ?? -1);

      final total = (response as List).length;
      const mapaTotales = {'1': 6, '2': 14, '3': 8};
      final totalDimension = mapaTotales[dimensionId] ?? 1;

      return total / totalDimension;
    } catch (e) {
      return 0.0; // Return 0.0 in case of an error
    }
  }

  Future<void> guardarEvaluacionDraft(String evaluacionId) async {
    await _client
        .from('evaluaciones')
        .update({'finalizada': false})
        .eq('id', evaluacionId);
  }

  Future<void> finalizarEvaluacion(String evaluacionId) async {
  await _client
      .from('detalles_evaluacion')
      .update({'finalizada': true})
      .eq('id', evaluacionId);

}


  Future<double> calcularProgresoDimensionGlobal(String empresaId, String dimensionId) async {
    try {
      final response = await _client
          .from('calificaciones')
          .select('comportamiento')
          .eq('id_empresa', empresaId)
          .eq('id_dimension', int.tryParse(dimensionId) ?? -1);

      final evaluados = (response as List).map((e) => e['comportamiento'].toString()).toSet().length;

      const mapaTotales = {'1': 6, '2': 14, '3': 8};
      final totalDimension = mapaTotales[dimensionId] ?? 1;

      return evaluados / totalDimension;
    } catch (e) {
      return 0.0;
    }
  }
  

  /// Inserta promedios en la tabla resultados_dashboard
  Future<void> insertarPromediosDashboard({
    required String evaluacionId,
    required String dimension,
    required Map<String, double> promedios,
  }) async {
    final uuid = const Uuid();
    final now = DateTime.now().toIso8601String();

    final data = promedios.entries.map((entry) => {
      'id': uuid.v4(),
      'evaluacion_id': evaluacionId,
      'dimension': dimension,
      'nivel': entry.key,
      'promedio': entry.value,
      'created_at': now,
    }).toList();

    await _client.from('resultados_dashboard').insert(data);
  }

  /// Inserta conteo de sistemas por nivel en tabla promedios_sistemas
  Future<void> insertarPromediosSistemas({
    required String evaluacionId,
    required String dimension,
    required Map<String, int> conteos,
  }) async {
    final uuid = const Uuid();
    final now = DateTime.now().toIso8601String();

    final data = conteos.entries.map((entry) => {
      'id': uuid.v4(),
      'evaluacion_id': evaluacionId,
      'dimension': dimension,
      'nivel': entry.key,
      'conteo_sistemas': entry.value,
      'created_at': now,
    }).toList();

    await _client.from('promedios_sistemas').insert(data);
  }
  Future<void> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'application/octet-stream',
  }) async {
    final response = await _client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );
  }

  /// Devuelve la URL pública de un archivo subido en el bucket.
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    final res = _client.storage.from(bucket).getPublicUrl(path);
    if (res.isEmpty) {
      throw Exception('Failed to generate public URL for the file.');
    }
    return res;
  }

  Future<void> limpiarDatosEvaluacion() async {
    // Implementar lógica para limpiar datos de evaluaciones en Supabase
  }
}