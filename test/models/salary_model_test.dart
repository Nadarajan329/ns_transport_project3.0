import 'package:flutter_test/flutter_test.dart';
import 'package:ns_transport/models/salary_model.dart';

void main() {
  group('SalaryModel Test', () {
    test('computed properties should calculate correctly', () {
      final model = SalaryModel(
        driverId: 'd1',
        totalSalary: 50000.0,
        paidAmount: 20000.0,
        advanceAmount: 10000.0,
        month: 10,
        year: 2023,
      );

      expect(model.baseSalary, 50000.0);
      expect(model.advances, 10000.0);
      expect(model.netSalary, 20000.0); // 50000 - 20000 - 10000
      expect(model.status, 'pending');
    });

    test('status should be paid if net salary is 0', () {
       final model = SalaryModel(
        driverId: 'd1',
        totalSalary: 50000.0,
        paidAmount: 40000.0,
        advanceAmount: 10000.0,
        month: 10,
        year: 2023,
      );
      expect(model.status, 'paid');
    });

    test('fromJson should parse correctly', () {
      final json = {
        'id': 's1',
        'driver_id': 'd1',
        'total_salary': 50000,
        'paid_amount': 20000,
        'advance_amount': 10000,
        'month': 10,
        'year': 2023,
      };

      final model = SalaryModel.fromJson(json);
      expect(model.id, 's1');
      expect(model.totalSalary, 50000.0);
      expect(model.paidAmount, 20000.0);
      expect(model.advanceAmount, 10000.0);
      expect(model.month, 10);
      expect(model.year, 2023);
    });

    test('toJson should serialize correctly', () {
       final model = SalaryModel(
        driverId: 'd1',
        totalSalary: 50000.0,
        paidAmount: 20000.0,
        advanceAmount: 10000.0,
        month: 10,
        year: 2023,
      );
      final json = model.toJson();
      expect(json['driver_id'], 'd1');
      expect(json['total_salary'], 50000.0);
      expect(json['paid_amount'], 20000.0);
      expect(json['advance_amount'], 10000.0);
      expect(json['month'], 10);
      expect(json['year'], 2023);
    });
  });
}
