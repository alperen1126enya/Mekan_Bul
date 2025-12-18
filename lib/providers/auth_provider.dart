import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if there's a saved session and restore it
  Future<bool> checkSession() async {
    try {
      final sessionData = await _sessionService.getSession();
      if (sessionData != null) {
        final user = await _authService.getUserById(sessionData['id']);
        if (user != null) {
          _currentUser = user;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        username: username,
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        // Save session
        await _sessionService.saveSession(
          userId: user.id!,
          username: user.username,
          email: user.email,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Kayıt işlemi başarısız oldu';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        // Save session
        await _sessionService.saveSession(
          userId: user.id!,
          username: user.username,
          email: user.email,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Giriş başarısız oldu';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _sessionService.clearSession();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_currentUser?.id != null) {
      final user = await _authService.getUserById(_currentUser!.id!);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    }
  }
}
