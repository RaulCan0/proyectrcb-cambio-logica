/*import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ReporteComportamiento {
  final String comportamiento;
  final String definicion;
  final String cargo;
  final int calificacion;
  final List<String> sistemasAsociados;
  final String resultado;
  final String benchmark;
  final String hallazgos;
  final Map<String, double> grafico;

  ReporteComportamiento({
    required this.comportamiento,
    required this.definicion,
    required this.cargo,
    required this.calificacion,
    required this.sistemasAsociados,
    required this.resultado,
    required this.benchmark,
    required this.hallazgos,
    required this.grafico,
  });

  Map<String, dynamic> toJson() => {
        'comportamiento': comportamiento,
        'definicion': definicion,
        'cargo': cargo,
        'calificacion': calificacion,
        'sistemas_asociados': sistemasAsociados,
        'resultado': resultado,
        'benchmark': benchmark,
        'hallazgos': hallazgos,
        'grafico': grafico,
      };
}

class ReporteUtils {
  static Future<List<ReporteComportamiento>> generarReporteDesdeTablaDatos(
    List<Map<String, dynamic>> tablaDatos,
    List<Map<String, dynamic>> t1,
    List<Map<String, dynamic>> t2,
    List<Map<String, dynamic>> t3,
  ) async {
    List<ReporteComportamiento> reporte = [];
    Map<String, Map<String, double>> mapaGrafico = {};

    for (var dato in tablaDatos) {
      final comportamiento = dato['comportamiento'];
      final cargo = dato['cargo'];
      final dimension = dato['dimension'].toString();
      final calificacion = double.tryParse(dato['calificacion'].toString()) ?? 0.0;
      final redondeada = (calificacion % 1) >= 0.5 ? calificacion.ceil() : calificacion.floor();
      final sistemas = List<String>.from(dato['sistemas_asociados'] ?? []);
      final hallazgo = dato['observacion'] ?? '';

      List<Map<String, dynamic>> fuente = [];
      if (dimension == "1") {
        fuente = t1;
      } else if (dimension == "2") {
        fuente = t2;
      } else if (dimension == "3") {
        fuente = t3;
      }

      final benchmarkData = fuente.firstWhere(
        (b) =>
            b['COMPORTAMIENTO'].toString().trim().toLowerCase() ==
                comportamiento.toString().trim().toLowerCase() &&
            b['NIVEL'].toString().toLowerCase() ==
                cargo.toString().trim().toLowerCase(),
        orElse: () => {},
      );

      final definicion = benchmarkData['BENCHMARK'] ?? '';
      final benchmark = benchmarkData['BENCHMARK POR NIVEL'] ?? '';

      String resultado = '';
      switch (redondeada) {
        case 1:
          resultado = benchmarkData['C1'] ?? '';
          break;
        case 2:
          resultado = benchmarkData['C2'] ?? '';
          break;
        case 3:
          resultado = benchmarkData['C3'] ?? '';
          break;
        case 4:
          resultado = benchmarkData['C4'] ?? '';
          break;
        case 5:
          resultado = benchmarkData['C5'] ?? '';
          break;
      }

      mapaGrafico.putIfAbsent(comportamiento, () => {});
      mapaGrafico[comportamiento]![cargo] = calificacion;

      reporte.add(ReporteComportamiento(
        comportamiento: comportamiento,
        definicion: definicion,
        cargo: cargo,
        calificacion: redondeada,
        sistemasAsociados: sistemas.toSet().toList(),
        resultado: resultado,
        benchmark: benchmark,
        hallazgos: hallazgo,
        grafico: {},
      ));
    }

    for (var r in reporte) {
      r.grafico.addAll({
        'Ejecutivo': mapaGrafico[r.comportamiento]?['EJECUTIVO'] ?? 0,
        'Gerente': mapaGrafico[r.comportamiento]?['GERENTE'] ?? 0,
        'Miembro': mapaGrafico[r.comportamiento]?['MIEMBRO DE EQUIPO'] ?? 0,
      });
    }

    return reporte;
  }

  static Future<String> exportReporteWordUnificado(
    List<Map<String, dynamic>> tablaDatos,
    List<Map<String, dynamic>> t1,
    List<Map<String, dynamic>> t2,
    List<Map<String, dynamic>> t3,
  ) async {
    final reporte = await generarReporteDesdeTablaDatos(tablaDatos, t1, t2, t3);
    final buffer = StringBuffer();
    buffer.writeln('<html><body><h1>Resumen de Comportamientos Evaluados</h1>');
    buffer.writeln('<table border="1" cellspacing="0" cellpadding="4">');
    buffer.writeln('<tr><th>Comportamiento</th><th>Definición</th><th>Cargo</th><th>Calificación</th><th>Resultado</th><th>Benchmark</th><th>Sistemas Asociados</th><th>Hallazgos</th></tr>');
    
    for (var r in reporte) {
      buffer.writeln('<tr>');
      buffer.writeln('<td>${r.comportamiento}</td>');
      buffer.writeln('<td>${r.definicion}</td>');
      buffer.writeln('<td>${r.cargo}</td>');
      buffer.writeln('<td>${r.calificacion}</td>');
      buffer.writeln('<td>${r.resultado}</td>');
      buffer.writeln('<td>${r.benchmark}</td>');
      buffer.writeln('<td>${r.sistemasAsociados.join(", ")}</td>');
      buffer.writeln('<td>${r.hallazgos}</td>');
      buffer.writeln('</tr>');
    }
    buffer.writeln('</table></body></html>');

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reporte_unificado.doc');
    await file.writeAsString(buffer.toString(), encoding: Utf8Codec());
    return file.path;
  }
}*/
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ReporteComportamiento {
  final String comportamiento;
  final String definicion;
  final Map<int, int> niveles; // nivel -> calificacion
  final List<String> sistemaSeleccionados;
  final Map<String, String> resultados; // nivelKey -> resultado
  final String benchmark;
  final String hallazgos;

  ReporteComportamiento({
    required this.comportamiento,
    required this.definicion,
    required this.niveles,
    required this.sistemaSeleccionados,
    required this.resultados,
    required this.benchmark,
    required this.hallazgos,
  });

  Map<String, dynamic> toJson() => {
        'comportamiento': comportamiento,
        'definicion': definicion,
        'niveles': niveles,
        'sistemas': sistemaSeleccionados,
        'resultados': resultados,
        'benchmark': benchmark,
        'hallazgos': hallazgos,
      };
}

class ReporteUtils {
  /// Genera lista de ReporteComportamiento con 3 niveles por comportamiento
  static Future<List<ReporteComportamiento>> generarReporte(
    List<Map<String, dynamic>> datos,
    List<Map<String, dynamic>> t1,
    List<Map<String, dynamic>> t2,
    List<Map<String, dynamic>> t3,
  ) async {
    // Map comportamiento -> {nivel -> List<double>}
    final Map<String, Map<int, List<double>>> raw = {};
    final Map<String, Map<int, List<String>>> sysRaw = {};
    final Map<String, String> definiciones = {};
    for (var d in datos) {
      final comp = d['comportamiento'].toString();
      final nivel = int.tryParse(d['nivel'].toString()) ?? 0;
      final cal = double.tryParse(d['calificacion'].toString()) ?? 0.0;
      final sisList = List<String>.from(d['sistemas_asociados'] ?? []);
      raw.putIfAbsent(comp, () => {1: [], 2: [], 3: []});
      raw[comp]![nivel]?.add(cal);
      sysRaw.putIfAbsent(comp, () => {1: [], 2: [], 3: []});
      sysRaw[comp]![nivel]?.addAll(sisList);
      // Definicion y benchmark solo una vez
      if (!definiciones.containsKey(comp)) {
        final dim = d['dimension'].toString();
        final source = dim == '1' ? t1 : dim == '2' ? t2 : t3;
        final bm = source.firstWhere(
          (b) => b['COMPORTAMIENTO'].toString().trim() == comp,
          orElse: () => {},
        );
        definiciones[comp] = bm['DEFINICION']?.toString() ?? '';
      }
    }

    return raw.entries.map((entry) {
      final comp = entry.key;
      final niveles = entry.value.map((lv, scores) {
        final avg = scores.isNotEmpty
            ? scores.reduce((a, b) => a + b) / scores.length
            : 0;
        return MapEntry(lv, avg.round());
      });
      final sistemas = sysRaw[comp]!.values
          .expand((list) => list)
          .toSet()
          .toList();
      // Determinar benchmark genérico
      final bm = t1
          .followedBy(t2)
          .followedBy(t3)
          .firstWhere(
            (b) => b['COMPORTAMIENTO'].toString().trim() == comp,
            orElse: () => {},
          )['BENCHMARK']
          ?.toString() ?? '';
      // Resultados por nivel
      final resultados = Map.fromEntries(
        niveles.entries.map((e) => MapEntry('Nivel \${e.key}',
            'C\${e.key}: acumulado \${e.value}')),
      );

      return ReporteComportamiento(
        comportamiento: comp,
        definicion: definiciones[comp]!,
        niveles: niveles,
        sistemaSeleccionados: sistemas,
        resultados: resultados,
        benchmark: bm,
        hallazgos: '',
      );
    }).toList();
  }

  /// Exporta reporte en formato HTML horizontal sin acentos
  static Future<String> exportarHtml(
    List<Map<String, dynamic>> datos,
    List<Map<String, dynamic>> t1,
    List<Map<String, dynamic>> t2,
    List<Map<String, dynamic>> t3,
  ) async {
    final reporte = await generarReporte(datos, t1, t2, t3);
    final buf = StringBuffer();
    buf.writeln('<!DOCTYPE html>');
    buf.writeln('<html><head>');
    buf.writeln('<meta charset="UTF-8"><title>Reporte Evaluacion</title>');
    buf.writeln('</head><body>');
    buf.writeln('<h1>Resumen Horizontal de Comportamientos</h1>');
    buf.writeln('<table border="1" cellSpacing="0" cellPadding="4">');
    // Encabezados horizontales
    buf.writeln('<tr>');
    buf.writeln('<th>Comportamiento</th>');
    buf.writeln('<th>Definicion</th>');
    buf.writeln('<th>Nivel 1</th>');
    buf.writeln('<th>Nivel 2</th>');
    buf.writeln('<th>Nivel 3</th>');
    buf.writeln('<th>Benchmark</th>');
    buf.writeln('<th>Sistemas</th>');
    buf.writeln('</tr>');
    
    for (var r in reporte) {
      buf.writeln('<tr>');
      buf.writeln('<td>${r.comportamiento}</td>');
      buf.writeln('<td>${r.definicion}</td>');
      buf.writeln('<td>\${r.niveles[1]}</td>');
      buf.writeln('<td>\${r.niveles[2]}</td>');
      buf.writeln('<td>\${r.niveles[3]}</td>');
      buf.writeln('<td>${r.benchmark}</td>');
      buf.writeln('<td>${r.sistemaSeleccionados.join(", ")}</td>');
      buf.writeln('</tr>');
    }
    buf.writeln('</table>');
    buf.writeln('</body></html>');

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reporte_evaluacion.html');
    await file.writeAsString(buf.toString(), encoding: Utf8Codec());
    return file.path;
  }}