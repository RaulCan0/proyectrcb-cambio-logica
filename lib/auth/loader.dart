// ignore: unused_import
import 'package:applensys/auth/login.dart';
// ignore: unused_import
import 'package:applensys/auth/register.dart';
import 'package:flutter/material.dart';


class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key});

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen> {
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: CustomPaint(
          painter: DiagonalPainter(color: const Color(0xFF003056)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          const Text(
                            'LENSYS TRAINING CENTER',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Bienvenido\na la aplicación oficial',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 60),
                          Center(
                            child: AnimatedPadding(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 80),
                              child: SizedBox(
                                height: 120,
                                child: Image.asset(
                                  Theme.of(context).brightness == Brightness.dark
                                      ? 'assets/logoblanco.webp'
                                      : 'assets/logo.webp',
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/login'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003056),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Iniciar Sesión',
                                    style: TextStyle(fontSize: 16, color: Colors.white)),
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF003056)),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Registrarse',
                                    style:
                                        TextStyle(fontSize: 16, color: Color(0xFF003056))),
                              ),
                            ],
                          ),
                          SizedBox(height: bottomPadding + 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class DiagonalPainter extends CustomPainter {
  final Color color;

  const DiagonalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
