import 'package:flutter/material.dart';

/// Widget fijo para mostrar un loader universal.
class LoaderFijo extends StatelessWidget {
  final String mensaje;

  const LoaderFijo({
    super.key,
    this.mensaje = 'Cargando...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(mensaje, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
