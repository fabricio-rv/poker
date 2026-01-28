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

  GameSession({
    required this.id,
    DateTime? date,
    this.isRanked = true,
    this.buyInAmount = 0.0,
    required this.players,
    this.winnerId,
    required this.gameMode,
    this.isCompleted = false,
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
    );
  }

  @override
  String toString() {
    return 'GameSession(id: $id, players: ${players.length}, mode: $gameMode)';
  }
}
