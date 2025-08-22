import 'package:applensys/evaluacion/services/domain/calificacion_service.dart';
import 'package:applensys/evaluacion/services/domain/empresa_service.dart';
import 'package:applensys/evaluacion/services/domain/evaluacion_service.dart';
import 'package:applensys/evaluacion/services/domain/asociado_service.dart';
import 'package:applensys/evaluacion/services/domain/sistema_asociado_service.dart';
import 'package:applensys/evaluacion/services/remote/auth_service.dart';
import 'package:applensys/evaluacion/services/remote/storage_service.dart';
import 'package:applensys/evaluacion/services/excel.dart';
import 'package:applensys/evaluacion/services/json_service.dart';
import 'package:applensys/evaluacion/services/notification_service.dart';
import 'package:applensys/evaluacion/services/pdf.dart';
import 'package:applensys/evaluacion/services/dashboard_service.dart';
import 'package:applensys/evaluacion/widgets/tabla_shingo.dart';
import 'package:get_it/get_it.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Servicios remotos
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => StorageService());
  
  // Microservicios de dominio
  locator.registerLazySingleton(() => EmpresaService());
  locator.registerLazySingleton(() => AsociadoService());
  locator.registerLazySingleton(() => EvaluacionService());
  locator.registerLazySingleton(() => CalificacionService());
  locator.registerLazySingleton(() => SistemaAsociadoService());
  
  // Servicios de utilidad
  locator.registerLazySingleton(() => ReporteExcelService());
  locator.registerLazySingleton(() => ReportePdfService());
  locator.registerLazySingleton(() => JsonService());
  locator.registerLazySingleton(() => DashboardService());
  locator.registerLazySingleton(() => ShingoResumenService());
  locator.registerLazySingleton(() => NotificationService());
}
