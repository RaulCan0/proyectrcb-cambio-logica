class CalificacionAdapter {
  static Map<String, Map<String, List<Map<String, dynamic>>>> toTablaDatos(
      List<Map<String, dynamic>> datos) {
    final result = {
      'Dimensión 1': <String, List<Map<String, dynamic>>>{},
      'Dimensión 2': <String, List<Map<String, dynamic>>>{},
      'Dimensión 3': <String, List<Map<String, dynamic>>>{},
    };

    for (final fila in datos) {
      final dimIdRaw = fila['id_dimension'];
      final dimId = dimIdRaw is int ? dimIdRaw.toString() : (dimIdRaw ?? '').toString();
      final dimensionKey = 'Dimensión $dimId';
      final evalId = fila['id_evaluacion'].toString();

      final sistemasRaw = fila['sistemas'];
      final sistemasList = (sistemasRaw is List)
          ? sistemasRaw.whereType<String>().toList()
          : <String>[];

      final puntaje = (fila['puntaje'] ?? fila['valor'] ?? 0);
      final intValor = (puntaje is num)
          ? puntaje.toInt()
          : int.tryParse(puntaje.toString()) ?? 0;

      result[dimensionKey]!.putIfAbsent(evalId, () => []).add({
        'principio': fila['principio'],
        'comportamiento': fila['comportamiento'],
        'cargo': (fila['cargo'] ?? '').toString(),
        'cargo_raw': (fila['cargo'] ?? '').toString(),
        'valor': intValor,
        'sistemas': sistemasList,
        'dimension_id': dimId,
        'asociado_id': fila['id_asociado'],
        'observaciones': fila['observaciones'] ?? '',
        'evidencia_url': fila['evidencia_url'],
        'fecha_evaluacion': fila['fecha_evaluacion'],
      });
    }

    return result;
  }
}
