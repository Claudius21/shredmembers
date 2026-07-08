import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/auth_repository.dart';
import 'supabase_providers.dart';
import 'subscription_provider.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  final bool rememberMe;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.rememberMe = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    bool? rememberMe,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage,
        rememberMe: rememberMe ?? this.rememberMe,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  SharedPreferences? _prefs;
  
  // Keys for SharedPreferences
  static const String _keyEmail = 'saved_email';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyLastSession = 'last_session_time';

  @override
  AuthState build() {
    // Restore session on cold start
    _restoreSession();
    return const AuthState(status: AuthStatus.loading);
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _restoreSession() async {
    await _initPrefs();
    
    try {
      // Check if remember me is enabled
      final rememberMe = _prefs?.getBool(_keyRememberMe) ?? false;
      final lastSession = _prefs?.getInt(_keyLastSession);
      
      // If no remember me and session expired (7 days), clear
      if (!rememberMe && lastSession != null) {
        final lastSessionTime = DateTime.fromMillisecondsSinceEpoch(lastSession);
        final daysSinceSession = DateTime.now().difference(lastSessionTime).inDays;
        if (daysSinceSession > 7) {
          await _clearSavedSession();
          state = const AuthState(status: AuthStatus.unauthenticated);
          return;
        }
      }
      
      // Extended timeout for better reliability (15 seconds)
      final user = await _repo.getCurrentUser().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Session restore timed out - using cached credentials if available');
          return null;
        },
      );
      
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          rememberMe: rememberMe,
        );
        // Update last session time
        await _prefs?.setInt(_keyLastSession, DateTime.now().millisecondsSinceEpoch);
        // Subscription laden
        await ref.read(subscriptionProvider.notifier).loadSubscription();
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          rememberMe: rememberMe,
        );
      }
    } catch (e) {
      print('Session restore error: $e');
      state = AuthState(
        status: AuthStatus.unauthenticated,
        rememberMe: _prefs?.getBool(_keyRememberMe) ?? false,
      );
    }
  }
  
  Future<void> _clearSavedSession() async {
    await _prefs?.remove(_keyEmail);
    await _prefs?.remove(_keyRememberMe);
    await _prefs?.remove(_keyLastSession);
  }
  
  Future<void> _saveSession(String email, bool rememberMe) async {
    if (rememberMe) {
      await _prefs?.setString(_keyEmail, email);
      await _prefs?.setBool(_keyRememberMe, true);
    } else {
      // Still save email for convenience, but don't auto-login
      await _prefs?.setString(_keyEmail, email);
      await _prefs?.setBool(_keyRememberMe, false);
    }
    await _prefs?.setInt(_keyLastSession, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> signIn(String email, String password, {bool rememberMe = false}) async {
    state = AuthState(status: AuthStatus.loading, rememberMe: rememberMe);
    try {
      final user = await _repo.signIn(email, password);
      await _saveSession(email, rememberMe);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        rememberMe: rememberMe,
      );
      // Subscription laden nach Login
      await ref.read(subscriptionProvider.notifier).loadSubscription();
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseError(e),
        rememberMe: rememberMe,
      );
      return false;
    }
  }
  
  String? getSavedEmail() {
    return _prefs?.getString(_keyEmail);
  }
  
  Future<void> refreshSession() async {
    if (state.status != AuthStatus.authenticated) return;
    
    try {
      final user = await _repo.getCurrentUser().timeout(
        const Duration(seconds: 10),
      );
      if (user != null) {
        state = state.copyWith(user: user);
      }
    } catch (e) {
      print('Session refresh failed: $e');
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _repo.signUp(name, email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      // Subscription laden nach Signup (wird automatisch erstellt via Trigger)
      await ref.read(subscriptionProvider.notifier).loadSubscription();
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseError(e, isSignUp: true),
      );
      return false;
    }
  }

  Future<void> signOut({bool clearSavedData = false}) async {
    await _repo.signOut();
    if (clearSavedData) {
      await _clearSavedSession();
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _repo.resetPassword(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateUser(AppUser updated) async {
    try {
      await _repo.updateProfile(updated);
      state = state.copyWith(user: updated);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  String _parseError(Object e, {bool isSignUp = false}) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login') ||
        msg.contains('invalid credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('bad request') ||
        msg.contains('400')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('already registered') || msg.contains('user already')) {
      return 'This email is already registered.';
    }
    if (msg.contains('network') || msg.contains('failed to fetch')) {
      return 'Network error. Please check your connection.';
    }
    if (msg.contains('email not confirmed') || msg.contains('confirmation')) {
      return 'Please confirm your email address first.';
    }
    return isSignUp
        ? 'Sign up failed. Please try again.'
        : 'Sign in failed. Please try again.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
