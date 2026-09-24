import 'package:intl/intl.dart';

/// Standard date-only display pattern across the app. Use [kCompactDatePattern]
/// instead where horizontal space is tight (card rows, chips).
const kDatePattern = 'dd-MM-yyyy';
const kCompactDatePattern = 'dd-MM-yy';

/// App-wide 12hr/24hr time display preference, set by [TimeFormatProvider]
/// (`lib/providers/time_format_provider.dart`) once loaded/toggled. Read
/// synchronously by the formatters below, which are plain functions called
/// from many places with no `BuildContext`/provider access. Defaults to
/// 12hr (`false`) until a preference is loaded, matching the API's existing
/// `hh:mm a`-style displays used throughout the app before this setting
/// existed.
bool use24HourFormat = false;

/// Formats a UTC [DateTime] from the API for display, converting to the
/// device's local time first. All API DateTime fields are UTC (see api.txt).
///
/// [pattern] should describe the date portion only (e.g. [kDatePattern] or
/// [kCompactDatePattern]); pass [includeTime] to additionally append a
/// time-of-day formatted per [use24HourFormat].
String formatLocalDateTime(DateTime utc, String pattern, {bool includeTime = false, String timeSeparator = ', '}) {
  final local = utc.toLocal();
  final datePart = DateFormat(pattern).format(local);
  if (!includeTime) return datePart;
  return '$datePart$timeSeparator${_formatTimeOfDay(local)}';
}

String _formatTimeOfDay(DateTime local) {
  return DateFormat(use24HourFormat ? 'HH:mm' : 'hh:mm a').format(local);
}

/// Joins a nullable "yyyy-MM-dd" date and "HH:mm" time string (e.g. a
/// booking's preferredServiceDate/preferredServiceTime, sourced from the
/// linked request - see api.txt's SERVICE BOOKINGS APIs notes) for display,
/// reformatted to [kDatePattern] and the user's 12hr/24hr preference. Neither
/// input is a UTC instant - both are wall-clock values with no timezone
/// conversion. Returns null when both are unset; falls back to the raw
/// string for either half if it doesn't parse as expected.
String? formatScheduledDateTime(String? date, String? time) {
  final hasDate = date != null && date.isNotEmpty;
  final hasTime = time != null && time.isNotEmpty;
  if (!hasDate && !hasTime) return null;

  final datePart = hasDate ? _formatIsoDate(date) : null;
  final timePart = hasTime ? _formatWallClockTime(time) : null;

  if (datePart == null) return timePart;
  if (timePart == null) return datePart;
  return '$datePart · $timePart';
}

String _formatIsoDate(String date) {
  try {
    return DateFormat(kDatePattern).format(DateTime.parse(date));
  } catch (_) {
    return date;
  }
}

String _formatWallClockTime(String time) {
  try {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final asDateTime = DateTime(2000, 1, 1, hour, minute);
    return DateFormat(use24HourFormat ? 'HH:mm' : 'hh:mm a').format(asDateTime);
  } catch (_) {
    return time;
  }
}
