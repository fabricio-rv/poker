import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum RankingCategory { overall, wins, xp, matches }

class RankingProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  List<User> _allUsers = [];
  List<User> _rankedUsers = [];
  RankingCategory _currentCategory = RankingCategory.overall;
  bool _isLoading = false;

  List<User> get rankedUsers => _rankedUsers;
  RankingCategory get currentCategory => _currentCategory;
  bool get isLoading => _isLoading;

  /// Load all users and calculate rankings
  Future<void> loadRankings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allUsers = await _authService.getAllUsers();
      _sortByCategory(_currentCategory);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change ranking category and resort
  void changeCategory(RankingCategory category) {
    _currentCategory = category;
    _sortByCategory(category);
    notifyListeners();
  }

  /// Sort users by selected category
  void _sortByCategory(RankingCategory category) {
    switch (category) {
      case RankingCategory.overall:
        // TASK 2: Sort by Level (desc), then TotalXP (desc), then Victories (desc)
        _rankedUsers = List.from(_allUsers)
          ..sort((a, b) {
            // First compare by level
            final levelCompare = b.level.compareTo(a.level);
            if (levelCompare != 0) return levelCompare;

            // If levels are equal, compare by total XP
            final xpCompare = b.currentXP.compareTo(a.currentXP);
            if (xpCompare != 0) return xpCompare;

            // If XP is also equal, compare by victories
            return b.totalWins.compareTo(a.totalWins);
          });
        break;
      case RankingCategory.wins:
        // TASK 2: Sort strictly by victories
        _rankedUsers = List.from(_allUsers)
          ..sort((a, b) => b.totalWins.compareTo(a.totalWins));
        break;
      case RankingCategory.xp:
        // TASK 2: Sort strictly by totalXP
        _rankedUsers = List.from(_allUsers)
          ..sort((a, b) => b.currentXP.compareTo(a.currentXP));
        break;
      case RankingCategory.matches:
        _rankedUsers = List.from(_allUsers)
          ..sort((a, b) => b.totalMatches.compareTo(a.totalMatches));
        break;
    }
  }

  /// Get top N users
  List<User> getTopUsers(int count) {
    return _rankedUsers.take(count).toList();
  }

  /// Get user position in current ranking
  int getUserPosition(String userId) {
    return _rankedUsers.indexWhere((u) => u.id == userId) + 1;
  }

  /// Get category display name in Portuguese
  String getCategoryName(RankingCategory category) {
    switch (category) {
      case RankingCategory.overall:
        return 'Geral';
      case RankingCategory.wins:
        return 'Vitórias';
      case RankingCategory.xp:
        return 'XP';
      case RankingCategory.matches:
        return 'Partidas';
    }
  }

  /// Get category value for a user
  int getCategoryValue(User user, RankingCategory category) {
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
}
