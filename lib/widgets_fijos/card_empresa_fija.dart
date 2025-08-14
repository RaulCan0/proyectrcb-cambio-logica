import 'package:flutter/material.dart';

/// Widget fijo para mostrar los detalles de la empresa en la evaluación.
class CardEmpresaFija extends StatelessWidget {
  final String nombre;
  final int empleados;
  final int unidades;

  const CardEmpresaFija({
    super.key,
    required this.nombre,
    required this.empleados,
    required this.unidades,
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
            Text(
              nombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Empleados: $empleados'),
            Text('Unidades: $unidades'),
          ],
        ),
      ),
    );
  }
}
