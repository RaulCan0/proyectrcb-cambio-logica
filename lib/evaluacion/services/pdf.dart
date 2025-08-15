import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class NivelEvaluacion {
  final double valor;
  final String interpretacion;
  final String benchmarkPorCargo;
  final String obs;
  final List<String> sistemasSeleccionados;

  NivelEvaluacion({
    required this.valor,
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

    final headerStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
    final normalStyle = pw.TextStyle(fontSize: 9);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => pw.Container(),
      ),
    );

    bool tituloImpreso = false;

    for (final comp in datos) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (!tituloImpreso) ...[
                pw.Text("BENCHMARK DE COMPORTAMIENTOS", style: headerStyle),
                pw.SizedBox(height: 6),
              ],

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey700),
                  color: PdfColors.grey200,
                ),
                child: pw.Text(comp.benchmarkGeneral, style: normalStyle),
              ),

              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey700),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8),
                  1: const pw.FlexColumnWidth(0.8),
                  2: const pw.FlexColumnWidth(5),
                  3: const pw.FlexColumnWidth(5),
                  4: const pw.FlexColumnWidth(2),
                  5: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _celda("Nivel", isHeader: true),
                      _celda("Valor", isHeader: true),
                      _celda("Interpretación", isHeader: true),
                      _celda("Benchmark por Cargo", isHeader: true),
                      _celda("Sistemas", isHeader: true),
                      _celda("Hallazgos", isHeader: true),
                    ],
                  ),
                  for (final n in ["E", "G", "M"])
                    if (comp.niveles[n] != null)
                      pw.TableRow(
                        children: [
                          _celda(n == "E" ? "Ejecutivo" : n == "G" ? "Gerente" : "Miembro\nde\nEquipo"),
                          _celda(comp.niveles[n]!.valor.toStringAsFixed(2)),
                          _celda(comp.niveles[n]!.interpretacion),
                          _celda(comp.niveles[n]!.benchmarkPorCargo),
                          _celda(comp.niveles[n]!.sistemasSeleccionados.join(", ")),
                          _celda(comp.niveles[n]!.obs),
                        ],
                      ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("Resumen Gráfico", style: headerStyle)),
              pw.SizedBox(height: 6),
              _buildVerticalBarChart(comp),
            ],
          ),
        ),
      );

      tituloImpreso = true;
    }

    return pdf.save();
  }

  static pw.Widget _celda(String texto, {bool isHeader = false}) {
    final style = pw.TextStyle(
      fontSize: isHeader ? 10 : 9,
      fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(texto.isEmpty ? 'Sin datos' : texto, style: style),
    );
  }

  static pw.Widget _buildVerticalBarChart(ReporteComportamiento comp) {
    final labels = ['Ejecutivo', 'Gerente', 'Miembro'];
    final values = [
      comp.niveles['E']?.valor ?? 0,
      comp.niveles['G']?.valor ?? 0,
      comp.niveles['M']?.valor ?? 0,
    ];
    final colors = [PdfColors.orange, PdfColors.green, PdfColors.blue];

    return pw.Center(
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 4),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Stack(
                  alignment: pw.Alignment.center,
                  children: [
                    pw.Container(
                      height: values[i] * 20,
                      width: 18,
                      color: colors[i],
                    ),
                    pw.Text(
                      values[i].toStringAsFixed(2),
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(labels[i], style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
