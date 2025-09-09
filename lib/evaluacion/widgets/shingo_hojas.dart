import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/shingo_result.dart';
import 'menu_reportes.dart';

class HojaShingoWidget extends StatefulWidget {
  final String titulo;
  final ShingoResultData data;

  const HojaShingoWidget({
    super.key,
    required this.titulo,
    required this.data,
  });

  @override
  State<HojaShingoWidget> createState() => _HojaShingoWidgetState();
}

class _HojaShingoWidgetState extends State<HojaShingoWidget> {
  late Map<String, String> campos;
  File? imagen;
  int calificacion = 0;

  @override
  void initState() {
    super.initState();
    campos = Map.from(widget.data.campos);
    imagen = widget.data.imagen;
    // Asegura que la calificación esté en el rango 0-5
    final rawCalif = widget.data.calificacion;
    if (rawCalif < 0) {
      calificacion = 0;
    } else if (rawCalif > 5) {
      calificacion = 5;
    } else {
      calificacion = rawCalif;
    }
  }

  Future<void> editarCampo(String campo) async {
    final controller = TextEditingController(text: campos[campo] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(campo),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => campos[campo] = result);
    }
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final archivo = await picker.pickImage(source: ImageSource.gallery);
    if (archivo != null && mounted) {
      setState(() => imagen = File(archivo.path));
    }
  }

  Widget campoItem(String titulo, String contenido, {int maxLines = 3, String? tooltip}) {
    return Tooltip(
      message: tooltip ?? titulo,
      child: InkWell(
        onTap: () async {
          final controller = TextEditingController(text: campos[titulo] ?? '');
          final result = await showDialog<String>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Editar "$titulo"'),
              content: TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Escribe el contenido'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
              ],
            ),
          );
          if (result != null && mounted) {
            setState(() => campos[titulo] = result);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            color: Colors.grey.shade50,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 2),
              Text(contenido.isEmpty ? 'Toca para editar' : contenido,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: contenido.isEmpty ? Colors.grey : Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 450;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.titulo, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar hoja',
            onPressed: () {
              // Actualiza los datos de la hoja y regresa
              widget.data.campos = Map.from(campos);
              widget.data.imagen = imagen;
              widget.data.calificacion = calificacion;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hoja guardada y calificación actualizada')),
              );
            },
          ),
          IcoButtonMenuReportes(
            onSelected: (formato) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Seleccionaste: $formato')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: isCompact ? double.infinity : 430, // Hacer la hoja más chica tipo A5/A6
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black87, width: 1.2),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen tipo gráfico
                GestureDetector(
                  onTap: seleccionarImagen,
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        image: imagen != null
                          ? DecorationImage(
                              image: FileImage(imagen!),
                              fit: BoxFit.contain,
                            )
                          : null,
                      ),
                      child: imagen == null
                          ? const Center(child: Text('Toca para subir imagen/gráfico', style: TextStyle(fontSize: 11)))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Primer bloque: 2 columnas
                Row(
                  children: [
                    Expanded(
                      child: campoItem(
                        'Cómo se calcula',
                        campos['Cómo se calcula'] ?? '',
                        tooltip: 'Describe el método de cálculo del resultado',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: campoItem(
                        'Cómo se mide',
                        campos['Cómo se mide'] ?? '',
                        tooltip: 'Explica cómo se mide este resultado',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 4 filas horizontales completas
                campoItem(
                  '¿Por qué es importante?',
                  campos['¿Por qué es importante?'] ?? '',
                  tooltip: 'Razón por la que este resultado es relevante',
                ),
                const SizedBox(height: 6),
                campoItem(
                  'Sistemas usados para mejorar',
                  campos['Sistemas usados para mejorar'] ?? '',
                  tooltip: 'Sistemas implementados para mejorar este resultado',
                ),
                const SizedBox(height: 6),
                campoItem(
                  'Explicación de desviaciones',
                  campos['Explicación de desviaciones'] ?? '',
                  tooltip: 'Explica las desviaciones observadas',
                ),
                const SizedBox(height: 6),
                campoItem(
                  'Cambios en 3 años',
                  campos['Cambios en 3 años'] ?? '',
                  tooltip: 'Cambios en la medición en los últimos 3 años',
                ),
                const SizedBox(height: 6),
                campoItem(
                  'Cómo se definen metas',
                  campos['Cómo se definen metas'] ?? '',
                  tooltip: 'Cómo se establecen las metas/objetivos',
                ),
                const SizedBox(height: 13),

                // Calificación 0-5
                Tooltip(
                  message: 'Selecciona la calificación del resultado (0 = muy bajo, 5 = excelente)',
                  child: Row(
                    children: [
                      const Text('Calificación (0-5):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Expanded(
                        child: Slider(
                          value: calificacion.clamp(0, 5).toDouble(),
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: calificacion.clamp(0, 5).toString(),
                          onChanged: (value) => setState(() => calificacion = value.toInt()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Editar calificación',
                        onPressed: () async {
                          final result = await showDialog<int>(
                            context: context,
                            builder: (_) => StatefulBuilder(
                              builder: (context, setStateDialog) => AlertDialog(
                                title: const Text('Editar calificación'),
                                content: Slider(
                                  value: calificacion.toDouble(),
                                  min: 0,
                                  max: 5,
                                  divisions: 5,
                                  label: calificacion.toString(),
                                  onChanged: (v) {
                                    setStateDialog(() {
                                      calificacion = v.toInt();
                                    });
                                  },
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                  TextButton(onPressed: () => Navigator.pop(context, calificacion), child: const Text('Guardar')),
                                ],
                              ),
                            ),
                          );
                          if (result != null) setState(() => calificacion = result);
                        },
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text('Calificación actual: $calificacion / 5',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                // ...eliminado el botón de guardar...
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
