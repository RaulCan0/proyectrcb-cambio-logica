import 'package:uuid/uuid.dart';

class EvaluacionEmpresa {
  final String id;
  final String idEmpresa;
  final String empresaNombre;
  int puntosDimensiones;
  int puntosResultados;
  DateTime fecha;
  bool finalizada;

  EvaluacionEmpresa({
    String? id,
    required this.idEmpresa,
    required this.empresaNombre,
    this.puntosDimensiones = 0,
    this.puntosResultados = 0,
    DateTime? fecha,
    this.finalizada = false,
  }) : id = id ?? const Uuid().v4(),
       fecha = fecha ?? DateTime.now();

  factory EvaluacionEmpresa.fromJson(Map<String, dynamic> j) => EvaluacionEmpresa(
    id: j['id'],
    idEmpresa: j['empresa_id'],
    empresaNombre: j['empresa_nombre'],
    puntosDimensiones: (j['puntos_dimensiones'] ?? 0) as int,
    puntosResultados: (j['puntos_resultados'] ?? 0) as int,
    fecha: DateTime.tryParse(j['fecha'] ?? '') ?? DateTime.now(),
    finalizada: (j['finalizada'] ?? false) as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'empresa_id': idEmpresa,
    'empresa_nombre': empresaNombre,
    'puntos_dimensiones': puntosDimensiones,
    'puntos_resultados': puntosResultados,
    'fecha': fecha.toIso8601String(),
    'finalizada': finalizada,
  };
}
