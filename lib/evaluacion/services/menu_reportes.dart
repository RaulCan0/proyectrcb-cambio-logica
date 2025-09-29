import 'package:applensys/evaluacion/services/pdf.dart';
import 'package:applensys/evaluacion/services/excel.dart';
import 'package:applensys/evaluacion/services/word.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReporteService {
  static Future<void> generarYSubirReporte({
    required String formato,
    required List<ReporteComportamiento> datos,
    required String nombreEmpresa,
    required List<String> recomendaciones,
    required Function(String mensaje) onStatus,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final nombreEmpresaSan = nombreEmpresa.replaceAll(' ', '_');
    String fileName;
    File file;
    try {
      onStatus('Generando reporte...');
      if (formato.contains('WORD')) {
        fileName = 'Reporte_$nombreEmpresaSan.docx';
        file = await ReporteWordService.generarReporteWord(datos, '${directory.path}/$fileName');
      } else if (formato.contains('PDF')) {
        fileName = 'Reporte_$nombreEmpresaSan.pdf';
        final pdfBytes = await ReportePdfService.generarReportePdf(datos, recomendaciones);
        file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
      } else {
        fileName = 'Reporte_$nombreEmpresaSan.xlsx';
        final excelBytes = ReporteExcelService.generarReporteExcel(datos);
        file = File('${directory.path}/$fileName');
        await file.writeAsBytes(excelBytes);
      }
      // Subir a Supabase Storage
      try {
        final supabase = Supabase.instance.client;
        await supabase.storage.from('reportes').upload(fileName, file);
        onStatus('Reporte generado y subido exitosamente');
      } catch (e) {
        onStatus('Reporte generado pero error al subir: $e');
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      onStatus('Error al generar reporte: $e');
    }
  }
}