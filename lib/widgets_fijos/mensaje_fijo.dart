import 'package:flutter/material.dart';

/// Widget fijo para mostrar mensajes de error o información.
class MensajeFijo extends StatelessWidget {
  final String mensaje;
  final bool esError;

  const MensajeFijo({
    super.key,
    required this.mensaje,
    this.esError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esError ? Colors.red.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(esError ? Icons.error : Icons.info, color: esError ? Colors.red : Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje, style: TextStyle(color: esError ? Colors.red : Colors.blue))),
        ],
      ),
    );
  }
}
