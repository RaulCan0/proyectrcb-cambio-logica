import 'dart:typed_data';
import 'package:applensys/evaluacion/screens/shingo_result.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

// Servicio completamente corregido para generar y registrar reportes Shingo
// Guarda datos en la tabla 'shingo_resultados', imágenes en 'shingo_report', y el PDF en 'reportes'

class ReporteShingoService {
  static Future<void> generarYRegistrarShingoPdf({
    required Map<String, ShingoResultData> tabla,
    required String empresaId,
    required String evaluacionId,
    required String empresaNombre,
  }) async {
    final pdfData = await _generarPdfShingoCompleto(tabla, empresaNombre);

    for (final entry in tabla.entries) {
      final tituloCategoria = entry.key;
      final dataCategoria = entry.value;

      String? imagenUrl;
      if (dataCategoria.imagen != null) {
        final bytes = await dataCategoria.imagen!.readAsBytes();
        final fileName = 'shingo_${empresaId}_${tituloCategoria}_${DateTime.now().millisecondsSinceEpoch}.png';
        await Supabase.instance.client.storage
            .from('shingo_report')
            .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
        imagenUrl = Supabase.instance.client.storage.from('shingo_report').getPublicUrl(fileName);
      }

      await Supabase.instance.client.from('shingo_resultados').insert({
        'categoria': tituloCategoria,
        'campos': dataCategoria.campos,
        'imagen_url': imagenUrl,
      });

      for (final subEntry in dataCategoria.subcategorias.entries) {
        final subTitulo = subEntry.key;
        final subData = subEntry.value;
        String? subImgUrl;

        if (subData.imagen != null) {
          final bytes = await subData.imagen!.readAsBytes();
          final subFileName = 'shingo_${empresaId}_${subTitulo}_${DateTime.now().millisecondsSinceEpoch}.png';
          await Supabase.instance.client.storage
              .from('shingo_report')
              .uploadBinary(subFileName, bytes, fileOptions: const FileOptions(upsert: true));
          subImgUrl = Supabase.instance.client.storage.from('shingo_report').getPublicUrl(subFileName);
        }

        await Supabase.instance.client.from('shingo_resultados').insert({
          'categoria': subTitulo,
          'campos': subData.campos,
          'imagen_url': subImgUrl,
        });
      }
    }

    final nombreArchivo = '${empresaNombre.replaceAll(' ', '_')}-reporte_shingo.pdf';
    await Supabase.instance.client.storage
        .from('reportes')
        .uploadBinary(nombreArchivo, pdfData, fileOptions: const FileOptions(upsert: true));
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
        if (imagenBytes != null)
          pw.Container(
            alignment: pw.Alignment.center,
            height: 95,
            margin: const pw.EdgeInsets.symmetric(vertical: 2),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600)),
            child: pw.Image(pw.MemoryImage(imagenBytes), fit: pw.BoxFit.contain),
          ),
        pw.SizedBox(height: 7),
        pw.Row(
          children: [
            pw.Expanded(child: _campoBlock('Cómo se calcula', data.campos['Cómo se calcula'] ?? '', txtStyle)),
            pw.SizedBox(width: 6),
            pw.Expanded(child: _campoBlock('Cómo se mide', data.campos['Cómo se mide'] ?? '', txtStyle)),
          ],
        ),
        pw.SizedBox(height: 5),
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
}