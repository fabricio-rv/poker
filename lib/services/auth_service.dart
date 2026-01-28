import '../models/user.dart';

/// Mock Authentication Service
/// In the future, this can be replaced with Firebase Authentication
class AuthService {
  // Mock user database
  static final List<User> _mockUsers = [
    User(
      id: '1',
      username: 'João',
      password: '123',
      currentXP: 2500,
      totalWins: 15,
      totalMatches: 45,
      joinDate: DateTime(2024, 1, 15),
    ),
    User(
      id: '2',
      username: 'Maria',
      password: '123',
      currentXP: 3200,
      totalWins: 22,
      totalMatches: 50,
      joinDate: DateTime(2024, 2, 10),
    ),
    User(
      id: '3',
      username: 'Pedro',
      password: '123',
      currentXP: 1800,
      totalWins: 10,
      totalMatches: 35,
      joinDate: DateTime(2024, 3, 5),
    ),
    User(
      id: '4',
      username: 'Ana',
      password: '123',
      currentXP: 2800,
      totalWins: 18,
      totalMatches: 42,
      joinDate: DateTime(2024, 1, 20),
    ),
    User(
      id: '5',
      username: 'Carlos',
      password: '123',
      currentXP: 1500,
      totalWins: 8,
      totalMatches: 30,
      joinDate: DateTime(2024, 4, 12),
    ),
    User(
      id: '6',
      username: 'Fernanda',
      password: '123',
      currentXP: 3500,
      totalWins: 25,
      totalMatches: 55,
      joinDate: DateTime(2024, 1, 8),
    ),
    User(
      id: '7',
      username: 'Ricardo',
      password: '123',
      currentXP: 2200,
      totalWins: 14,
      totalMatches: 40,
      joinDate: DateTime(2024, 2, 28),
    ),
    User(
      id: '8',
      username: 'Juliana',
      password: '123',
      currentXP: 1200,
      totalWins: 6,
      totalMatches: 25,
      joinDate: DateTime(2024, 5, 3),
    ),
  ];

  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  /// Mock login - returns user if credentials match
  Future<User?> login(String username, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final user = _mockUsers.firstWhere(
        (u) =>
            u.username.toLowerCase() == username.toLowerCase() &&
            u.password == password,
      );
      _currentUser = user;
      return user;
    } catch (e) {
      return null;
    }
  }

  /// Set guest user (login without credentials)
  Future<void> setGuestUser(User guestUser) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = guestUser;
  }

  /// Register new user
  Future<User?> register(String username, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Verifica se o usuário já existe
    final existingUser = _mockUsers.where(
      (u) => u.username.toLowerCase() == username.toLowerCase(),
    );

    if (existingUser.isNotEmpty) {
      return null; // Usuário já existe
    }

    // Cria novo usuário
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      password: password,
      currentXP: 0,
      totalWins: 0,
      totalMatches: 0,
      joinDate: DateTime.now(),
    );

    // Adiciona ao banco mock
    _mockUsers.add(newUser);

    // Auto-login
    _currentUser = newUser;

    return newUser;
  }

  /// Logout current user
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  /// Update user data (mock implementation)
  Future<User> updateUser(User updatedUser) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Update in mock database
    final index = _mockUsers.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _mockUsers[index] = updatedUser;
    }

    // Update current user if it's the same
    if (_currentUser?.id == updatedUser.id) {
      _currentUser = updatedUser;
    }

    return updatedUser;
  }

  /// Get all users (for ranking)
  Future<List<User>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockUsers);
  }

  /// Get user by ID
  Future<User?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _mockUsers.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add XP to user
  Future<User> addXP(String userId, int xpAmount) async {
    final user = await getUserById(userId);
    if (user != null) {
      final updatedUser = user.copyWith(currentXP: user.currentXP + xpAmount);
      return await updateUser(updatedUser);
    }
    throw Exception('User not found');
  }

  /// Record a match result
  Future<User> recordMatch(String userId, bool isWinner) async {
    final user = await getUserById(userId);
    if (user != null) {
      int xpGain = 100; // Base XP
      if (isWinner) {
        xpGain += 500; // Winner bonus
      }

      final updatedUser = user.copyWith(
        currentXP: user.currentXP + xpGain,
        totalMatches: user.totalMatches + 1,
        totalWins: isWinner ? user.totalWins + 1 : user.totalWins,
      );
      return await updateUser(updatedUser);
    }
    throw Exception('User not found');
  }
}
