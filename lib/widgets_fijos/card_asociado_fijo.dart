import 'package:flutter/material.dart';

/// Widget fijo para mostrar los detalles de un asociado.
class CardAsociadoFijo extends StatelessWidget {
  final String nombre;
  final String puesto;
  final int antiguedad;
  final String cargo;

  const CardAsociadoFijo({
    super.key,
    required this.nombre,
    required this.puesto,
    required this.antiguedad,
    required this.cargo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Puesto: $puesto'),
            Text('Antigüedad: $antiguedad años'),
            Text('Cargo: $cargo'),
          ],
        ),
      ),
    );
  }
}
