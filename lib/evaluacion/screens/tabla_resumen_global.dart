import 'package:applensys/evaluacion/screens/shingo_result.dart';
import 'package:applensys/evaluacion/widgets/tabla_puntuacion_global.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/tabla_shingo.dart';
import '../widgets/termometro.dart';
import 'package:applensys/evaluacion/screens/tablas_screen.dart';

class TablaResumenGlobal extends ConsumerWidget {
  final Map<String, Map<String, double>> promediosPorDimension;

  const TablaResumenGlobal({
    super.key,
    required this.promediosPorDimension,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  // Calcular puntos globales (máx 800)
  final puntosGlobales = AuxTablaService.obtenerTotalPuntosGlobal();

  // Usar la instancia global de resultados Shingo de la pantalla
  final resumenShingo = ShingoResumenService.generarResumen(ShingoCategorias.tablaShingo);
  final puntosShingo = resumenShingo.isNotEmpty ? resumenShingo.last.puntos : 0.0;

  // Suma total (máx 1000)
  final puntosTotales = puntosGlobales + puntosShingo;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Score Global',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                child: Text(
                  'PUNTUACION EN DIMENSIONES',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              Tab(
                child: Text(
                  'PUNTUACION EN LOGROS',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: TablaPuntuacionGlobal(
                promediosPorDimension: promediosPorDimension,
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TablaResultadosShingo(resultados: ShingoCategorias.tablaShingo),
                  const SizedBox(height: 32),
                  TermometroGlobal(
                    valorObtenido: puntosTotales,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
