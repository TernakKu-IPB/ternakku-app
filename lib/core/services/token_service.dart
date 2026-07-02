import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider agar mudah dipanggil di mana saja
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final tokenServiceProvider = Provider((ref) => TokenService(ref.read(secureStorageProvider)));

class TokenService {
  final FlutterSecureStorage _storage;

  TokenService(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  String? _accessToken;
  String? _refreshToken;

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    if (_accessToken != null) {
      return _accessToken;
    }
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    if (_refreshToken != null) {
      return _refreshToken;
    }
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}