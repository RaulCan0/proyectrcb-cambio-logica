// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:applensys/evaluacion/models/asociado.dart';
import 'package:applensys/evaluacion/models/calificacion.dart';
import 'package:applensys/evaluacion/models/empresa.dart';
import 'package:applensys/evaluacion/services/domain/calificacion_service.dart';
import 'package:applensys/evaluacion/services/remote/storage_service.dart';
import 'package:applensys/evaluacion/widgets/sistemas_asociados.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/principio_json.dart';
import '../screens/tablas_screen.dart';
import '../widgets/drawer_lensys.dart';
import '../providers/text_size_provider.dart';

// Mapa de sistemas recomendados por comportamiento
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
  "A prueba de error": "Sistemas de Mejora, Solución de Problemas",
  "Propiedad": "Sistemas de Mejora, Solución de Problemas",
  "Conectar": "Sistemas de Mejora",
  "Ininterrumpido": "Planificación y Programación, Sistemas de Mejora",
  "Demanda": "Planificación y Programación",
  "Eliminar": "Voz de cliente, Sistemas de Mejora",
  "Optimizar": "Sistemas de Mejora, Despliegue de Estrategia",
  "Impacto": "Sistemas de Mejora",
  "Alinear": "Despliegue de Estrategia",
  "Aclarar": "Comunicación, Despliegue de Estrategia",
  "Comunicar": "Comunicación, Despliegue de Estrategia",
  "Relación": "Voz del Cliente",
  "Valor": "Voz del Cliente",
  "Medida": "Despliegue de Estrategia, Medición, Voz del Cliente, Recompensas, Reconocimientos",
};

// Modificada para devolver la clave interna que TablasDimensionScreen espera.
String obtenerNombreDimensionInterna(String dimensionId) {
  switch (dimensionId) {
    case '1': return 'Dimensión 1';
    case '2': return 'Dimensión 2';
    case '3': return 'Dimensión 3';
    default: return 'Dimensión 1'; // Considerar un manejo de error más robusto si es necesario
  }
}

class ComportamientoEvaluacionScreen extends ConsumerStatefulWidget {
  final PrincipioJson principio;
  final String cargo;
  final String evaluacionId;
  final String dimensionId;
  final String empresaId;
  final String asociadoId;
  final Calificacion? calificacionExistente; // Nuevo parámetro opcional

  const ComportamientoEvaluacionScreen({
    super.key,
    required this.principio,
    required this.cargo,
    required this.evaluacionId,
    required this.dimensionId,
    required this.empresaId,
    required this.asociadoId,
    this.calificacionExistente, required String dimension, required Empresa empresa, required void Function(String comportamiento, Calificacion calificacion) onEvaluado, required Asociado asociado, 
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

  late int calificacion; // Modificado para inicializar en initState
  final observacionController = TextEditingController();
  List<String> sistemasSeleccionados = [];
  bool isSaving = false;
  String? evidenciaUrl;

  @override
  void initState() {
    super.initState();
    if (widget.calificacionExistente != null) {
      // Si hay una calificación existente, aqui se proceden a cargar sus datos
      calificacion = widget.calificacionExistente!.puntaje;
      observacionController.text = widget.calificacionExistente!.observaciones ?? ''; // Corregido: Manejar posible nulo
      sistemasSeleccionados = List<String>.from(widget.calificacionExistente!.sistemas);
      evidenciaUrl = widget.calificacionExistente!.evidenciaUrl;
    } else {
      calificacion = 0; // Inicialización predeterminada
      sistemasSeleccionados = []; // Asegurar que la lista esté inicializada
    }
  }

  /// Guarda la lista de sistemas seleccionados y refresca la UI
  Future<void> _saveSelectedSystems(List<String> selected) async {
    setState(() {
      sistemasSeleccionados = List.from(selected);
    });
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

  Future<void> _takePhoto() async {
    const source = ImageSource.gallery;
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo == null) return;
      final Uint8List bytes = await photo.readAsBytes();
      final String fileName = const Uuid().v4();

      await storageService.uploadFile(
        bucket: 'evidencias',
        path: fileName,
        bytes: bytes,
        contentType: 'image/jpeg',
      );
      evidenciaUrl =
          storageService.getPublicUrl(bucket: 'evidencias', path: fileName);
      setState(() {});
      _showAlert('Evidencia', 'Imagen subida correctamente.');
    } catch (e) {
      _showAlert('Error', 'No se pudo obtener la imagen: $e');
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
    setState(() => isSaving = true);
    try {
      final nombreComp =
          widget.principio.benchmarkComportamiento.split(':').first.trim();
      final dimId = int.tryParse(widget.dimensionId) ?? 1;

      // Usar la calificación existente si se pasó al widget, de lo contrario, buscarla.
      final Calificacion? calificacionParaActualizar = widget.calificacionExistente ??
          await calificacionService.getCalificacionExistente(
            idAsociado: widget.asociadoId,
            idEmpresa: widget.empresaId,
            idDimension: dimId,
            comportamiento: nombreComp,
          );

      if (calificacionParaActualizar != null) {
        bool debeEditar = true;
        // Solo mostrar el diálogo de confirmación si la calificación no se pasó directamente (es decir, el usuario no hizo clic explícitamente para editar)
        if (widget.calificacionExistente == null) {
          final editar = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Modificar calificación'),
              content: const Text(
                  'Ya existe una calificación para este comportamiento. ¿Deseas modificarla?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sí')),
              ],
            ),
          );
          debeEditar = editar ?? false;
        }

        if (debeEditar) {
          final calObj = Calificacion(
            id: calificacionParaActualizar.id, // Usar el ID existente
            idAsociado: widget.asociadoId,
            idEmpresa: widget.empresaId,
            idDimension: dimId,
            comportamiento: nombreComp,
            puntaje: calificacion,
            fechaEvaluacion: DateTime.now(), // Considera si quieres actualizar la fecha o mantener la original
            observaciones: obs,
            sistemas: sistemasSeleccionados,
            evidenciaUrl: evidenciaUrl,
          );
          await calificacionService.updateCalificacionFull(calObj);
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
          if (mounted) Navigator.pop(context, nombreComp); // Devolver el nombre del comportamiento para actualizar la pantalla anterior
        } else {
           if (mounted) setState(() => isSaving = false); // Si el usuario decide no editar, detener el indicador de carga
           return; // Salir si el usuario elige no editar
        }
        return; // Salir después de intentar la edición
      }

      // Crear nueva calificación si no existe una para actualizar
      final calObj = Calificacion(
        id: const Uuid().v4(),
        idAsociado: widget.asociadoId,
        idEmpresa: widget.empresaId,
        idDimension: dimId,
        comportamiento: nombreComp,
        puntaje: calificacion,
        fechaEvaluacion: DateTime.now(),
        observaciones: obs,
        sistemas: sistemasSeleccionados,
        evidenciaUrl: evidenciaUrl,
      );
      await calificacionService.addCalificacion(calObj);
      TablasDimensionScreen.actualizarDato(
        widget.evaluacionId,
        dimension: obtenerNombreDimensionInterna(widget.dimensionId), // Usar la nueva función
        principio: widget.principio.nombre,
        comportamiento: nombreComp,
        cargo: widget.cargo,
        valor: calificacion,
        sistemas: sistemasSeleccionados,
        dimensionId: widget.dimensionId, // Se mantiene por si es útil en otro lado, pero la clave principal es 'dimension'
        asociadoId: widget.asociadoId,
        observaciones: obs,
      );
      if (mounted) Navigator.pop(context, nombreComp);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Semantics _buildLentesDataTable() {
    final textSize = ref.watch(textSizeProvider);
    final double scaleFactor = (textSize / 13.0).clamp(0.9, 1.0);

    DataCell wrapText(String text) => DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 280 * scaleFactor),
            child: Text(text,
                softWrap: true,
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13 * scaleFactor)),
          ),
        );

    return Semantics(
      label: 'Tabla de niveles de madurez por rol',
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 10.0 * scaleFactor, // espacio entre columnas reducido
            dataRowMinHeight: 05 * scaleFactor, // más compacto
            dataRowMaxHeight: 160 * scaleFactor, // más compacto
            headingRowHeight: 38* scaleFactor, // altura de encabezado más pequeña
            headingTextStyle: TextStyle(
              fontSize: 12 * scaleFactor, // ligeramente mayor para encabezados
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003056),

            ),
            dataTextStyle: TextStyle(
              fontSize: 12 * scaleFactor, // mejor visibilidad
              color: Colors.black87,
            ),
            columns: const [
              DataColumn(label: Text('Lentes / Rol')),
              DataColumn(label: Text('Nivel 1\n0–20%', textAlign: TextAlign.center)),
              DataColumn(label: Text('Nivel 2\n21–40%', textAlign: TextAlign.center)),
              DataColumn(label: Text('Nivel 3\n41–60%', textAlign: TextAlign.center)),
              DataColumn(label: Text('Nivel 4\n61–80%', textAlign: TextAlign.center)),
              DataColumn(label: Text('Nivel 5\n81–100%', textAlign: TextAlign.center)),
            ],
            rows: [
              DataRow(cells: [
                const DataCell(Text('Ejecutivos')),
                wrapText('Los ejecutivos se centran principalmente en la lucha contra incendios y en gran parte están ausentes de los esfuerzos de mejora.'),
                wrapText('Los ejecutivos son conscientes de las iniciativas de otros para mejorar, pero en gran parte no están involucrados.'),
                wrapText('Los ejecutivos establecen la dirección para la mejora y respaldan los esfuerzos de los demás.'),
                wrapText('Los ejecutivos participan en los esfuerzos de mejora y respaldan el alineamiento de los principios de excelencia operacional con los sistemas.'),
                wrapText('Los ejecutivos se centran en garantizar que los principios de excelencia operativa se arraiguen profundamente en la cultura y se evalúen regularmente para mejorar.'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Gerentes')),
                wrapText('Los gerentes están orientados a obtener resultados "a toda costa".'),
                wrapText('Los gerentes generalmente buscan especialistas para crear mejoras a través de la orientación del proyecto.'),
                wrapText('Los gerentes participan en el desarrollo de sistemas y ayudan a otros a usar herramientas de manera efectiva.'),
                wrapText('Los gerentes se enfocan en conductas de manejo a través del diseño de sistemas.'),
                wrapText('Los gerentes están "principalmente enfocados" en la mejora continua de los sistemas para impulsar un comportamiento más alineado con los principios de excelencia operativa.'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Miembros del equipo')),
                wrapText('Los miembros del equipo se enfocan en hacer su trabajo y son tratados en gran medida como un gasto.'),
                wrapText('A veces se solicita a los asociados que participen en un equipo de mejora usualmente dirigido por alguien externo a su equipo de trabajo natural.'),
                wrapText('Están capacitados y participan en proyectos de mejora.'),
                wrapText('Están involucrados todos los días en el uso de herramientas para la mejora continua en sus propias áreas de responsabilidad.'),
                wrapText('Entienden los principios "el por qué" detrás de las herramientas y son líderes para mejorar sus propios sistemas y ayudar a otros.'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Frecuencia')),
                wrapText('Infrecuente • Raro'),
                wrapText('Basado en eventos • Irregular'),
                wrapText('Frecuente • Común'),
                wrapText('Consistente • Predominante'),
                wrapText('Constante • Uniforme'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Duración')),
                wrapText('Iniciado • Subdesarrollado'),
                wrapText('Experimental • Formativo'),
                wrapText('Repetible • Previsible'),
                wrapText('Establecido • Estable'),
                wrapText('Culturalmente Arraigado • Maduro'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Intensidad')),
                wrapText('Apático • Indiferente'),
                wrapText('Aparente • Compromiso Individual'),
                wrapText('Moderado • Compromiso Local'),
                wrapText('Persistente • Amplio Compromiso'),
                wrapText('Tenaz • Compromiso Total'),
              ]),
              DataRow(cells: [
                const DataCell(Text('Alcance')),
                wrapText('Aislado • Punto de Solución'),
                wrapText('Silos • Flujo de Valor Interno'),
                wrapText('Predominantemente Operaciones • Flujo de Valor Funcional'),
                wrapText('Múltiples Procesos de Negocios • Flujo de Valor Integrado'),
                wrapText('En Toda la Empresa • Flujo de Valor Extendido'),
              ]),
            ],
          ),
        ),
      ),);
  }

 void _mostrarLentesRolDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 150, vertical: 130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.90,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad
              },
            ),
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildLentesDataTable(),
              ),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
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
            Text(widget.principio.nombre, style: TextStyle(color: Colors.white, fontSize: 20 * scaleFactor)),
            Text(widget.principio.benchmarkComportamiento.split(':').first.trim(),
                style: TextStyle(color: Colors.white, fontSize: 14 * scaleFactor)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openEndDrawer())],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Benchmark text
          Text(
            'Benchmark: ${widget.principio.benchmarkPorNivel}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor),
          ),
          const SizedBox(height: 8),
          // Guía y Sistemas asociados como botones estilizados
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.help_outline),
                  label: Text('Guía', style: TextStyle(fontSize: 14 * scaleFactor)),
                  onPressed: () => _showAlert('Guía', widget.principio.preguntas),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003056),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    padding: EdgeInsets.symmetric(vertical: 12 * scaleFactor, horizontal: 16 * scaleFactor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: Text('Sistemas asociados', style: TextStyle(fontSize: 14 * scaleFactor)),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final seleccion = await showModalBottomSheet<List<String>>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => SistemasScreen(
                              onSeleccionar: (s) => Navigator.pop(context, s.map((e) => e['nombre'].toString()).toList()),
                            ),
                          );
                          if (seleccion != null) await _saveSelectedSystems(seleccion);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003056),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    padding: EdgeInsets.symmetric(vertical: 12 * scaleFactor, horizontal: 16 * scaleFactor),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          if (evidenciaUrl != null) ...[
            Image.network(evidenciaUrl!, height: 200 * scaleFactor),
            const SizedBox(height: 16),
          ],

          Text('Calificación:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor)),
          Slider(
            value: calificacion.toDouble(),
            min: 0,
            max: 5,
            divisions: 5,
            label: calificacion.toString(),
            activeColor: const Color(0xFF003056),
            inactiveColor: const Color(0xFF003056).withAlpha(77),
            onChanged: isSaving ? null : (v) => setState(() => calificacion = v.round()),
          ),
          Text(desc, style: TextStyle(fontSize: 14 * scaleFactor)),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.remove_red_eye),
            label: Text('Ver lentes de madurez', style: TextStyle(fontSize: 14 * scaleFactor)),
            onPressed: _mostrarLentesRolDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003056),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              padding: EdgeInsets.symmetric(vertical: 12 * scaleFactor, horizontal: 16 * scaleFactor),
            ),
          ),
          // Mostrar sistemas recomendados según comportamiento
          if (sistemasRecomendadosPorComportamiento.containsKey(widget.principio.benchmarkComportamiento.split(':').first.trim())) ...[
            const SizedBox(height: 8),
            Text(
              sistemasRecomendadosPorComportamiento[widget.principio.benchmarkComportamiento.split(':').first.trim()]!.replaceAll('\\n', ', '),
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 0, 0),
                fontSize: 13 * scaleFactor,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),
          if (sistemasSeleccionados.isNotEmpty) ...[
  const SizedBox(height: 16),
  const Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
     
      
    ],
  ),
],

          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                controller: observacionController,
                maxLines: 2,
                enabled: !isSaving,
                decoration: const InputDecoration(hintText: 'Observaciones...', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.camera_alt, size: 28), onPressed: isSaving ? null : _takePhoto),
          ]),

          if (sistemasSeleccionados.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Sistemas Asociados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: sistemasSeleccionados.map((s) => Chip(
                label: Text(s, style: TextStyle(fontSize: 12 * scaleFactor)),
                onDeleted: () => _saveSelectedSystems(sistemasSeleccionados..remove(s)),
              )).toList(),
            ),
          ],

          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: isSaving
                ? SizedBox(width: 20 * scaleFactor, height: 20 * scaleFactor, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, color: Colors.white),
              label: Text(isSaving ? 'Guardando...' : 'Guardar Evaluación', style: TextStyle(fontSize: 14 * scaleFactor)),
              onPressed: isSaving ? null : _guardarEvaluacion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003056),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30 * scaleFactor, vertical: 15 * scaleFactor),
                side: const BorderSide(color: Color(0xFF003056), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
          ),
        ]),
      ),  );}}
