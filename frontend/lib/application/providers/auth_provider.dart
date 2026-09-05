import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../../main.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(prefs);
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? userName;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.userName,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? userName,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userName: userName ?? this.userName,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SharedPreferences _prefs;
  static const _authUserKey = 'auth_user_name';

  AuthNotifier(this._prefs) : super(const AuthState()) {
    _restoreSession();
  }

  void _restoreSession() {
    final savedUser = _prefs.getString(_authUserKey);
    if (savedUser != null) {
      state = AuthState(isAuthenticated: true, userName: savedUser);
    }
  }

  /// Try backend login first; if backend is unavailable, fall back to local auth
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ApiService.login(email, password);
      if (result != null) {
        // Backend login succeeded
        await _prefs.setString(_authUserKey, email);
        state = state.copyWith(isAuthenticated: true, userName: email, isLoading: false, error: null);
        return;
      }
    } catch (e) {
      debugPrint('Backend login unavailable: $e');
    }
    // Fallback: local-only auth (for offline use)
    await _prefs.setString(_authUserKey, email);
    state = state.copyWith(isAuthenticated: true, userName: email, isLoading: false, error: 'Using offline mode');
  }

  /// Register on backend if reachable, otherwise just store locally.
  Future<void> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ApiService.register(email, password, fullName);
      if (result != null) {
        await _prefs.setString(_authUserKey, email);
        state = state.copyWith(isAuthenticated: true, userName: email, isLoading: false, error: null);
        return;
      }
    } catch (e) {
      debugPrint('Backend register unavailable: $e');
    }
    await _prefs.setString(_authUserKey, email);
    state = state.copyWith(isAuthenticated: true, userName: email, isLoading: false, error: 'Using offline mode');
  }

  Future<void> logout() async {
    await ApiService.logout();
    await _prefs.remove(_authUserKey);
    state = const AuthState();
  }
}
