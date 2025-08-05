import 'package:flutter/material.dart';


class AnotacionesScreen extends StatelessWidget {
  final String userId;

  const AnotacionesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anotaciones'),
      ),
      body: Center(
        child: Text('Bienvenido, $userId'),
      ),
    );
  }
}
