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

  /// Calculate level from XP using strict formula: Level = (TotalXP / 1000).floor() + 1
  /// It takes exactly 1000 XP to advance to the next level
  int get level {
    return (currentXP / 1000).floor() + 1;
  }

  /// Calculate XP required for next level (always 1000 XP per level)
  int get xpForNextLevel {
    return level * 1000;
  }

  /// Calculate XP required for current level
  int get xpForCurrentLevel {
    return (level - 1) * 1000;
  }

  /// Calculate progress percentage to next level
  /// Formula: (TotalXP % 1000) / 1000
  double get progressToNextLevel {
    final xpInCurrentLevel = currentXP % 1000;
    return xpInCurrentLevel / 1000.0;
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
