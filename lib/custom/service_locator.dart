import 'package:applensys/evaluacion/services/calificacion_service.dart';
import 'package:applensys/evaluacion/services/empresa_service.dart';
import 'package:applensys/evaluacion/services/evaluacion_service.dart';
import 'package:applensys/evaluacion/services/evaluacion_cache_service.dart';
import 'package:applensys/evaluacion/services/auth_service.dart';
import 'package:applensys/evaluacion/services/storage_service.dart';

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
