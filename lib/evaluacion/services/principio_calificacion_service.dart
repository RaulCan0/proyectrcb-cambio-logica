// Servicio para acumular calificaciones por principio y calcular promedios por cargo.
// Cada principio mantiene la suma y el conteo de valores por nivel de cargo,
// permitiendo obtener promedios sin promediar promedios de comportamientos.

class _Acumulador {
  double suma = 0;
  int conteo = 0;
}

class PrincipioCalificacionService {
  final Map<String, Map<String, _Acumulador>> _datos = {};

  /// Registra una calificación asociada a un [principio] y [cargo].
  /// [valor] representa la calificación numérica dada.
  void registrar({
    required String principio,
    required String cargo,
    required double valor,
  }) {
    final nivel = _nivelDesdeCargo(cargo);
    if (nivel == null) return;

    final cargoMap = _datos.putIfAbsent(principio, () => {});
    final acumulador = cargoMap.putIfAbsent(nivel, () => _Acumulador());
    acumulador.suma += valor;
    acumulador.conteo += 1;
  }

  /// Retorna un mapa con el promedio por cargo para cada principio
  /// registrado. Las llaves externas son el nombre del principio y
  /// las internas los niveles de cargo ('E', 'G', 'M').
  Map<String, Map<String, double>> obtenerPromedios() {
    final Map<String, Map<String, double>> resultado = {};
    _datos.forEach((principio, cargos) {
      resultado[principio] = {};
      cargos.forEach((nivel, acumulador) {
        resultado[principio]![nivel] =
            acumulador.conteo == 0 ? 0.0 : acumulador.suma / acumulador.conteo;
      });
    });
    return resultado;
  }

  String? _nivelDesdeCargo(String cargo) {
    final c = cargo.toLowerCase();
    if (c.contains('ejecutivo')) return 'E';
    if (c.contains('gerente')) return 'G';
    if (c.contains('miembro')) return 'M';
    return null;
  }
}

