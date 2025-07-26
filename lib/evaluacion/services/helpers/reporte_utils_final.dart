// Cliente de autenticación para Google APIs
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
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
      final String comportamiento = dato['comportamiento'];
      final String cargo = dato['cargo'];
      final String dimension = dato['dimension'].toString();
      final double calificacion = double.tryParse(dato['calificacion'].toString()) ?? 0.0;
      final int redondeada = (calificacion % 1) >= 0.5 ? calificacion.ceil() : calificacion.floor();
      final List<String> sistemas = List<String>.from(dato['sistemas_asociados'] ?? []);
      final String hallazgo = dato['observacion'] ?? '';

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
            b['BENCHMARK DE COMPORTAMIENTOS']
                .toString()
                .trim()
                .startsWith(comportamiento.trim()) &&
            b['CARGO']
                .toString()
                .toLowerCase()
                .contains(cargo.toLowerCase().split(' ')[0]),
        orElse: () => {},
      );

      final String definicion = benchmarkData['BENCHMARK DE COMPORTAMIENTOS'] ?? '';
      final String benchmark = benchmarkData['BENCHMARK POR NIVEL'] ?? '';

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
        'Ejecutivos': mapaGrafico[r.comportamiento]?['Ejecutivos'] ?? 0,
        'Gerentes': mapaGrafico[r.comportamiento]?['Gerentes'] ?? 0,
        'Equipo': mapaGrafico[r.comportamiento]?['Equipo'] ??
                  mapaGrafico[r.comportamiento]?['Miembro'] ?? 0,
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
    buffer.writeln('<tr><th>Comportamiento</th><th>Definición</th><th>Nivel</th><th>Calificación</th><th>Resultado</th><th>Benchmark</th><th>Sistemas Asociados</th><th>Hallazgos</th></tr>');
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
    buffer.writeln('</table>');

    buffer.writeln('<h2>Detalles de Evaluación</h2>');
    buffer.writeln('<table border="1" cellspacing="0" cellpadding="4">');
    buffer.writeln('<tr><th>Asociado</th><th>Dimensión</th><th>Principio</th><th>Comportamiento</th><th>Observaciones</th><th>Sistemas Asociados</th></tr>');
    for (var dato in tablaDatos) {
      buffer.writeln('<tr>');
      buffer.writeln('<td>${dato['asociado_nombre']}</td>');
      buffer.writeln('<td>${dato['dimension']}</td>');
      buffer.writeln('<td>${dato['principio']}</td>');
      buffer.writeln('<td>${dato['comportamiento']}</td>');
      buffer.writeln('<td>${dato['observacion']}</td>');
      buffer.writeln('<td>${(dato['sistemas_asociados'] ?? []).join(", ")}</td>');
      buffer.writeln('</tr>');
    }
    buffer.writeln('</table></body></html>');

    // Guardar en almacenamiento interno (Documents) según plataforma
    final dir = await getApplicationDocumentsDirectory();
    String filePath = '';
    if (Platform.isAndroid || Platform.isIOS) {
      filePath = '${dir.path}/reporte_unificado.doc';
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      filePath = '${dir.path}/reporte_unificado.doc';
    } else {
      filePath = '${dir.path}/reporte_unificado.doc';
    }
    final file = File(filePath);
    await file.writeAsString(buffer.toString(), encoding: const Utf8Codec());

    // Subir automáticamente a Google Drive
    await subirReporteADrive(filePath);

    return file.path;
  }

  static Future<void> subirReporteADrive(String filePath) async {
    final googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);
    final account = await googleSignIn.signInSilently() ?? await googleSignIn.signIn();
    if (account == null) throw Exception('No se pudo autenticar con Google');
    final authHeaders = await account.authHeaders;
    final client = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(client);

    final fileToUpload = drive.File();
    fileToUpload.name = 'reporte_unificado.doc';
    final file = File(filePath);
    await driveApi.files.create(
      fileToUpload,
      uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
    );
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}