import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/evaluacion_service.dart';
import '../models/calificacion.dart';

final calificacionesProvider = FutureProvider<List<Calificacion>>((ref) async {
  final service = EvaluacionService();
  return await service.getCalificacionesActuales();
});
