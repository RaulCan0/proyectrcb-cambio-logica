import 'package:flutter/material.dart';

/// Widget fijo para mostrar un botón de acción principal.
class BotonAccionFijo extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const BotonAccionFijo({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF003056),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
      icon: icon != null ? Icon(icon, color: Colors.white) : const SizedBox.shrink(),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      onPressed: onPressed,
    );
  }
}
