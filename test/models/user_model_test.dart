import 'package:flutter_test/flutter_test.dart';
import 'package:ns_transport/models/user_model.dart';

void main() {
  group('UserModel Test', () {
    test('should parse from JSON correctly', () {
      final json = {
        'id': '1',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '1234567890',
        'role': 'driver',
        'avatar_url': 'http://example.com/avatar.png',
        'advance_balance': 500.0,
        'created_at': '2023-10-15T10:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '1');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '1234567890');
      expect(user.role, 'driver');
      expect(user.avatarUrl, 'http://example.com/avatar.png');
      expect(user.advanceBalance, 500.0);
      expect(user.createdAt, DateTime.parse('2023-10-15T10:00:00.000Z'));
      
      expect(user.isDriver, isTrue);
      expect(user.isOwner, isFalse);
    });

    test('should convert to JSON correctly', () {
      final user = UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'owner',
        advanceBalance: 0.0,
      );

      final json = user.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['role'], 'owner');
      expect(json['advance_balance'], 0.0);
      expect(json.containsKey('phone'), isFalse);
    });

    test('copyWith should update properties correctly', () {
      final user = UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'driver',
      );

      final updatedUser = user.copyWith(name: 'Jane Doe', role: 'owner');
      expect(updatedUser.name, 'Jane Doe');
      expect(updatedUser.role, 'owner');
      expect(updatedUser.id, '1');
      expect(updatedUser.email, 'john@example.com');
    });
  });
}
