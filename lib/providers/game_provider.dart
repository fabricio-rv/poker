import 'package:flutter/foundation.dart';
import '../models/game_session.dart';
import '../models/player_in_game.dart';
import '../models/chip_config.dart';
import '../models/user.dart';
import '../services/game_service.dart';
import '../services/chip_calculator_service.dart';

class GameProvider with ChangeNotifier {
  final GameService _gameService = GameService();

  // Game setup state
  GameMode? _selectedMode;
  List<User> _selectedPlayers = [];
  bool _hasMoneyBet = false;
  double _buyInAmount = 0.0;
  ChipConfig? _calculatedChips;

  // Active game state
  GameSession? _currentGame;
  int _elapsedSeconds = 0;
  int _currentSmallBlind = 5;
  int _currentBigBlind = 10;

  // Multiplayer specific
  double _winProbability = 0.0;

  // Getters
  GameMode? get selectedMode => _selectedMode;
  List<User> get selectedPlayers => _selectedPlayers;
  bool get hasMoneyBet => _hasMoneyBet;
  double get buyInAmount => _buyInAmount;
  ChipConfig? get calculatedChips => _calculatedChips;
  GameSession? get currentGame => _currentGame;
  int get elapsedSeconds => _elapsedSeconds;
  int get currentSmallBlind => _currentSmallBlind;
  int get currentBigBlind => _currentBigBlind;
  double get winProbability => _winProbability;

  bool get isGameActive => _currentGame != null;
  bool get isGameFinished => _currentGame?.isFinished ?? false;

  /// Setup Methods

  void selectMode(GameMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  void togglePlayerSelection(User user) {
    if (_selectedPlayers.any((p) => p.id == user.id)) {
      _selectedPlayers.removeWhere((p) => p.id == user.id);
    } else {
      _selectedPlayers.add(user);
    }
    notifyListeners();
  }

  bool isPlayerSelected(User user) {
    return _selectedPlayers.any((p) => p.id == user.id);
  }

  void setMoneyBet(bool value) {
    _hasMoneyBet = value;
    if (!value) {
      _buyInAmount = 0.0;
    }
    notifyListeners();
  }

  void setBuyInAmount(double amount) {
    _buyInAmount = amount;
    notifyListeners();
  }

  void calculateChips() {
    if (_selectedPlayers.isEmpty) return;

    final distribution = ChipCalculatorService.calculateDistribution(
      _selectedPlayers.length,
    );

    _calculatedChips = ChipConfig(
      whiteChips: distribution['white'] ?? 0,
      redChips: distribution['red'] ?? 0,
      greenChips: distribution['green'] ?? 0,
      blueChips: distribution['blue'] ?? 0,
      blackChips: distribution['black'] ?? 0,
    );
    notifyListeners();
  }

  /// Start a new game
  Future<void> startGame() async {
    if (_selectedMode == null ||
        _selectedPlayers.isEmpty ||
        _calculatedChips == null) {
      return;
    }

    final players = _selectedPlayers.map((user) {
      return PlayerInGame(
        userId: user.id,
        username: user.username,
        initialChips: _calculatedChips!,
      );
    }).toList();

    _currentGame = await _gameService.createGame(
      players: players,
      gameMode: _selectedMode!,
      isRanked: true,
      buyInAmount: _buyInAmount,
    );

    // Reset timer
    _elapsedSeconds = 0;

    notifyListeners();
  }

  /// Game Actions

  Future<void> eliminatePlayer(String userId) async {
    if (_currentGame == null) return;

    await _gameService.eliminatePlayer(userId);
    notifyListeners();
  }

  Future<void> rebuyPlayer(String userId) async {
    if (_currentGame == null) return;

    await _gameService.rebuyPlayer(userId);
    notifyListeners();
  }

  Future<GameSession?> finishGame(String winnerId) async {
    if (_currentGame == null) return null;

    final completedGame = await _gameService.completeGame(winnerId);
    _currentGame = null;

    // Reset setup
    _resetSetup();

    notifyListeners();
    return completedGame;
  }

  Future<void> cancelGame() async {
    await _gameService.cancelGame();
    _currentGame = null;
    _resetSetup();
    notifyListeners();
  }

  /// Timer management
  void incrementTimer() {
    _elapsedSeconds++;

    // Auto-increase blinds every 10 minutes (600 seconds)
    if (_elapsedSeconds % 600 == 0) {
      _currentSmallBlind = (_currentSmallBlind * 1.5).round();
      _currentBigBlind = _currentSmallBlind * 2;
    }

    notifyListeners();
  }

  String get formattedTime {
    final minutes = (_elapsedSeconds / 60).floor();
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Multiplayer specific methods
  void updateWinProbability(double probability) {
    _winProbability = probability;
    notifyListeners();
  }

  void mockCalculateOdds() {
    // Mock calculation - in real app this would be based on cards
    _winProbability = 50.0 + (DateTime.now().millisecond % 40 - 20);
    notifyListeners();
  }

  /// Helper methods
  void _resetSetup() {
    _selectedMode = null;
    _selectedPlayers = [];
    _hasMoneyBet = false;
    _buyInAmount = 0.0;
    _calculatedChips = null;
    _elapsedSeconds = 0;
    _currentSmallBlind = 5;
    _currentBigBlind = 10;
    _winProbability = 0.0;
  }

  void resetSetup() {
    _resetSetup();
    notifyListeners();
  }
}
