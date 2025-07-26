import 'package:applensys/evaluacion/services/remote/auth_service.dart';
import 'package:flutter/material.dart';
import '../custom/appcolors.dart';

class Recovery extends StatefulWidget {
  const Recovery({super.key});

  @override
  State<Recovery> createState() => _RecoveryState();
}

class _RecoveryState extends State<Recovery> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _recover() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu correo electrónico')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService().resetPassword(email);
    setState(() => _isLoading = false);

    if (!mounted) return;
    final success = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
      content: Text(success
        ? (result['message'] ?? 'Correo enviado para restablecer la contraseña')
        : (result['message'] ?? 'Error al enviar el correo')),
      ),
    );

    if (success) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context); // volver al login
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 40,
                bottom: bottomInset + 10,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 30),
                        AnimatedPadding(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 60),
                          child: SizedBox(
                            height: 100,
                            child: Image.asset('assets/logo.webp'),
                          ),
                        ),
                        const SizedBox(height: 20),
                  const Text(
                    'Recuperar Contraseña',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _recover,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Enviar',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                  SizedBox(height: bottomInset + 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
