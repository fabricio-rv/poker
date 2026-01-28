// Import ChipConfig
import 'chip_config.dart';

class PlayerInGame {
  final String userId;
  final String username;
  bool isEliminated;
  int rebuyCount;
  final ChipConfig initialChips;

  PlayerInGame({
    required this.userId,
    required this.username,
    this.isEliminated = false,
    this.rebuyCount = 0,
    required this.initialChips,
  });

  PlayerInGame copyWith({
    String? userId,
    String? username,
    bool? isEliminated,
    int? rebuyCount,
    ChipConfig? initialChips,
  }) {
    return PlayerInGame(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      isEliminated: isEliminated ?? this.isEliminated,
      rebuyCount: rebuyCount ?? this.rebuyCount,
      initialChips: initialChips ?? this.initialChips,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'isEliminated': isEliminated,
      'rebuyCount': rebuyCount,
      'initialChips': initialChips.toJson(),
    };
  }

  factory PlayerInGame.fromJson(Map<String, dynamic> json) {
    return PlayerInGame(
      userId: json['userId'] as String,
      username: json['username'] as String,
      isEliminated: json['isEliminated'] as bool? ?? false,
      rebuyCount: json['rebuyCount'] as int? ?? 0,
      initialChips: ChipConfig.fromJson(
        json['initialChips'] as Map<String, dynamic>,
      ),
    );
  }
}
