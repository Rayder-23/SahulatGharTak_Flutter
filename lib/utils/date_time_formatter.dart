import 'package:intl/intl.dart';

/// Formats a UTC [DateTime] from the API for display, converting to the
/// device's local time first. All API DateTime fields are UTC (see api.txt).
String formatLocalDateTime(DateTime utc, String pattern) {
  return DateFormat(pattern).format(utc.toLocal());
}
