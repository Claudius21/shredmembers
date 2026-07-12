import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  User? get currentSupabaseUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AppUser> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user!;
    try {
      return await _fetchProfile(user);
    } catch (_) {
      // Profile row missing – create it now
      await _client.from('profiles').upsert({
        'id': user.id,
        'name': user.userMetadata?['name'] as String? ?? '',
        'goal': 'buildMuscle',
        'weekly_target': 4,
      });
      return await _fetchProfile(user);
    }
  }

  Future<AppUser> signUp(String name, String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    final user = response.user;
    if (user == null) {
      throw Exception('Signup failed. Check your email for a confirmation link.');
    }
    // Wait briefly for the DB trigger to create the profile row
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return await _fetchProfile(user);
    } catch (_) {
      // Profile trigger may not have run yet – return minimal user
      return AppUser(
        id: user.id,
        name: name,
        email: email,
        goal: FitnessGoal.buildMuscle,
        weeklyTargetDays: 4,
        joinedAt: DateTime.now(),
      );
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<bool> verifyMagicLink(String token, String type) async {
    try {
      await _client.auth.verifyOTP(
        token: token,
        type: type == 'magiclink' ? OtpType.magiclink : OtpType.signup,
      );
      return true;
    } catch (e) {
      debugPrint('Error verifying magic link: $e');
      return false;
    }
  }

  Future<bool> setSession(String accessToken, String refreshToken) async {
    try {
      await _client.auth.setSession(refreshToken);
      return true;
    } catch (e) {
      debugPrint('Error setting session: $e');
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<AppUser?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user);
  }

  Future<AppUser> _fetchProfile(User user) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return AppUser(
      id: user.id,
      name: data['name'] as String? ?? '',
      email: user.email ?? '',
      goal: _parseGoal(data['goal'] as String?),
      weeklyTargetDays: data['weekly_target'] as int? ?? 4,
      avatarUrl: data['avatar_url'] as String?,
      gender: _parseGender(data['gender'] as String?),
      heightCm: (data['height_cm'] as num?)?.toDouble(),
      weightKg: (data['weight_kg'] as num?)?.toDouble(),
      joinedAt: DateTime.parse(data['created_at'] as String),
    );
  }

  Future<void> updateProfile(AppUser user) async {
    await _client.from('profiles').update({
      'name': user.name,
      'goal': user.goal.name,
      'weekly_target': user.weeklyTargetDays,
      if (user.gender != null) 'gender': user.gender!.name,
      if (user.heightCm != null) 'height_cm': user.heightCm,
      if (user.weightKg != null) 'weight_kg': user.weightKg,
    }).eq('id', user.id);
  }

  FitnessGoal _parseGoal(String? value) => switch (value) {
        'loseWeight' => FitnessGoal.loseWeight,
        'buildMuscle' => FitnessGoal.buildMuscle,
        'improveEndurance' => FitnessGoal.improveEndurance,
        'stayActive' => FitnessGoal.stayActive,
        _ => FitnessGoal.buildMuscle,
      };

  Gender? _parseGender(String? value) => switch (value) {
        'male' => Gender.male,
        'female' => Gender.female,
        'other' => Gender.other,
        'preferNotToSay' => Gender.preferNotToSay,
        _ => null,
      };
}
