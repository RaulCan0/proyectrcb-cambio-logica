import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CargoEvaluacion {
  final double promedio;
  final String interpretacion;
  final String benchmarkPorCargo;
  final String obs;
  final List<String> sistemasSeleccionados;

  CargoEvaluacion({
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
  final Map<String, CargoEvaluacion> cargos;

  ReporteComportamiento({
    required this.nombre,
    required this.benchmarkGeneral,
    required this.cargos,
  });
}

class ReportePdfService {
  static Future<Uint8List> generarReportePdf(List<ReporteComportamiento> datos) async {
    final pdf = pw.Document();

    // Estilos (mismas fuentes; no aumentamos tamaño, solo redistribuimos ancho de columnas)
    final txtSmall = pw.TextStyle(fontSize: 9);
    final txtNormal = pw.TextStyle(fontSize: 10);
    final headerStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    // Hoja 1 vacía horizontal
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => pw.Container(),
      ),
    );

    bool tituloImpreso = false; // Mostrar el título global solo una vez

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

              // Benchmark general del comportamiento (mantener por comportamiento)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey700),
                  color: PdfColors.grey200,
                ),
                child: pw.Text(comp.benchmarkGeneral, style: txtNormal),
              ),

              pw.SizedBox(height: 10),

              // Encabezado
              _fila(
                cargo: "Cargo",
                promedio: "Promedio",
                interp: "Interpretación",
                benchmark: "Benchmark por Cargo",
                sistemas: "Sistemas",
                hallazgos: "Hallazgos",
                isHeader: true,
                txtSmall: txtSmall,
              ),

              // Filas por nivel
              for (final n in const ["E", "G", "M"])
                if (comp.cargos[n] != null)
                  _fila(
                    cargo: n == "E" ? "Ejecutivo" : n == "G" ? "Gerente" : "Miembro",
                    promedio: comp.cargos[n]!.promedio.toStringAsFixed(2),
                    interp: comp.cargos[n]!.interpretacion,
                    benchmark: comp.cargos[n]!.benchmarkPorCargo,
                    sistemas: comp.cargos[n]!.sistemasSeleccionados.join(", "),
                    hallazgos: comp.cargos[n]!.obs,
                    txtSmall: txtSmall,
                  ),

              pw.SizedBox(height: 14),

              // Gráfico de barras compacto
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

  /// Distribución de anchos (solo ancho, misma fuente):
  /// Cargo(1) | Promedio(1) | Interpretación(8) | Benchmark(8) | Sistemas(1) | Hallazgos(1)
  static pw.Widget _fila({
    required String cargo,
    required String promedio,
    required String interp,
    required String benchmark,
    required String sistemas,
    required String hallazgos,
    bool isHeader = false,
    required pw.TextStyle txtSmall,
  }) {
    final style = pw.TextStyle(
      fontSize: isHeader ? 10 : 9,
      fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    pw.Widget plano(String texto) {
      final items = texto.contains('\n')
          ? texto.split('\n')
          : texto.split(',').map((e) => e.trim()).toList();
      final contenido = items.where((t) => t.isNotEmpty).join(', ');
      return pw.Text(contenido.isEmpty ? 'Sin datos' : contenido, style: style);
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 1, child: pw.Text(cargo, style: style, textAlign: pw.TextAlign.center)),
          pw.Expanded(flex: 1, child: pw.Text(promedio, style: style, textAlign: pw.TextAlign.center)),
          pw.Expanded(flex: 5, child: pw.Text(interp, style: style)),
          pw.Expanded(flex: 5, child: pw.Text(benchmark, style: style)),
          pw.Expanded(flex: 2, child: plano(sistemas)),
          pw.Expanded(flex: 1, child: plano(hallazgos)),
        ],
      ),
    );
  }

  /// Barras más juntas (menos padding, ancho reducido)
  static pw.Widget _buildVerticalBarChart(ReporteComportamiento comp) {
    final labels = ['Ejecutivo', 'Gerente', 'Miembro'];
    final values = [
      comp.cargos['E']?.promedio ?? 0,
      comp.cargos['G']?.promedio ?? 0,
      comp.cargos['M']?.promedio ?? 0,
    ];
    final colors = [PdfColors.orange, PdfColors.green, PdfColors.blue];

    return pw.Center(
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 1), // juntas
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  height: values[i] * 20, // escala vertical
                  width: 14,              // barra un poco más angosta para pegarlas
                  color: colors[i],
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
