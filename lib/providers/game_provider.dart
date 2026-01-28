import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_session.dart';
import '../models/player_in_game.dart';
import '../models/chip_config.dart';
import '../models/user.dart';
import '../services/game_service.dart';
import '../services/chip_calculator_service.dart';
import '../services/firestore_service.dart';

/// Match Result - Stores the outcome of a completed game
class MatchResult {
  final String winnerUserId;
  final String winnerUsername;
  final String winningHandType; // e.g., "Full House", "Flush"
  final Map<String, XPResult> participantResults; // userId -> XPResult

  MatchResult({
    required this.winnerUserId,
    required this.winnerUsername,
    required this.winningHandType,
    required this.participantResults,
  });
}

/// XP Result for a participant
class XPResult {
  final String username;
  final int previousXP;
  final int currentXP;

  XPResult({
    required this.username,
    required this.previousXP,
    required this.currentXP,
  });

  int get xpGained => currentXP - previousXP;
}

/// Provider principal para gerenciamento de estado do jogo de poker
/// Implementa toda a lógica de temporização, blinds, eliminação e rebuys
/// NOW WITH FIREBASE INTEGRATION - Real-time sync with Firestore
class GameProvider with ChangeNotifier {
  final GameService _gameService = GameService();
  final FirestoreService _firestoreService = FirestoreService();

  // Firebase Auth state
  firebase_auth.User? _firebaseUser;
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  // Firebase session stream
  String? _activeSessionId;
  StreamSubscription<GameSession?>? _sessionSubscription;

  // Event stream for session cancellation (broadcast to all participants)
  final _sessionCanceledController = StreamController<bool>.broadcast();

  // ========== Estado de Configuração do Jogo ==========
  GameMode? _selectedMode;
  List<User> _selectedPlayers = [];
  bool _hasMoneyBet = false;
  double _buyInAmount = 0.0;
  ChipConfig? _calculatedChips;
  bool _isProgressiveBlind = true; // true = Tournament, false = Cash Game

  // ========== Estado do Jogo Ativo ==========
  GameSession? _currentGame;

  // Timer e Blinds
  Timer? _blindTimer;
  int _remainingSeconds = 1200; // 20 minutos por padrão
  int _elapsedSeconds = 0; // Para modo Cash Game (count-up)
  int _currentBlindLevel = 1;
  int _currentSmallBlind = 5;
  int _currentBigBlind = 10;

  // Dealer
  int _dealerIndex = 0;

  // Estrutura de blinds progressiva
  final List<Map<String, int>> _blindStructure = [
    {'level': 1, 'small': 5, 'big': 10},
    {'level': 2, 'small': 10, 'big': 20},
    {'level': 3, 'small': 25, 'big': 50},
    {'level': 4, 'small': 50, 'big': 100},
    {'level': 5, 'small': 100, 'big': 200},
    {'level': 6, 'small': 200, 'big': 400},
    {'level': 7, 'small': 400, 'big': 800},
    {'level': 8, 'small': 800, 'big': 1600},
  ];

  // Multiplayer específico
  bool _isHost =
      true; // true = Host (Manager Mode), false = Guest (Player Mode)

  // Match result (synced from Firestore when game ends)
  MatchResult? _matchResult;

  // ========== Getters ==========
  GameMode? get selectedMode => _selectedMode;
  List<User> get selectedPlayers => _selectedPlayers;
  bool get hasMoneyBet => _hasMoneyBet;
  double get buyInAmount => _buyInAmount;
  ChipConfig? get calculatedChips => _calculatedChips;
  GameSession? get currentGame => _currentGame;
  bool get isProgressiveBlind => _isProgressiveBlind;

  int get remainingSeconds => _remainingSeconds;
  int get elapsedSeconds => _elapsedSeconds;
  int get currentBlindLevel => _currentBlindLevel;
  int get currentSmallBlind => _currentSmallBlind;
  int get currentBigBlind => _currentBigBlind;
  int get dealerIndex => _dealerIndex;
  bool get isHost => _isHost;
  MatchResult? get matchResult => _matchResult;
  String? get activeSessionId => _activeSessionId;

  bool get isGameActive => _currentGame != null;
  bool get isGameFinished => _currentGame?.isFinished ?? false;
  firebase_auth.User? get firebaseUser => _firebaseUser;
  Stream<bool> get sessionCanceledStream => _sessionCanceledController.stream;

  // Constructor - Initialize Firebase auth listener
  GameProvider() {
    _initAuthListener();
  }

  /// Retorna o próximo nível de blinds (ou null se já estiver no último)
  Map<String, int>? get nextBlindLevel {
    if (_currentBlindLevel < _blindStructure.length) {
      return _blindStructure[_currentBlindLevel]; // próximo nível (índice atual pois começa em 1)
    }
    return null;
  }

  /// Tempo formatado (MM:SS)
  String get formattedTime {
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Tempo decorrido formatado para Cash Game (MM:SS)
  String get formattedElapsedTime {
    final minutes = (_elapsedSeconds / 60).floor();
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ========== Métodos de Configuração ==========

  void selectMode(GameMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  void setIsHost(bool isHost) {
    _isHost = isHost;
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

  // ========== Iniciar Jogo ==========

  /// Inicia um novo jogo e começa o timer de blinds
  /// NOW WITH FIREBASE: Creates session in Firestore
  Future<void> startGame() async {
    if (_selectedMode == null ||
        _selectedPlayers.isEmpty ||
        _calculatedChips == null ||
        _firebaseUser == null) {
      return;
    }

    // Get Host user data from Firestore
    final hostUser = await _firestoreService.getUser(_firebaseUser!.uid);
    if (hostUser == null) {
      debugPrint('Erro: não foi possível carregar dados do Host');
      return;
    }

    // Create players list including Host + selected players
    final players = <PlayerInGame>[
      // Add Host first
      PlayerInGame(
        userId: hostUser.id,
        username: hostUser.username,
        initialChips: _calculatedChips!,
      ),
      // Add selected players
      ..._selectedPlayers.map((user) {
        return PlayerInGame(
          userId: user.id,
          username: user.username,
          initialChips: _calculatedChips!,
        );
      }),
    ];

    // Create local game session
    _currentGame = await _gameService.createGame(
      players: players,
      gameMode: _selectedMode!,
      isRanked: true,
      buyInAmount: _buyInAmount,
      isProgressiveBlind: _isProgressiveBlind,
      hostUserId: hostUser.id,
    );

    // Create session in Firebase
    if (_currentGame != null) {
      final sessionId = await _firestoreService.createSession(_currentGame!);
      if (sessionId != null) {
        _activeSessionId = sessionId;
        // Subscribe to real-time updates
        await joinSession(sessionId);
      }
    }

    // Reset e inicia timer de blinds
    _remainingSeconds = 1200; // 20 minutos
    _elapsedSeconds = 0;
    _currentBlindLevel = 1;
    _currentSmallBlind = _blindStructure[0]['small']!;
    _currentBigBlind = _blindStructure[0]['big']!;
    _dealerIndex = 0;

    // Só inicia timer se for modo progressivo (Torneio)
    if (_isProgressiveBlind) {
      _startBlindTimer();
    } else {
      // Modo Cash Game: inicia count-up timer
      _startBlindTimer();
    }

    notifyListeners();
  }

  // ========== Timer e Blinds ==========

  /// Inicia o timer de countdown para blinds
  void _startBlindTimer() {
    _blindTimer?.cancel();
    _blindTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // Timer zerou - aumentar blinds
        _onTimerComplete();
      }
    });
  }

  /// Chamado quando o timer chega a 00:00
  void _onTimerComplete() async {
    // Vibração e notificação
    try {
      await HapticFeedback.heavyImpact();
      // TODO: Tocar som de alerta aqui (requer package audioplayers)
    } catch (e) {
      debugPrint('Erro ao executar feedback háptico: $e');
    }

    // Aumentar nível de blinds
    if (_currentBlindLevel < _blindStructure.length) {
      _currentBlindLevel++;
      _currentSmallBlind = _blindStructure[_currentBlindLevel - 1]['small']!;
      _currentBigBlind = _blindStructure[_currentBlindLevel - 1]['big']!;

      // Reset timer para próximo nível
      _remainingSeconds = 1200; // 20 minutos novamente

      notifyListeners();

      debugPrint(
        '📢 Blinds aumentados! Nível $_currentBlindLevel: $_currentSmallBlind/$_currentBigBlind',
      );
    } else {
      // Já está no nível máximo - apenas reseta o timer
      _remainingSeconds = 1200;
      notifyListeners();
    }
  }

  /// Aumenta os blinds manualmente (para testes ou ajustes)
  void increaseBlindsManually() {
    _remainingSeconds = 0; // Força o timer a completar
    notifyListeners();
  }

  // ========== Gerenciamento de Jogadores ==========

  /// Elimina um jogador e registra sua posição final
  Future<void> eliminatePlayer(String userId) async {
    if (_currentGame == null) return;

    // Encontra o jogador
    final playerIndex = _currentGame!.players.indexWhere(
      (p) => p.userId == userId,
    );
    if (playerIndex == -1) return;

    // Marca como eliminado
    _currentGame!.players[playerIndex].isEliminated = true;

    // Calcula e registra a posição (quantos jogadores ainda estão ativos + 1)
    final remainingPlayers = _currentGame!.players
        .where((p) => !p.isEliminated)
        .length;
    final position = remainingPlayers + 1;

    debugPrint(
      '🚫 ${_currentGame!.players[playerIndex].username} eliminado em $position'
      'º lugar',
    );

    // Atualiza no serviço (local)
    await _gameService.eliminatePlayer(userId);

    // CRITICAL MULTIPLAYER FIX: Sync elimination to Firestore so all participants see it
    if (_activeSessionId != null) {
      await _firestoreService.eliminatePlayer(_activeSessionId!, userId);
    }

    // O jogo acabou automaticamente quando remainingPlayers == 1
    // (isFinished é um getter que verifica activePlayers.length)

    notifyListeners();
  }

  /// Realiza rebuy para um jogador eliminado
  Future<void> rebuyPlayer(String userId) async {
    if (_currentGame == null) return;

    final playerIndex = _currentGame!.players.indexWhere(
      (p) => p.userId == userId,
    );
    if (playerIndex == -1) return;

    // Reativa o jogador
    _currentGame!.players[playerIndex].isEliminated = false;
    _currentGame!.players[playerIndex].rebuyCount++;

    final rebuyCount = _currentGame!.players[playerIndex].rebuyCount;
    debugPrint(
      '🔄 ${_currentGame!.players[playerIndex].username} fez rebuy (total: $rebuyCount)',
    );

    await _gameService.rebuyPlayer(userId);
    notifyListeners();
  }

  // ========== Dealer ==========

  /// Rotaciona o dealer para o próximo jogador ativo
  Future<void> rotateDealer() async {
    if (_currentGame == null || _currentGame!.players.isEmpty) return;

    final activePlayers = _currentGame!.players
        .asMap()
        .entries
        .where((entry) => !entry.value.isEliminated)
        .toList();

    if (activePlayers.isEmpty) return;

    // Encontra o índice atual do dealer na lista de ativos
    int currentDealerIndexInActive = activePlayers.indexWhere(
      (entry) => entry.key == _dealerIndex,
    );

    // Próximo dealer (circular)
    if (currentDealerIndexInActive == -1 || activePlayers.length == 1) {
      _dealerIndex = activePlayers.first.key;
    } else {
      final nextIndex = (currentDealerIndexInActive + 1) % activePlayers.length;
      _dealerIndex = activePlayers[nextIndex].key;
    }

    debugPrint(
      '🃏 Dealer rotacionado para: ${_currentGame!.players[_dealerIndex].username}',
    );

    // CRITICAL MULTIPLAYER FIX: Sync dealer to Firestore so all participants see it
    if (_activeSessionId != null) {
      await _firestoreService.updateDealer(_activeSessionId!, _dealerIndex);
    }

    notifyListeners();
  }

  // ========== Finalização ==========

  /// Finaliza o jogo e retorna os dados completos
  Future<GameSession?> finishGame(String winnerId) async {
    if (_currentGame == null) return null;

    _blindTimer?.cancel();

    final completedGame = await _gameService.completeGame(winnerId);
    _currentGame = null;

    // Reset setup
    _resetSetup();

    notifyListeners();
    return completedGame;
  }

  /// Cancela o jogo atual sem distribuir XP
  Future<void> cancelGame() async {
    _blindTimer?.cancel();
    await _gameService.cancelGame();
    _currentGame = null;
    _resetSetup();
    notifyListeners();
  }

  // ========== Multiplayer (Probabilidades) ==========

  // ========== FIREBASE INTEGRATION ==========

  /// Initialize Firebase Auth listener
  /// Keeps user logged in across app restarts
  void _initAuthListener() {
    _authSubscription = firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen((firebase_auth.User? user) {
          _firebaseUser = user;
          notifyListeners();
        });
  }

  /// Check if current user is the Host of the session
  bool get isCurrentUserHost {
    if (_currentGame == null || _firebaseUser == null) return false;
    return _firebaseUser!.uid == _currentGame!.hostId;
  }

  /// Join or create a real-time game session
  /// Subscribes to Firestore stream for automatic UI updates
  /// CRITICAL: Detects 'canceled' status and emits event to all participants
  Future<void> joinSession(String sessionId) async {
    _activeSessionId = sessionId;

    // Cancel previous subscription if any
    await _sessionSubscription?.cancel();

    // Listen to session changes in real-time
    _sessionSubscription = _firestoreService.sessionStream(sessionId).listen((
      GameSession? session,
    ) {
      if (session != null) {
        // CRITICAL: Check if Host has canceled the match
        if (session.status == 'canceled') {
          debugPrint(
            'NUCLEAR FIX: Session canceled by Host! Redirecting to Home...',
          );
          _sessionCanceledController.add(true); // Notify all listeners
          leaveSession();
          return;
        }

        // Update game session
        _currentGame = session;

        // CRITICAL: Sync all game state from Firestore to local state
        // This ensures all participants see the same game state in real-time

        // Sync dealer position (changes when host rotates dealer)
        if (_dealerIndex != session.dealerIndex) {
          _dealerIndex = session.dealerIndex;
        }

        // Board cards are now part of GameSession model
        // All participants automatically see board card updates through _currentGame
        // No need to sync to local variables - read from session.boardCards instead

        notifyListeners();
      }
    });
  }

  /// Update board cards in Firestore (Host only)
  /// All clients will see this change in real-time
  Future<void> updateBoardCards(List<String> cards) async {
    if (_activeSessionId != null) {
      await _firestoreService.updateBoard(_activeSessionId!, cards);
    }
  }

  /// End game and distribute XP to winner
  /// CRITICAL: Creates and broadcasts match result to all participants
  Future<void> endGameWithFirebase({
    required String winnerId,
    required String winningHandType,
  }) async {
    if (_currentGame == null || _activeSessionId == null) return;

    try {
      final participantIds = _currentGame!.players
          .map((p) => p.userId)
          .toList();

      // 1. Get current XP before batch update (for XP tracking)
      final previousXP = <String, int>{};
      for (final player in _currentGame!.players) {
        previousXP[player.userId] =
            0; // We'll update this from Firestore if needed
      }

      // 2. Distribute XP to all players atomically (batch write)
      await _firestoreService.recordMatchResultsBatch(
        winnerId: winnerId,
        participantIds: participantIds,
      );

      // 3. Build match result for UI
      final winnerPlayer = _currentGame!.players.firstWhere(
        (p) => p.userId == winnerId,
      );

      final participantResults = <String, XPResult>{};
      for (final player in _currentGame!.players) {
        final isWinner = player.userId == winnerId;
        final xpGained = isWinner ? 500 : 100;
        final previousUserXP = previousXP[player.userId] ?? 0;
        final newXP = previousUserXP + xpGained;

        participantResults[player.userId] = XPResult(
          username: player.username,
          previousXP: previousUserXP,
          currentXP: newXP,
        );
      }

      // 4. Create match result (broadcast to all devices via provider)
      _matchResult = MatchResult(
        winnerUserId: winnerId,
        winnerUsername: winnerPlayer.username,
        winningHandType: winningHandType,
        participantResults: participantResults,
      );

      // 5. Mark session as finished
      await _firestoreService.updateGameStatus(_activeSessionId!, 'finished');

      // 6. Update local state
      _currentGame = _currentGame!.copyWith(
        isCompleted: true,
        winnerId: winnerId,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error ending game: $e');
      rethrow;
    }
  }

  /// Clear match result after displaying overlay
  void clearMatchResult() {
    _matchResult = null;
    notifyListeners();
  }

  /// Leave current session
  Future<void> leaveSession() async {
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
    _activeSessionId = null;
    _currentGame = null;
    notifyListeners();
  }

  /// Cancel match without determining a winner - no XP distributed
  /// HOST ONLY: Sets status to 'canceled' (not 'finished') to signal all participants
  /// All participants detect 'canceled' status via stream and are redirected to home
  Future<void> cancelGameWithoutWinner() async {
    if (_currentGame == null || _activeSessionId == null) return;
    if (!isCurrentUserHost) {
      debugPrint('ERROR: Only Host can cancel the match!');
      return;
    }

    try {
      // Update session status to 'canceled' (special state, not 'finished')
      // This is detected by all participants via the stream listener
      final db = FirebaseFirestore.instance;
      await db.collection('gameSessions').doc(_activeSessionId).update({
        'status': 'canceled', // CRITICAL: 'canceled' instead of 'finished'
      });

      // Create a "cancelled" match result to show in the overlay
      _matchResult = MatchResult(
        winnerUserId: '', // Empty = cancelled
        winnerUsername: 'Partida Cancelada',
        winningHandType: 'Sem Vencedor',
        participantResults: {}, // No XP changes
      );

      notifyListeners();

      // Brief delay to let the overlay show, then clear and leave
      await Future.delayed(const Duration(milliseconds: 500));

      // Clear session state completely
      await leaveSession();
      _activeSessionId =
          null; // CRITICAL: Clear to prevent re-login resuming game
    } catch (e) {
      debugPrint('Error canceling game: $e');
    }
  }

  // ========== Helpers ==========

  void _resetSetup() {
    _selectedMode = null;
    _selectedPlayers = [];
    _hasMoneyBet = false;
    _buyInAmount = 0.0;
    _calculatedChips = null;
    _remainingSeconds = 1200;
    _currentBlindLevel = 1;
    _currentSmallBlind = 5;
    _currentBigBlind = 10;
    _dealerIndex = 0;
  }

  void resetSetup() {
    _resetSetup();
    notifyListeners();
  }

  @override
  void dispose() {
    _blindTimer?.cancel();
    _authSubscription?.cancel();
    _sessionSubscription?.cancel();
    _sessionCanceledController.close();
    super.dispose();
  }
}
