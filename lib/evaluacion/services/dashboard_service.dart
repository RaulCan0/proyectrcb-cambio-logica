import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de métricas del dashboard
class DashboardMetrics {
  final Map<String, double> promedioPorDimension;
  final Map<String, int> conteoPorDimension;
  final Map<String, Map<String, double>> sistemasPorNivel;
  final Map<String, Map<String, double>> principiosPorNivel;
  final Map<String, Map<String, double>> comportamientosPorNivel;

  DashboardMetrics({
    required this.promedioPorDimension,
    required this.conteoPorDimension,
    required this.sistemasPorNivel,
    required this.principiosPorNivel,
    required this.comportamientosPorNivel,
  });
}

/// Servicio para alimentar datos del dashboard
typedef DashboardListener = void Function(DashboardMetrics metrics);

class DashboardService {
  final SupabaseClient _client = Supabase.instance.client;
  final String empresaId;
  late final StreamSubscription _subscription;

  DashboardService(this.empresaId);

  Future<void> start(DashboardListener onUpdate) async {
    await _fetchAndNotify(onUpdate);

    _subscription = _client
        .from('calificaciones')
        .stream(primaryKey: ['id'])
        .eq('id_empresa', empresaId)
        .listen((_) async {
      await _fetchAndNotify(onUpdate);
    });
  }

  void dispose() {
    _subscription.cancel();
  }

  Future<void> _fetchAndNotify(DashboardListener onUpdate) async {
    final datos = await _client
        .from('calificaciones')
        .select('id_asociado, id_principio, puntaje, cargo_raw')
        .eq('id_empresa', empresaId);

    final Map<String, List<double>> principioPuntajes = {};

    for (final rec in datos as List) {
      final principio = rec['id_principio']?.toString() ?? '';
      final puntaje = (rec['puntaje'] as num?)?.toDouble() ?? 0.0;

      if (principio.isEmpty) continue;

      principioPuntajes.putIfAbsent(principio, () => []);
      principioPuntajes[principio]!.add(puntaje);
    }

    final Map<String, Map<String, double>> principiosPorNivel = {
      'GLOBAL': {},
    };

    principioPuntajes.forEach((principio, valores) {
      final suma = valores.fold(0.0, (a, b) => a + b);
      principiosPorNivel['GLOBAL']![principio] = suma / valores.length;
    });

    final DashboardMetrics metrics = DashboardMetrics(
      promedioPorDimension: {},
      conteoPorDimension: {},
      principiosPorNivel: principiosPorNivel,
      comportamientosPorNivel: {},
      sistemasPorNivel: {},
    );

    onUpdate(metrics);
  }
}