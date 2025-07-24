// ignore_for_file: use_build_context_synchronously

import 'package:applensys/evaluacion/models/empresa.dart';
import 'package:applensys/evaluacion/screens/asociado_screen.dart';
import 'package:applensys/evaluacion/screens/empresas_screen.dart';
import 'package:applensys/evaluacion/screens/shingo_result.dart';
import 'package:applensys/evaluacion/screens/tabla_resumen_global.dart';
import 'package:applensys/evaluacion/screens/tablas_screen.dart';
import 'package:applensys/evaluacion/services/domain/evaluacion_service.dart';
import 'package:applensys/evaluacion/services/local/evaluacion_cache_service.dart';
import 'package:applensys/evaluacion/widgets/chat_screen.dart';
import 'package:applensys/evaluacion/widgets/drawer_lensys.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class DimensionesScreen extends StatefulWidget {
  final Empresa empresa;
  final String evaluacionId;

  const DimensionesScreen({
    super.key,
    required this.empresa,
    required this.evaluacionId,
  });

  @override
  State<DimensionesScreen> createState() => _DimensionesScreenState();
}

class _DimensionesScreenState extends State<DimensionesScreen> with RouteAware {
  final EvaluacionService evaluacionService = EvaluacionService();

  final List<Map<String, dynamic>> dimensiones = const [
    {
      'id': '1',
      'nombre': 'IMPULSORES CULTURALES',
      'color': Colors.indigo,
    },
    {
      'id': '2',
      'nombre': 'MEJORA CONTINUA',
      'color': Color.fromARGB(255, 71, 87, 160),
    },
    {
      'id': '3',
      'nombre': 'ALINEAMIENTO EMPRESARIAL',
      'color': Color.fromARGB(255, 39, 33, 99),
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
  }

  Widget _buildProgressCircle(double value, Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 7,
                backgroundColor: Colors.grey[300],
                color: color,
              ),
              Text('${(value * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    const double cardHeight = 200;

    return Scaffold(
      key: scaffoldKey,
      drawer: const SizedBox(width: 300, child: ChatWidgetDrawer()),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EmpresasScreen()),
            );
          },
        ),
        title: Text(
          'Dimensiones - ${widget.empresa.nombre}',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: const DrawerLensys(),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: dimensiones.length + 2,
                itemBuilder: (context, index) {
                  Widget cardItem;
                  if (index < dimensiones.length) {
                    final dimension = dimensiones[index];
                    cardItem = _buildCard(
                      color: dimension['color'],
                      title: dimension['nombre'],
                      child: FutureBuilder<Map<String, double>>(
                        future: Future.wait([
                          evaluacionService.obtenerProgresoDimensionPorCargo(
                            empresaId: widget.empresa.id,
                            dimensionId: dimension['id'],
                            cargo: 'ejecutivo',
                          ),
                          evaluacionService.obtenerProgresoDimensionPorCargo(
                            empresaId: widget.empresa.id,
                            dimensionId: dimension['id'],
                            cargo: 'gerente',
                          ),
                          evaluacionService.obtenerProgresoDimensionPorCargo(
                            empresaId: widget.empresa.id,
                            dimensionId: dimension['id'],
                            cargo: 'miembro',
                          ),
                        ]).then((results) {
                          return {
                            'ejecutivo': results[0]['ejecutivo'] ?? 0.0,
                            'gerente': results[1]['gerente'] ?? 0.0,
                            'miembro': results[2]['miembro'] ?? 0.0,
                          };
                        }),
                        builder: (context, snapshot) {
                          final progresoEj = (snapshot.data?['ejecutivo'] ?? 0.0).clamp(0.0, 1.0);
                          final progresoGe = (snapshot.data?['gerente'] ?? 0.0).clamp(0.0, 1.0);
                          final progresoMi = (snapshot.data?['miembro'] ?? 0.0).clamp(0.0, 1.0);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildProgressCircle(progresoEj, Colors.orange, 'Ejecutivo'),
                              _buildProgressCircle(progresoGe, Colors.green, 'Gerente'),
                              _buildProgressCircle(progresoMi, Colors.blue, 'Miembro'),
                            ],
                          );
                        },
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AsociadoScreen(
                              empresa: widget.empresa,
                              dimensionId: dimension['id'],
                              evaluacionId: widget.evaluacionId,
                            ),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                    );
                  } else if (index == dimensiones.length) {
                    cardItem = _buildCard(
                      color: Colors.orange,
                      title: 'Resultados',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShingoResultSheet(
                              title: 'Resultados',
                              initialData: ShingoResultData(),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    cardItem = _buildCard(
                      color: Colors.blue,
                      title: 'Evaluación Final',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TablaScoreGlobal(
                              empresa: widget.empresa,
                              detalles: const [],
                              evaluaciones: const [], evaluacionId: '',
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return SizedBox(height: cardHeight, child: cardItem);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Continuar más tarde'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003056),
                      foregroundColor: const Color.fromARGB(255, 212, 209, 209),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: () async {
                      await EvaluacionCacheService().guardarPendiente(widget.evaluacionId);
                      await EvaluacionCacheService().guardarTablas(TablasDimensionScreen.tablaDatos);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Progreso guardado localmente')),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Finalizar evaluación', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 94, 156, 96)),
                    onPressed: () async {
                      try {
                        final cache = EvaluacionCacheService();
                        await cache.eliminarPendiente();
                        await cache.limpiarCacheTablaDatos();
                        TablasDimensionScreen.tablaDatos.clear();
                        TablasDimensionScreen.dataChanged.value =
                            !TablasDimensionScreen.dataChanged.value;

                        final prefs = await SharedPreferences.getInstance();
                        final hist = prefs.getStringList('empresas_historial') ?? [];
                        if (!hist.contains(widget.empresa.id)) {
                          hist.add(widget.empresa.id);
                          await prefs.setStringList('empresas_historial', hist);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Evaluación finalizada y datos limpiados')),
                        );
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const EmpresasScreen()),
                          (route) => false,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al finalizar: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required Color color,
    required String title,
    Widget? child,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (child != null) ...[
                  const SizedBox(height: 10),
                  child,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
