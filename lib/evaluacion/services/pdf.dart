import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class NivelEvaluacion {
  final double promedio;
  final String interpretacion;
  final String benchmarkPorCargo;
  final String obs;
  final List<String> sistemasSeleccionados;

  NivelEvaluacion({
    required this.promedio,
    required this.interpretacion,
    required this.benchmarkPorCargo,
    required this.obs,
    required this.sistemasSeleccionados,
  });
}

class ReporteComportamiento {
  final String nombre;
  final String benchmarkGeneral;
  final Map<String, NivelEvaluacion> niveles;

  ReporteComportamiento({
    required this.nombre,
    required this.benchmarkGeneral,
    required this.niveles,
  });
}

class ReportePdfService {
  static Future<Uint8List> generarReportePdf(List<ReporteComportamiento> datos) async {
    final pdf = pw.Document();

    final textStyle = pw.TextStyle(fontSize: 10);
    final headerStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    // Hoja 1 vacía horizontal
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => pw.Container(),
      ),
    );

    for (final comp in datos) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("BENCHMARK DE COMPORTAMIENTOS", style: headerStyle),
              pw.SizedBox(height: 4),
              pw.Text("${comp.nombre}: ${comp.benchmarkGeneral}", style: textStyle),
              pw.SizedBox(height: 12),
              _fila("Nivel", "Promedio", "Interpretación", "Benchmark por Cargo", "Sistemas", "Hallazgos", isHeader: true),
              for (final nivel in ["E", "G", "M"])
                if (comp.niveles[nivel] != null)
                  _fila(
                    nivel == "E" ? "Ejecutivo" : nivel == "G" ? "Gerente" : "Miembro",
                    comp.niveles[nivel]!.promedio.toStringAsFixed(2),
                    comp.niveles[nivel]!.interpretacion,
                    comp.niveles[nivel]!.benchmarkPorCargo,
                    comp.niveles[nivel]!.sistemasSeleccionados.join(", "),
                    comp.niveles[nivel]!.obs,
                  ),
              pw.SizedBox(height: 20),
              pw.Text("Resumen Gráfico", style: headerStyle),
              pw.SizedBox(height: 10),
              _buildVerticalBarChart(comp),
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _fila(String nivel, String promedio, String interp, String benchmark, String sistemas, String hallazgos, {bool isHeader = false}) {
    final style = pw.TextStyle(
      fontSize: isHeader ? 10 : 9,
      fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    pw.Widget mostrarTextoPlano(String texto) {
      final items = texto.contains('\n')
          ? texto.split('\n')
          : texto.split(',').map((e) => e.trim()).toList();

      final contenido = items.where((item) => item.trim().isNotEmpty).join(', ');

      return pw.Text(contenido.isEmpty ? 'Sin datos' : contenido, style: style);
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 1, child: pw.Text(nivel, style: style, textAlign: pw.TextAlign.center)),
          pw.Expanded(flex: 1, child: pw.Text(promedio, style: style, textAlign: pw.TextAlign.center)),
          pw.Expanded(flex: 3, child: pw.Text(interp, style: style)),
          pw.Expanded(flex: 3, child: pw.Text(benchmark, style: style)),
          pw.Expanded(flex: 2, child: mostrarTextoPlano(sistemas)),
          pw.Expanded(flex: 2, child: mostrarTextoPlano(hallazgos)),
        ],
      ),
    );
  }

  static pw.Widget _buildVerticalBarChart(ReporteComportamiento comp) {
    final labels = ['Ejecutivo', 'Gerente', 'Miembro'];
    final values = [
      comp.niveles['E']?.promedio ?? 0,
      comp.niveles['G']?.promedio ?? 0,
      comp.niveles['M']?.promedio ?? 0,
    ];
    final colors = [PdfColors.red, PdfColors.green, PdfColors.blue];

    return pw.Center(
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  height: values[i] * 20,
                  width: 15,
                  color: colors[i],
                ),
                pw.SizedBox(height: 4),
                pw.Text(labels[i], style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
