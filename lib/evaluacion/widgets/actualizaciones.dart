import 'package:flutter/material.dart';

class ActualizacionesWidget {
  static void mostrarDialogoActualizacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Actualización Disponible'),
          content: const Text('Hay una nueva actualización disponible. ¿Deseas actualizar ahora?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Lógica para iniciar la actualización
                Navigator.of(context).pop();
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }
}