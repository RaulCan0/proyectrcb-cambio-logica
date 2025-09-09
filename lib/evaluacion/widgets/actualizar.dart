import 'package:applensys/evaluacion/services/release.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ActualizacionDialog extends StatelessWidget {
  final ReleaseInfo info;
  const ActualizacionDialog({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actualización disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Versión ${info.version} (build ${info.build})'),
          const SizedBox(height: 8),
          if ((info.notas ?? '').isNotEmpty)
            Text(info.notas!, style: const TextStyle(fontSize: 13)),
          if ((info.notas ?? '').isEmpty)
            const Text('Hay una nueva actualización lista para descargar.'),
        ],
      ),
      actions: [
        if (!info.obligatoria)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Luego'),
          ),
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final uri = Uri.parse(info.url);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!info.obligatoria) {
              navigator.pop();
            }
          },
          child: const Text('Actualizar'),
        ),
      ],
    );
  }
}