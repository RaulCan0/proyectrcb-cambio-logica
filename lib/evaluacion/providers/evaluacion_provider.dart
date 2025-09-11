
import 'package:flutter/material.dart';

class EvaluacionProvider extends ChangeNotifier {
  Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };

  Map<String, double> progresoAsociado = {};

  void actualizarTabla(String dimension, String categoria, Map<String, dynamic> dato) {
    if (!tablaDatos.containsKey(dimension)) {
      tablaDatos[dimension] = {};
    }
    if (!tablaDatos[dimension]!.containsKey(categoria)) {
      tablaDatos[dimension]![categoria] = [];
    }
    tablaDatos[dimension]![categoria]!.add(dato);
    notifyListeners();
  }

  void actualizarProgreso(String dimension, double progreso) {
    progresoAsociado[dimension] = progreso;
    notifyListeners();
  }

  void reiniciarDatos() {
    tablaDatos.clear();
    progresoAsociado.clear();
    notifyListeners();
  }
}