import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ns_transport/services/supabase_service.dart';

class StorageService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<String> uploadTripDocument(String tripId, String fileName, File file) async {
    final path = 'trip_documents/$tripId/$fileName';
    await _supabase.storage.from('documents').upload(path, file);
    return _supabase.storage.from('documents').getPublicUrl(path);
  }

  Future<String> uploadProfileImage(String userId, File file) async {
    final fileExt = file.path.split('.').last;
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = 'profiles/$fileName';
    await _supabase.storage.from('images').upload(path, file);
    return _supabase.storage.from('images').getPublicUrl(path);
  }

  Future<void> deleteFile(String bucket, String path) async {
    await _supabase.storage.from(bucket).remove([path]);
  }
}
