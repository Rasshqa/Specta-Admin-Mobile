import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final token = await _storage.read(key: 'auth_token');

    if (token != null) {
      try {
        _currentUser = await _apiService.getCurrentUser();
        _isAuthenticated = true;
      } catch (_) {
        await _storage.delete(key: 'auth_token');
        _isAuthenticated = false;
        _currentUser = null;
      }
    } else {
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _apiService.login(email, password);
      _currentUser = user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}
