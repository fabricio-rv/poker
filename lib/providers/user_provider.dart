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

  /// Login como convidado (sem autenticação)
  Future<bool> loginAsGuest() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cria um usuário convidado temporário
      final guestUser = User(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        username: 'Jogador Convidado',
        password: '', // Sem senha
        currentXP: 0,
        totalWins: 0,
        totalMatches: 0,
        joinDate: DateTime.now(),
      );

      // Simula delay de carregamento
      await Future.delayed(const Duration(milliseconds: 500));

      await _authService.setGuestUser(guestUser);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao entrar como convidado: $e';
      notifyListeners();
      return false;
    }
  }

  /// Registrar novo usuário
  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(username, password);
      _isLoading = false;

      if (user != null) {
        // Auto-login após registro bem-sucedido
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erro ao criar conta. Usuário já existe?';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao criar conta: $e';
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

  /// Update user profile (username and/or password)
  Future<bool> updateProfile({String? username, String? newPassword}) async {
    if (currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Criar usuário atualizado com novos dados
      final updatedUser = currentUser!.copyWith(
        username: username ?? currentUser!.username,
        password: newPassword ?? currentUser!.password,
      );

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

  /// TASK 1: Complete a match with strict XP rewards
  /// Winner: +500 XP, increment victories and matchesPlayed
  /// Loser: +100 XP (participation), increment matchesPlayed only
  Future<void> completeMatch({required bool isWinner}) async {
    if (currentUser == null) return;

    try {
      // Calculate XP reward based on result
      final xpReward = isWinner ? 500 : 100;
      final newXP = currentUser!.currentXP + xpReward;
      final newWins = isWinner
          ? currentUser!.totalWins + 1
          : currentUser!.totalWins;
      final newMatches = currentUser!.totalMatches + 1;

      // Create updated user with new stats
      final updatedUser = currentUser!.copyWith(
        currentXP: newXP,
        totalWins: newWins,
        totalMatches: newMatches,
      );

      // Update via auth service
      await _authService.updateUser(updatedUser);

      // Notify listeners to update UI immediately
      notifyListeners();
    } catch (e) {
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
