import 'package:flutter_test/flutter_test.dart';
import 'package:ns_transport/models/advance_history_model.dart';

void main() {
  group('AdvanceHistoryModel Test', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 'a1',
        'driver_id': 'd1',
        'amount': 1500.0,
        'type': 'given_by_owner',
        'description': 'Test advance',
        'trip_id': 't1',
        'created_at': '2023-10-15T10:00:00.000Z'
      };

      final model = AdvanceHistoryModel.fromJson(json);
      expect(model.id, 'a1');
      expect(model.driverId, 'd1');
      expect(model.amount, 1500.0);
      expect(model.type, 'given_by_owner');
      expect(model.description, 'Test advance');
      expect(model.tripId, 't1');
      expect(model.createdAt, DateTime.parse('2023-10-15T10:00:00.000Z'));
    });

    test('toJson should serialize correctly', () {
      final model = AdvanceHistoryModel(
        driverId: 'd1',
        amount: 2000.0,
        type: 'expense_adjustment',
      );

      final json = model.toJson();
      expect(json['driver_id'], 'd1');
      expect(json['amount'], 2000.0);
      expect(json['type'], 'expense_adjustment');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('description'), isFalse);
    });
  });
}
