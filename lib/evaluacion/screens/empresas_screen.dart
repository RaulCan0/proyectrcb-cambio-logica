// ignore_for_file: use_build_context_synchronously

import 'package:applensys/evaluacion/screens/historial_screen.dart';
import 'package:applensys/evaluacion/services/empresa_service.dart';
import 'package:applensys/evaluacion/widgets/chat_screen.dart';
import 'package:applensys/evaluacion/widgets/drawer_lensys.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/empresa.dart';
import 'dimensiones_screen.dart';

// Servicio para empresas
final empresaService = EmpresaService();

class EmpresasScreen extends StatefulWidget {
  const EmpresasScreen({super.key});

  @override
  State<EmpresasScreen> createState() => _EmpresasScreenState();
}

class _EmpresasScreenState extends State<EmpresasScreen> {
  final List<Empresa> empresas = [];
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String correoUsuario = '';
  Empresa? empresaCreada;

  @override
  void initState() {
    super.initState();
    _verificarNuevoUsuario();
    _cargarEmpresas();
    _obtenerCorreoUsuario();
  }

  Future<void> _verificarNuevoUsuario() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    // Aquí podrías verificar si el usuario es nuevo y realizar alguna acción
  }

  Future<void> _cargarEmpresas() async {
    setState(() => isLoading = true);
    try {
      final loadedEmpresas = await empresaService.getEmpresas();
      setState(() {
        empresas.clear();
        empresas.addAll(loadedEmpresas);
        isLoading = false;
        if (empresas.isNotEmpty) {
          empresaCreada = empresas.first;
        }
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error cargando empresas: $e');
    }
  }

  Future<void> _obtenerCorreoUsuario() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      correoUsuario = user?.email ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final empresaCreada = empresas.isNotEmpty ? empresas.last : null;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: SizedBox(width: 300, child: const ChatWidgetDrawer()),
      endDrawer: const DrawerLensys(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
        ),
        title: const Text(
          'LensysApp',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            tooltip: 'Ir a Inicio',
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido: \$correoUsuario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (correoUsuario == 'sistemas@lensys.com.mx')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.science),
                        label: const Text('Modo pruebas: Usar/Cargar empresa'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                        onPressed: () => _mostrarDialogoEmpresaPruebas(),
                      ),
                    const SizedBox(height: 20),
                    if (empresaCreada != null)
                      _buildButton(
                        context,
                        label: "Evaluación de ${empresaCreada.nombre}",
                        onTap: () {
                          final String nuevaEvaluacionId = const Uuid().v4();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DimensionesScreen(empresa: empresaCreada, evaluacionId: nuevaEvaluacionId),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                    _buildButton(
                      context,
                      label: 'HISTORIAL',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialScreen())),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickNavButton(
                          context: context,
                          icon: Icons.home,
                          label: 'Inicio',
                          color: const Color(0xFF4CAF50),
                          onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                        ),
                        _buildQuickNavButton(
                          context: context,
                          icon: Icons.person,
                          label: 'Perfil',
                          color: const Color(0xFF2196F3),
                          onTap: () => Navigator.pushNamed(context, '/perfil'),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevaEmpresa(context),
        backgroundColor: const Color(0xFF003056),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        elevation: 8,
        child: const Icon(Icons.add, size: 25, color: Colors.white),
      ),
    );
  }

  Widget _buildButton(BuildContext context, {required String label, required VoidCallback onTap}) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF003056)),
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? Colors.grey[700] : Colors.grey[200], // Color de fondo del contenedor
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
            ), // Color de texto del botón
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.chevron_right, color: Color(0xFF003056)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNavButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
          ), // Color de texto del botón
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoNuevaEmpresa(BuildContext context) {
    final nombreController = TextEditingController();
    final empleadosController = TextEditingController();
    final unidadesController = TextEditingController();
    final areasController = TextEditingController();
    final sectorController = TextEditingController();
    String tamano = 'Pequeña';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar nueva empresa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: empleadosController,
                decoration: const InputDecoration(
                    labelText: 'Total de empleados en la empresa', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tamano,
                items: ['Pequeña', 'Mediana', 'Grande']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => tamano = value ?? 'Pequeña',
                decoration: const InputDecoration(
                  labelText: 'Tamaño de la empresa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unidadesController,
                decoration: const InputDecoration(labelText: 'Unidades de negocio', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: areasController,
                decoration: const InputDecoration(
                  labelText: 'Número de áreas',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sectorController,
                decoration: const InputDecoration(labelText: 'Sector', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              if (nombre.isNotEmpty) {
                final nuevaEmpresa = Empresa(
                  id: const Uuid().v4(),
                  nombre: nombre,
                  tamano: tamano,
                  empleadosTotal: int.tryParse(empleadosController.text.trim()) ?? 0,
                  empleadosAsociados: [],
                  unidades: unidadesController.text.trim(),
                  areas: int.tryParse(areasController.text.trim()) ?? 0,
                  sector: sectorController.text.trim(),
                  createdAt: DateTime.now(),
                );

                try {
                  await empresaService.addEmpresa(nuevaEmpresa);
                  if (!mounted) return;
                  setState(() => empresas.add(nuevaEmpresa));
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint('❌ Error al guardar empresa: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error al guardar empresa: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEmpresaPruebas() {
    // Implementa el diálogo para seleccionar o cargar una empresa de pruebas
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar empresa de pruebas'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Aquí puedes listar las empresas de pruebas disponibles
                // Por ejemplo, usando ListTile para cada empresa
                ListTile(
                  title: const Text('Empresa Prueba 1'),
                  onTap: () {
                    // Lógica para usar la empresa de prueba 1
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Empresa Prueba 2'),
                  onTap: () {
                    // Lógica para usar la empresa de prueba 2
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}