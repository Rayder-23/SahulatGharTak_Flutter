import 'package:intl/intl.dart';

final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

/// Formats a money amount as a whole number with thousand separators,
/// e.g. 125000 -> "Rs 125,000". Never shows decimal places - all amounts
/// in this app are already whole rupees.
String formatCurrency(num amount) => 'Rs ${_currencyFormat.format(amount)}';
