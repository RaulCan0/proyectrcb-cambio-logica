import 'package:applensys/evaluacion/services/releases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final releasesServiceProvider = Provider<ReleasesService>((ref) {
  return ReleasesService();
});

/// Estado simple para actualización
class UpdateState {
  final bool hasUpdate;
  final ReleaseInfo? info;
  const UpdateState({required this.hasUpdate, this.info});
}

final updateCheckerProvider = FutureProvider.family<UpdateState, ({String appId, int currentBuild})>((ref, args) async {
  final svc = ref.read(releasesServiceProvider);
  final latest = await svc.fetchLatestRelease(appId: args.appId);
  if (latest == null) return const UpdateState(hasUpdate: false);
  final newer = svc.isNewer(currentBuild: args.currentBuild, latestBuild: latest.build);
  return UpdateState(hasUpdate: newer, info: newer ? latest : null);
});
