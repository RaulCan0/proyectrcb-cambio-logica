// ignore_for_file: use_build_context_synchronously

import 'package:applensys/evaluacion/services/empresa_service.dart';
import 'package:flutter/material.dart';
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
  final _supabase = Supabase.instance.client;
  final EmpresaService _empresaService = EmpresaService();

  List<dynamic> _empresas = [];
  bool _isLoadingEmpresas = true;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _loadEmpresas();
  }

  Future<void> _loadEmpresas() async {
    setState(() => _isLoadingEmpresas = true);
    try {
      final data = await _empresaService.getEmpresas();
      if (!mounted) return;
      setState(() => _empresas = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar empresas: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingEmpresas = false);
    }
  }

  Future<void> _showArchivos(dynamic empresa) async {
    if (_sheetOpen) return;         // evita abrir múltiples sheets
    _sheetOpen = true;

    List<Map<String, dynamic>> archivos = [];
    bool isLoading = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        // uso StatefulBuilder para manejar el estado interno del sheet
        return StatefulBuilder(builder: (ctx, setInner) {
          // en cuanto se construya, se dispara la carga
          if (isLoading) {
            _fetchArchivos(empresa).then((list) {
              archivos = list;
              setInner(() => isLoading = false);
            }).catchError((e) {
              archivos = [];
              setInner(() => isLoading = false);
            });
          }

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Wrap(
                      runSpacing: 8,
                      children: [
                        Text('Archivos de ${empresa.nombre}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        if (archivos.isEmpty)
                          const ListTile(
                            title:
                                Text('No hay reportes generados para esta empresa.'),
                          ),
                        ...archivos.map((a) => ListTile(
                              leading: a['name'].endsWith('.pdf')
                                  ? const Icon(Icons.picture_as_pdf,
                                      color: Colors.red)
                                  : const Icon(Icons.table_chart,
                                      color: Colors.green),
                              title: Text(a['name']),
                              onTap: () async {
                                // deshabilita taps mientras abre
                                setInner(() => isLoading = true);
                                await _openUrl(a['url']);
                                setInner(() => isLoading = false);
                              },
                            )),
                        const Divider(),
                        ListTile(
                          leading:
                              const Icon(Icons.folder_open, color: Colors.blue),
                          title: const Text("Buscar en este dispositivo"),
                          subtitle:
                              const Text("Abrir desde almacenamiento local"),
                          onTap: () async {
                            setInner(() => isLoading = true);
                            await _openFromLocal();
                            setInner(() => isLoading = false);
                          },
                        ),
                      ],
                    ),
            ),
          );
        });
      },
    );

    _sheetOpen = false;
  }

  Future<List<Map<String, dynamic>>> _fetchArchivos(dynamic empresa) async {
    final prefix = 'Reporte_${empresa.nombre.replaceAll(' ', '_')}';
    final response = await _supabase
        .storage
        .from('reportes')
        .list(path: '', searchOptions: SearchOptions(search: prefix));

    return response.map((f) {
      final url = _supabase.storage.from('reportes').getPublicUrl(f.name);
      return {'name': f.name, 'url': url};
    }).toList();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el archivo remoto.')),
      );
    }
  }

  Future<void> _openFromLocal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        await OpenFilex.open(result.files.single.path!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir archivo local: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Empresas'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003056),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEmpresas),
        ],
      ),
      body: SafeArea(
        child: _isLoadingEmpresas
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _empresas.length,
                itemBuilder: (context, i) {
                  final empresa = _empresas[i];
                  return GestureDetector(
                    onTap: () => _showArchivos(empresa),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        empresa.nombre,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
