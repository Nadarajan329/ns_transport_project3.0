import 'package:flutter_test/flutter_test.dart';
import 'package:ns_transport/models/notification_model.dart';

void main() {
  group('NotificationModel Test', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 'n1',
        'user_id': 'u1',
        'title': 'New Trip',
        'message': 'You have a new trip assigned.',
        'is_read': true,
        'type': 'trip',
        'related_id': 't1',
        'created_at': '2023-10-15T10:00:00.000Z'
      };

      final model = NotificationModel.fromJson(json);
      expect(model.id, 'n1');
      expect(model.userId, 'u1');
      expect(model.title, 'New Trip');
      expect(model.message, 'You have a new trip assigned.');
      expect(model.isRead, true);
      expect(model.type, 'trip');
      expect(model.relatedId, 't1');
      expect(model.createdAt, DateTime.parse('2023-10-15T10:00:00.000Z'));
    });

    test('copyWith should copy properties correctly', () {
      final model = NotificationModel(
        id: 'n1',
        userId: 'u1',
        title: 'Title',
        message: 'Message',
        createdAt: DateTime.now(),
      );

      final updated = model.copyWith(isRead: true, title: 'New Title');
      expect(updated.isRead, true);
      expect(updated.title, 'New Title');
      expect(updated.message, 'Message');
      expect(updated.id, 'n1');
    });

    test('toJson should serialize correctly', () {
      final model = NotificationModel(
        id: 'n1',
        userId: 'u1',
        title: 'Title',
        message: 'Message',
        createdAt: DateTime.now(),
      );

      final json = model.toJson();
      expect(json['id'], 'n1');
      expect(json['user_id'], 'u1');
      expect(json['title'], 'Title');
      expect(json['message'], 'Message');
      expect(json['is_read'], false);
    });
  });
}
