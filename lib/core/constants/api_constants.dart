/// Supabase configuration and API constants for NS Transport.
///
/// Replace placeholder values (`YOUR_*`) with real credentials
/// before running the app. In production, prefer loading secrets
/// from environment variables or a `.env` file.
abstract final class ApiConstants {
  // ─── Supabase Configuration ───────────────────────────────────────
  static const String supabaseUrl = 'https://opkukaigfuepwuypxset.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9wa3VrYWlnZnVlcHd1eXB4c2V0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5NTAzMTEsImV4cCI6MjA5NTUyNjMxMX0.ohREx696Y7IbwKgTFvnEDIRB8ac-1dE6xQP1DRnv7-0';

  // ─── Google OAuth ─────────────────────────────────────────────────
  static const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';

  // ─── Database Table Names ─────────────────────────────────────────
  static const String usersTable = 'users';
  static const String tripsTable = 'trips';
  static const String salariesTable = 'salaries';

  // ─── Storage Buckets ──────────────────────────────────────────────
  static const String tripDocumentsBucket = 'trip_documents';
  static const String profileImagesBucket = 'profile_images';

  // ─── Timeouts & Limits ────────────────────────────────────────────
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
  static const int maxFileUploadSizeMB = 10;
  static const int defaultPageSize = 20;
}
