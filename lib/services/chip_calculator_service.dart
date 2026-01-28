/// Service for calculating chip distribution for poker games
/// Handles physical chip inventory and even distribution among players
class ChipCalculatorService {
  /// Physical chip constants (total = 200 chips)
  static const int whiteChips = 50; // Value: 1
  static const int redChips = 50; // Value: 5
  static const int greenChips = 50; // Value: 10
  static const int blueChips = 25; // Value: 25
  static const int blackChips = 25; // Value: 50

  static const int totalChipsAvailable =
      200; // whiteChips + redChips + greenChips + blueChips + blackChips

  /// Chip values for calculation
  static const Map<String, int> chipValues = {
    'white': 1,
    'red': 5,
    'green': 10,
    'blue': 25,
    'black': 50,
  };

  /// Calculate chip distribution for a given number of players
  /// Returns a map with chip distribution per player
  /// Format: {'white': int, 'red': int, 'green': int, 'blue': int, 'black': int, 'totalValue': int}
  ///
  /// Algorithm:
  /// 1. Calculate target chips per player (total 200 / playerCount)
  /// 2. Distribute chips starting with highest value chips
  /// 3. Ensure even distribution and no stock-outs
  /// 4. Fill remaining with appropriate denominations
  static Map<String, int> calculateDistribution(int playerCount) {
    if (playerCount <= 0) {
      throw ArgumentError('Player count must be greater than 0');
    }

    if (playerCount > 20) {
      throw ArgumentError('Maximum 20 players supported');
    }

    // Initialize distribution
    Map<String, int> distribution = {
      'white': 0,
      'red': 0,
      'green': 0,
      'blue': 0,
      'black': 0,
      'totalValue': 0,
    };

    // Strategy: Distribute from highest value to ensure even stacks
    // Prioritize balance and playability

    if (playerCount <= 3) {
      // Very few players: Large stacks with mix of denominations
      distribution['black'] = (blackChips ~/ playerCount);
      distribution['blue'] = (blueChips ~/ playerCount);
      distribution['green'] = (greenChips ~/ playerCount);
      distribution['red'] = (redChips ~/ playerCount);
      distribution['white'] = (whiteChips ~/ playerCount);
    } else if (playerCount <= 6) {
      // Small group: Balanced distribution
      distribution['black'] = (blackChips ~/ playerCount);
      distribution['blue'] = ((blueChips * 2) ~/ playerCount);
      distribution['green'] = (greenChips ~/ playerCount);
      distribution['red'] = ((redChips * 2) ~/ playerCount);
      distribution['white'] = (whiteChips ~/ playerCount);
    } else if (playerCount <= 10) {
      // Medium group: Emphasis on mid-value chips
      distribution['black'] = (blackChips ~/ playerCount);
      distribution['blue'] = (blueChips ~/ playerCount);
      distribution['green'] = ((greenChips * 2) ~/ playerCount);
      distribution['red'] = ((redChips * 2) ~/ playerCount);
      distribution['white'] = ((whiteChips * 2) ~/ playerCount);
    } else {
      // Large group: Efficient distribution with high-value chips
      distribution['black'] = ((blackChips * 2) ~/ playerCount);
      distribution['blue'] = ((blueChips * 2) ~/ playerCount);
      distribution['green'] = ((greenChips * 2) ~/ playerCount);
      distribution['red'] = (redChips ~/ playerCount);
      distribution['white'] = (whiteChips ~/ playerCount);
    }

    // Calculate total value per player
    int totalValue =
        (distribution['white'] ?? 0) * 1 +
        (distribution['red'] ?? 0) * 5 +
        (distribution['green'] ?? 0) * 10 +
        (distribution['blue'] ?? 0) * 25 +
        (distribution['black'] ?? 0) * 50;

    distribution['totalValue'] = totalValue;
    distribution['totalChips'] =
        (distribution['white'] ?? 0) +
        (distribution['red'] ?? 0) +
        (distribution['green'] ?? 0) +
        (distribution['blue'] ?? 0) +
        (distribution['black'] ?? 0);

    return distribution;
  }

  /// Validate that distribution doesn't exceed available chips
  static bool validateDistribution(
    Map<String, int> distribution,
    int playerCount,
  ) {
    int totalWhite = (distribution['white'] ?? 0) * playerCount;
    int totalRed = (distribution['red'] ?? 0) * playerCount;
    int totalGreen = (distribution['green'] ?? 0) * playerCount;
    int totalBlue = (distribution['blue'] ?? 0) * playerCount;
    int totalBlack = (distribution['black'] ?? 0) * playerCount;
    return totalWhite <= whiteChips &&
        totalRed <= redChips &&
        totalGreen <= greenChips &&
        totalBlue <= blueChips &&
        totalBlack <= blackChips;
  }

  /// Get a formatted string representation of the distribution
  static String formatDistribution(Map<String, int> distribution) {
    return 'White: ${distribution['white']}, '
        'Red: ${distribution['red']}, '
        'Green: ${distribution['green']}, '
        'Blue: ${distribution['blue']}, '
        'Black: ${distribution['black']} '
        '(Total Value: R\$ ${distribution['totalValue']}, '
        'Total Chips: ${distribution['totalChips']})';
  }

  /// Get chip inventory status
  static Map<String, int> getInventoryStatus() {
    return {
      'white': whiteChips,
      'red': redChips,
      'green': greenChips,
      'blue': blueChips,
      'black': blackChips,
      'total': totalChipsAvailable,
    };
  }

  /// Calculate recommended stack for given player count and buy-in
  static Map<String, dynamic> calculateStackRecommendation(
    int playerCount,
    double? buyInAmount,
  ) {
    final distribution = calculateDistribution(playerCount);
    final totalValue = distribution['totalValue'] ?? 0;
    final totalChips = distribution['totalChips'] ?? 0;

    return {
      'distribution': distribution,
      'chipsPerPlayer': totalChips,
      'valuePerPlayer': 'R\$ $totalValue',
      'buyIn': buyInAmount != null ? 'R\$ $buyInAmount' : 'No buy-in',
      'recommendedBlinds': _recommendBlinds(totalValue),
      'recommendedAnte': _recommendAnte(totalValue),
    };
  }

  /// Recommend small and big blinds based on stack value
  static Map<String, int> _recommendBlinds(int stackValue) {
    // Blinds should be ~1-2% of average stack
    final smallBlind = (stackValue * 0.01).ceil();
    final bigBlind = smallBlind * 2;

    return {'smallBlind': smallBlind, 'bigBlind': bigBlind};
  }

  /// Recommend ante based on stack value
  static int _recommendAnte(int stackValue) {
    // Ante should be ~0.1% of stack
    return (stackValue * 0.001).ceil();
  }
}
