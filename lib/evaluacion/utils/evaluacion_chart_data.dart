import 'dart:ui';

import 'package:applensys/evaluacion/charts/scatter_bubble_chart.dart';
import 'package:applensys/evaluacion/models/comportamiento.dart';
import 'package:applensys/evaluacion/models/principio.dart';
import 'package:applensys/evaluacion/models/dimension.dart';

class EvaluacionChartData {
  static List<Dimension> buildDimensionesChartData(List<Map<String, dynamic>> dimensionesRaw) {
    return dimensionesRaw.map((dim) {
      List<Principio> principios = (dim['principios'] as List).map((pri) {
        List<Comportamiento> comportamientos = (pri['comportamientos'] as List).map((comp) {
          return Comportamiento(
            nombre: comp['nombre'],
            promedioEjecutivo: (comp['ejecutivo'] ?? 0.0).toDouble(),
            promedioGerente: (comp['gerente'] ?? 0.0).toDouble(),
            promedioMiembro: (comp['miembro'] ?? 0.0).toDouble(),
            sistemas: List<String>.from(comp['sistemas'] ?? []),
            cargo: comp['cargo'] ?? '',
            principioId: '',
            id: '',
            nivel: null,
          );
        }).toList();

        return Principio(
          id: pri['id'] ?? '',
          dimensionId: dim['id'] ?? '',
          nombre: pri['nombre'],
          promedioGeneral: (pri['promedio'] ?? 0.0).toDouble(),
          comportamientos: comportamientos,
        );
      }).toList();

      return Dimension(
        id: dim['id'].toString(),
        nombre: dim['nombre'],
        promedioGeneral: (dim['promedio'] ?? 0.0).toDouble(),
        principios: principios,
      );
    }).toList();
  }

  static List<Principio> extractPrincipios(List<Dimension> dimensiones) {
    return dimensiones.expand((d) => d.principios).toList();
  }

  static List<Comportamiento> extractComportamientos(List<Dimension> dimensiones) {
    return dimensiones
        .expand((d) => d.principios)
        .expand((p) => p.comportamientos)
        .toList();
  }

  /// 🟢 NUEVO: Generar los datos del gráfico de burbujas con y de 1 a 10
  static List<ScatterData> buildScatterData(List<Dimension> dimensiones) {
    final principios = extractPrincipios(dimensiones);

    return principios.asMap().entries.map((entry) {
      final index = entry.key;
      final principio = entry.value;

      return ScatterData(
        x: principio.promedioGeneral,
        y: (index + 1).toDouble(), // 1 al 10

        color: const Color.fromARGB(255, 19, 32, 43), seriesName: '', radius: 5, principleNames: '',
      );
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> cargarPromediosSistemas([Map<String, Map<String, List<Map<String, dynamic>>>>? tablaData]) async {
    // Use provided data or return empty list since cache is eliminated
    final tabla = tablaData ?? <String, Map<String, List<Map<String, dynamic>>>>{};
    final Map<String, List<double>> acumulador = {};

    tabla.forEach((_, submap) {
      submap.values.expand((rows) => rows).forEach((item) {
        final sistema = item['sistema'] as String? ?? '';
        final raw = item['valor'];

        final valor = raw is num
            ? raw.toDouble()
            : double.tryParse(raw.toString()) ?? 0.0;

        if (sistema.isNotEmpty) {
          acumulador.putIfAbsent(sistema, () => []).add(valor);
        }
      });
    });

    return acumulador.entries.map((e) {
      final lista = e.value;
      final suma = lista.fold<double>(0, (a, b) => a + b);
      final promedio = lista.isNotEmpty ? suma / lista.length : 0.0;
      return {
        'sistema': e.key,
        'valor': promedio,
      };
    }).toList();
  }
}
