import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TermometroGlobal extends ConsumerWidget {
  final double valorObtenido;
  static const double valorMaximo = 1000.0;

  const TermometroGlobal({super.key, required this.valorObtenido});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fill = (valorObtenido / valorMaximo).clamp(0.0, 1.0);
    final barWidth = MediaQuery.of(context).size.width - 32;
    final indicatorX = barWidth * fill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Termómetro Global', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const SizedBox(height: 12),
        Builder(builder: (_) {
          String mensaje;
          if (valorObtenido >= 775) {
            mensaje = "🏆 SHINGO PRIZE ALCANZADO";
          } else if (valorObtenido >= 758) {
            mensaje = "🥈 PREMIO PLATA";
          } else if (valorObtenido >= 757) {
            mensaje = "🥉 PREMIO BRONCE";
          } else {
            mensaje = "⏳ NO SE HA ALCANZADO PREMIO";
          }
          return Text(
            mensaje,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
            textAlign: TextAlign.center,
          );
        }),

        Text('${valorObtenido.toStringAsFixed(0)} / ${valorMaximo.toStringAsFixed(0)} pts'),
        const SizedBox(height: 8),
        const SizedBox(height: 12),
        Builder(builder: (_) {
          String mensaje;
          if (valorObtenido >= 775) {
            mensaje = "🏆 SHINGO PRIZE ALCANZADO";
          } else if (valorObtenido >= 758) {
            mensaje = "🥈 PREMIO PLATA";
          } else if (valorObtenido >= 757) {
            mensaje = "🥉 PREMIO BRONCE";
          } else {
            mensaje = "⏳ NO SE HA ALCANZADO PREMIO";
          }
          return Text(
            mensaje,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
            textAlign: TextAlign.center,
          );
        }),

        Container(
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
      ],
    );
  }
}
