import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the user's 12hr/24hr time display preference, keyed by [userId]
/// so it's shared between a Client and Provider profile on the same account
/// (both roles read/write the same key) rather than being per-role.
class TimeFormatService {
  final _storage = const FlutterSecureStorage();

  String _keyFor(int userId) => 'timeFormat24h_$userId';

  /// Returns null when the user hasn't set a preference yet (caller should
  /// fall back to a sensible default, e.g. 12hr).
  Future<bool?> loadUse24Hour(int userId) async {
    final value = await _storage.read(key: _keyFor(userId));
    if (value == null) return null;
    return value == 'true';
  }

  Future<void> saveUse24Hour(int userId, bool use24Hour) async {
    await _storage.write(key: _keyFor(userId), value: use24Hour.toString());
  }
}
