// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:applensys/evaluacion/services/evaluacion_cache_service.dart';
import 'package:applensys/evaluacion/widgets/shingo_hojas.dart';
import 'package:applensys/evaluacion/services/shingoservice.dart';
import 'package:flutter/material.dart';

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
    final data = tablaShingo.map((key, value) => MapEntry(key, value.toJson()));
    await EvaluacionCacheService().guardarObservaciones(data.cast<String, String>());
  }

  static Future<void> cargarTablaShingo() async {
    final data = await EvaluacionCacheService().cargarObservaciones();
    tablaShingo = data.map((key, value) => MapEntry(key, ShingoResultData.fromJson(value as Map<String, dynamic>)));
  }

  @override
  State<ShingoCategorias> createState() => _ShingoCategoriasState();
}

class _ShingoCategoriasState extends State<ShingoCategorias> {
  List<String> categorias = [
    'seguridad/medio/ambiente/moral',
    'satisfacción del cliente',
    'calidad',
    'costo/productividad',
    'entregas',
  ];

  void abrirHoja(String categoria, {String? subcategoria}) async {
    final data = subcategoria == null
        ? ShingoCategorias.tablaShingo[categoria]!
        : ShingoCategorias.tablaShingo[categoria]!.subcategorias[subcategoria]!;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HojaShingoWidget(
          titulo: subcategoria ?? categoria,
          data: data,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {}); // Refresca la UI y la tabla tras editar
  }

  void agregarCategoria() async {
    final controller = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre de la categoría'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Agregar')),
        ],
      ),
    );
    if (nombre != null && nombre.trim().isNotEmpty) {
      setState(() {
        categorias.add(nombre.trim());
        ShingoCategorias.tablaShingo[nombre.trim()] = ShingoResultData();
      });
    }
  }

  void eliminarCategoria(String categoria) {
    setState(() {
      categorias.remove(categoria);
      ShingoCategorias.tablaShingo.remove(categoria);
    });
  }

  void agregarSubcategoria(String categoria) async {
    final controller = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva subcategoría'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre de la subcategoría'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Agregar')),
        ],
      ),
    );
    if (nombre != null && nombre.trim().isNotEmpty) {
      setState(() {
        ShingoCategorias.tablaShingo[categoria]!.subcategorias[nombre.trim()] = ShingoResultData();
      });
    }
  }

  void eliminarSubcategoria(String categoria, String subcategoria) {
    setState(() {
      ShingoCategorias.tablaShingo[categoria]!.subcategorias.remove(subcategoria);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EVALUACION DE RESULTADOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generar reporte Shingo',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generando reporte Shingo...')),
              );
              // Ejecuta el servicio directamente (ajusta los parámetros según tu lógica de negocio)
              try {
                await ReporteShingoService.generarYRegistrarShingoPdf(
                  tabla: ShingoCategorias.tablaShingo,
                  empresaId: 'ID_EMPRESA', // <-- Reemplaza por el ID real
                  evaluacionId: 'ID_EVALUACION', // <-- Reemplaza por el ID real
                  empresaNombre: 'Nombre Empresa', // <-- Reemplaza por el nombre real
                  usuarioId: 'ID_USUARIO', // <-- Reemplaza por el ID real
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reporte Shingo generado y subido correctamente.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al generar el reporte: $e')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: agregarCategoria,
        tooltip: 'Agregar categoría',
        child: const Icon(Icons.add),
      ),
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
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(cat.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              Text('Calificación: ${hoja.calificacion}', style: const TextStyle(fontSize: 14)),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Editar categoría',
                                onPressed: () => abrirHoja(cat),
                              ),
                            ],
                          ),
                          if (hoja.subcategorias.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...hoja.subcategorias.entries.map((entry) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Text(entry.key, style: const TextStyle(fontSize: 15)),
                                    ),
                                    Text('Calificación: ${entry.value.calificacion}', style: const TextStyle(fontSize: 14)),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Editar subcategoría',
                                      onPressed: () => abrirHoja(cat, subcategoria: entry.key),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Eliminar subcategoría',
                                      onPressed: () => eliminarSubcategoria(cat, entry.key),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                            )),
                          ],
                          Row(
                            children: [
                              Icon(Icons.add, color: Colors.green),
                              TextButton(
                                onPressed: () => agregarSubcategoria(cat),
                                child: const Text('Agregar subcategoría'),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Eliminar categoría',
                                onPressed: () => eliminarCategoria(cat),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Tabla de resultados Shingo OCULTA de la UI
              // const SizedBox(height: 30),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 20),
              //   child: Text('Tabla Resultados Shingo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              // ),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: TablaResultadosShingo(resultados: ShingoCategorias.tablaShingo),
              // ),
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
  Map<String, ShingoResultData> subcategorias;

  ShingoResultData({
    Map<String, String>? campos,
    this.imagen,
    int? calificacion,
    Map<String, ShingoResultData>? subcategorias,
  })  : campos = campos ?? {
          'Cómo se calcula': '',
          'Cómo se mide': '',
          '¿Por qué es importante?': '',
          'Sistemas usados para mejorar': '',
          'Explicación de desviaciones': '',
          'Cambios en 3 años': '',
          'Cómo se definen metas': '',
        },
        calificacion = calificacion ?? 0,
        subcategorias = subcategorias ?? {};

  Map<String, dynamic> toJson() => {
        'campos': campos,
        'imagen': imagen?.path,
        'calificacion': calificacion,
        'subcategorias': subcategorias.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory ShingoResultData.fromJson(Map<String, dynamic> json) => ShingoResultData(
        campos: Map<String, String>.from(json['campos'] ?? {}),
        imagen: json['imagen'] != null ? File(json['imagen']) : null,
        calificacion: json['calificacion'] ?? 0,
        subcategorias: (json['subcategorias'] != null)
            ? Map<String, ShingoResultData>.from(
                (json['subcategorias'] as Map).map((k, v) => MapEntry(k, ShingoResultData.fromJson(v as Map<String, dynamic>))))
            : {},
      );
}

// Eliminada la clase ShingoResultSheet. Ahora se usa HojaShingoWidget para editar hojas.
