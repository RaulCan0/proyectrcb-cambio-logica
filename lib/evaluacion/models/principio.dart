
import 'comportamiento.dart';

class Principio {
  final String id;
  final String dimensionId;
  final String nombre;
  final double promedioGeneral;
  final double promedioEjecutivo;
  final double promedioGerente;
  final double promedioMiembro;
  final List<Comportamiento> comportamientos;

  Principio({
    required this.id,
    required this.dimensionId,
    required this.nombre,
    required this.promedioGeneral,
    required this.promedioEjecutivo,
    required this.promedioGerente,
    required this.promedioMiembro,
    required this.comportamientos,
  });
}
