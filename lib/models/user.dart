import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final int currentXP;
  final int totalWins;
  final int totalMatches;
  final String? avatarUrl;
  final DateTime joinDate;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.currentXP = 0,
    this.totalWins = 0,
    this.totalMatches = 0,
    this.avatarUrl,
    DateTime? joinDate,
  }) : joinDate = joinDate ?? DateTime.now();

  // --- Lógica de Nível Baseada em XP ---
  int get level => (currentXP / 1000).floor() + 1;
  double get progressToNextLevel => (currentXP % 1000) / 1000.0;
  int get rankingScore =>
      (totalWins * 10) + (totalMatches * 2) + ((level - 1) * 5);

  double get winRate {
    if (totalMatches == 0) return 0.0;
    return (totalWins / totalMatches * 100);
  }

  // --- Conversores para o Firebase ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': username, // Garante compatibilidade se o banco usar 'name'
      'email': email,
      'currentXP': currentXP,
      'xp': currentXP, // Garante compatibilidade se o banco usar 'xp'
      'totalWins': totalWins,
      'totalMatches': totalMatches,
      'avatarUrl': avatarUrl,
      'photoUrl':
          avatarUrl, // Garante compatibilidade se o banco usar 'photoUrl'
      'joinDate': Timestamp.fromDate(joinDate),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      username: (json['username'] ?? json['name'] ?? 'Jogador') as String,
      email: json['email'] as String? ?? '',
      currentXP: (json['currentXP'] ?? json['xp'] ?? 0) as int,
      totalWins: (json['totalWins'] ?? 0) as int,
      totalMatches: (json['totalMatches'] ?? 0) as int,
      avatarUrl: (json['avatarUrl'] ?? json['photoUrl']) as String?,
      joinDate: json['joinDate'] is Timestamp
          ? (json['joinDate'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    int? currentXP,
    int? totalWins,
    int? totalMatches,
    String? avatarUrl,
    DateTime? joinDate,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      currentXP: currentXP ?? this.currentXP,
      totalWins: totalWins ?? this.totalWins,
      totalMatches: totalMatches ?? this.totalMatches,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinDate: joinDate ?? this.joinDate,
    );
  }
}
