import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  UserProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    firebase_auth.FirebaseAuth.instance.authStateChanges().listen((
      firebaseUser,
    ) async {
      if (firebaseUser != null) {
        await refreshUser();
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> refreshUser() async {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await _loadUserFromFirestore(firebaseUser.uid);
    }
  }

  Future<void> _loadUserFromFirestore(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var user = await _firestoreService.getUser(uid);

      // Tenta novamente após 1 segundo se não achar (ajuda no primeiro cadastro)
      if (user == null) {
        await Future.delayed(const Duration(seconds: 1));
        user = await _firestoreService.getUser(uid);
      }

      if (user != null) {
        _currentUser = user;
      } else {
        _errorMessage = "Perfil não encontrado no servidor.";
      }
    } catch (e) {
      _errorMessage = "Erro ao carregar dados: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CORREÇÃO: Chamada usando parâmetros posicionais ou nomeados conforme seu AuthService
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Se o seu AuthService.signIn usar parâmetros nomeados:
    final result = await _authService.signIn(email: email, password: password);

    if (result['success']) {
      await _loadUserFromFirestore(result['uid']);
      return true;
    } else {
      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.signUp(email, password, name);

    if (result['success']) {
      await Future.delayed(const Duration(milliseconds: 800));
      await _loadUserFromFirestore(result['uid']);
      return true;
    } else {
      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> updateProfile(String name, String? avatarUrl) async {
    if (_currentUser == null) return false;
    try {
      await _firestoreService.updateUser(_currentUser!.id, {
        'username': name,
        'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (avatarUrl != null) 'photoUrl': avatarUrl,
      });
      await refreshUser();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar: $e';
      notifyListeners();
      return false;
    }
  }

  /// Record match result
  Future<void> recordMatch(bool isWinner) async {
    if (_currentUser == null) return;

    try {
      await _firestoreService.recordMatchResult(
        uid: _currentUser!.id,
        isWinner: isWinner,
      );
      await refreshUser();
    } catch (e) {
      print('Error recording match: $e');
    }
  }

  /// Complete match (alias for recordMatch)
  Future<void> completeMatch({required bool isWinner}) async {
    await recordMatch(isWinner);
  }
}
