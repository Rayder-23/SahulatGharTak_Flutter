import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the last-observed `progressStatus` per request UID, so the
/// repository can detect when a request's progress moves backward (e.g. a
/// provider cancels an accepted booking and the request is reset to
/// `Requested` for re-assignment — see api.txt v3.22) and surface a
/// "provider had to cancel" notice instead of silently reverting the UI.
class RequestProgressHistoryStore {
  final _storage = const FlutterSecureStorage();

  String _keyFor(int clientUid) => 'requestProgressHistory_$clientUid';

  Future<Map<int, String?>> load(int clientUid) async {
    final raw = await _storage.read(key: _keyFor(clientUid));
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(int.parse(key), value as String?));
    } catch (_) {
      return {};
    }
  }

  Future<void> save(int clientUid, Map<int, String?> history) async {
    final encoded = history.map((key, value) => MapEntry(key.toString(), value));
    await _storage.write(key: _keyFor(clientUid), value: jsonEncode(encoded));
  }
}
