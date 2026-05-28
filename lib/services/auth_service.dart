import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ns_transport/core/constants/api_constants.dart';
import 'package:ns_transport/models/user_model.dart';
import 'package:ns_transport/services/supabase_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await signInWithEmail(email, password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required UserModel userModel,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': userModel.name,
        'role': userModel.role,
      },
    );

    if (response.user != null) {
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'name': userModel.name,
        'role': userModel.role,
        if (userModel.phone != null) 'phone': userModel.phone,
        if (userModel.avatarUrl != null) 'avatar_url': userModel.avatarUrl,
      });
    }

    return response;
  }

  Future<AuthResponse?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: ApiConstants.googleWebClientId,
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;
    final accessToken = googleAuth?.accessToken;
    final idToken = googleAuth?.idToken;

    if (accessToken == null || idToken == null) {
      return null;
    }

    return await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Future<UserModel?> getCurrentUser() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await getUserProfile(user.id);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> getUserProfile(String uid) async {
    final response = await _supabase.from('users').select().eq('id', uid).single();
    return UserModel.fromJson(response);
  }

  Future<void> createUserProfile(UserModel userModel) async {
    await _supabase.from('users').upsert(userModel.toJson());
  }
}
