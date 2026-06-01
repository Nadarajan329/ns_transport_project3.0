import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ns_transport/models/notification_model.dart';
import 'package:ns_transport/providers/auth_provider.dart';

final notificationProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationNotifier(ref);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsState = ref.watch(notificationProvider);
  return notificationsState.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref _ref;
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _subscription;

  NotificationNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final user = _ref.read(authProvider).value;
    if (user != null) {
      _fetchNotifications(user.id);
      _subscribeToRealtime(user.id);
    }

    _ref.listen(authProvider, (previous, next) {
      if (next.value != null && previous?.value?.id != next.value?.id) {
        _fetchNotifications(next.value!.id);
        _subscribeToRealtime(next.value!.id);
      } else if (next.value == null) {
        state = const AsyncValue.data([]);
        _unsubscribe();
      }
    });
  }

  Future<void> _fetchNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
          
      final notifications = (response as List).map((n) => NotificationModel.fromJson(n)).toList();
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _subscribeToRealtime(String userId) {
    _unsubscribe();
    _subscription = _supabase.channel('public:notifications:user_id=eq.$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          _fetchNotifications(userId); // Refresh list on change
        },
      )
      .subscribe();
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _supabase.removeChannel(_subscription!);
      _subscription = null;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      
      // The realtime subscription will trigger a refresh, 
      // but we can also update state directly for faster UI response.
      if (state.value != null) {
        final updatedList = state.value!.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      // Handle error quietly or log it
    }
  }

  Future<void> markAllAsRead() async {
    final user = _ref.read(authProvider).value;
    if (user == null) return;
    
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
          
      if (state.value != null) {
        final updatedList = state.value!.map((n) => n.copyWith(isRead: true)).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      // Error handling
    }
  }
  
  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}
