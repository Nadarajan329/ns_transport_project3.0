import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ns_transport/models/trip_model.dart';
import 'package:ns_transport/core/errors/failure.dart';
import 'package:ns_transport/services/supabase_service.dart';

class TripService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<List<TripModel>> getDriverTrips(String driverId) async {
    try {
      final response = await _supabase
          .from('trips')
          .select()
          .eq('driver_id', driverId)
          .order('trip_date', ascending: false);
      
      return response.map((json) => TripModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerFailure(message: 'Failed to get driver trips: $e');
    }
  }

  Future<List<TripModel>> getAllTrips() async {
    try {
      final response = await _supabase
          .from('trips')
          .select()
          .order('trip_date', ascending: false);
      
      return response.map((json) => TripModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerFailure(message: 'Failed to get all trips: $e');
    }
  }

  Future<TripModel> getTripById(String id) async {
    try {
      final response = await _supabase
          .from('trips')
          .select()
          .eq('id', id)
          .single();
      
      return TripModel.fromJson(response);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get trip by id: $e');
    }
  }

  Future<TripModel> createTrip(TripModel trip) async {
    try {
      final response = await _supabase
          .from('trips')
          .insert(trip.toJson())
          .select()
          .single();
      
      return TripModel.fromJson(response);
    } catch (e) {
      throw ServerFailure(message: 'Failed to create trip: $e');
    }
  }

  Future<TripModel> updateTrip(TripModel trip) async {
    try {
      final response = await _supabase
          .from('trips')
          .update(trip.toJson())
          .eq('id', trip.id!)
          .select()
          .single();
      
      return TripModel.fromJson(response);
    } catch (e) {
      throw ServerFailure(message: 'Failed to update trip: $e');
    }
  }

  Future<void> updateTripStatus(String id, String status, {String? comment}) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
      };
      
      if (comment != null) {
        updateData['owner_comment'] = comment;
      }
      
      await _supabase
          .from('trips')
          .update(updateData)
          .eq('id', id);
    } catch (e) {
      throw ServerFailure(message: 'Failed to update trip status: $e');
    }
  }

  Future<void> deleteTrip(String id) async {
    try {
      await _supabase
          .from('trips')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw ServerFailure(message: 'Failed to delete trip: $e');
    }
  }

  Future<String> uploadImage(File file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = '$folder/$fileName';
      await _supabase.storage.from('trip_images').upload(path, file);
      return _supabase.storage.from('trip_images').getPublicUrl(path);
    } catch (e) {
      throw ServerFailure(message: 'Failed to upload image: $e');
    }
  }
}
