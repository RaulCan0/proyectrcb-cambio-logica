import 'package:applensys/evaluacion/services/dashboard_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notificador que gestiona el estado del dashboard con métricas actualizadas
class DashboardNotifier extends StateNotifier<DashboardMetrics> {
  final DashboardService dashboardService;

  DashboardNotifier(this.dashboardService)
      : super(DashboardMetrics(
          promedioPorDimension: {},
          conteoPorDimension: {},
          principiosPorNivel: {},
          comportamientosPorNivel: {},
          sistemasPorNivel: {},
        ));

  /// Inicia la suscripción al dashboard
  Future<void> startDashboard() async {
    await dashboardService.start((metrics) {
      state = metrics;
    });
  }

  /// Detiene la suscripción cuando se destruye
  void stopDashboard() {
    dashboardService.dispose();
  }
}

/// Provider parametrizado que expone el notificador
final dashboardGraficosProvider = StateNotifierProvider.family<
    DashboardNotifier, DashboardMetrics, String>(
  (ref, empresaId) {
    final service = DashboardService(empresaId);
    final notifier = DashboardNotifier(service);
    notifier.startDashboard();

    ref.onDispose(() {
      notifier.stopDashboard();
    });

    return notifier;
  },
);
