import 'dart:io';
import 'package:flutter/services.dart';
import 'package:docx_template/docx_template.dart';
import 'package:applensys/evaluacion/services/pdf.dart'; // ReporteComportamiento

class ReporteWordService {
  static Future<File> generarReporteWord(
    List<ReporteComportamiento> datos,
    String outputPath,
    [List<String>? recomendaciones]
  ) async {
    // Leer el template desde los assets usando rootBundle
    final templateBytes = await rootBundle.load('assets/template.docx');
    final docx = await DocxTemplate.fromBytes(templateBytes.buffer.asUint8List());

    final content = Content();
    content.add(TextContent("titulo", "BENCHMARK DE COMPORTAMIENTOS"));

    final List<Content> comportamientos = [];
    for (int i = 0; i < datos.length; i++) {
      final comp = datos[i];
      final comportamientoContent = Content();
      comportamientoContent
        ..add(TextContent("nombre", comp.nombre))
        ..add(TextContent("benchmarkGeneral", comp.benchmarkGeneral));

      final List<Content> niveles = [];
      for (final nivelKey in ["E", "G", "M"]) {
        final nivel = comp.niveles[nivelKey];
        if (nivel != null) {
          niveles.add(
            Content()
              ..add(TextContent("nivel", nivelKey == "E" ? "Ejecutivo" : nivelKey == "G" ? "Gerente" : "Miembro"))
              ..add(TextContent("valor", nivel.valor.toStringAsFixed(2)))
              ..add(TextContent("interpretacion", nivel.interpretacion))
              ..add(TextContent("benchmarkPorCargo", nivel.benchmarkPorCargo))
              ..add(TextContent("sistemas", nivel.sistemasSeleccionados.join(", ")))
              ..add(TextContent("obs", nivel.obs))
          );
        }
      }
      comportamientoContent.add(ListContent("niveles", niveles));

      // Agregar recomendación si existe
      if (recomendaciones != null && recomendaciones.length > i) {
        comportamientoContent.add(TextContent("recomendacion", recomendaciones[i]));
      }

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
