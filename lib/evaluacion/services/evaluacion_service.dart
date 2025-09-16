import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/models/emplado_evaluacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/empresa.dart';
import '../models/evaluacion_empresa.dart';

import '../models/sistema_asociado.dart';

class EvaluacionService {
  final _sb = Supabase.instance.client;

  // === EMPRESAS ===

  Future<List<Empresa>> cargarEmpresas() async {
    final resp = await _sb.from('empresas').select();
    return (resp as List).map((e) => Empresa.fromMap(e)).toList();
  }

  Future<Empresa> agregarEmpresa(Empresa empresa) async {
    final resp = await _sb.from('empresas').insert(empresa.toMap()).select().single();
    return Empresa.fromMap(resp);
  }

  Future<void> actualizarEmpresa(Empresa empresa) async {
    await _sb.from('empresas').update(empresa.toMap()).eq('id', empresa.id);
  }

  Future<void> eliminarEmpresa(String id) async {
    await _sb.from('empresas').delete().eq('id', id);
  }

  // === EVALUACIONES ===

  Future<List<EvaluacionEmpresa>> cargarEvaluaciones(String empresaId) async {
    final resp = await _sb.from('evaluaciones').select().eq('empresa_id', empresaId);
    return (resp as List).map((e) => EvaluacionEmpresa.fromJson(e)).toList();
  }

  Future<EvaluacionEmpresa> agregarEvaluacion(EvaluacionEmpresa evaluacion) async {
    final resp = await _sb.from('evaluaciones').insert(evaluacion.toJson()).select().single();
    return EvaluacionEmpresa.fromJson(resp);
  }

  Future<void> actualizarEvaluacion(EvaluacionEmpresa evaluacion) async {
    await _sb.from('evaluaciones').update(evaluacion.toJson()).eq('id', evaluacion.id);
  }

  Future<void> eliminarEvaluacion(String id) async {
    await _sb.from('evaluaciones').delete().eq('id', id);
  }

  // === EMPLEADOS EVALUADOS ===

  Future<List<EmpleadoEvaluacion>> cargarEmpleados(String evaluacionId) async {
    final resp = await _sb.from('empleados_evaluacion').select().eq('evaluacion_id', evaluacionId);
    return (resp as List).map((e) => EmpleadoEvaluacion.fromJson(e)).toList();
  }

  Future<EmpleadoEvaluacion> agregarEmpleado(EmpleadoEvaluacion empleado) async {
    final resp = await _sb.from('empleados_evaluacion').insert(empleado.toJson()).select().single();
    return EmpleadoEvaluacion.fromJson(resp);
  }

  Future<void> actualizarEmpleado(EmpleadoEvaluacion empleado) async {
    await _sb.from('empleados_evaluacion').update(empleado.toJson()).eq('id', empleado.id);
  }

  Future<void> eliminarEmpleado(String id) async {
    await _sb.from('empleados_evaluacion').delete().eq('id', id);
  }

  // === COMPORTAMIENTOS ===

  Future<List<CalificacionComportamiento>> cargarComportamientos(String evaluacionId, String empleadoId) async {
    final resp = await _sb.from('datos_evaluacion')
      .select()
      .eq('evaluacion_id', evaluacionId)
      .eq('empleado_id', empleadoId);
    return (resp as List).map((e) => CalificacionComportamiento.fromJson(e)).toList();
  }

  Future<void> registrarComportamiento(CalificacionComportamiento c) async {
    await _sb.from('datos_evaluacion').upsert(c.toJson());
  }

  Future<void> eliminarComportamiento(String id) async {
    await _sb.from('datos_evaluacion').delete().eq('id', id);
  }

  // === SISTEMAS ASOCIADOS ===

  Future<List<SistemaAsociado>> cargarSistemas() async {
    final resp = await _sb.from('sistemas').select();
    return (resp as List).map((e) => SistemaAsociado.fromJson(e)).toList();
  }

  Future<void> agregarSistema(SistemaAsociado sistema) async {
    await _sb.from('sistemas').upsert(sistema.toJson());
  }

  Future<void> eliminarSistema(String id) async {
    await _sb.from('sistemas').delete().eq('id', id);
  }

  // Crear empresa + evaluación activa + empleados + calificaciones vacías
  Future<void> registrarEmpresaConEvaluacion({
    required Empresa empresa,
    required List<EmpleadoEvaluacion> empleados,
  }) async {
    final empresaId = empresa.id;
    final evaluacionId = const Uuid().v4();
    final now = DateTime.now();

    // Insertar empresa
    await _sb.from('empresas').insert(empresa.toMap());

    // Crear evaluación activa
    final evaluacion = EvaluacionEmpresa(
      id: evaluacionId,
      idEmpresa: empresaId,
      empresaNombre: empresa.nombre,
      fecha: now,
    );
    await _sb.from('evaluaciones_empresa').insert(evaluacion.toJson());

    // Insertar empleados evaluados y calificaciones vacías
    for (final empleado in empleados) {
      final empleadoFinal = EmpleadoEvaluacion(
        evaluacionId: evaluacionId,
        nombreCompleto: empleado.nombreCompleto,
        antiguedad: empleado.antiguedad,
        puesto: empleado.puesto,
        cargo: empleado.cargo,
      );

      await _sb.from('empleados_evaluacion').insert(empleadoFinal.toJson());

      final comportamientos = [
        'Liderazgo', 'Colaboración', 'Comunicación', 'Innovación'
      ];

      for (final comportamiento in comportamientos) {
        final calificacion = CalificacionComportamiento(
          evaluacionId: evaluacionId,
          idEmpleado: empleadoFinal.id,
          comportamiento: comportamiento,
          cargo: empleadoFinal.cargo,
          puntaje: 0,
          observacion: '',
          fechaEvaluacion: now, idDimension: '', principio: '',
        );

        await _sb.from('calificaciones').insert(calificacion.toJson());
      }
    }
  }

  // Obtener empresas
  Future<List<Empresa>> cargarEmpresasDesdeMap() async {
    final res = await _sb.from('empresas').select();
    return (res as List).map((e) => Empresa.fromMap(e)).toList();
  }

  // Editar empresa
  Future<void> editarEmpresa(Empresa empresa) async {
    await _sb.from('empresas').update(empresa.toMap()).eq('id', empresa.id);
  }

  // Eliminar empresa (y cascada si aplica)
  Future<void> eliminarEmpresaPorId(String empresaId) async {
    await _sb.from('empresas').delete().eq('id', empresaId);
  }

  // Obtener evaluación activa
  Future<EvaluacionEmpresa?> obtenerEvaluacionActiva(String empresaId) async {
    final res = await _sb
        .from('evaluaciones_empresa')
        .select()
        .eq('empresa_id', empresaId)
        .eq('finalizada', false)
        .order('fecha', ascending: false)
        .limit(1);

    if (res.isEmpty) return null;
    return EvaluacionEmpresa.fromJson(res.first);
  }

  // Finalizar evaluación
  Future<void> finalizarEvaluacion(String evaluacionId) async {
    await _sb
        .from('evaluaciones_empresa')
        .update({'finalizada': true})
        .eq('id', evaluacionId);
  }

  // Calificaciones por evaluación
  Future<List<CalificacionComportamiento>> getCalificacionesPorEvaluacion(String evaluacionId) async {
    final res = await _sb
        .from('calificaciones')
        .select()
        .eq('evaluacion_id', evaluacionId);
    return (res as List).map((e) => CalificacionComportamiento.fromJson(e)).toList();
  }

  // Editar solo campos válidos de calificación
  Future<void> updateCalificacionEditable(CalificacionComportamiento c) async {
    await _sb.from('calificaciones').update({
      'puntaje': c.puntaje,
      'observacion': c.observacion,
      'sistemas_asociados': c.sistemasAsociados,
      'evidencia_url': c.evidenciaUrl,
    }).eq('id', c.id);
  }

  // Obtener empleados de una evaluación
  Future<List<EmpleadoEvaluacion>> getEmpleadosDeEvaluacion(String evaluacionId) async {
    final res = await _sb
        .from('empleados_evaluacion')
        .select()
        .eq('evaluacion_id', evaluacionId);
    return (res as List).map((e) => EmpleadoEvaluacion.fromJson(e)).toList();
  }
}
