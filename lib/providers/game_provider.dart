import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/game_session.dart';
import '../models/player_in_game.dart';
import '../models/chip_config.dart';
import '../models/user.dart';
import '../services/game_service.dart';
import '../services/chip_calculator_service.dart';
import '../services/poker_logic_service.dart';
import '../services/firestore_service.dart';

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
  double _winProbability = 0.0;
  bool _isHost =
      true; // true = Host (Manager Mode), false = Guest (Player Mode)

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
  double get winProbability => _winProbability;
  bool get isHost => _isHost;

  bool get isGameActive => _currentGame != null;
  bool get isGameFinished => _currentGame?.isFinished ?? false;
  firebase_auth.User? get firebaseUser => _firebaseUser;

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

  void updateWinProbability(double probability) {
    _winProbability = probability;
    notifyListeners();
  }

  /// Calcula a probabilidade de vitória usando simulação Monte Carlo
  /// Simula 600 mãos aleatórias do oponente contra a mão atual do jogador
  /// Usa a avaliação real de mãos de poker (não apenas high cards)
  void calculateWinProbability({
    required List<String> playerCards,
    required List<String> boardCards,
  }) {
    if (playerCards.length != 2) {
      _winProbability = 0.0;
      notifyListeners();
      return;
    }

    // Se não houver cartas da mesa, probabilidade neutra
    if (boardCards.isEmpty) {
      _winProbability = 50.0;
      notifyListeners();
      return;
    }

    try {
      _updateProbability(playerCards, boardCards);
    } catch (e) {
      debugPrint('Erro ao calcular probabilidade: $e');
      _winProbability = 50.0;
      notifyListeners();
    }
  }

  /// Método interno que executa a simulação Monte Carlo com avaliação real de mãos
  /// Algoritmo:
  /// 1. Cria um deck fresco excluindo as cartas do jogador e da mesa
  /// 2. Para cada iteração:
  ///    a. Sorteia 2 cartas para o oponente
  ///    b. Completa a mesa para 5 cartas se necessário
  ///    c. Avalia a mão do jogador e do oponente
  ///    d. Compara: Win se jogador > oponente, Loss se < , Tie se ==
  /// 3. Calcula: winRate = wins / 600
  void _updateProbability(List<String> playerCards, List<String> boardCards) {
    const int simulations = 600;
    int wins = 0;

    // Cartas usadas (não podem ser sorteadas para oponente)
    final usedCards = <String>{...playerCards, ...boardCards};

    // Deck completo (52 cartas) - mantém a ordem padronizada
    final ranks = [
      'A',
      'K',
      'Q',
      'J',
      'T',
      '9',
      '8',
      '7',
      '6',
      '5',
      '4',
      '3',
      '2',
    ];
    final suits = ['h', 'd', 'c', 's'];
    final fullDeck = <String>[];
    for (final rank in ranks) {
      for (final suit in suits) {
        fullDeck.add('$rank$suit');
      }
    }

    // Cartas disponíveis para sortear (excluindo usadas)
    final availableCards = fullDeck
        .where((c) => !usedCards.contains(c))
        .toList();

    // Quantas cartas faltam na mesa para completar 5?
    final missingBoardCards = 5 - boardCards.length;

    // Instância do serviço de lógica de poker para avaliação real
    final pokerLogic = PokerLogicService();

    // Simulação Monte Carlo - 600 iterações
    for (int i = 0; i < simulations; i++) {
      // Embaralhar cartas disponíveis para esta iteração
      final shuffled = List<String>.from(availableCards)..shuffle();

      // Sortear 2 cartas para oponente
      final opponentCards = shuffled.take(2).toList();

      // Completar a mesa se necessário (se temos turn/river incompleto)
      final completedBoard = List<String>.from(boardCards);
      if (missingBoardCards > 0) {
        completedBoard.addAll(shuffled.skip(2).take(missingBoardCards));
      }

      try {
        // Avaliar mão do jogador com a mesa completa
        final myEval = pokerLogic.evaluateHand(
          playerName: 'Player',
          playerCards: playerCards,
          boardCards: completedBoard,
        );

        // Avaliar mão do oponente com a MESMA mesa
        // CRITICAL: Oponente usa as mesmas 5 cartas da mesa (não cartas diferentes)
        final opponentEval = pokerLogic.evaluateHand(
          playerName: 'Opponent',
          playerCards: opponentCards,
          boardCards: completedBoard,
        );

        // Comparar mãos usando o comparador correto
        // compareHands retorna: > 0 se A vence, < 0 se B vence, 0 se empate
        final comparisonResult = pokerLogic.compareHands(myEval, opponentEval);

        // CRITICAL: Contar APENAS vitórias (não empates como 0.5)
        if (comparisonResult > 0) {
          wins++;
        }
        // Se comparisonResult == 0 (empate), não contamos como win
        // Se comparisonResult < 0 (derrota), também não contamos
      } catch (e) {
        debugPrint('Erro na iteração $i da simulação: $e');
        // Continua a simulação em caso de erro
        continue;
      }
    }

    // Calcular porcentagem de vitórias (sem contar empates como wins)
    _winProbability = (wins / simulations) * 100;
    notifyListeners();
  }

  void mockCalculateOdds() {
    // Método legado - mantido para compatibilidade
    _winProbability = 50.0 + (DateTime.now().millisecond % 40 - 20);
    notifyListeners();
  }

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

  /// Join or create a real-time game session
  /// Subscribes to Firestore stream for automatic UI updates
  Future<void> joinSession(String sessionId) async {
    _activeSessionId = sessionId;

    // Cancel previous subscription if any
    await _sessionSubscription?.cancel();

    // Listen to session changes in real-time
    _sessionSubscription = _firestoreService.sessionStream(sessionId).listen((
      GameSession? session,
    ) {
      if (session != null) {
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
  Future<void> endGameWithFirebase({required String winnerId}) async {
    if (_currentGame == null || _activeSessionId == null) return;

    try {
      // 1. Distribute XP to all players atomically (batch write)
      final participantIds = _currentGame!.players
          .map((p) => p.userId)
          .toList();
      await _firestoreService.recordMatchResultsBatch(
        winnerId: winnerId,
        participantIds: participantIds,
      );

      // 2. Mark session as finished
      await _firestoreService.updateGameStatus(_activeSessionId!, 'finished');

      // 3. Update local state
      _currentGame = _currentGame!.copyWith(
        isCompleted: true,
        winnerId: winnerId,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error ending game: $e');
      rethrow; // Critical error - caller should handle
    }
  }

  /// Leave current session
  Future<void> leaveSession() async {
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;
    _activeSessionId = null;
    _currentGame = null;
    notifyListeners();
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
    _winProbability = 0.0;
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
    super.dispose();
  }
}
