import '../models/app_config.dart';

/// Compares dotted version strings numerically per segment, so `1.0.10 > 1.0.9`.
/// A `+build` / `-suffix` tail is ignored and missing segments count as 0.
/// Returns a negative, zero or positive number like [Comparable.compareTo].
int compareVersions(String a, String b) {
  final pa = _segments(a);
  final pb = _segments(b);
  final length = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

List<int> _segments(String version) {
  final core = version.split(RegExp(r'[+\-]')).first.trim();
  if (core.isEmpty) return const [0];
  return core.split('.').map((s) => int.tryParse(s) ?? 0).toList();
}

enum AppUpdateKind { none, optional, required }

/// Applies the client rule from `api.txt`: block when below the minimum, or
/// when `force_update` is set and below the latest; prompt when only below
/// the latest.
AppUpdateKind evaluateUpdate(String installedVersion, AppConfig config) {
  if (compareVersions(installedVersion, config.minimumRequiredVersion) < 0) {
    return AppUpdateKind.required;
  }
  final belowLatest =
      compareVersions(installedVersion, config.latestVersion) < 0;
  if (belowLatest && config.forceUpdate) return AppUpdateKind.required;
  if (belowLatest) return AppUpdateKind.optional;
  return AppUpdateKind.none;
}
