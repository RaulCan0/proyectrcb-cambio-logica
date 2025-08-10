import 'package:flutter/material.dart';
import 'package:applensys/evaluacion/services/empresa_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _mostrarArchivosEmpresa(dynamic empresa) {
    final nombre = empresa.nombre.toString().replaceAll(' ', '_');
    final pdfUrl = 'https://hdwbaswbinbjbnziwsyu.supabase.co/storage/v1/object/public/reportes/Reporte_$nombre.pdf';
    final excelUrl = 'https://hdwbaswbinbjbnziwsyu.supabase.co/storage/v1/object/public/reportes/Reporte_$nombre.xlsx';

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Archivos de ${empresa.nombre}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('Reporte_$nombre.pdf'),
              onTap: () => _abrirUrl(pdfUrl),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: Text('Reporte_$nombre.xlsx'),
              onTap: () => _abrirUrl(excelUrl),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el archivo.')),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarEmpresas),
        ],
      ),
      body: isLoading
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
    );
  }
}
