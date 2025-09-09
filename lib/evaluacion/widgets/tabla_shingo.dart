import 'package:flutter/material.dart';
import '../screens/shingo_result.dart';


class TablaResultadosShingo extends StatefulWidget {
  final Map<String, ShingoResultData> resultados;

  const TablaResultadosShingo({super.key, required this.resultados});

  @override
  State<TablaResultadosShingo> createState() => _TablaResultadosShingoState();
}

class _TablaResultadosShingoState extends State<TablaResultadosShingo> {
  @override
  Widget build(BuildContext context) {
    final resumen = ShingoResumenService.generarResumen(widget.resultados);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Pts obtenidos')),
          DataColumn(label: Text('% obtenido')),
        ],
        rows: resumen.map((r) {
          return DataRow(
            color: r.esTotal ? WidgetStateProperty.all(const Color.fromARGB(255, 57, 103, 141)) : null,
            cells: [
              DataCell(
                Text(
                  r.categoria,
                  style: r.esTotal ? const TextStyle(color: Colors.white) : null,
                ),
              ),
                DataCell(
                  Container(
                    width: 90,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r.puntos.toStringAsFixed(0),
                          style: r.esTotal ? const TextStyle(color: Colors.white) : null,
                        ),
                        if (!r.esTotal)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: 'Editar calificación',
                            onPressed: () async {
                              await _editarCalificacion(context, r.categoria);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              DataCell(
                Text(
                  '${r.porcentaje.toStringAsFixed(1)}%',
                  style: r.esTotal ? const TextStyle(color: Colors.white) : null,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _editarCalificacion(BuildContext context, String categoria) async {
    String cat;
    String? subcat;
    if (categoria.contains('>')) {
      final partes = categoria.split('>');
      cat = partes[0].trim();
      subcat = partes.length > 1 ? partes[1].trim() : null;
    } else {
      cat = categoria;
      subcat = null;
    }
    final tabla = widget.resultados;
    final data = subcat == null
        ? tabla[cat]!
        : tabla[cat]!.subcategorias[subcat]!;
    int nuevaCalif = data.calificacion;
      final result = await showDialog<int>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Editar calificación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selecciona la calificación (0-5)'),
                Slider(
                  value: nuevaCalif.toDouble(),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: nuevaCalif.toString(),
                  onChanged: (v) {
                    setStateDialog(() {
                      nuevaCalif = v.toInt();
                    });
                  },
                ),
                Text('Calificación actual: $nuevaCalif / 5'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(context, nuevaCalif), child: const Text('Guardar')),
            ],
          ),
        ),
      );
    if (result != null) {
      setState(() {
        data.calificacion = result;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calificación actualizada a $result')),
      );
    }
  }
}

class ShingoResumenService {
  static List<ResumenCategoria> generarResumen(Map<String, ShingoResultData> hojas) {
    final List<ResumenCategoria> resumen = [];
    double totalPts = 0;
    int subcatCount = 0;

    // Validar que el mapa no esté vacío
    if (hojas.isEmpty) {
      resumen.add(ResumenCategoria(
        categoria: 'TOTAL',
        puntos: 0,
        porcentaje: 0,
        esTotal: true,
      ));
      return resumen;
    }

    // Contar subcategorías (si no hay, cuenta la principal)
    hojas.forEach((_, cat) {
      if (cat.subcategorias.isEmpty) {
        subcatCount++;
      } else {
        subcatCount += cat.subcategorias.length;
      }
    });
    final puntosPorSubcat = subcatCount > 0 ? 200 / subcatCount : 0;

    hojas.forEach((nombre, cat) {
      if (cat.subcategorias.isEmpty) {
        final calif = cat.calificacion.toDouble();
        final puntos = calif * puntosPorSubcat / 5;
        final porcentaje = puntosPorSubcat > 0 ? (puntos / puntosPorSubcat * 100).toDouble() : 0.0;
        totalPts += puntos;
        resumen.add(ResumenCategoria(
          categoria: nombre,
          puntos: puntos,
          porcentaje: porcentaje,
          esTotal: false,
        ));
      } else {
        cat.subcategorias.forEach((subnombre, subcat) {
          final calif = subcat.calificacion.toDouble();
          final puntos = calif * puntosPorSubcat / 5;
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
