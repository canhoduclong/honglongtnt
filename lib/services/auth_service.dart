import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  AuthService(this._api, this._storage);

  final ApiService _api;
  final StorageService _storage;

  UserModel? get cachedUser => _storage.user;
  bool get hasToken => (_storage.token ?? '').isNotEmpty;

  Future<UserModel?> restoreSession() async {
    if (!hasToken) return null;
    final response = await _api.getJson('/auth/me');
    final user = UserModel.fromJson(
      response['data']['user'] as Map<String, dynamic>,
    );
    await _storage.saveUser(user);
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    final response = await _api.postJson(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'device_name': 'Android Flutter',
        'platform': 'android',
        'app_version': '1.0.0',
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'].toString();
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.saveSession(token: token, user: user, remember: remember);
    return user;
  }

  Future<UserModel> switchRole(String role) async {
    final response = await _api.postJson(
      '/auth/switch-role',
      data: {'role': role},
    );
    final user = UserModel.fromJson(
      response['data']['user'] as Map<String, dynamic>,
    );
    await _storage.saveUser(user);
    return user;
  }

  Future<void> logout() async {
    try {
      if (hasToken) {
        await _api.postJson('/auth/logout');
      }
    } finally {
      await _storage.clearSession();
    }
  }

  Future<void> saveUser(UserModel user) => _storage.saveUser(user);
}
