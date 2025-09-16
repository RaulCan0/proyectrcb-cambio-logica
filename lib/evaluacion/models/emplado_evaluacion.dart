import 'package:uuid/uuid.dart';

class EmpleadoEvaluacion {
  final String id;
  final String evaluacionId;
  String nombreCompleto;
  String antiguedad;
  String puesto;
  String cargo;

  EmpleadoEvaluacion({
    String? id,
    required this.evaluacionId,
    required this.nombreCompleto,
    required this.antiguedad,
    required this.puesto,
    required this.cargo,
  }) : id = id ?? const Uuid().v4();

  factory EmpleadoEvaluacion.fromJson(Map<String, dynamic> j) => EmpleadoEvaluacion(
    id: j['id'],
    evaluacionId: j['evaluacion_id'],
    nombreCompleto: j['nombre_completo'],
    antiguedad: j['antiguedad'] ?? '',
    puesto: j['puesto'] ?? '',
    cargo: j['cargo'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'evaluacion_id': evaluacionId,
    'nombre_completo': nombreCompleto,
    'antiguedad': antiguedad,
    'puesto': puesto,
    'cargo': cargo,
  };
}
