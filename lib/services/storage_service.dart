import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _rememberKey = 'remember_session';

  late final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  String? _sessionToken;
  UserModel? _sessionUser;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _sessionToken = await _secureStorage.read(key: _tokenKey);
    final rawUser = _prefs.getString(_userKey);
    if (rawUser != null && rawUser.isNotEmpty) {
      _sessionUser = UserModel.fromJson(
        jsonDecode(rawUser) as Map<String, dynamic>,
      );
    }
  }

  String? get token => _sessionToken;
  bool get rememberSession => _prefs.getBool(_rememberKey) ?? true;

  UserModel? get user {
    return _sessionUser;
  }

  Future<void> saveSession({
    required String token,
    required UserModel user,
    bool remember = true,
  }) async {
    _sessionToken = token;
    _sessionUser = user;
    await _prefs.setBool(_rememberKey, remember);

    if (remember) {
      await _secureStorage.write(key: _tokenKey, value: token);
      await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    } else {
      await _secureStorage.delete(key: _tokenKey);
      await _prefs.remove(_userKey);
    }
  }

  Future<void> saveUser(UserModel user) async {
    _sessionUser = user;
    if (rememberSession) {
      await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    }
  }

  Future<void> clearSession() async {
    _sessionToken = null;
    _sessionUser = null;
    await _secureStorage.delete(key: _tokenKey);
    await _prefs.remove(_userKey);
  }
}
