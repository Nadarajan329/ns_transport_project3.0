import 'package:flutter_test/flutter_test.dart';
import 'package:ns_transport/models/trip_model.dart';

void main() {
  group('TripModel Test', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 't1',
        'driver_id': 'd1',
        'vehicle_number': 'MH12AB1234',
        'trip_date': '2023-10-15T00:00:00.000Z',
        'from_location': 'Mumbai',
        'to_location': 'Pune',
        'load_type': 'Goods',
        'load_tonnage': '10',
        'rent_amount': 15000,
        'loading_expense': 1000,
        'unloading_expense': 1000,
        'other_expense': 500,
        'advance_amount': 2000,
        'status': 'completed',
      };

      final model = TripModel.fromJson(json);
      expect(model.id, 't1');
      expect(model.driverId, 'd1');
      expect(model.vehicleNumber, 'MH12AB1234');
      expect(model.tripDate, DateTime.parse('2023-10-15T00:00:00.000Z'));
      expect(model.rentAmount, 15000.0);
      expect(model.loadingExpense, 1000.0);
      expect(model.unloadingExpense, 1000.0);
      expect(model.otherExpense, 500.0);
      expect(model.advanceAmount, 2000.0);
      expect(model.status, 'completed');
    });

    test('toJson should serialize correctly', () {
      final model = TripModel(
        driverId: 'd1',
        vehicleNumber: 'MH12AB1234',
        tripDate: DateTime(2023, 10, 15),
        fromLocation: 'Mumbai',
        toLocation: 'Pune',
        loadTonnage: '10',
        rentAmount: 15000.0,
        loadingExpense: 1000.0,
        unloadingExpense: 1000.0,
        otherExpense: 500.0,
        advanceAmount: 2000.0,
        status: 'draft',
      );

      final json = model.toJson();
      expect(json['driver_id'], 'd1');
      expect(json['vehicle_number'], 'MH12AB1234');
      expect(json['from_location'], 'Mumbai');
      expect(json['to_location'], 'Pune');
      expect(json['status'], 'draft');
    });

    test('copyWith should copy properties correctly', () {
      final model = TripModel(
        driverId: 'd1',
        vehicleNumber: 'MH12AB1234',
        tripDate: DateTime(2023, 10, 15),
        fromLocation: 'Mumbai',
        toLocation: 'Pune',
        loadTonnage: '10',
        rentAmount: 15000.0,
        loadingExpense: 1000.0,
        unloadingExpense: 1000.0,
        otherExpense: 500.0,
        advanceAmount: 2000.0,
        status: 'draft',
      );

      final updated = model.copyWith(status: 'completed', notes: 'Done');
      expect(updated.status, 'completed');
      expect(updated.notes, 'Done');
      expect(updated.driverId, 'd1'); // Remains unchanged
    });
  });
}
