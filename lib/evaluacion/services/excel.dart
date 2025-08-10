import 'dart:typed_data';
import 'package:applensys/evaluacion/services/pdf.dart';
import 'package:excel/excel.dart';

class ReporteExcelService {
  static Uint8List generarReporteExcel(List<ReporteComportamiento> datos) {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Reporte'];

    int rowIndex = 0;

    for (final comp in datos) {
      // Título del benchmark (con formato destacado)
      sheet.merge(CellIndex.indexByString("A${rowIndex + 1}"), CellIndex.indexByString("F${rowIndex + 1}"));
      final tituloCell = sheet.cell(CellIndex.indexByString("A${rowIndex + 1}"));
   

      final subtituloCell = sheet.cell(CellIndex.indexByString("A${rowIndex + 2}"));
      subtituloCell.value = TextCellValue(" ${comp.benchmarkGeneral}");
      subtituloCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
      );

      rowIndex += 3;

      // Encabezado (con formato destacado)
      final headers = ["Nivel", "Promedio", "Interpretación", "Benchmark por Cargo", "Sistemas", "Hallazgos"];
      for (int i = 0; i < headers.length; i++) {
        final headerCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
        headerCell.value = TextCellValue(headers[i]);
        headerCell.cellStyle = CellStyle(
          bold: true,
        );
      }

      rowIndex++;

      // Datos por nivel
      for (final nivelKey in ['E', 'G', 'M']) {
        final nivel = comp.niveles[nivelKey];
        if (nivel != null) {
          final nivelNombre = nivelKey == 'E'
              ? 'Ejecutivo'
              : nivelKey == 'G'
                  ? 'Gerente'
                  : 'Miembro';

          final row = [
            nivelNombre,
            nivel.promedio.toStringAsFixed(2),
            nivel.interpretacion,
            nivel.benchmarkPorCargo,
            nivel.sistemasSeleccionados.join(", "),
            nivel.obs,
          ];

          for (int i = 0; i < row.length; i++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
            cell.value = TextCellValue(row[i]);
            // Aplicar estilo de ajuste de texto para que el alto de la fila se ajuste
            cell.cellStyle = CellStyle(
              verticalAlign: VerticalAlign.Top,
              bold: true,
            );
          }

          rowIndex++;
        }
      }

      
    }

    // Ajustar automáticamente el ancho de las columnas al contenido
    _ajustarAnchoColumnas(sheet);

    return Uint8List.fromList(excel.encode()!);
  }

  /// Ajusta automáticamente el ancho de las columnas basado en el contenido
  static void _ajustarAnchoColumnas(Sheet sheet) {
    // Definir anchos para cada columna (en unidades de ancho Excel)
    final anchos = <int, double>{
      0: 12.0, // Nivel
      1: 10.0, // Promedio  
      2: 60.0, // Interpretación - más ancho para textos largos
      3: 50.0, // Benchmark por Cargo - más ancho para textos largos
      4: 30.0, // Sistemas - mediano
      5: 40.0, // Hallazgos - más ancho para textos largos
    };

    // Aplicar los anchos a las columnas usando setColumnWidth
    for (final entry in anchos.entries) {
      final colIndex = entry.key;
      final ancho = entry.value;
      sheet.setColumnWidth(colIndex, ancho);
    }
  }
}
