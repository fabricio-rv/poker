import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/game_session.dart';
import '../models/player_in_game.dart';

/// Firestore Service - Complete backend integration
/// Handles all Firestore operations for users, rankings, and game sessions
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER OPERATIONS ====================

  /// Get user data by UID
  Future<User?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return User.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Update user data
  /// Used for editing profile (name, photo, etc.)
  Future<bool> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  /// Get rankings as real-time stream
  /// Returns users ordered by XP descending
  Stream<List<User>> getRankings() {
    return _firestore
        .collection('users')
        .orderBy('currentXP', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return User.fromJson({...doc.data(), 'id': doc.id});
          }).toList();
        });
  }

  /// Add XP to user (used when winning matches)
  Future<void> addXP(String uid, int xpAmount) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'currentXP': FieldValue.increment(xpAmount),
      });
    } catch (e) {
      print('Error adding XP: $e');
    }
  }

  /// Record match result for user
  /// Updates wins, matches, and XP
  Future<void> recordMatchResult({
    required String uid,
    required bool isWinner,
  }) async {
    try {
      final updates = <String, dynamic>{
        'totalMatches': FieldValue.increment(1),
      };

      if (isWinner) {
        updates['totalWins'] = FieldValue.increment(1);
        updates['currentXP'] = FieldValue.increment(500); // Winner bonus
      } else {
        updates['currentXP'] = FieldValue.increment(100); // Participation XP
      }

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      print('Error recording match result: $e');
    }
  }

  /// Record match results for multiple players atomically (batch write)
  /// CRITICAL for multiplayer: Ensures all players get XP even if one fails
  Future<void> recordMatchResultsBatch({
    required String winnerId,
    required List<String> participantIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final uid in participantIds) {
        final userRef = _firestore.collection('users').doc(uid);
        final isWinner = uid == winnerId;

        final updates = <String, dynamic>{
          'totalMatches': FieldValue.increment(1),
        };

        if (isWinner) {
          updates['totalWins'] = FieldValue.increment(1);
          updates['currentXP'] = FieldValue.increment(500); // Winner bonus
        } else {
          updates['currentXP'] = FieldValue.increment(100); // Participation XP
        }

        batch.update(userRef, updates);
      }

      // Execute all updates atomically
      await batch.commit();
    } catch (e) {
      print('Error recording batch match results: $e');
      rethrow; // Critical error - caller should handle
    }
  }

  // ==================== GAME SESSION OPERATIONS ====================

  /// Create a new game session
  Future<String?> createSession(GameSession session) async {
    try {
      final docRef = await _firestore
          .collection('sessions')
          .add(
            session.toJson()
              ..['status'] =
                  'waiting' // waiting, playing, finished
              ..['createdAt'] = FieldValue.serverTimestamp()
              ..['boardCards'] = []
              ..['currentDealer'] = 0,
          );

      return docRef.id;
    } catch (e) {
      print('Error creating session: $e');
      return null;
    }
  }

  /// Join an existing session
  /// Adds player to the session's players array
  Future<bool> joinSession(String sessionId, PlayerInGame player) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'players': FieldValue.arrayUnion([player.toJson()]),
      });
      return true;
    } catch (e) {
      print('Error joining session: $e');
      return false;
    }
  }

  /// Get real-time session stream
  /// UI listens to this to update automatically when host changes cards
  Stream<GameSession?> sessionStream(String sessionId) {
    return _firestore.collection('sessions').doc(sessionId).snapshots().map((
      doc,
    ) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return GameSession.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  /// Stream of available sessions that match criteria (waiting status, not full, etc.)
  /// Used for auto-join functionality to find joinable games
  Stream<List<GameSession>> getAvailableSessions() {
    return _firestore
        .collection('sessions')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return GameSession.fromJson({...doc.data(), 'id': doc.id});
          }).toList();
        });
  }

  /// Update game status (waiting → playing → finished)
  Future<void> updateGameStatus(String sessionId, String status) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating game status: $e');
    }
  }

  /// Update board cards (host reveals flop, turn, river)
  /// All clients see this in real-time via sessionStream
  Future<void> updateBoard(String sessionId, List<String> cards) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'boardCards': cards,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating board: $e');
    }
  }

  /// Update player's private hand
  /// Each player can only see their own cards
  /// CRITICAL: Uses transaction to prevent race conditions in multiplayer
  Future<void> updatePlayerHand({
    required String sessionId,
    required String playerId,
    required List<String> cards,
  }) async {
    try {
      final sessionRef = _firestore.collection('sessions').doc(sessionId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(sessionRef);
        if (!doc.exists) return;

        final data = doc.data();
        if (data == null) return;

        // Update specific player's cards atomically
        final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
        final playerIndex = players.indexWhere((p) => p['userId'] == playerId);

        if (playerIndex != -1) {
          players[playerIndex]['cards'] = cards;

          transaction.update(sessionRef, {
            'players': players,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error updating player hand: $e');
    }
  }

  /// Update dealer position
  Future<void> updateDealer(String sessionId, int dealerIndex) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'currentDealer': dealerIndex,
      });
    } catch (e) {
      print('Error updating dealer: $e');
    }
  }

  /// Mark player as eliminated
  /// CRITICAL: Uses transaction to prevent race conditions in multiplayer
  Future<void> eliminatePlayer(String sessionId, String playerId) async {
    try {
      final sessionRef = _firestore.collection('sessions').doc(sessionId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(sessionRef);
        if (!doc.exists) return;

        final data = doc.data();
        if (data == null) return;

        final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
        final playerIndex = players.indexWhere((p) => p['userId'] == playerId);

        if (playerIndex != -1) {
          players[playerIndex]['isEliminated'] = true;

          transaction.update(sessionRef, {
            'players': players,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error eliminating player: $e');
    }
  }

  /// Delete session (cleanup after game ends)
  Future<void> deleteSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).delete();
    } catch (e) {
      print('Error deleting session: $e');
    }
  }

  // ==================== ACHIEVEMENTS ====================

  /// Unlock achievement for user
  /// Stores in subcollection or array depending on preference
  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .set({
            'unlockedAt': FieldValue.serverTimestamp(),
            'achievementId': achievementId,
          });

      // Also update main user document with achievement count
      await _firestore.collection('users').doc(userId).update({
        'achievementCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }

  /// Get user's unlocked achievements
  Future<List<String>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting achievements: $e');
      return [];
    }
  }
}
