import 'dart:io';
import 'package:docx_template/docx_template.dart';
import 'package:applensys/evaluacion/services/pdf.dart'; // ReporteComportamiento

class ReporteWordService {
  static Future<File> generarReporteWord(List<ReporteComportamiento> datos, String outputPath) async {
    final template = await File('assets/template.docx').readAsBytes();
    final docx = await DocxTemplate.fromBytes(template);

    final content = Content();

    content.add(TextContent("titulo", "BENCHMARK DE COMPORTAMIENTOS"));

    final List<Content> comportamientos = [];
    for (final comp in datos) {
      final comportamientoContent = Content();
      comportamientoContent
        ..add(TextContent("nombre", comp.nombre))
        ..add(TextContent("benchmarkGeneral", comp.benchmarkGeneral));

      final List<Content> niveles = [];
      for (final nivelKey in ["E", "G", "M"]) {
        final nivel = comp.niveles[nivelKey];
        if (nivel != null) {
          niveles.add(Content()
            ..add(TextContent("nivel", nivelKey == "E" ? "Ejecutivo" : nivelKey == "G" ? "Gerente" : "Miembro"))
            ..add(TextContent("valor", nivel.valor.toStringAsFixed(2)))
            ..add(TextContent("interpretacion", nivel.interpretacion))
            ..add(TextContent("benchmarkPorCargo", nivel.benchmarkPorCargo))
            ..add(TextContent("sistemas", nivel.sistemasSeleccionados.join(", ")))
            ..add(TextContent("obs", nivel.obs)));
        }
      }

      comportamientoContent.add(ListContent("niveles", niveles));
      comportamientos.add(comportamientoContent);
    }

    content.add(ListContent("comportamientos", comportamientos));

    final d = await docx.generate(content);

    if (d != null) {
      final file = File(outputPath);
      await file.writeAsBytes(d);
      return file;
    } else {
      throw Exception("Error al generar el documento Word");
    }
  }
}
