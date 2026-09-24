import 'package:flutter/material.dart';

import '../services/time_format_service.dart';
import '../utils/date_time_formatter.dart' as date_time_formatter;

/// Owns the account's 12hr/24hr time display preference (shared between a
/// Client and Provider profile on the same account - see
/// `TimeFormatService`) and keeps `date_time_formatter.dart`'s module-level
/// `use24HourFormat` flag in sync, since the shared formatters are plain
/// functions with no provider/context access.
class TimeFormatProvider extends ChangeNotifier {
  TimeFormatProvider({TimeFormatService? service}) : _service = service ?? TimeFormatService();

  final TimeFormatService _service;

  int? _userId;
  bool _use24Hour = false;

  bool get use24Hour => _use24Hour;

  /// Loads the preference for [userId] (called on login/auto-login). Safe to
  /// call repeatedly - re-loading for the same userId is a cheap no-op read.
  Future<void> load(int userId) async {
    _userId = userId;
    final stored = await _service.loadUse24Hour(userId);
    _use24Hour = stored ?? false;
    date_time_formatter.use24HourFormat = _use24Hour;
    notifyListeners();
  }

  Future<void> setUse24Hour(bool value) async {
    if (_use24Hour == value) return;
    _use24Hour = value;
    date_time_formatter.use24HourFormat = value;
    notifyListeners();
    final userId = _userId;
    if (userId != null) await _service.saveUse24Hour(userId, value);
  }

  /// Clears in-memory state on logout - does NOT delete the stored
  /// preference, which stays keyed to the account for next login.
  void reset() {
    _userId = null;
    _use24Hour = false;
    date_time_formatter.use24HourFormat = false;
    notifyListeners();
  }
}
