import 'dart:typed_data';
import 'package:applensys/evaluacion/services/pdf.dart'; // ReporteComportamiento, NivelEvaluacion
import 'package:excel/excel.dart';

class ReporteExcelService {
  static Uint8List generarReporteExcel(List<ReporteComportamiento> datos) {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Reporte'];

    int rowIndex = 0;

    // Título global (una sola vez)
    sheet.merge(CellIndex.indexByString("A${rowIndex + 1}"), CellIndex.indexByString("F${rowIndex + 1}"));
    final tituloCell = sheet.cell(CellIndex.indexByString("A${rowIndex + 1}"));
    tituloCell.value = TextCellValue("BENCHMARK DE COMPORTAMIENTOS"); // <- sin const
    tituloCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText, // <- wrap correcto
    );
    sheet.setRowHeight(rowIndex, 22.0);
    rowIndex += 2;

    for (final comp in datos) {
      // Subtítulo por comportamiento
      sheet.merge(CellIndex.indexByString("A${rowIndex + 1}"), CellIndex.indexByString("F${rowIndex + 1}"));
      final subtituloCell = sheet.cell(CellIndex.indexByString("A${rowIndex + 1}"));
      subtituloCell.value = TextCellValue(comp.benchmarkGeneral);
      subtituloCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText, // <- wrap correcto
      );
      sheet.setRowHeight(rowIndex, 18.0);
      rowIndex += 2;

      // Encabezados
      final headers = ["Nivel", "Promedio", "Interpretación", "Benchmark por Cargo", "Sistemas", "Hallazgos"];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          textWrapping: TextWrapping.WrapText,
        );
      }
      sheet.setRowHeight(rowIndex, 18.0);
      rowIndex++;

      // Filas de datos (E, G, M)
      for (final nivelKey in const ['E', 'G', 'M']) {
        final nivel = comp.niveles[nivelKey];
        if (nivel == null) continue;

        final nivelNombre = switch (nivelKey) {
          'E' => 'Ejecutivo',
          'G' => 'Gerente',
          _ => 'Miembro',
        };

        final valores = <String>[
          nivelNombre,
          nivel.valor.toStringAsFixed(2),
          nivel.interpretacion,
          nivel.benchmarkPorCargo,
          nivel.sistemasSeleccionados.join(", "),
          nivel.obs,
        ];

        for (int col = 0; col < valores.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
          cell.value = TextCellValue(valores[col]);
          cell.cellStyle = CellStyle(
            verticalAlign: VerticalAlign.Top,
            horizontalAlign: col <= 1 ? HorizontalAlign.Center : HorizontalAlign.Left,
            textWrapping: TextWrapping.WrapText, // <- wrap correcto
            bold: false,
          );
        }

        sheet.setRowHeight(rowIndex, 18.0);
        rowIndex++;
      }

      rowIndex++; // espacio entre bloques
    }

    // Anchos de columnas (Interpretación/Benchmark más anchas)
    _ajustarAnchoColumnas(sheet);

    // Ajuste heurístico de alturas según contenido y anchos
    _ajustarAltosDeFilas(sheet, 0, rowIndex - 1);

    return Uint8List.fromList(excel.encode()!);
  }

  static void _ajustarAnchoColumnas(Sheet sheet) {
    // 0: Nivel | 1: Promedio | 2: Interpretación | 3: Benchmark por Cargo | 4: Sistemas | 5: Hallazgos
    final anchos = <int, double>{
      0: 12.0,
      1: 10.0,
      2: 80.0, // más ancho
      3: 80.0, // más ancho
      4: 24.0,
      5: 36.0,
    };
    for (final e in anchos.entries) {
      sheet.setColumnWidth(e.key, e.value);
    }
  }

  static void _ajustarAltosDeFilas(Sheet sheet, int fromRow, int toRow) {
    // Aprox. caracteres por línea según ancho de columna
    final colChars = <int, int>{
      0: 10,  // Nivel
      1: 8,   // Promedio
      2: 70,  // Interpretación
      3: 70,  // Benchmark por Cargo
      4: 20,  // Sistemas
      5: 30,  // Hallazgos
    };

    for (int r = fromRow; r <= toRow; r++) {
      int maxLines = 1;

      for (int c = 0; c <= 5; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
        final val = cell.value;

        // Convierte a String de forma segura
        final text = (val is TextCellValue) ? (val.value) : (val?.toString() ?? '');
        if ((text is String) && text.isEmpty) continue;

        // Respeta saltos de línea y longitudes
        final piezas = (text is String ? text : text.toString()).split('\n').where((s) => s.trim().isNotEmpty).toList();
        int linesForCell = 0;

        for (final p in piezas) {
          final chars = p.trim().length;
          final int perLine = (colChars[c] ?? 30); // entero
          final int needed = (chars / perLine).ceil(); // entero
          linesForCell += (needed < 1 ? 1 : needed);
        }
        if (linesForCell == 0) linesForCell = 1;

        if (linesForCell > maxLines) maxLines = linesForCell;
      }

      final double height = 18.0 + 14.0 * (maxLines - 1);
      sheet.setRowHeight(r, height);
    }
  }
}
