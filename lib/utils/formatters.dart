import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _currencyFormatCompact = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String formatCurrency(double amount, {bool compact = false}) {
    if (compact) {
      return _currencyFormatCompact.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  static String formatDate(DateTime date, {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String generateTripId() {
    final now = DateTime.now();
    final randomStr = now.microsecondsSinceEpoch.toString().substring(10);
    return 'TRIP-$randomStr';
  }
}
