import 'package:applensys/evaluacion/services/domain/calificacion_service.dart';
import 'package:applensys/evaluacion/services/domain/empresa_service.dart';
import 'package:applensys/evaluacion/services/domain/evaluacion_service.dart';
import 'package:applensys/evaluacion/services/local/evaluacion_cache_service.dart';
import 'package:applensys/evaluacion/services/remote/auth_service.dart';
import 'package:applensys/evaluacion/services/remote/storage_service.dart';
import 'package:get_it/get_it.dart';


final GetIt locator = GetIt.instance;

/// Registra todos los servicios en el locator
void setupLocator() {
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => EmpresaService());
  locator.registerLazySingleton(() => EvaluacionService());
  locator.registerLazySingleton(() => CalificacionService());
  locator.registerLazySingleton(() => StorageService());
  locator.registerLazySingleton(() => EvaluacionCacheService());

}
