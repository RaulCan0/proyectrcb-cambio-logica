import 'package:applensys/evaluacion/services/supabase_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/asociado.dart';
import '../models/empresa.dart';
import 'principios_screen.dart';
import '../widgets/drawer_lensys.dart';
import 'package:applensys/evaluacion/widgets/chat_screen.dart';

class AsociadoScreen extends StatefulWidget {
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
  State<AsociadoScreen> createState() => _AsociadoScreenState();
}

class _AsociadoScreenState extends State<AsociadoScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();

  final Map<String, double> progresoAsociado = {};
  final GlobalKey<ScaffoldState> _scaffoldKeyAsociado = GlobalKey<ScaffoldState>();

  List<Asociado> ejecutivos = [];
  List<Asociado> gerentes = [];
  List<Asociado> miembros = [];

  TabController? _tabController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarAsociados();
  }

  Future<void> _cargarAsociados() async {
    setState(() => _loading = true);
    try {
      final list = await _supabaseService.getAsociadosPorEmpresa(widget.empresa.id);
      ejecutivos.clear();
      gerentes.clear();
      miembros.clear();
      progresoAsociado.clear();
        for (final aso in list) {
          final prog = await _supabaseService.obtenerProgresoAsociado(
            evaluacionId: widget.evaluacionId,
            asociadoId: aso.id,
            dimensionId: widget.dimensionId,
            empresaId: widget.empresa.id,
          );
          progresoAsociado[aso.id] = prog;
          switch (aso.cargo.toLowerCase()) {
            case 'ejecutivo':
              ejecutivos.add(aso);
              break;
            case 'gerente':
              gerentes.add(aso);
              break;
            default:
              miembros.add(aso);
          }
        }
    } catch (e) {
      _mostrarAlerta('Error', 'Error al cargar asociados: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _mostrarAlerta(String titulo, String mensaje) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo, style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
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

    await showDialog(
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
                items: const ['Ejecutivo', 'Gerente', 'Miembro']
                    .map((nivel) => DropdownMenuItem(
                          value: nivel,
                          child: Text(nivel, style: GoogleFonts.roboto()),
                        ))
                    .toList(),
                onChanged: (value) => cargoSeleccionado = value!,
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
                empleadosAsociados: const [],
                progresoDimensiones: const {},
                comportamientosEvaluados: const {},
                antiguedad: antiguedad,
                puesto: puesto,
              );

              try {
                await supabase.from('asociados').insert({
                  'id': nuevoId,
                  'nombre': nombre,
                  'puesto': puesto,
                  'cargo': cargoSeleccionado.toLowerCase(),
                  'empresa_id': widget.empresa.id,
                  'dimension_id': widget.dimensionId,
                  'antiguedad': antiguedad,
                });

                if (!mounted) return;
                Navigator.pop(context);
                await _cargarAsociados();
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

  Future<void> _mostrarDialogoEditarAsociado(Asociado asociado) async {
  final nombreController = TextEditingController(text: asociado.nombre);
  final puestoController = TextEditingController(text: asociado.puesto);
  final antiguedadController = TextEditingController(text: (asociado.antiguedad).toString());
  String cargoSeleccionado = (asociado.cargo.isNotEmpty)
    ? asociado.cargo[0].toUpperCase() + asociado.cargo.substring(1).toLowerCase()
    : 'Ejecutivo';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar Asociado', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
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
                  labelText: 'Puesto (puede estar vacío)',
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
                items: const ['Ejecutivo', 'Gerente', 'Miembro']
                    .map((nivel) => DropdownMenuItem(
                          value: nivel,
                          child: Text(nivel, style: GoogleFonts.roboto()),
                        ))
                    .toList(),
                onChanged: (value) => cargoSeleccionado = value!,
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

              if (nombre.isEmpty || antiguedad == null) {
                _mostrarAlerta('Error', 'Completa todos los campos correctamente.');
                return;
              }

              try {
                await _supabaseService.updateAsociado(
                  asociado.id,
                  Asociado(
                    id: asociado.id,
                    nombre: nombre,
                    cargo: cargoSeleccionado.toLowerCase(),
                    empresaId: asociado.empresaId,
                    empleadosAsociados: asociado.empleadosAsociados,
                    progresoDimensiones: asociado.progresoDimensiones,
                    comportamientosEvaluados: asociado.comportamientosEvaluados,
                    antiguedad: antiguedad,
                    puesto: puesto.isEmpty ? '' : puesto,
                  ),
                );
                if (!mounted) return;
                Navigator.pop(context);
                await _cargarAsociados();
                _mostrarAlerta('Éxito', 'Asociado actualizado exitosamente.');
              } catch (e) {
                if (mounted) Navigator.pop(context);
                _mostrarAlerta('Error', 'Error al actualizar asociado: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003056),
              foregroundColor: Colors.white,
            ),
            child: Text('Guardar cambios', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminarAsociado(Asociado asociado) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar Asociado', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${asociado.nombre}?',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.roboto()),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _supabaseService.deleteAsociado(asociado.id);
                if (!mounted) return;
                Navigator.pop(context);
                await _cargarAsociados();
                _mostrarAlerta('Éxito', 'Asociado eliminado exitosamente.');
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                _mostrarAlerta('Error', 'Error al eliminar asociado: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(List<Asociado> lista) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return lista.isEmpty
        ? const Center(child: Text('SIN ASOCIADOS'))
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final asociado = lista[index];
                final progreso = progresoAsociado[asociado.id] ?? 0.0;

                return Dismissible(
                  key: ValueKey(asociado.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    await _confirmarEliminarAsociado(asociado);
                    // No hacemos el borrado local aquí; recargamos desde BD tras confirmar
                    return false;
                  },
                  child: Card(
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
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progreso:',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.blueGrey[800],
                                ),
                              ),
                              Text(
                                '${(progreso * 100).toStringAsFixed(1)}% completado',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.blueGrey[700],
                                ),
                              ),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _mostrarDialogoEditarAsociado(asociado),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmarEliminarAsociado(asociado),
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
                            ),
                          ),
                        ).then((_) => _cargarAsociados());
                      },
                    ),
                  ),
                );
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
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLista(ejecutivos),
            _buildLista(gerentes),
            _buildLista(miembros),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _mostrarDialogoAgregarAsociado();
          await _cargarAsociados();
        },
        backgroundColor: const Color(0xFF003056),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        elevation: 8,
        child: const Icon(FluentIcons.people_add_16_regular, size: 25, color: Colors.white),
      ),
    );
  }
}
