import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ns_transport/models/trip_model.dart';
import 'package:ns_transport/services/trip_service.dart';
import 'package:ns_transport/providers/auth_provider.dart';

final tripServiceProvider = Provider((ref) => TripService());

class TripNotifier extends StateNotifier<AsyncValue<List<TripModel>>> {
  final TripService _tripService;
  final Ref _ref;

  TripNotifier(this._tripService, this._ref) : super(const AsyncValue.loading());

  Future<void> loadTrips() async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authProvider).value;
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }
      List<TripModel> trips;
      if (user.isOwner) {
        trips = await _tripService.getAllTrips();
      } else {
        trips = await _tripService.getDriverTrips(user.id);
      }
      state = AsyncValue.data(trips);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTrip(TripModel trip) async {
    try {
      final newTrip = await _tripService.createTrip(trip);
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newTrip]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTripStatus(String tripId, String newStatus) async {
    try {
      await _tripService.updateTripStatus(tripId, newStatus);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((trip) {
            if (trip.id == tripId) {
              return trip.copyWith(status: newStatus);
            }
            return trip;
          }).toList(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      await _tripService.deleteTrip(tripId);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((trip) => trip.id != tripId).toList(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, AsyncValue<List<TripModel>>>((ref) {
  return TripNotifier(ref.watch(tripServiceProvider), ref);
});
