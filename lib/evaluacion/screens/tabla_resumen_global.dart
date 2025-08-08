import 'package:applensys/evaluacion/screens/shingo_result.dart';
import 'package:applensys/evaluacion/widgets/tabla_puntuacion_global.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/tabla_shingo.dart';

class TablaResumenGlobal extends ConsumerWidget {
  final Map<String, Map<String, double>> promediosPorDimension;
  final Map<String, ShingoResultData> resultadosShingo;

  const TablaResumenGlobal({
    super.key,
    required this.promediosPorDimension,
    required this.resultadosShingo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si no usas un provider, elimina la línea y usa directamente los datos recibidos por el widget.
    // final state = ref.watch(({
    //   'promediosPorDimension': promediosPorDimension,
    //   'resultadosShingo': resultadosShingo,
    // }));

    // También podemos usar el nuevo provider para dashboard si tenemos las dimensiones y datos raw
    // Ejemplo de cómo usarlo:
    // final dashboardState = ref.watch(dashboardTablesProvider({
    //   'dimensiones': dimensiones,
    //   'datosRaw': datosRaw,
    //   'resultadosShingo': resultadosShingo,
    // }));

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
            'Puntuación Global',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
              ),
              Tab(
          child: Text(
            'Resultados Shingo',
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
              child: TablaResultadosShingo(
                resultados: resultadosShingo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
