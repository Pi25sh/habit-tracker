import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final loginProvider = StateNotifierProvider<LoginNotifier, bool>((ref) {
  return LoginNotifier();
});

class LoginNotifier extends StateNotifier<bool> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  LoginNotifier() : super(true) {
    _initPasscode();
  }

  Future<void> _initPasscode() async {
    final existingId = await _storage.read(key: 'user_id');
    final existingPass = await _storage.read(key: 'user_pass');

    // Migrate or initialize default if not set
    if (existingId == null || existingPass == null) {
      await _storage.write(key: 'user_id', value: 'shivani');
      await _storage.write(key: 'user_pass', value: 'shivba');
    }
  }

  Future<bool> login(String userId, String password) async {
    try {
      final storedId = await _storage.read(key: 'user_id') ?? 'shivani';
      final storedPass = await _storage.read(key: 'user_pass') ?? 'shivba';

      if (userId.trim().toLowerCase() == storedId && password.trim() == storedPass) {
        state = false; // logged in
        return true;
      }
    } catch (e) {
      // Fallback for when Web Crypto API is unavailable (e.g. accessing via local IP without HTTPS)
      if (userId.trim().toLowerCase() == 'shivani' && password.trim() == 'shivba') {
        state = false;
        return true;
      }
    }
    return false;
  }

  void logout() {
    state = true;
  }
}
