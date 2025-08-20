// ignore_for_file: use_build_context_synchronously

import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/services/calificacion_service.dart';
import 'package:applensys/evaluacion/services/storage_service.dart';
import 'package:applensys/evaluacion/widgets/sistemas_asociados.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uuid/uuid.dart';

import '../models/principio_json.dart';
import '../widgets/drawer_lensys.dart';
import '../providers/text_size_provider.dart';

// Mapa de sistemas recomendados por comportamiento
const Map<String, String> sistemasRecomendadosPorComportamiento = {
  "Soporte": "Desarrollo de personas, Medición, Reconocimiento",
  "Reconocer": "Medición, Involucramiento, Reconocimiento, Desarrollo de Personas",
  "Comunidad": "Seguridad, Ambiental, EHS, Compromiso, Desarrollo de Personas",
  "Liderazgo de Servidor": "Desarrollo de Personas",
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

String obtenerNombreDimension(String dimensionId) {
  switch (dimensionId) {
    case '1':
      return 'Dimensión 1';
    case '2':
      return 'Dimensión 2';
    case '3':
      return 'Dimensión 3';
    default:
      return 'Dimensión 1';
  }
}

class ComportamientoEvaluacionScreen extends ConsumerStatefulWidget {
  final PrincipioJson principio;
  final String cargo;
  final String evaluacionId;
  final String dimensionId;
  final String empresaId;
  final String asociadoId;

  const ComportamientoEvaluacionScreen({
    super.key,
    required this.principio,
    required this.cargo,
    required this.evaluacionId,
    required this.dimensionId,
    required this.empresaId,
    required this.asociadoId,
    required String dimension,
  });

  @override
  ConsumerState<ComportamientoEvaluacionScreen> createState() =>
      _ComportamientoEvaluacionScreenState();
}

class _ComportamientoEvaluacionScreenState
    extends ConsumerState<ComportamientoEvaluacionScreen> {
  final storageService = StorageService();
  final calificacionService = CalificacionService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int calificacion = 3;
  final observacionController = TextEditingController();
  List<String> sistemasSeleccionados = [];
  bool isSaving = false;
  String? evidenciaUrl;
  Calificacion? _existente;

  @override
  void initState() {
    super.initState();
    _loadExistingCalificacion();
  }

  Future<void> _loadExistingCalificacion() async {
    final nombreComp = widget.principio.benchmarkComportamiento
        .split(':')
        .first
        .trim();
    final dimId = int.tryParse(widget.dimensionId) ?? 1;
    _existente = await calificacionService.getCalificacionExistente(
      idAsociado: widget.asociadoId,
      idEmpresa: widget.empresaId,
      idDimension: dimId,
      comportamiento: nombreComp,
    );
    if (_existente != null) {
      setState(() {
        calificacion = _existente!.puntaje;
        observacionController.text = _existente!.observaciones ?? '';
        sistemasSeleccionados = List.from(_existente!.sistemas);
        evidenciaUrl = _existente!.evidenciaUrl;
      });
    }
  }

  Future<void> _guardarEvaluacion() async {
    final obs = observacionController.text.trim();
    if (obs.isEmpty) {
      _showAlert('Validación', 'Debes escribir una observación.');
      return;
    }
    if (sistemasSeleccionados.isEmpty) {
      _showAlert('Validación', 'Selecciona al menos un sistema.');
      return;
    }

    if (_existente != null) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Modificar evaluación'),
          content: const Text(
              'Ya existe una evaluación previa. ¿Deseas sobrescribirla?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    setState(() => isSaving = true);
    try {
      final calObj = Calificacion(
        id: _existente?.id ?? const Uuid().v4(),
        idAsociado: widget.asociadoId,
        idEmpresa: widget.empresaId,
        idDimension: int.tryParse(widget.dimensionId) ?? 1,
        comportamiento: widget.principio.benchmarkComportamiento
            .split(':')
            .first
            .trim(),
        puntaje: calificacion,
        fechaEvaluacion: DateTime.now(),
        observaciones: obs,
        sistemas: sistemasSeleccionados,
        evidenciaUrl: evidenciaUrl,
      );

      if (_existente != null) {
        await calificacionService.updateCalificacionFull(calObj);
      } else {
        await calificacionService.addCalificacion(calObj);
      }

      if (mounted) Navigator.pop(context, calObj.comportamiento);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showAlert(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textSize = ref.watch(textSizeProvider);
    final double scaleFactor = textSize / 14.0;

    final desc = widget.principio.calificaciones['C\$calificacion'] ?? 'Sin descripción disponible';
    final comportamientoNombre = widget.principio.benchmarkComportamiento.split(":").first.trim();
    final sistemasRecomendados = sistemasRecomendadosPorComportamiento[comportamientoNombre];

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const DrawerLensys(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 35, 47, 112),
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.principio.nombre,
                style: TextStyle(color: Colors.white, fontSize: 18 * scaleFactor)),
            Text(comportamientoNombre,
                style: TextStyle(color: Colors.white70, fontSize: 14 * scaleFactor))
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer())
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.principio.benchmarkPorNivel,
              style: TextStyle(fontSize: 14 * scaleFactor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(widget.principio.benchmarkComportamiento,
              style: TextStyle(fontSize: 13 * scaleFactor, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.info_outline, size: 18),
              label: Text('Benchmark Nivel', style: TextStyle(fontSize: 12 * scaleFactor)),
              onPressed: () => _showAlert('Benchmark', widget.principio.benchmarkPorNivel),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.help_outline, size: 18),
              label: Text('Guía', style: TextStyle(fontSize: 12 * scaleFactor)),
              onPressed: () => _showAlert('Guía', widget.principio.preguntas),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings, size: 18),
              label: Text('Sistemas', style: TextStyle(fontSize: 12 * scaleFactor)),
              onPressed: isSaving
                  ? null
                  : () async {
                      final sel = await showModalBottomSheet<List<String>>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => SistemasScreen(
                          onSeleccionar: (s) {
                            Navigator.pop(
                                context,
                                s.map((e) => e['nombre'].toString()).toList());
                          },
                        ),
                      );
                      if (sel != null) setState(() => sistemasSeleccionados = sel);
                    },
            ),
          ]),
          const SizedBox(height: 12),
          Text('Descripción:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(desc,
                key: ValueKey(desc),
                style: TextStyle(fontSize: 14 * scaleFactor, color: Colors.black87)),
          ),
            if (sistemasRecomendados != null) ...[
            const SizedBox(height: 10),
            Text(
              'Sistemas recomendados por comportamiento:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13 * scaleFactor, color: Colors.blueGrey),
            ),
            const SizedBox(height: 4),
            Text(
              sistemasRecomendados,
              style: TextStyle(fontSize: 13 * scaleFactor, color: Colors.black87),
            ),
            ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: isSaving ? null : _guardarEvaluacion,
            child: Text(isSaving ? 'Guardando...' : 'Guardar'),
          ),
        ]),
      ),
    );
  }
}
