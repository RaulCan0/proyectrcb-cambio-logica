import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applensys/evaluacion/providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _fotoUrl; // guardamos SOLO la URL pública final
  bool _loading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _loading = true);
    try {
      // Asumimos que el perfil está en una tabla 'perfiles' o similar accesible vía RPC o auth.user().metadata
      // Si tienes una función concreta, cámbiala aquí:
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Sesión no encontrada');

      // Ejemplo: leer de un perfil estándar (ajusta a tu estructura real)
      final resp = await _supabase
          .from('perfiles')
          .select()
          .eq('id_usuario', user.id)
          .maybeSingle();

      if (resp != null) {
        _nombreController.text = (resp['nombre'] ?? '').toString();
        _emailController.text =
            (resp['email'] ?? user.email ?? '').toString();
        _telefonoController.text = (resp['telefono'] ?? '').toString();
        final f = resp['foto_url'];
        _fotoUrl = (f == null || (f is String && f.trim().isEmpty)) ? null : f.toString();
        setState(() {});
      } else {
        // fallback con auth
        _emailController.text = user.email ?? '';
      }
    } catch (e) {
      _showError('Error al cargar perfil: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _actualizarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Sesión no encontrada');

      // Actualiza tu tabla de perfil (ajusta el nombre/where a tu esquema)
      await _supabase.from('perfiles').upsert({
        'id_usuario': user.id,
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'foto_url': _fotoUrl, // guardamos SOLO la URL pública
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Contraseña opcional
      if (_newPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text != _confirmPasswordController.text) {
          _showError('Las nuevas contraseñas no coinciden.');
          setState(() => _loading = false);
          return;
        }
        await _supabase.auth.updateUser(
          UserAttributes(password: _newPasswordController.text.trim()),
        );
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }

      _showMessage('Perfil actualizado correctamente.');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError('Error al actualizar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarFoto() async {
    if (_loading) return;
    String? path;
    Uint8List? bytes;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (picked == null) return;
        path = picked.path;
        bytes = await picked.readAsBytes();
      } else {
        final file = await openFile(
          acceptedTypeGroups: [
            XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png', 'webp']),
          ],
        );
        if (file == null) return;
        path = file.path;
        bytes = await File(path).readAsBytes();
      }

      await _subirAFotosPerfiles(bytes, path);
      _showMessage('Foto actualizada');
    } catch (e) {
      _showError('Error al subir foto: $e');
    }
  }

  Future<void> _subirAFotosPerfiles(Uint8List bytes, String originalPath) async {
    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Sesión no encontrada');

      final ext = originalPath.split('.').last.toLowerCase();
      final fileName = 'perfil_${user.id}.${ext.isEmpty ? 'jpg' : ext}';
      final objectPath = 'users/${user.id}/$fileName'; // carpeta ordenada

      // Elimina anterior (best-effort)
      try {
        await _supabase.storage.from('perfiles').remove([objectPath]);
      } catch (_) {}

      // Sube
      await _supabase.storage
          .from('perfiles')
          .uploadBinary(objectPath, bytes, fileOptions: const FileOptions(upsert: true));

      // URL pública (asegúrate que el bucket 'perfiles' sea público)
      final publicUrl = _supabase.storage.from('perfiles').getPublicUrl(objectPath);

      // Para bust de caché en UI, agrega un query param temporal
      final cacheBuster = '${DateTime.now().millisecondsSinceEpoch}';
      setState(() => _fotoUrl = '$publicUrl?t=$cacheBuster');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _quitarFoto() async {
    if (_loading) return;
    setState(() => _fotoUrl = null);
    _showMessage('Foto removida (guarda para aplicar cambios)');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String err) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          _AvatarEditor(
                            imageUrl: _fotoUrl,
                            onPick: _seleccionarFoto,
                            onRemove: _fotoUrl != null ? _quitarFoto : null,
                            enabled: !_loading,
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _Input(
                                    controller: _nombreController,
                                    label: 'Nombre',
                                    textInputAction: TextInputAction.next,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Ingresa tu nombre'
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                  _Input(
                                    controller: _emailController,
                                    label: 'Correo',
                                    keyboardType: TextInputType.emailAddress,
                                    readOnly: true, // generalmente controlado por auth
                                  ),
                                  const SizedBox(height: 12),
                                  _Input(
                                    controller: _telefonoController,
                                    label: 'Teléfono',
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Cambiar Contraseña (opcional)',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 12),
                                  _PasswordInput(
                                    controller: _newPasswordController,
                                    label: 'Nueva Contraseña',
                                    obscure: _obscureNewPassword,
                                    onToggle: () => setState(() =>
                                        _obscureNewPassword = !_obscureNewPassword),
                                  ),
                                  const SizedBox(height: 12),
                                  _PasswordInput(
                                    controller: _confirmPasswordController,
                                    label: 'Confirmar Contraseña',
                                    obscure: _obscureConfirmPassword,
                                    onToggle: () => setState(() =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Tema de la app',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 12),
                                  SegmentedButton<ThemeMode>(
                                    segments: const [
                                      ButtonSegment(
                                          value: ThemeMode.system,
                                          label: Text('Auto'),
                                          icon: Icon(Icons.settings)),
                                      ButtonSegment(
                                          value: ThemeMode.light,
                                          label: Text('Claro'),
                                          icon: Icon(Icons.light_mode)),
                                      ButtonSegment(
                                          value: ThemeMode.dark,
                                          label: Text('Oscuro'),
                                          icon: Icon(Icons.dark_mode)),
                                    ],
                                    selected: {current},
                                    onSelectionChanged: (modes) {
                                      themeNotifier.setTheme(modes.first);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _loading ? null : _actualizarPerfil,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF003056),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Guardar cambios',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final bool enabled;

  const _AvatarEditor({
    required this.imageUrl,
    required this.onPick,
    required this.enabled,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 64,
            backgroundImage: (imageUrl != null) ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? const Icon(Icons.person, size: 64)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Row(
              children: [
                if (onRemove != null)
                  _RoundIconButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Quitar foto',
                    onTap: onRemove!,
                  ),
                const SizedBox(width: 8),
                _RoundIconButton(
                  icon: Icons.camera_alt_rounded,
                  tooltip: 'Cambiar foto',
                  onTap: enabled ? onPick : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.7),
            border: Border.all(color: Colors.white, width: 2),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _Input({
    required this.controller,
    required this.label,
    this.validator,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordInput({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
