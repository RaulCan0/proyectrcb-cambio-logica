import 'package:flutter/material.dart';
import 'package:applensys/evaluacion/services/empresa_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final empresaService = EmpresaService();
  List<dynamic> empresas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEmpresas();
  }

  Future<void> _cargarEmpresas() async {
    try {
      final data = await empresaService.getEmpresas();
      if (!mounted) return;
      setState(() {
        empresas = data;
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
      // ignore: use_build_context_synchronously
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
      // ignore: use_build_context_synchronously
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Empresas'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003056),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarEmpresas),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: empresas.length,
                itemBuilder: (context, index) {
                  final empresa = empresas[index];
                  return GestureDetector(
                    onTap: () => _mostrarArchivosEmpresa(empresa),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        empresa.nombre,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
