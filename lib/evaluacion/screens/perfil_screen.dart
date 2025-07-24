import 'dart:io';
import 'package:applensys/evaluacion/services/domain/supabase_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _fotoUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _loading = true);
    try {
      final data = await _supabaseService.getPerfil();
      if (data != null) {
        _nombreController.text = data['nombre'] ?? '';
        _emailController.text = data['email'] ?? '';
        _telefonoController.text = data['telefono'] ?? '';
        _fotoUrl = data['foto_url'];
      }
    } catch (e) {
      _showError('Error al cargar perfil: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _actualizarPerfil() async {
    if (_nombreController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _telefonoController.text.trim().isEmpty) {
      _showError('Todos los campos son obligatorios');
      return;
    }

    setState(() => _loading = true);

    try {
      await _supabaseService.actualizarPerfil({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'foto_url': _fotoUrl,
      });

      if (_newPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text != _confirmPasswordController.text) {
          _showError('Las contraseñas no coinciden');
          return;
        }
        await _supabaseService.actualizarContrasena(
          newPassword: _newPasswordController.text.trim(),
        );
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }

      _showMessage('Perfil actualizado correctamente');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError('Error al actualizar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarFoto() async {
    String? path;
    if (Platform.isAndroid || Platform.isIOS) {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      path = picked.path;
    } else {
      final file = await openFile(acceptedTypeGroups: [
        const XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']),
      ]);
      if (file == null) return;
      path = file.path;
    }

    setState(() => _loading = true);

    try {
      final fileInBucket = await _supabaseService.subirFotoPerfil(path);
      final url = _supabaseService.getPublicUrl(bucket: 'profile_photos', path: fileInBucket);
      setState(() => _fotoUrl = url);
      _showMessage('Foto actualizada correctamente');
    } catch (e) {
      _showError('Error al subir foto: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _showError(String err) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).setTheme(newMode);
            },
            
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _seleccionarFoto,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
                          child: _fotoUrl == null ? const Icon(Icons.person, size: 60) : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre')),
                      const SizedBox(height: 16),
                      TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo')),
                      const SizedBox(height: 16),
                      TextField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono')),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _actualizarPerfil,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003056),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Actualizar Perfil', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
