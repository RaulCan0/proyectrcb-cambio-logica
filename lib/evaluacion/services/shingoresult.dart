

class ShingoResumenServiceAuto {
  static List<ResumenCategoria> generarResumen() {
    final List<ResumenCategoria> resumen = [];
    double totalPts = 0;

    final hojas = ShingoResultStore.resultados;

    for (final entry in hojas.entries) {
      final nombre = entry.key;
      final cal = entry.value.calificacion;
      final puntos = cal * 8;
      final porcentaje = puntos / 40 * 100;
      totalPts += puntos;

      resumen.add(ResumenCategoria(
        categoria: nombre,
        puntos: puntos.toDouble(),
        porcentaje: porcentaje,
        esTotal: false,
      ));
    }

    resumen.add(ResumenCategoria(
      categoria: 'TOTAL',
      puntos: totalPts,
      porcentaje: totalPts / 200 * 100,
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

class ShingoResultData {
  final int calificacion;
  ShingoResultData({this.calificacion = 0});
}

class ShingoResultStore {
  static final Map<String, ShingoResultData> resultados = {
    'seguridad/medio/ambiente/moral': ShingoResultData(),
    'satisfacción del cliente': ShingoResultData(),
    'calidad': ShingoResultData(),
    'costo/productividad': ShingoResultData(),
    'entregas': ShingoResultData(),
  };
}