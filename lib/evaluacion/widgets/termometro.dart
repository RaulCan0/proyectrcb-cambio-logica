import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TermometroGlobal extends ConsumerWidget {
  final double valorObtenido;
  static const double valorMaximo = 1000.0;

  const TermometroGlobal({super.key, required this.valorObtenido});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fill = (valorObtenido / valorMaximo).clamp(0.0, 1.0);
    final barWidth = MediaQuery.of(context).size.width * 0.5; // 50% del ancho de pantalla
    final indicatorX = barWidth * fill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
Builder(builder: (_) {
  String mensaje;
  if (valorObtenido >= 775) {
    mensaje = "LA EVALUACIÓN ESTIMA QUÉ TU NIVEL ES CERCANO A 775 O MÁS (SHINGO PRIZE)";
  } else if (valorObtenido >= 675) {
    mensaje = "LA EVALUACIÓN ESTIMA QUE TU NIVEL ES CERCANO A 675–774 (PLATA)";
  } else if (valorObtenido >= 575) {
    mensaje = "LA EVALUACIÓN ESTIMA QUÉ TU NIVEL ES CERCANO A 575–674 (BRONCE)";
  } else {
    mensaje = "LA EVALUACIÓN ESTIMA QUE TU NIVEL ES INFERIOR A 575 (MEJORA-INMEDIATA)";
  }
  return Align(
    alignment: Alignment.center,
    child: Text(
      mensaje,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
      textAlign: TextAlign.center,
    ),
  );
}),


        Align(
          alignment: Alignment.centerRight,
          child: Text('${valorObtenido.toStringAsFixed(0)} / ${valorMaximo.toStringAsFixed(0)} pts', textAlign: TextAlign.right),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: barWidth,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.red, Colors.yellow, Colors.green]),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  width: indicatorX,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.yellow.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  left: (indicatorX - 12).clamp(0.0, barWidth - 24),
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Tooltip(
                      message: '${valorObtenido.toStringAsFixed(0)} / ${valorMaximo.toStringAsFixed(0)} pts',
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
