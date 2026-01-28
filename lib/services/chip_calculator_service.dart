/// Service for calculating chip distribution for poker games
/// Handles physical chip inventory and even distribution among players
class ChipCalculatorService {
  /// Physical chip constants (total = 200 chips)
  static const int whiteChips = 50; // Value: 1
  static const int redChips = 50; // Value: 5
  static const int greenChips = 50; // Value: 10
  static const int blueChips = 25; // Value: 25
  static const int blackChips = 25; // Value: 50

  static const int totalChipsAvailable = 200;

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
  static Map<String, int> calculateDistribution(int playerCount) {
    if (playerCount <= 0) return {};
    if (playerCount > 20) playerCount = 20;

    // Initialize distribution
    Map<String, int> distribution = {
      'white': 0,
      'red': 0,
      'green': 0,
      'blue': 0,
      'black': 0,
      'totalValue': 0,
    };

    // Distribution Logic based on Player Count tiers
    if (playerCount <= 3) {
      distribution['black'] = (blackChips ~/ playerCount);
      distribution['blue'] = (blueChips ~/ playerCount);
      distribution['green'] = (greenChips ~/ playerCount);
      distribution['red'] = (redChips ~/ playerCount);
      distribution['white'] = (whiteChips ~/ playerCount);
    } else if (playerCount <= 6) {
      distribution['black'] = (blackChips ~/ playerCount);
      distribution['blue'] = ((blueChips * 2) ~/ playerCount).clamp(
        0,
        blueChips,
      );
      distribution['green'] = (greenChips ~/ playerCount);
      distribution['red'] = ((redChips * 2) ~/ playerCount).clamp(0, redChips);
      distribution['white'] = (whiteChips ~/ playerCount);
    } else if (playerCount <= 10) {
      distribution['black'] = (blackChips ~/ playerCount);
      distribution['blue'] = (blueChips ~/ playerCount);
      distribution['green'] = ((greenChips * 2) ~/ playerCount).clamp(
        0,
        greenChips,
      );
      distribution['red'] = ((redChips * 2) ~/ playerCount).clamp(0, redChips);
      distribution['white'] = ((whiteChips * 2) ~/ playerCount).clamp(
        0,
        whiteChips,
      );
    } else {
      distribution['black'] = ((blackChips * 2) ~/ playerCount).clamp(
        0,
        blackChips,
      );
      distribution['blue'] = ((blueChips * 2) ~/ playerCount).clamp(
        0,
        blueChips,
      );
      distribution['green'] = ((greenChips * 2) ~/ playerCount).clamp(
        0,
        greenChips,
      );
      distribution['red'] = (redChips ~/ playerCount);
      distribution['white'] = (whiteChips ~/ playerCount);
    }

    // Calculate total value per player
    int totalValue =
        (distribution['white'] ?? 0) * chipValues['white']! +
        (distribution['red'] ?? 0) * chipValues['red']! +
        (distribution['green'] ?? 0) * chipValues['green']! +
        (distribution['blue'] ?? 0) * chipValues['blue']! +
        (distribution['black'] ?? 0) * chipValues['black']!;

    distribution['totalValue'] = totalValue;

    // Calculate Total Chips Count
    distribution['totalChips'] =
        (distribution['white'] ?? 0) +
        (distribution['red'] ?? 0) +
        (distribution['green'] ?? 0) +
        (distribution['blue'] ?? 0) +
        (distribution['black'] ?? 0);

    return distribution;
  }
}
