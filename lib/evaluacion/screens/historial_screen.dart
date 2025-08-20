// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:applensys/evaluacion/services/empresa_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:applensys/evaluacion/services/sincronizacion_service.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final empresaService = EmpresaService();
  final sincronizacionService = SincronizacionService();
  List<dynamic> empresas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEmpresas();
  }

  Future<void> _cargarEmpresas() async {
    try {
      final data = await sincronizacionService.obtenerDatos('empresas');
      if (!mounted) return;
      setState(() {
        empresas = data ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar empresas: $e')),
      );
    }
  }

  Future<void> _mostrarArchivosEmpresa(dynamic empresa) async {
    List<Map<String, dynamic>> archivos = [];
    try {
      archivos = await obtenerArchivosEmpresa(empresa.nombre);
    } catch (_) {
      archivos = [];
    }

    showModalBottomSheet(
      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      context: context,
      builder: (_) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 8,
            children: [
              Text('Archivos de ${empresa.nombre}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              if (archivos.isEmpty)
                const ListTile(
                  title: Text('No hay reportes generados para esta empresa.'),
                ),
              ...archivos.map((archivo) => ListTile(
                    leading: archivo['name'].endsWith('.pdf')
                        ? const Icon(Icons.picture_as_pdf, color: Colors.red)
                        : const Icon(Icons.table_chart, color: Colors.green),
                    title: Text(archivo['name']),
                    onTap: () => _abrirUrl(archivo['url']),
                  )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.blue),
                title: const Text("Buscar en este dispositivo"),
                subtitle: const Text("Abrir desde almacenamiento local"),
                onTap: _abrirDesdeLocal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre archivos remotos (Supabase URL)
  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el archivo remoto.')),
      );
    }
  }

  /// Abre archivos desde el almacenamiento local
  Future<void> _abrirDesdeLocal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        await OpenFilex.open(filePath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir archivo local: $e')),
      );
    }
  }

  /// Lista archivos de Supabase Storage
  Future<List<Map<String, dynamic>>> obtenerArchivosEmpresa(String nombreEmpresa) async {
    final supabase = Supabase.instance.client;
    final prefijo = 'Reporte_${nombreEmpresa.replaceAll(' ', '_')}';
    final response = await supabase.storage.from('reportes').list(
      path: '',
      searchOptions: SearchOptions(search: prefijo),
    );

    if (response.isEmpty) return [];

    return response.map((archivo) {
      final url = supabase.storage.from('reportes').getPublicUrl(archivo.name);
      return {
        'name': archivo.name,
        'url': url,
      };
    }).toList();
  }

  Future<void> _sincronizarEmpresa(dynamic empresa) async {
    try {
      await sincronizacionService.sincronizarDatos('empresa_${empresa["id"]}', empresa);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa sincronizada correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al sincronizar empresa: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Evaluaciones')),
      backgroundColor: Colors.grey[200],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: empresas.length,
              itemBuilder: (_, index) {
                final empresa = empresas[index];
                final nombre = empresa['nombre'] ?? 'Sin nombre';
                final fechaEvaluacion = empresa['fecha_evaluacion'] ?? 'Sin fecha';

                return Column(
                  children: [
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Evaluado el: $fechaEvaluacion',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => _mostrarArchivosEmpresa(empresa),
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Ver archivos'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _sincronizarEmpresa(empresa),
                            icon: const Icon(Icons.sync),
                            label: const Text('Sincronizar'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16), // Separación entre empresas
                  ],
                );
              },
            ),
    );
  }
}