// ignore_for_file: use_build_context_synchronously

import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/services/calificacion_service.dart';
import 'package:applensys/evaluacion/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/principio_json.dart';
import '../screens/tablas_screen.dart';
import '../widgets/drawer_lensys.dart';
import '../providers/text_size_provider.dart';

// Mapa de sistemas recomendados
const Map<String, String> sistemasRecomendadosPorComportamiento = {
  "Soporte": "Desarrollo de personas, Medición, Reconocimiento",
  "Reconocer": "Medición, Involucramiento, Reconocimiento, Desarrollo de Personas",
  "Comunidad": "Seguridad, Ambiental, EHS, Compromiso, Desarrollo de Personas",
  "Liderazgo de servidor": "Desarrollo de Personas",
  "Valorar": "Desarrollo de Personas, Involucramiento",
  "Empoderar": "Medición, Reconocimiento, Desarrollo de Personas",
  "Mentalidad": "Sistemas de Mejora",
  "Estructura": "Sistemas de Mejora",
  "Reflexionar": "Solución de Problemas",
  "Análisis": "Solución de Problemas",
  "Colaborar": "Solución de Problemas",
  "Comprender": "Solución de Problemas, Gestión Visual",
  "Diseño": "Sistemas de Mejora, Gestión Visual",
  "Atribución": "Sistemas de Mejora, Solución de Problemas",
  "A Prueba de Errores": "Sistemas de Mejora, Solución de Problemas",
  "Propiedad": "Sistemas de Mejora, Solución de Problemas",
  "Conectar": "Sistemas de Mejora",
  "Ininterrumpido": "Planificación y Programación, Sistemas de Mejora",
  "Demanda": "Planificación y Programación",
  "Eliminar": "Voz de Cliente, Sistemas de Mejora",
  "Optimizar": "Sistemas de Mejora, Despliegue de Estrategia",
  "Impacto": "Sistemas de Mejora",
  "Alinear": "Despliegue de Estrategia",
  "Aclarar": "Comunicación, Despliegue de Estrategia",
  "Comunicar": "Comunicación, Despliegue de Estrategia",
  "Relación": "Voz del Cliente",
  "Valor": "Voz del Cliente",
  "Medida": "Despliegue de Estrategia, Medición, Voz del Cliente, Recompensas, Reconocimientos",
};

String obtenerNombreDimensionInterna(String dimensionId) {
  switch (dimensionId) {
    case '1': return 'Dimensión 1';
    case '2': return 'Dimensión 2';
    case '3': return 'Dimensión 3';
    default: return 'Dimensión 1';
  }
}

class ComportamientoEvaluacionScreen extends ConsumerStatefulWidget {
  final PrincipioJson principio;
  final String cargo;
  final String evaluacionId;
  final String dimensionId;
  final String empresaId;
  final String asociadoId;
  final CalificacionComportamiento? calificacionExistente;

  const ComportamientoEvaluacionScreen({
    super.key,
    required this.principio,
    required this.cargo,
    required this.evaluacionId,
    required this.dimensionId,
    required this.empresaId,
    required this.asociadoId,
    this.calificacionExistente,
  });

  @override
  ConsumerState<ComportamientoEvaluacionScreen> createState() =>
      _ComportamientoEvaluacionScreenState();
}

class _ComportamientoEvaluacionScreenState
    extends ConsumerState<ComportamientoEvaluacionScreen> {
  final storageService = StorageService();
  final calificacionService = CalificacionService();
  final _picker = ImagePicker();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late int calificacion;
  final observacionController = TextEditingController();
  List<String> sistemasSeleccionados = [];
  bool isSaving = false;
  String? evidenciaUrl;

  @override
  void initState() {
    super.initState();
    if (widget.calificacionExistente != null) {
      calificacion = widget.calificacionExistente!.puntaje;
      observacionController.text = widget.calificacionExistente!.observacion ?? '';
      sistemasSeleccionados = List.from(widget.calificacionExistente!.sistemasAsociados);
      evidenciaUrl = widget.calificacionExistente!.evidenciaUrl;
    } else {
      calificacion = 0;
      sistemasSeleccionados = [];
    }
  }

  Future<void> _saveSelectedSystems(List<String> selected) async {
    setState(() => sistemasSeleccionados = List.from(selected));
  }

  void _showAlert(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      final String fileName = const Uuid().v4();

      await storageService.uploadFile(
        bucket: 'evidencias',
        path: fileName,
        bytes: bytes,
        contentType: 'image/jpeg',
      );
      evidenciaUrl = storageService.getPublicUrl(bucket: 'evidencias', path: fileName);
      setState(() {});
      _showAlert('Evidencia', 'Imagen subida correctamente.');
    } catch (e) {
      _showAlert('Error', 'No se pudo obtener la imagen: $e');
    }
  }

  Future<void> _guardarDato() async {
    final obs = observacionController.text.trim();
    if (obs.isEmpty) {
      _showAlert('Validación', 'Debes escribir una observación.');
      return;
    }
    if (sistemasSeleccionados.isEmpty) {
      _showAlert('Validación', 'Selecciona al menos un sistema.');
      return;
    }

    setState(() => isSaving = true);
    try {
      final nombreComp = widget.principio.benchmarkComportamiento.split(':').first.trim();

      final CalificacionComportamiento nuevoDato = CalificacionComportamiento(
        evaluacionId: widget.evaluacionId,
        idEmpleado: widget.asociadoId,
        idDimension: widget.dimensionId,
        principio: widget.principio.nombre,
        comportamiento: nombreComp,
        cargo: widget.cargo,
        puntaje: calificacion,
        observacion: obs,
        sistemasAsociados: sistemasSeleccionados,
        evidenciaUrl: evidenciaUrl,
        fechaEvaluacion: DateTime.now(),
      );

      if (widget.calificacionExistente != null) {
        await calificacionService.actualizarDato(nuevoDato);
      } else {
        await calificacionService.guardarDato(nuevoDato);
      }

      TablasDimensionScreen.actualizarDato(
        widget.evaluacionId,
        dimension: obtenerNombreDimensionInterna(widget.dimensionId),
        principio: widget.principio.nombre,
        comportamiento: nombreComp,
        cargo: widget.cargo,
        valor: calificacion,
        sistemas: sistemasSeleccionados,
        dimensionId: widget.dimensionId,
        asociadoId: widget.asociadoId,
        observaciones: obs,
      );

      if (mounted) Navigator.pop(context, nombreComp);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textSize = ref.watch(textSizeProvider);
    final scaleFactor = textSize / 14.0;

    final desc = widget.principio.calificaciones['C$calificacion']
        ?? 'Desliza para agregar una calificación';

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const DrawerLensys(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        centerTitle: true,
        title: Column(
          children: [
            Text(widget.principio.nombre,
                style: TextStyle(color: Colors.white, fontSize: 20 * scaleFactor)),
            Text(widget.principio.benchmarkComportamiento.split(':').first.trim(),
                style: TextStyle(color: Colors.white, fontSize: 14 * scaleFactor)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer())
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Benchmark: ${widget.principio.benchmarkPorNivel}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor)),
          const SizedBox(height: 8),

          Text('Calificación:', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: calificacion.toDouble(),
            min: 0,
            max: 5,
            divisions: 5,
            label: calificacion.toString(),
            activeColor: const Color(0xFF003056),
            onChanged: isSaving ? null : (v) => setState(() => calificacion = v.round()),
          ),
          Text(desc, style: TextStyle(fontSize: 14 * scaleFactor)),

          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                controller: observacionController,
                maxLines: 2,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  hintText: 'Observaciones...', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.camera_alt),
                onPressed: isSaving ? null : _takePhoto),
          ]),

          if (sistemasSeleccionados.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              children: sistemasSeleccionados.map((s) => Chip(
                label: Text(s),
                onDeleted: () => _saveSelectedSystems(sistemasSeleccionados..remove(s)),
              )).toList(),
            ),
          ],

          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: isSaving
                  ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(isSaving ? 'Guardando...' : 'Guardar Dato'),
              onPressed: isSaving ? null : _guardarDato,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003056),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
