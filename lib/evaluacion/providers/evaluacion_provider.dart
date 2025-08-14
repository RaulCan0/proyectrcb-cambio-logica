import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/evaluacion_service.dart';
import '../models/evaluacion.dart';

final evaluacionProvider = FutureProvider<Evaluacion>((ref) async {
  final service = EvaluacionService();
  return await service.getEvaluacionActual();
});
