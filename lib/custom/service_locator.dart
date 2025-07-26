import 'package:applensys/evaluacion/services/domain/calificacion_service.dart';
import 'package:applensys/evaluacion/services/domain/empresa_service.dart';
import 'package:applensys/evaluacion/services/domain/evaluacion_service.dart';
import 'package:applensys/evaluacion/services/evaluation_chart.dart';
import 'package:applensys/evaluacion/services/local/evaluacion_cache_service.dart';
import 'package:applensys/evaluacion/services/remote/auth_service.dart';
import 'package:applensys/evaluacion/services/remote/storage_service.dart';
import 'package:get_it/get_it.dart';
final GetIt locator = GetIt.instance;
void setupLocator() {
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => EmpresaService());
  locator.registerLazySingleton(() => EvaluacionService());
  locator.registerLazySingleton(() => CalificacionService());
  locator.registerLazySingleton(() => StorageService());
  locator.registerLazySingleton(() => EvaluacionCacheService());
  locator.registerLazySingleton(() => EvaluationChartDataService());
}
