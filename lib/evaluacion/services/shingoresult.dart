import 'package:applensys/evaluacion/screens/shingo_result.dart';

class ShingoResumenServiceAuto {
  /// Genera el resumen de todas las categorías y subcategorías, calcula total.
  static List<ResumenCategoria> generarResumen(Map<String, ShingoResultData> hojas) {
    final List<ResumenCategoria> resumen = [];
    double totalPts = 0;
    int subcatCount = 0;

    // Contar total de subcategorías (si no hay, cuenta 1 por categoría principal)
    hojas.forEach((_, cat) {
      if (cat.subcategorias.isEmpty) {
        subcatCount++;
      } else {
        subcatCount += cat.subcategorias.length;
      }
    });
    final puntosPorSubcat = subcatCount > 0 ? 200 / subcatCount : 0;

    // Llenar resumen
    hojas.forEach((nombre, cat) {
      if (cat.subcategorias.isEmpty) {
        final puntos = cat.calificacion * puntosPorSubcat / 5;
        final porcentaje = puntosPorSubcat > 0 ? puntos / puntosPorSubcat * 100 : 0;
        totalPts += puntos;
        resumen.add(ResumenCategoria(
          categoria: nombre,
          puntos: puntos,
          porcentaje: porcentaje.toDouble(),
          esTotal: false,
        ));
      } else {
        cat.subcategorias.forEach((subnombre, subcat) {
        final puntos = (cat.calificacion * puntosPorSubcat / 5).toDouble();
final porcentaje = puntosPorSubcat > 0 ? (puntos / puntosPorSubcat * 100).toDouble() : 0.0;

          totalPts += puntos;
          resumen.add(ResumenCategoria(
            categoria: '$nombre > $subnombre',
            puntos: puntos,
            porcentaje: porcentaje,
            esTotal: false,
          ));
        });
      }
    });

    resumen.add(ResumenCategoria(
      categoria: 'TOTAL',
      puntos: totalPts,
      porcentaje: subcatCount > 0 ? totalPts / 200 * 100 : 0,
      esTotal: true,
    ));

    return resumen;
  }
}

class ResumenCategoria {
  final String categoria;
  final double puntos;
  final double porcentaje;
  final bool esTotal;

  ResumenCategoria({
    required this.categoria,
    required this.puntos,
    required this.porcentaje,
    this.esTotal = false,
  });
}
