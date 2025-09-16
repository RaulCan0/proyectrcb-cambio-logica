
import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/models/emplado_evaluacion.dart';
import 'package:applensys/evaluacion/services/evaluacion_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/empresa.dart';
import '../models/evaluacion_empresa.dart';

import '../models/sistema_asociado.dart';

class EvaluacionState {
  final List<Empresa> empresas;
  final List<EvaluacionEmpresa> evaluaciones;
  final List<EmpleadoEvaluacion> empleados;
  final List<CalificacionComportamiento> comportamientos;
  final List<SistemaAsociado> sistemas;

  const EvaluacionState({
    this.empresas = const [],
    this.evaluaciones = const [],
    this.empleados = const [],
    this.comportamientos = const [],
    this.sistemas = const [],
  });

  EvaluacionState copyWith({
    List<Empresa>? empresas,
    List<EvaluacionEmpresa>? evaluaciones,
    List<EmpleadoEvaluacion>? empleados,
    List<CalificacionComportamiento>? comportamientos,
    List<SistemaAsociado>? sistemas,
  }) {
    return EvaluacionState(
      empresas: empresas ?? this.empresas,
      evaluaciones: evaluaciones ?? this.evaluaciones,
      empleados: empleados ?? this.empleados,
      comportamientos: comportamientos ?? this.comportamientos,
      sistemas: sistemas ?? this.sistemas,
    );
  }
}

class EvaluacionController extends StateNotifier<EvaluacionState> {
  EvaluacionController(this._service) : super(const EvaluacionState());
  final EvaluacionService _service;

  // ===== EMPRESAS =====

  Future<void> cargarEmpresas() async {
    final list = await _service.cargarEmpresas();
    state = state.copyWith(empresas: list);
  }

  Future<void> agregarEmpresa(Empresa empresa) async {
    final nueva = await _service.agregarEmpresa(empresa);
    state = state.copyWith(empresas: [...state.empresas, nueva]);
  }

  Future<void> actualizarEmpresa(Empresa empresa) async {
    await _service.actualizarEmpresa(empresa);
    final next = state.empresas.map((e) => e.id == empresa.id ? empresa : e).toList();
    state = state.copyWith(empresas: next);
  }

  Future<void> eliminarEmpresa(String id) async {
    await _service.eliminarEmpresa(id);
    state = state.copyWith(empresas: state.empresas.where((e) => e.id != id).toList());
  }

  // ===== EVALUACIONES =====

  Future<void> cargarEvaluaciones(String empresaId) async {
    final list = await _service.cargarEvaluaciones(empresaId);
    state = state.copyWith(evaluaciones: list);
  }

  Future<void> agregarEvaluacion(EvaluacionEmpresa evaluacion) async {
    final nueva = await _service.agregarEvaluacion(evaluacion);
    state = state.copyWith(evaluaciones: [...state.evaluaciones, nueva]);
  }

  Future<void> actualizarEvaluacion(EvaluacionEmpresa evaluacion) async {
    await _service.actualizarEvaluacion(evaluacion);
    final next = state.evaluaciones.map((e) => e.id == evaluacion.id ? evaluacion : e).toList();
    state = state.copyWith(evaluaciones: next);
  }

  Future<void> eliminarEvaluacion(String id) async {
    await _service.eliminarEvaluacion(id);
    state = state.copyWith(evaluaciones: state.evaluaciones.where((e) => e.id != id).toList());
  }

  // ===== EMPLEADOS =====

  Future<void> cargarEmpleados(String evaluacionId) async {
    final list = await _service.cargarEmpleados(evaluacionId);
    state = state.copyWith(empleados: list);
  }

  Future<void> agregarEmpleado(EmpleadoEvaluacion empleado) async {
    final nuevo = await _service.agregarEmpleado(empleado);
    state = state.copyWith(empleados: [...state.empleados, nuevo]);
  }

  Future<void> actualizarEmpleado(EmpleadoEvaluacion empleado) async {
    await _service.actualizarEmpleado(empleado);
    final next = state.empleados.map((e) => e.id == empleado.id ? empleado : e).toList();
    state = state.copyWith(empleados: next);
  }

  Future<void> eliminarEmpleado(String id) async {
    await _service.eliminarEmpleado(id);
    state = state.copyWith(empleados: state.empleados.where((e) => e.id != id).toList());
  }

  // ===== COMPORTAMIENTOS =====

  Future<void> cargarComportamientos(String evaluacionId, String empleadoId) async {
      final list = await _service.cargarComportamientos(evaluacionId, empleadoId);
      state = state.copyWith(comportamientos: list);
    }

  Future<void> registrarComportamiento(CalificacionComportamiento c) async {
    await _service.registrarComportamiento(c);
    final i = state.comportamientos.indexWhere((e) => e.id == c.id);
    if (i != -1) {
      final next = [...state.comportamientos]..[i] = c;
      state = state.copyWith(comportamientos: next);
    } else {
      state = state.copyWith(comportamientos: [...state.comportamientos, c]);
    }
  }

  Future<void> eliminarComportamiento(String id) async {
    await _service.eliminarComportamiento(id);
    state = state.copyWith(comportamientos: state.comportamientos.where((c) => c.id != id).toList());
  }

  // ===== SISTEMAS =====

  Future<void> cargarSistemas() async {
    final list = await _service.cargarSistemas();
    state = state.copyWith(sistemas: list);
  }

  Future<void> agregarSistema(SistemaAsociado sistema) async {
    await _service.agregarSistema(sistema);
    state = state.copyWith(sistemas: [...state.sistemas, sistema]);
  }

  Future<void> eliminarSistema(String id) async {
    await _service.eliminarSistema(id);
    state = state.copyWith(sistemas: state.sistemas.where((s) => s.id != id).toList());
  }

  // ===== LIMPIEZA UI =====
  void limpiar() => state = const EvaluacionState();
}

final evaluacionProvider = StateNotifierProvider<EvaluacionController, EvaluacionState>(
  (ref) => EvaluacionController(EvaluacionService()),
);
