import '../models/chip_config.dart';
import '../utils/constants.dart';

/// Service for calculating chip distribution
class ChipCalculatorService {
  /// Calculate chip distribution for each player
  ///
  /// Algorithm:
  /// - Total physical chips available: 200
  /// - Distribute evenly based on player count
  /// - Prioritize higher value chips for efficiency
  /// - Ensure each player has playable stacks for blinds
  ChipConfig calculateChipsPerPlayer(int numberOfPlayers) {
    if (numberOfPlayers <= 0) {
      return const ChipConfig();
    }

    // Total 200 chips to distribute
    final int totalChips = GameConstants.totalPhysicalChips;

    // Calculate base chips per player
    final int chipsPerPlayer = (totalChips / numberOfPlayers).floor();

    // Calculate target value per player for balanced play
    // We want each player to have a reasonable stack
    // Using a distribution that favors mid-value chips

    if (numberOfPlayers <= 4) {
      // For 2-4 players: Larger stacks
      return _calculateForSmallGroup(chipsPerPlayer);
    } else if (numberOfPlayers <= 6) {
      // For 5-6 players: Medium stacks
      return _calculateForMediumGroup(chipsPerPlayer);
    } else {
      // For 7+ players: Smaller but playable stacks
      return _calculateForLargeGroup(chipsPerPlayer);
    }
  }

  ChipConfig _calculateForSmallGroup(int chipsPerPlayer) {
    // For 2-4 players (50 chips each = 200/4)
    // Strategy: Mix of high and low values
    // Example distribution for 50 chips
    return ChipConfig(
      whiteChips: (chipsPerPlayer * 0.2).round(), // 10 white (value: 10)
      redChips: (chipsPerPlayer * 0.3).round(), // 15 red (value: 75)
      greenChips: (chipsPerPlayer * 0.2).round(), // 10 green (value: 100)
      blueChips: (chipsPerPlayer * 0.2).round(), // 10 blue (value: 250)
      blackChips: (chipsPerPlayer * 0.1).round(), // 5 black (value: 250)
    );
  }

  ChipConfig _calculateForMediumGroup(int chipsPerPlayer) {
    // For 5-6 players (33-40 chips each)
    // Strategy: Focus on mid-range chips
    return ChipConfig(
      whiteChips: (chipsPerPlayer * 0.25).round(), // More small chips
      redChips: (chipsPerPlayer * 0.35).round(), // Emphasis on red
      greenChips: (chipsPerPlayer * 0.25).round(), // Good amount of green
      blueChips: (chipsPerPlayer * 0.1).round(), // Some blue
      blackChips: (chipsPerPlayer * 0.05).round(), // Few black
    );
  }

  ChipConfig _calculateForLargeGroup(int chipsPerPlayer) {
    // For 7+ players (28 chips or less each)
    // Strategy: Efficient distribution with higher value chips
    return ChipConfig(
      whiteChips: (chipsPerPlayer * 0.15).round(),
      redChips: (chipsPerPlayer * 0.3).round(),
      greenChips: (chipsPerPlayer * 0.3).round(),
      blueChips: (chipsPerPlayer * 0.15).round(),
      blackChips: (chipsPerPlayer * 0.1).round(),
    );
  }

  /// Calculate recommended blind structure based on chip distribution
  Map<String, int> calculateRecommendedBlinds(ChipConfig chips) {
    final totalValue = chips.totalValue;

    // Small blind should be about 1-2% of total stack value
    final smallBlind = (totalValue * 0.01).round();
    final bigBlind = smallBlind * 2;

    return {
      'smallBlind': smallBlind > 0 ? smallBlind : 1,
      'bigBlind': bigBlind > 0 ? bigBlind : 2,
    };
  }

  /// Format chip distribution for display
  String formatChipDistribution(ChipConfig chips) {
    List<String> parts = [];

    if (chips.whiteChips > 0) {
      parts.add('${chips.whiteChips} Brancas (R\$ ${chips.whiteChips * 1})');
    }
    if (chips.redChips > 0) {
      parts.add('${chips.redChips} Vermelhas (R\$ ${chips.redChips * 5})');
    }
    if (chips.greenChips > 0) {
      parts.add('${chips.greenChips} Verdes (R\$ ${chips.greenChips * 10})');
    }
    if (chips.blueChips > 0) {
      parts.add('${chips.blueChips} Azuis (R\$ ${chips.blueChips * 25})');
    }
    if (chips.blackChips > 0) {
      parts.add('${chips.blackChips} Pretas (R\$ ${chips.blackChips * 50})');
    }

    return parts.join('\n');
  }
}
