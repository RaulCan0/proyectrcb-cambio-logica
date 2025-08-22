import 'dart:io';
import 'package:applensys/evaluacion/widgets/tabla_shingo.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ShingoCategorias extends StatefulWidget {
  const ShingoCategorias({super.key});

  static Map<String, ShingoResultData> tablaShingo = {
    for (var cat in [
      'seguridad/medio/ambiente/moral',
      'satisfacción del cliente',
      'calidad',
      'costo/productividad',
      'entregas',
    ]) cat: ShingoResultData()
  };

  static Future<void> guardarTablaShingo() async {
    // Data is now stored directly in Supabase, no local cache needed
    final data = tablaShingo.map((key, value) => MapEntry(key, value.toJson()));
    // TODO: Implement Supabase storage for Shingo observations if needed
  }

  static Future<void> cargarTablaShingo() async {
    // Data is loaded directly from Supabase, no local cache needed  
    // TODO: Implement Supabase loading for Shingo observations if needed
  }

  @override
  State<ShingoCategorias> createState() => _ShingoCategoriasState();
}

class _ShingoCategoriasState extends State<ShingoCategorias> {
  final List<String> categorias = [
    'seguridad/medio/ambiente/moral',
    'satisfacción del cliente',
    'calidad',
    'costo/productividad',
    'entregas',
  ];


  void abrirHoja(String categoria) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShingoResultSheet(
          title: categoria,
          initialData: ShingoCategorias.tablaShingo[categoria]!,
        ),
      ),
    );

    if (resultado != null && resultado is ShingoResultData) {
      if (!mounted) return;
    setState(() {
        ShingoCategorias.tablaShingo[categoria] = resultado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluación por Categorías')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final cat = categorias[index];
                final hoja = ShingoCategorias.tablaShingo[cat]!;
                return GestureDetector(
                  onTap: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShingoResultSheet(
                          title: cat,
                          initialData: hoja,
                        ),
                      ),
                    );
                    if (resultado != null && resultado is ShingoResultData) {
                      if (!mounted) return;
    setState(() {
                        ShingoCategorias.tablaShingo[cat] = resultado;
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade100,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(cat.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Calificación: ${hoja.calificacion}', style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Tabla Resultados Shingo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TablaResultadosShingo(resultados: ShingoCategorias.tablaShingo),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class ShingoResultData {
  Map<String, String> campos;
  File? imagen;
  int calificacion;

  ShingoResultData({
    Map<String, String>? campos,
    this.imagen,
    int? calificacion,
  })  : campos = campos ?? {
          'Cómo se calcula': '',
          'Cómo se mide': '',
          '¿Por qué es importante?': '',
          'Sistemas usados para mejorar': '',
          'Explicación de desviaciones': '',
          'Cambios en 3 años': '',
          'Cómo se definen metas': '',
        },
        calificacion = calificacion ?? 0;

  Map<String, dynamic> toJson() => {
        'campos': campos,
        'imagen': imagen?.path,
        'calificacion': calificacion,
      };

  factory ShingoResultData.fromJson(Map<String, dynamic> json) => ShingoResultData(
        campos: Map<String, String>.from(json['campos'] ?? {}),
        imagen: json['imagen'] != null ? File(json['imagen']) : null,
        calificacion: json['calificacion'] ?? 0,
      );
}

class ShingoResultSheet extends StatefulWidget {
  final String title;
  final ShingoResultData initialData;

  const ShingoResultSheet({
    super.key,
    required this.title,
    required this.initialData,
  });

  @override
  State<ShingoResultSheet> createState() => _ShingoResultSheetState();
}

class _ShingoResultSheetState extends State<ShingoResultSheet> {
  late Map<String, String> campos;
  File? imagen;
  int calificacion = 0;

  @override
  void initState() {
    super.initState();
    campos = Map.from(widget.initialData.campos);
    imagen = widget.initialData.imagen;
    calificacion = widget.initialData.calificacion;
  }

  Future<void> editarCampo(String titulo) async {
    final controller = TextEditingController(text: campos[titulo] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    if (result != null) if (!mounted) return;
    setState(() => campos[titulo] = result!);
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final archivo = await picker.pickImage(source: ImageSource.gallery);
    if (archivo == null) return;
    try {
      if (!mounted) return;
    setState(() => imagen = File(archivo.path));
      // Aquí puedes agregar lógica para subir la imagen a la nube si lo necesitas
    } catch (e) {
  
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar imagen: $e')),
      );
    }
  }

  String _tooltipForField(String campo) {
    switch (campo) {
      case 'Cómo se calcula':
        return 'Explica claramente cómo se mide y calcula este resultado.';
      case 'Cómo se mide':
        return 'Describe la fuente de datos y la frecuencia de medición.';
      case '¿Por qué es importante?':
        return 'Explica el impacto que tiene este resultado en la organización.';
      case 'Sistemas usados para mejorar':
        return 'Describe qué sistemas se usan para mejorar este resultado.';
      case 'Explicación de desviaciones':
        return 'Expón las razones de cualquier desviación significativa.';
      case 'Cambios en 3 años':
        return 'Describe si ha habido cambios en la medición durante los últimos 3 años.';
      case 'Cómo se definen metas':
        return 'Explica cómo se establecen los objetivos y metas para este resultado.';
      default:
        return 'Campo informativo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(
                context,
                ShingoResultData(
                  campos: campos,
                  imagen: imagen,
                  calificacion: calificacion,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: seleccionarImagen,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    color: Colors.grey.shade200,
                    image: imagen != null
                        ? DecorationImage(image: FileImage(imagen!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imagen == null
                      ? const Center(child: Text('Tocar para agregar imagen del gráfico'))
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              ...campos.keys.map((campo) => Tooltip(
                    message: _tooltipForField(campo),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(campo, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => editarCampo(campo),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              color: Colors.grey.shade100,
                            ),
                            child: Text(
                              campos[campo]?.isEmpty ?? true ? 'Tocar para escribir...' : campos[campo]!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
              const Text('Calificación (0 a 5)', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Text('0'),
                  Expanded(
                    child: Slider(
                      value: calificacion.toDouble(),
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: calificacion.toString(),
    onChanged: (v) {
      if (!mounted) return;
      setState(() => calificacion = v.round());
    },
                    ),
                  ),
                  const Text('5'),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
