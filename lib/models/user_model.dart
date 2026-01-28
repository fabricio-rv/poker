import 'package:uuid/uuid.dart';

/// Core user model for the poker app
/// Handles user authentication, XP progression, and player statistics
class AppUser {
  final String id;
  final String username;
  final String password;
  int level;
  int currentXP;
  int totalWins;
  int totalMatches;
  final DateTime createdAt;

  AppUser({
    String? id,
    required this.username,
    required this.password,
    this.level = 1,
    this.currentXP = 0,
    this.totalWins = 0,
    this.totalMatches = 0,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// Add XP to the user and handle level progression
  /// Level up occurs when currentXP >= level * 1000
  void addXP(int amount) {
    if (amount < 0) {
      throw ArgumentError('XP amount cannot be negative');
    }

    currentXP += amount;

    // Check for level ups
    while (currentXP >= level * 1000) {
      currentXP -= level * 1000;
      level++;
    }
  }

  /// Record a match result (win or loss)
  void recordMatch(bool isWinner) {
    totalMatches++;
    if (isWinner) {
      totalWins++;
      addXP(500); // Bonus XP for winning
    } else {
      addXP(100); // Base XP for participating
    }
  }

  /// Calculate win rate percentage
  double get winRate {
    if (totalMatches == 0) return 0.0;
    return (totalWins / totalMatches) * 100;
  }

  /// Calculate XP needed for next level
  int get xpNeededForNextLevel {
    return level * 1000 - currentXP;
  }

  /// Calculate total XP accumulated (including previous levels)
  int get totalXPAccumulated {
    int total = currentXP;
    for (int i = 1; i < level; i++) {
      total += i * 1000;
    }
    return total;
  }

  /// Create a copy with modified fields
  AppUser copyWith({
    String? id,
    String? username,
    String? password,
    int? level,
    int? currentXP,
    int? totalWins,
    int? totalMatches,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      totalWins: totalWins ?? this.totalWins,
      totalMatches: totalMatches ?? this.totalMatches,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'level': level,
      'currentXP': currentXP,
      'totalWins': totalWins,
      'totalMatches': totalMatches,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON data
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      level: json['level'] as int? ?? 1,
      currentXP: json['currentXP'] as int? ?? 0,
      totalWins: json['totalWins'] as int? ?? 0,
      totalMatches: json['totalMatches'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AppUser(id: $id, username: $username, level: $level, '
        'XP: $currentXP/$xpNeededForNextLevel, wins: $totalWins/$totalMatches)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppUser &&
        other.id == id &&
        other.username == username &&
        other.level == level &&
        other.currentXP == currentXP &&
        other.totalWins == totalWins &&
        other.totalMatches == totalMatches;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        level.hashCode ^
        currentXP.hashCode ^
        totalWins.hashCode ^
        totalMatches.hashCode;
  }
}
