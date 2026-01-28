import 'dart:math';

class User {
  final String id;
  final String username;
  final String password;
  final int currentXP;
  final int totalWins;
  final int totalMatches;
  final String? avatarUrl;
  final DateTime joinDate;

  User({
    required this.id,
    required this.username,
    required this.password,
    this.currentXP = 0,
    this.totalWins = 0,
    this.totalMatches = 0,
    this.avatarUrl,
    DateTime? joinDate,
  }) : joinDate = joinDate ?? DateTime.now();

  /// Calculate level from XP using the formula: Level = sqrt(XP / 100)
  int get level {
    return sqrt(currentXP / 100).floor();
  }

  /// Calculate XP required for next level
  int get xpForNextLevel {
    final nextLevel = level + 1;
    return (nextLevel * nextLevel * 100);
  }

  /// Calculate XP required for current level
  int get xpForCurrentLevel {
    return (level * level * 100);
  }

  /// Calculate progress percentage to next level
  double get progressToNextLevel {
    final currentLevelXP = xpForCurrentLevel;
    final nextLevelXP = xpForNextLevel;
    final xpInCurrentLevel = currentXP - currentLevelXP;
    final xpNeededForLevel = nextLevelXP - currentLevelXP;

    if (xpNeededForLevel == 0) return 0.0;
    return (xpInCurrentLevel / xpNeededForLevel).clamp(0.0, 1.0);
  }

  /// Calculate overall ranking score
  /// Formula: (Wins * 10) + (Matches * 2) + (Level * 5)
  int get rankingScore {
    return (totalWins * 10) + (totalMatches * 2) + (level * 5);
  }

  /// Win rate percentage
  double get winRate {
    if (totalMatches == 0) return 0.0;
    return (totalWins / totalMatches * 100);
  }

  User copyWith({
    String? id,
    String? username,
    String? password,
    int? currentXP,
    int? totalWins,
    int? totalMatches,
    String? avatarUrl,
    DateTime? joinDate,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      currentXP: currentXP ?? this.currentXP,
      totalWins: totalWins ?? this.totalWins,
      totalMatches: totalMatches ?? this.totalMatches,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinDate: joinDate ?? this.joinDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'currentXP': currentXP,
      'totalWins': totalWins,
      'totalMatches': totalMatches,
      'avatarUrl': avatarUrl,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      currentXP: json['currentXP'] as int? ?? 0,
      totalWins: json['totalWins'] as int? ?? 0,
      totalMatches: json['totalMatches'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
      joinDate: json['joinDate'] != null
          ? DateTime.parse(json['joinDate'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, level: $level, XP: $currentXP)';
  }
}
