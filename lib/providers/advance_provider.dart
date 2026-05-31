import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ns_transport/models/advance_history_model.dart';
import 'package:ns_transport/services/advance_service.dart';

final advanceServiceProvider = Provider((ref) => AdvanceService());

final advanceHistoryProvider = StateNotifierProvider.family<AdvanceHistoryNotifier, AsyncValue<List<AdvanceHistoryModel>>, String>((ref, driverId) {
  final service = ref.read(advanceServiceProvider);
  return AdvanceHistoryNotifier(service, driverId);
});

class AdvanceHistoryNotifier extends StateNotifier<AsyncValue<List<AdvanceHistoryModel>>> {
  final AdvanceService _advanceService;
  final String _driverId;

  AdvanceHistoryNotifier(this._advanceService, this._driverId) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      state = const AsyncValue.loading();
      final history = await _advanceService.getAdvanceHistory(_driverId);
      state = AsyncValue.data(history);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> giveAdvance(double amount, String description) async {
    try {
      final newEntry = await _advanceService.giveAdvance(_driverId, amount, description);
      if (state.hasValue) {
        state = AsyncValue.data([newEntry, ...state.value!]);
      } else {
        state = AsyncValue.data([newEntry]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deductAdvance(double amount, String description) async {
    try {
      final newEntry = await _advanceService.deductAdvance(_driverId, amount, description);
      if (state.hasValue) {
        state = AsyncValue.data([newEntry, ...state.value!]);
      } else {
        state = AsyncValue.data([newEntry]);
      }
    } catch (e) {
      rethrow;
    }
  }
}
