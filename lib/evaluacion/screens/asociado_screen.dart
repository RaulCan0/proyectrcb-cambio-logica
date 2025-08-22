import 'package:applensys/evaluacion/providers/asociado_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/asociado.dart';
import '../models/empresa.dart';
import 'principios_screen.dart';
import '../widgets/drawer_lensys.dart';
import 'package:applensys/evaluacion/widgets/chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AsociadoScreen extends ConsumerStatefulWidget {
  final Empresa empresa;
  final String dimensionId;
  final String evaluacionId;

  const AsociadoScreen({
    super.key,
    required this.empresa,
    required this.dimensionId,
    required this.evaluacionId,
  });

  @override
  ConsumerState<AsociadoScreen> createState() => _AsociadoScreenState();
}

class _AsociadoScreenState extends ConsumerState<AsociadoScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKeyAsociado = GlobalKey<ScaffoldState>();

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _mostrarAlerta(String titulo, String mensaje) {
  if (!mounted) return; // ← Agrega esta línea
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

  Future<void> _mostrarDialogoAgregarAsociado() async {
    final nombreController = TextEditingController();
    final antiguedadController = TextEditingController();
    final puestoController = TextEditingController();
    String cargoSeleccionado = 'Ejecutivo';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Nuevo Asociado', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: GoogleFonts.roboto(),
                  border: const OutlineInputBorder(),
                ),
                style: GoogleFonts.roboto(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: puestoController,
                decoration: InputDecoration(
                  labelText: 'Puesto (ej. Gerente de Logística)',
                  labelStyle: GoogleFonts.roboto(),
                  border: const OutlineInputBorder(),
                ),
                style: GoogleFonts.roboto(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: antiguedadController,
                decoration: InputDecoration(
                  labelText: 'Antigüedad (años)',
                  labelStyle: GoogleFonts.roboto(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.roboto(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: cargoSeleccionado,
                items: ['Ejecutivo', 'Gerente', 'Miembro'].map((nivel) {
                  return DropdownMenuItem<String>(
                    value: nivel,
                    child: Text(nivel, style: GoogleFonts.roboto()),
                  );
                }).toList(),
                onChanged: (value) {
                  cargoSeleccionado = value!;
                },
                decoration: InputDecoration(
                  labelText: 'Nivel',
                  labelStyle: GoogleFonts.roboto(),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.roboto()),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              final puesto = puestoController.text.trim();
              final antiguedadTexto = antiguedadController.text.trim();
              final antiguedad = int.tryParse(antiguedadTexto);

              if (nombre.isEmpty || puesto.isEmpty || antiguedad == null) {
                _mostrarAlerta('Error', 'Completa todos los campos correctamente.');
                return;
              }

              final nuevoId = const Uuid().v4();
              final nuevo = Asociado(
                id: nuevoId,
                nombre: nombre,
                cargo: cargoSeleccionado.toLowerCase(),
                empresaId: widget.empresa.id,
                empleadosAsociados: [],
                progresoDimensiones: {},
                comportamientosEvaluados: {},
                antiguedad: antiguedad, puesto: puesto,
              );

              try {
                final asociadoService = ref.read(asociadoServiceProvider);
                await asociadoService.addAsociado(nuevo);

                if (!mounted) return;
                // No need to manually update lists, the provider will refresh
                Navigator.pop(context);
                _mostrarAlerta('Éxito', 'Asociado agregado exitosamente.');
              } catch (e) {
                if (mounted) Navigator.pop(context);
                _mostrarAlerta('Error', 'Error al guardar asociado: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003056),
              foregroundColor: Colors.white,
            ),
            child: Text('Asociar empleado', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(List<Asociado> lista) {
    return lista.isEmpty
        ? const Center(child: Text('SIN ASOCIADOS'))
        : Padding( // Añadido Padding horizontal
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final asociado = lista[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.person_outline,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF003056),
                    ),
                    title: Text(asociado.nombre, style: GoogleFonts.roboto()),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${asociado.cargo.trim().toLowerCase() == "miembro" ? "MIEMBRO DE EQUIPO" : asociado.cargo.toUpperCase()} - ${asociado.puesto} - ${asociado.antiguedad} años',
                          style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrincipiosScreen(
                            empresa: widget.empresa,
                            asociado: asociado,
                            dimensionId: widget.dimensionId, 
                            evaluacionId: widget.evaluacionId, 
                            // Corregido: Usar el evaluacionId del widget actual
                          ),
                        ),
                      ).then((_) => _cargarAsociados());
                    },
                  ));
              },
            ),
          );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKeyAsociado,
      drawer: SizedBox(width: 300, child: const ChatWidgetDrawer()),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Center(
          child: Text(
            ' ${widget.empresa.nombre}',
            style: GoogleFonts.roboto(color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKeyAsociado.currentState?.openEndDrawer(),
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
      body: Padding( // Añadido Padding superior para el TabBarView
        padding: const EdgeInsets.only(top: 15.0),
        child: Consumer(
          builder: (context, ref, child) {
            final asociadosAsync = ref.watch(asociadosPorEmpresaProvider(widget.empresa.id));
            
            return asociadosAsync.when(
              data: (asociados) {
                final ejecutivos = asociados.where((a) => a.cargo.toLowerCase() == 'ejecutivo').toList();
                final gerentes = asociados.where((a) => a.cargo.toLowerCase() == 'gerente').toList();
                final miembros = asociados.where((a) => a.cargo.toLowerCase() == 'miembro').toList();
                
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLista(ejecutivos),
                    _buildLista(gerentes),
                    _buildLista(miembros),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error cargando asociados: $error'),
                    ElevatedButton(
                      onPressed: () => ref.refresh(asociadosPorEmpresaProvider(widget.empresa.id)),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _mostrarDialogoAgregarAsociado();
          // Refresh the provider to get updated data
          ref.refresh(asociadosPorEmpresaProvider(widget.empresa.id));
        },
        backgroundColor: const Color(0xFF003056),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        elevation: 8,
        child: const Icon(FluentIcons.people_add_16_regular, size: 25, color: Colors.white),
      ),
    );
  }
}
