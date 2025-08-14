import 'package:applensys/evaluacion/services/calificacion_service.dart';
import 'package:applensys/evaluacion/services/dashboard_service.dart';
import 'package:applensys/evaluacion/services/empresa_service.dart';
import 'package:applensys/evaluacion/services/evaluacion_service.dart';
import 'package:applensys/evaluacion/services/evaluacion_cache_service.dart';
import 'package:applensys/evaluacion/services/auth_service.dart';
import 'package:applensys/evaluacion/services/excel.dart';
import 'package:applensys/evaluacion/services/json_service.dart';
import 'package:applensys/evaluacion/services/notification_service.dart';
import 'package:applensys/evaluacion/services/pdf.dart';
import 'package:applensys/evaluacion/services/storage_service.dart';
import 'package:applensys/evaluacion/widgets/tabla_shingo.dart';
import 'package:get_it/get_it.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => EmpresaService());
  locator.registerLazySingleton(() => EvaluacionService());
  locator.registerLazySingleton(() => CalificacionService());
  locator.registerLazySingleton(() => StorageService());
  locator.registerLazySingleton(() => EvaluacionCacheService());
  locator.registerLazySingleton(() => ReporteExcelService());
  locator.registerLazySingleton(() => ReportePdfService());
  locator.registerLazySingleton(() => JsonService());
  locator.registerLazySingleton(() => DashboardService(DashboardMetrics as String));
  locator.registerLazySingleton(() => ShingoResumenService());
  locator.registerLazySingleton(() => NotificationService());
}
/*import 'package:applensys/evaluacion/services/calificacion_service.dart';
import 'package:applensys/evaluacion/services/dashboard_service.dart';
import 'package:applensys/evaluacion/services/empresa_service.dart';
import 'package:applensys/evaluacion/services/evaluacion_service.dart';
import 'package:applensys/evaluacion/services/evaluacion_cache_service.dart';
import 'package:applensys/evaluacion/services/auth_service.dart';
import 'package:applensys/evaluacion/services/excel.dart';
import 'package:applensys/evaluacion/services/json_service.dart';
import 'package:applensys/evaluacion/services/notification_service.dart';
import 'package:applensys/evaluacion/services/number_feed_service.dart';
import 'package:applensys/evaluacion/services/pdf.dart';
import 'package:applensys/evaluacion/services/storage_service.dart';
import 'package:applensys/evaluacion/widgets/tabla_shingo.dart';
import 'package:get_it/get_it.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => EmpresaService());
  locator.registerLazySingleton(() => EvaluacionService());
  locator.registerLazySingleton(() => CalificacionService());
  locator.registerLazySingleton(() => StorageService());
  locator.registerLazySingleton(() => EvaluacionCacheService());
  locator.registerLazySingleton(() => ReporteExcelService());
  locator.registerLazySingleton(() => ReportePdfService());
  locator.registerLazySingleton(() => JsonService());
  locator.registerLazySingleton(() => DashboardService(DashboardMetrics as String));
  locator.registerLazySingleton(() => ShingoResumenService());
  locator.registerLazySingleton(() => NumberFeedService(numbers: []));
  locator.registerLazySingleton(() => NotificationService());
}
*/