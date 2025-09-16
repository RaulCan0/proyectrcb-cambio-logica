import 'package:uuid/uuid.dart';

class CalificacionComportamiento {
  final String id;
  final String evaluacionId;
  final String idEmpleado;
  final String idDimension;     // requerido por SQL
  final String principio;       // agregado
  final String comportamiento;  // requerido
  final String cargo;           // requerido por SQL
  final int puntaje;            // 0–5
  final String? observacion;
  final List<String> sistemasAsociados;
  final String? evidenciaUrl;
  final DateTime fechaEvaluacion;

  CalificacionComportamiento({
    String? id,
    required this.evaluacionId,
    required this.idEmpleado,
    required this.idDimension,
    required this.principio,
    required this.comportamiento,
    required this.cargo,
    required this.puntaje,
    this.observacion,
    List<String>? sistemasAsociados,
    this.evidenciaUrl,
    required this.fechaEvaluacion,
  })  : id = id ?? const Uuid().v4(),
        sistemasAsociados = sistemasAsociados ?? <String>[];

  factory CalificacionComportamiento.fromJson(Map<String, dynamic> json) {
    return CalificacionComportamiento(
      id: json['id'],
      evaluacionId: json['evaluacion_id'],
      idEmpleado: json['empleado_id'],
      idDimension: json['id_dimension']?.toString() ?? '',
      principio: json['principio'] ?? '',
      comportamiento: json['comportamiento'] ?? '',
      cargo: json['cargo'] ?? '',
      puntaje: (json['puntaje'] ?? 0) as int,
      observacion: json['observacion'],
      sistemasAsociados: List<String>.from(json['sistemas_asociados'] ?? const []),
      evidenciaUrl: json['evidencia_url'],
      fechaEvaluacion: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'evaluacion_id': evaluacionId,
        'empleado_id': idEmpleado,
        'id_dimension': idDimension,
        'principio': principio,
        'comportamiento': comportamiento,
        'cargo': cargo,
        'puntaje': puntaje,
        'observacion': observacion,
        'sistemas_asociados': sistemasAsociados,
        'evidencia_url': evidenciaUrl,
        'fecha': fechaEvaluacion.toIso8601String(),
      };
}
