import 'package:applensys/evaluacion/models/emplado_evaluacion.dart';
import 'package:applensys/evaluacion/services/supabase_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empresa.dart';
import 'principios_screen.dart';
import '../widgets/drawer_lensys.dart';
import 'package:applensys/evaluacion/widgets/chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class EmpleadosScreen extends StatefulWidget {
  final Empresa empresa;
  final String dimensionId;
  final String nombreDimension;
  final String evaluacionId;

  const EmpleadosScreen({
    super.key,
    required this.empresa,
    required this.dimensionId,
    required this.evaluacionId,
    required this.nombreDimension,
  });

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();
  final Map<String, double> progresoEmpleado = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<EmpleadoEvaluacion> ejecutivos = [];
  List<EmpleadoEvaluacion> gerentes = [];
  List<EmpleadoEvaluacion> miembros = [];

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarEmpleados();
  }

  Future<void> _cargarEmpleados() async {
    try {
      final empleados = await _supabaseService.getEmpleadosPorEvaluacion(widget.evaluacionId);
      final futures = empleados.map((empleado) => _supabaseService.obtenerProgresoEmpleadoEvaluacion(
        evaluacionId: widget.evaluacionId,
        empleadoId: empleado.id,
        dimensionId: widget.dimensionId,
      )).toList();
      final progresos = await Future.wait(futures);
      progresoEmpleado.clear();
      for (int i = 0; i < empleados.length; i++) {
        progresoEmpleado[empleados[i].id] = progresos[i];
      }
      ejecutivos = empleados.where((e) => e.cargo.toLowerCase() == 'ejecutivo').toList();
      gerentes = empleados.where((e) => e.cargo.toLowerCase() == 'gerente').toList();
      miembros = empleados.where((e) => e.cargo.toLowerCase() == 'miembro').toList();
      if (mounted) setState(() {});
    } catch (e) {
      _mostrarAlerta('Error', 'Error al cargar empleados: $e');
    }
  }

  void _mostrarAlerta(String titulo, String mensaje) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo, style: GoogleFonts.roboto()),
        content: Text(mensaje, style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Aceptar', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(List<EmpleadoEvaluacion> lista) {
    return lista.isEmpty
        ? const Center(child: Text('SIN EMPLEADOS'))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final empleado = lista[index];
              final progreso = progresoEmpleado[empleado.id] ?? 0.0;
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.person_outline,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF003056),
                  ),
                  title: Text(empleado.nombreCompleto, style: GoogleFonts.roboto()),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${empleado.cargo.toUpperCase()} - ${empleado.puesto} - ${empleado.antiguedad} años',
                        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Progreso:', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                          Text('${(progreso * 100).toStringAsFixed(1)}% completado',
                              style: GoogleFonts.roboto(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progreso,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrincipiosScreen(
                          nombreEmpresa: widget.empresa,
                          empleadoEvaluacion: empleado,
                          dimensionId: widget.dimensionId,
                          evaluacionId: widget.evaluacionId,  
                        ),
                      ),
                    ).then((_) => _cargarEmpleados());
                  },
                ),
              );
            },
          );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: SizedBox(width: 300, child: const ChatWidgetDrawer()),
        appBar: AppBar(
          backgroundColor: const Color(0xFF003056),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '${widget.nombreDimension} - ${widget.empresa.nombre}',
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ],
          bottom: TabBar(
            controller: _tabController!,
            indicatorColor: Colors.grey.shade300,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade300,
            labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500),
            unselectedLabelStyle: GoogleFonts.roboto(),
            tabs: const [
              Tab(text: 'EJECUTIVOS'),
              Tab(text: 'GERENTES'),
              Tab(text: 'MIEMBROS DE EQUIPO'),
            ],
          ),
        ),
        endDrawer: const DrawerLensys(),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLista(ejecutivos),
            _buildLista(gerentes),
            _buildLista(miembros),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Acción de agregar empleados (opcional)
          },
          backgroundColor: const Color(0xFF003056),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: 8,
          child: const Icon(FluentIcons.people_add_16_regular, size: 25, color: Colors.white),
        ),
      ),
    );
  }
}
