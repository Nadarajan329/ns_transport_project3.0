import 'package:flutter_test/flutter_test.dart';
import 'package:ns_transport/utils/formatters.dart';

void main() {
  group('Formatters Test', () {
    test('formatCurrency should format amount with 2 decimal places by default', () {
      expect(Formatters.formatCurrency(1234.56), '₹1,234.56');
      expect(Formatters.formatCurrency(0), '₹0.00');
    });

    test('formatCurrency with compact=true should format amount with 0 decimal places', () {
      expect(Formatters.formatCurrency(1234.56, compact: true), '₹1,235');
      expect(Formatters.formatCurrency(1000, compact: true), '₹1,000');
    });

    test('formatDate should format DateTime to dd MMM yyyy by default', () {
      final date = DateTime(2023, 10, 15);
      expect(Formatters.formatDate(date), '15 Oct 2023');
    });

    test('formatDate should format DateTime with custom format', () {
      final date = DateTime(2023, 10, 15);
      expect(Formatters.formatDate(date, format: 'yyyy-MM-dd'), '2023-10-15');
    });

    test('formatDateTime should format DateTime to dd MMM yyyy, hh:mm a', () {
      final date = DateTime(2023, 10, 15, 14, 30);
      expect(Formatters.formatDateTime(date), '15 Oct 2023, 02:30 PM');
    });

    test('generateTripId should return a valid trip ID string', () {
      final tripId = Formatters.generateTripId();
      expect(tripId.startsWith('TRIP-'), isTrue);
      expect(tripId.length, greaterThan(5));
    });
  });
}
