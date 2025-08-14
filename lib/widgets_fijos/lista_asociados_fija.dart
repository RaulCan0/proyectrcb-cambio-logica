import 'package:flutter/material.dart';

/// Widget fijo para mostrar la lista de asociados en la evaluación.
class ListaAsociadosFija extends StatelessWidget {
  final List<String> asociados;
  final void Function(String) onTap;

  const ListaAsociadosFija({
    super.key,
    required this.asociados,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: asociados.length,
        itemBuilder: (context, index) {
          final asociado = asociados[index];
          return ListTile(
            title: Text(asociado),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => onTap(asociado),
          );
        },
      ),
    );
  }
}
