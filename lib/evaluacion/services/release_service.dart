import 'dart:io' show Platform;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReleaseInfo {
  final String appId;
  final String plataforma; // 'android' | 'windows'
  final String version;    // '1.2.3'
  final int build;         // 45
  final String url;
  final String? notas;
  final bool obligatoria;

  ReleaseInfo({
    required this.appId,
    required this.plataforma,
    required this.version,
    required this.build,
    required this.url,
    this.notas,
    required this.obligatoria,
  });

  factory ReleaseInfo.fromMap(Map<String, dynamic> m) => ReleaseInfo(
    appId: (m['app_id'] ?? '') as String,
    plataforma: (m['plataforma'] ?? '') as String,
    version: (m['version'] ?? '') as String,
    build: (m['build'] ?? 0) as int,
    url: (m['url'] ?? '') as String,
    notas: m['notas'] as String?,
    obligatoria: (m['obligatoria'] as bool?) ?? false,
  );
}

class ReleasesService {
  final SupabaseClient _db = Supabase.instance.client;

  /// Obtiene el último release por plataforma para el appId indicado.
  Future<ReleaseInfo?> fetchLatestRelease({
    required String appId,
    String canal = 'stable',
  }) async {
    final plataforma = Platform.isAndroid ? 'android' : 'windows';

    final row = await _db
        .from('releases')
        .select()
        .eq('app_id', appId)
        .eq('plataforma', plataforma)
        .eq('canal', canal)
        .order('build', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return ReleaseInfo.fromMap(row);
  }

  /// Compara builds (preferible a comparar versiones semánticas).
  bool isNewer({required int currentBuild, required int latestBuild}) {
    return latestBuild > currentBuild;
  }
}
