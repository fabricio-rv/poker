import '../models/game_session.dart';
import '../models/player_in_game.dart';

/// Mock Game Service
/// Manages game sessions and game state
class GameService {
  final List<GameSession> _mockGames = [];
  GameSession? _currentGame;

  GameSession? get currentGame => _currentGame;

  /// Create a new game session
  Future<GameSession> createGame({
    required List<PlayerInGame> players,
    required GameMode gameMode,
    required bool isRanked,
    required double buyInAmount,
    required bool isProgressiveBlind,
    required String hostUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final game = GameSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      players: players,
      gameMode: gameMode,
      isRanked: isRanked,
      buyInAmount: buyInAmount,
      isProgressiveBlind: isProgressiveBlind,
      hostId: hostUserId,
    );

    _mockGames.add(game);
    _currentGame = game;
    return game;
  }

  /// Eliminate a player from the current game
  Future<void> eliminatePlayer(String userId) async {
    if (_currentGame == null) return;

    await Future.delayed(const Duration(milliseconds: 200));

    final playerIndex = _currentGame!.players.indexWhere(
      (p) => p.userId == userId,
    );
    if (playerIndex != -1) {
      _currentGame!.players[playerIndex].isEliminated = true;
    }
  }

  /// Rebuy for a player
  Future<void> rebuyPlayer(String userId) async {
    if (_currentGame == null) return;

    await Future.delayed(const Duration(milliseconds: 200));

    final playerIndex = _currentGame!.players.indexWhere(
      (p) => p.userId == userId,
    );
    if (playerIndex != -1) {
      _currentGame!.players[playerIndex].rebuyCount++;
      _currentGame!.players[playerIndex].isEliminated = false;
    }
  }

  /// Complete the current game with a winner
  Future<GameSession> completeGame(String winnerId) async {
    if (_currentGame == null) {
      throw Exception('No active game');
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final completedGame = _currentGame!.copyWith(
      winnerId: winnerId,
      isCompleted: true,
    );

    // Update in mock database
    final index = _mockGames.indexWhere((g) => g.id == completedGame.id);
    if (index != -1) {
      _mockGames[index] = completedGame;
    }

    _currentGame = null;
    return completedGame;
  }

  /// Cancel the current game
  Future<void> cancelGame() async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_currentGame != null) {
      _mockGames.removeWhere((g) => g.id == _currentGame!.id);
      _currentGame = null;
    }
  }

  /// Get game history
  Future<List<GameSession>> getGameHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockGames.where((g) => g.isCompleted));
  }

  /// Get active game
  Future<GameSession?> getActiveGame() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentGame;
  }
}
