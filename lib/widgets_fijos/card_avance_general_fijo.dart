import 'package:flutter/material.dart';

/// Widget fijo para mostrar el avance general de la evaluación.
class CardAvanceGeneralFijo extends StatelessWidget {
  final double avance;
  final String label;

  const CardAvanceGeneralFijo({
    super.key,
    required this.avance,
    required this.label,
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
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: avance,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text('${(avance * 100).toStringAsFixed(1)}% completado'),
          ],
        ),
      ),
    );
  }
}
