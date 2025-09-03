import 'dart:typed_data';
import 'package:applensys/evaluacion/screens/shingo_result.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReporteShingoService {
  static Future<void> generarYRegistrarShingoPdf({
    required Map<String, ShingoResultData> tabla,
    required String empresaId,
    required String evaluacionId,
    required String empresaNombre,
    required String usuarioId,
  }) async {
    final pdfData = await _generarPdfShingoCompleto(tabla, empresaNombre);

    final nombreArchivo = 'shingo_${empresaId}_${evaluacionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final url = await _subirPdfShingo(pdfData, nombreArchivo);

    await Supabase.instance.client.from('historial_reportes').insert({
      'empresa_id': empresaId,
      'evaluacion_id': evaluacionId,
      'usuario_id': usuarioId,
      'nombre_archivo': nombreArchivo,
      'url': url,
      'fecha': DateTime.now().toIso8601String(),
      'tipo': 'shingo',
    });
  }

  static Future<Uint8List> _generarPdfShingoCompleto(Map<String, ShingoResultData> tabla, String empresaNombre) async {
    final pdf = pw.Document();

    int pagina = 1;
    final totalPaginas = tabla.values.fold<int>(0, (acc, e) => acc + (e.subcategorias.isNotEmpty ? e.subcategorias.length + 1 : 1));

    for (final entry in tabla.entries) {
      final tituloCategoria = entry.key;
      final dataCategoria = entry.value;
      Uint8List? imagenBytes;
      if (dataCategoria.imagen != null) {
        imagenBytes = await dataCategoria.imagen!.readAsBytes();
      }
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(18),
          build: (context) => _buildHojaShingoPdf(
            dataCategoria,
            tituloCategoria,
            empresaNombre,
            pagina,
            totalPaginas,
            imagenBytes: imagenBytes,
          ),
        ),
      );
      pagina++;

      if (dataCategoria.subcategorias.isNotEmpty) {
        for (final subEntry in dataCategoria.subcategorias.entries) {
          Uint8List? subImagenBytes;
          if (subEntry.value.imagen != null) {
            subImagenBytes = await subEntry.value.imagen!.readAsBytes();
          }
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a5,
              margin: const pw.EdgeInsets.all(18),
              build: (context) => _buildHojaShingoPdf(
                subEntry.value,
                subEntry.key,
                empresaNombre,
                pagina,
                totalPaginas,
                imagenBytes: subImagenBytes,
              ),
            ),
          );
          pagina++;
        }
      }
    }

    return pdf.save();
  }

  /// Hoja PDF igualita a la plantilla visual, **EN ESPAÑOL**
  static pw.Widget _buildHojaShingoPdf(
    ShingoResultData data,
    String titulo,
    String empresaNombre,
    int pagina,
    int totalPaginas, {
    Uint8List? imagenBytes,
  }) {
    final txtStyle = pw.TextStyle(fontSize: 8.7);
    final headerStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Calidad', style: headerStyle),
            pw.Text(empresaNombre, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
            pw.Text('p. $pagina de $totalPaginas', style: pw.TextStyle(fontSize: 8.5)),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Text(titulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 7),

        // Imagen tipo gráfico
        if (imagenBytes != null)
          pw.Container(
            alignment: pw.Alignment.center,
            height: 95,
            margin: const pw.EdgeInsets.symmetric(vertical: 2),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600)),
            child: pw.Image(pw.MemoryImage(imagenBytes), fit: pw.BoxFit.contain),
          ),
        pw.SizedBox(height: 7),

        // Primer bloque horizontal 2 columnas
        pw.Row(
          children: [
            pw.Expanded(
              child: _campoBlock('Cómo se calcula', data.campos['Cómo se calcula'] ?? '', txtStyle),
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(
              child: _campoBlock('Cómo se mide', data.campos['Cómo se mide'] ?? '', txtStyle),
            ),
          ],
        ),
        pw.SizedBox(height: 5),

        // Siguientes bloques horizontales completos
        _campoBlock('Alcance', data.campos['Alcance'] ?? '', txtStyle),
        pw.SizedBox(height: 4),
        _campoBlock('¿Por qué es importante?', data.campos['¿Por qué es importante?'] ?? '', txtStyle),
        pw.SizedBox(height: 4),
        _campoBlock('Sistemas usados para mejorar', data.campos['Sistemas usados para mejorar'] ?? '', txtStyle),
        pw.SizedBox(height: 4),
        _campoBlock('Explicación de desviaciones', data.campos['Explicación de desviaciones'] ?? '', txtStyle),
        pw.SizedBox(height: 4),
        _campoBlock('Cambios en los últimos 3 años', data.campos['Cambios en los últimos 3 años'] ?? '', txtStyle),
        pw.SizedBox(height: 4),
        _campoBlock('Cómo se definen metas', data.campos['Cómo se definen metas'] ?? '', txtStyle),
      ],
    );
  }

  static pw.Widget _campoBlock(String titulo, String contenido, pw.TextStyle style) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 7),
      margin: const pw.EdgeInsets.only(bottom: 0.5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.7),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
          pw.SizedBox(height: 2),
          pw.Text(contenido.isEmpty ? '[No completado]' : contenido, style: style, maxLines: 4, overflow: pw.TextOverflow.clip),
        ],
      ),
    );
  }

  static Future<String> _subirPdfShingo(Uint8List pdfData, String nombreArchivo) async {
    final storage = Supabase.instance.client.storage;
    await storage.from('shingo_report').uploadBinary(
      nombreArchivo,
      pdfData,
      fileOptions: const FileOptions(upsert: true, contentType: 'application/pdf'),
    );
    return storage.from('shingo_report').getPublicUrl(nombreArchivo);
  }
}
