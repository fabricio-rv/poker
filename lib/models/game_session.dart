import 'player_in_game.dart';

enum GameMode {
  multiplayer, // Each player on their own device
  manager, // Single device manager mode
}

class GameSession {
  final String id;
  final DateTime date;
  final bool isRanked;
  final double buyInAmount;
  final List<PlayerInGame> players;
  final String? winnerId;
  final GameMode gameMode;
  final bool isCompleted;
  final bool
  isProgressiveBlind; // true = Tournament (blinds increase), false = Cash Game (fixed blinds)

  // CRITICAL MULTIPLAYER FIELDS: Synced from Firestore
  final String hostId; // User ID of the Host (who controls the game)
  final List<String> boardCards; // Flop, Turn, River cards visible to all
  final int dealerIndex; // Current dealer button position
  final String status; // 'waiting', 'playing', 'finished', 'canceled'

  GameSession({
    required this.id,
    DateTime? date,
    this.isRanked = true,
    this.buyInAmount = 0.0,
    required this.players,
    this.winnerId,
    required this.gameMode,
    this.isCompleted = false,
    this.isProgressiveBlind = true, // Default to tournament mode
    required this.hostId,
    this.boardCards = const [],
    this.dealerIndex = 0,
    this.status = 'waiting',
  }) : date = date ?? DateTime.now();

  /// Get active players (not eliminated)
  List<PlayerInGame> get activePlayers {
    return players.where((p) => !p.isEliminated).toList();
  }

  /// Check if game is finished (only one player left)
  bool get isFinished {
    return activePlayers.length <= 1;
  }

  GameSession copyWith({
    String? id,
    DateTime? date,
    bool? isRanked,
    double? buyInAmount,
    List<PlayerInGame>? players,
    String? winnerId,
    GameMode? gameMode,
    bool? isCompleted,
    bool? isProgressiveBlind,
    String? hostId,
    List<String>? boardCards,
    int? dealerIndex,
    String? status,
  }) {
    return GameSession(
      id: id ?? this.id,
      date: date ?? this.date,
      isRanked: isRanked ?? this.isRanked,
      buyInAmount: buyInAmount ?? this.buyInAmount,
      players: players ?? this.players,
      winnerId: winnerId ?? this.winnerId,
      gameMode: gameMode ?? this.gameMode,
      isCompleted: isCompleted ?? this.isCompleted,
      isProgressiveBlind: isProgressiveBlind ?? this.isProgressiveBlind,
      hostId: hostId ?? this.hostId,
      boardCards: boardCards ?? this.boardCards,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'isRanked': isRanked,
      'buyInAmount': buyInAmount,
      'players': players.map((p) => p.toJson()).toList(),
      'winnerId': winnerId,
      'gameMode': gameMode.toString().split('.').last,
      'isCompleted': isCompleted,
      'isProgressiveBlind': isProgressiveBlind,
      'hostId': hostId,
      'boardCards': boardCards,
      'currentDealer': dealerIndex,
      'status': status,
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      isRanked: json['isRanked'] as bool? ?? true,
      buyInAmount: (json['buyInAmount'] as num?)?.toDouble() ?? 0.0,
      players: (json['players'] as List)
          .map((p) => PlayerInGame.fromJson(p as Map<String, dynamic>))
          .toList(),
      winnerId: json['winnerId'] as String?,
      gameMode: json['gameMode'] == 'multiplayer'
          ? GameMode.multiplayer
          : GameMode.manager,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isProgressiveBlind: json['isProgressiveBlind'] as bool? ?? true,
      hostId: json['hostId'] as String? ?? '',
      boardCards: (json['boardCards'] as List?)?.cast<String>() ?? [],
      dealerIndex: json['currentDealer'] as int? ?? 0,
      status: json['status'] as String? ?? 'waiting',
    );
  }

  @override
  String toString() {
    return 'GameSession(id: $id, players: ${players.length}, mode: $gameMode)';
  }
}
