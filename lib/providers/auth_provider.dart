import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isAuthenticated = false;
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'admin_auth_token');
    _isAuthenticated = (token == AppConstants.adminSecret);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    if (username.trim().toLowerCase() == AppConstants.defaultAdminUser &&
        password.trim() == AppConstants.defaultAdminPass) {
      await _storage.write(key: 'admin_auth_token', value: AppConstants.adminSecret);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'admin_auth_token');
    _isAuthenticated = false;
    notifyListeners();
  }
}