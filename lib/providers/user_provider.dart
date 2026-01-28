import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? get currentUser => _authService.currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Login user
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(username, password);
      _isLoading = false;

      if (user != null) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Usuário ou senha incorretos';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao fazer login: $e';
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao sair: $e';
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateUser(updatedUser);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao atualizar perfil: $e';
      notifyListeners();
      return false;
    }
  }

  /// Add XP to current user
  Future<void> addXP(int amount) async {
    if (currentUser == null) return;

    try {
      await _authService.addXP(currentUser!.id, amount);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao adicionar XP: $e';
      notifyListeners();
    }
  }

  /// Record a match result for current user
  Future<void> recordMatch(bool isWinner) async {
    if (currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.recordMatch(currentUser!.id, isWinner);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao registrar partida: $e';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
