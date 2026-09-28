import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserRole = 'user_role';
  static const _keyEmailVerified = 'email_verified';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String role,
    required bool emailVerified,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyUserRole, value: role);
    await _storage.write(key: _keyEmailVerified, value: emailVerified.toString());
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  static Future<bool> isEmailVerified() async {
    final val = await _storage.read(key: _keyEmailVerified);
    return val == 'true';
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
