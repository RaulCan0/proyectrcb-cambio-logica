class Comportamiento {
  String nombre;
  final double promedioEjecutivo;
  final double promedioGerente;
  final double promedioMiembro;
  final List<String> sistemas;
  final String? observaciones;
  final String? nivel;
  final String principioId;
  final String id;
  final String? cargo;

  Comportamiento({
    required this.nombre,
    required this.promedioEjecutivo,
    required this.promedioGerente,
    required this.promedioMiembro,
    required this.sistemas,
    this.observaciones,
    required this.nivel,
    required this.principioId,
    required this.id,
    required this.cargo,
  });
}
