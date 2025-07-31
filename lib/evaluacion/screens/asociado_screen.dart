// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/evaluacion/models/asociado.dart';
import 'package:applensys/evaluacion/models/empresa.dart';
import 'package:applensys/evaluacion/screens/principios_screen.dart';
import 'package:applensys/evaluacion/services/domain/supabase_service.dart';
import 'package:applensys/evaluacion/widgets/chat_screen.dart';
import 'package:applensys/evaluacion/widgets/drawer_lensys.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:uuid/uuid.dart';

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _supabase = Supabase.instance.client;
  final _service = SupabaseService();
  late TabController _tabController;

  bool _isLoading = true;
  final Map<String, double> progresoAsociado = {};
  final List<Asociado> ejecutivos = [];
  final List<Asociado> gerentes = [];
  final List<Asociado> miembros = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarAsociados();
  }

  Future<void> _cargarAsociados() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getAsociadosPorEmpresa(widget.empresa.id);
      ejecutivos.clear();
      gerentes.clear();
      miembros.clear();
      progresoAsociado.clear();
      for (final aso in list) {
        final prog = await _service.obtenerProgresoAsociado(
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
      _showDialog('Error', 'Error al cargar asociados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: GoogleFonts.roboto()),
        content: Text(message, style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Aceptar', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  Future<void> _openNuevoAsociado() async {
    final nombreCtrl = TextEditingController();
    String cargo = 'Ejecutivo';
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Nuevo Asociado', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: cargo,
              items: ['Ejecutivo', 'Gerente', 'Miembro']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => cargo = v!,
              decoration: InputDecoration(labelText: 'Cargo', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              if (nombre.isEmpty) {
                _showDialog('Error', 'El nombre es obligatorio.');
                return;
              }
              Navigator.pop(context);
              await _guardarAsociado(nombre, cargo);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003056)),
            child: Text('Guardar', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarAsociado(String nombre, String cargo) async {
    setState(() => _isLoading = true);
    try {
      final id = const Uuid().v4();
      await _supabase.from('asociados').insert({
        'id': id,
        'nombre': nombre,
        'cargo': cargo,
        'empresa_id': widget.empresa.id,
      });
      await _cargarAsociados();
      _showDialog('Éxito', 'Asociado agregado correctamente.');
    } catch (e) {
      _showDialog('Error', 'Error al guardar asociado: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLista(List<Asociado> lista) {
    if (lista.isEmpty) return const Center(child: Text('SIN ASOCIADOS'));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: lista.length,
      itemBuilder: (_, i) {
        final a = lista[i];
        final prog = progresoAsociado[a.id] ?? 0.0;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF003056)),
            title: Text(a.nombre),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.cargo.toUpperCase()),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: prog, color: Colors.green),
                const SizedBox(height: 4),
                Text('${(prog * 100).toStringAsFixed(1)}% completado'),
              ],
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrincipiosScreen(
                    empresa: widget.empresa,
                    asociado: a,
                    dimensionId: widget.dimensionId,
                    evaluacionId: widget.evaluacionId,
                  ),
                ),
              );
              _cargarAsociados();
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const ChatWidgetDrawer(),
      endDrawer: const DrawerLensys(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('${widget.dimensionId} - ${widget.empresa.nombre}'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
            tabs: const [
            Tab(child: Text('EJECUTIVOS', style: TextStyle(color: Colors.white))),
            Tab(child: Text('GERENTES', style: TextStyle(color: Colors.white))),
            Tab(child: Text('MIEMBROS', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLista(ejecutivos),
                _buildLista(gerentes),
                _buildLista(miembros),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNuevoAsociado,
        backgroundColor: const Color(0xFF003056),
        child: const Icon(FluentIcons.people_add_16_regular),
      ),
    );
  }
}
