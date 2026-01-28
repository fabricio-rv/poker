import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/firestore_service.dart';

enum RankingCategory { overall, wins, xp, matches }

class RankingProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<User> _users = [];
  bool _isLoading = false;
  RankingCategory _currentCategory = RankingCategory.overall;
  StreamSubscription<List<User>>? _rankingSubscription;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  RankingCategory get currentCategory => _currentCategory;

  RankingProvider() {
    loadRankings();
  }

  /// Load rankings from Firestore with real-time updates
  void loadRankings() {
    _isLoading = true;
    notifyListeners();

    _rankingSubscription?.cancel();
    _rankingSubscription = _firestoreService.getRankings().listen(
      (users) {
        _users = users;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        print('Error loading rankings: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Change ranking category
  void changeCategory(RankingCategory category) {
    _currentCategory = category;
    _sortUsersByCategory();
    notifyListeners();
  }

  /// Sort users by current category
  void _sortUsersByCategory() {
    switch (_currentCategory) {
      case RankingCategory.overall:
        _users.sort((a, b) => b.rankingScore.compareTo(a.rankingScore));
        break;
      case RankingCategory.wins:
        _users.sort((a, b) => b.totalWins.compareTo(a.totalWins));
        break;
      case RankingCategory.xp:
        _users.sort((a, b) => b.currentXP.compareTo(a.currentXP));
        break;
      case RankingCategory.matches:
        _users.sort((a, b) => b.totalMatches.compareTo(a.totalMatches));
        break;
    }
  }

  /// Get top N users
  List<User> getTopUsers(int count) {
    return _users.take(count).toList();
  }

  /// Get category value for a user
  dynamic getCategoryValue(User user, RankingCategory category) {
    switch (category) {
      case RankingCategory.overall:
        return user.rankingScore;
      case RankingCategory.wins:
        return user.totalWins;
      case RankingCategory.xp:
        return user.currentXP;
      case RankingCategory.matches:
        return user.totalMatches;
    }
  }

  @override
  void dispose() {
    _rankingSubscription?.cancel();
    super.dispose();
  }
}
