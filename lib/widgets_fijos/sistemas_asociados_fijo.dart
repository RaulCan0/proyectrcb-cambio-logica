import 'package:flutter/material.dart';

/// Widget fijo para mostrar los sistemas asociados a un comportamiento o principio.
class SistemasAsociadosFijo extends StatelessWidget {
  final List<String> sistemas;
  final String titulo;

  const SistemasAsociadosFijo({
    super.key,
    required this.sistemas,
    this.titulo = 'Sistemas Asociados',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            sistemas.isEmpty
                ? const Text('Sin sistemas asociados')
                : Wrap(
                    spacing: 8,
                    children: sistemas.map((s) => Chip(label: Text(s))).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
