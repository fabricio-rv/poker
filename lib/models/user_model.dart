import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String username; // Mantendo o nome original que você prefere
  final String email; // Adicionado para o Auth
  final String password;
  int level;
  int currentXP;
  int totalWins;
  int totalMatches;
  final DateTime createdAt;
  String photoUrl;

  AppUser({
    String? id,
    required this.username,
    required this.email,
    required this.password,
    this.level = 1,
    this.currentXP = 0,
    this.totalWins = 0,
    this.totalMatches = 0,
    this.photoUrl = '',
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // --- TODA A SUA LÓGICA DE JOGO PRESERVADA ---

  void addXP(int amount) {
    if (amount < 0) throw ArgumentError('XP amount cannot be negative');
    currentXP += amount;
    while (currentXP >= level * 1000) {
      currentXP -= level * 1000;
      level++;
    }
  }

  void recordMatch(bool isWinner) {
    totalMatches++;
    if (isWinner) {
      totalWins++;
      addXP(500);
    } else {
      addXP(100);
    }
  }

  double get winRate =>
      totalMatches == 0 ? 0.0 : (totalWins / totalMatches) * 100;
  int get xpNeededForNextLevel => level * 1000 - currentXP;

  int get totalXPAccumulated {
    int total = currentXP;
    for (int i = 1; i < level; i++) {
      total += i * 1000;
    }
    return total;
  }

  // --- CONVERSÃO PARA O FIREBASE (O QUE ESTAVA FALTANDO) ---

  /// Para o UserProvider: Cria o objeto a partir do Firestore
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      username:
          map['username'] ??
          map['name'] ??
          'Jogador', // Aceita ambos para evitar erro
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      level: map['level'] ?? 1,
      currentXP: map['currentXP'] ?? 0,
      totalWins: map['totalWins'] ?? 0,
      totalMatches: map['totalMatches'] ?? 0,
      photoUrl: map['photoUrl'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Para o AuthService: Salva os dados no Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'level': level,
      'currentXP': currentXP,
      'totalWins': totalWins,
      'totalMatches': totalMatches,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt), // Formato padrão do Firebase
    };
  }

  // Mantendo o seu copyWith para facilitar updates locais
  AppUser copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    int? level,
    int? currentXP,
    int? totalWins,
    int? totalMatches,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      totalWins: totalWins ?? this.totalWins,
      totalMatches: totalMatches ?? this.totalMatches,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
