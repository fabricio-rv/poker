/// Card Helper - Handles card string conversions
class CardHelper {
  /// Map card format from Firestore string (e.g., 'H5', 'DA') to poker engine format (e.g., '5h', 'ad')
  /// Also handles intermediate formats like 'Ah', '5c'
  static String toEngineFormat(String card) {
    if (card.isEmpty || card == '??') return card;

    final card_lower = card.toLowerCase();

    // Already in engine format (e.g., '5h', 'ah')
    if (card_lower.length == 2) {
      final rank = card_lower[0];
      final suit = card_lower[1];

      // Check if it's already correct format (rank-suit)
      if (_isValidRank(rank) && _isValidSuit(suit)) {
        return card_lower;
      }
    }

    // Handle card length of 2 or 3 (e.g., 'H5', 'DA', '10h')
    if (card_lower.length >= 2) {
      // Extract suit (last character)
      final suit = card_lower[card_lower.length - 1];

      // Extract rank (everything except last character)
      final rank = card_lower.substring(0, card_lower.length - 1);

      // Validate
      if (_isValidRank(rank) && _isValidSuit(suit)) {
        return '$rank$suit';
      }
    }

    return card; // Return original if can't parse
  }

  /// Get card display rank (e.g., '5h' -> '5', 'Ah' -> 'A', 'th' -> '10')
  static String getRank(String card) {
    if (card.isEmpty || card == '??') return '?';

    final engineFormat = toEngineFormat(card);
    if (engineFormat.isEmpty) return '?';

    final rank = engineFormat
        .substring(0, engineFormat.length - 1)
        .toUpperCase();
    // Convert T (ten) to 10
    return rank == 'T' ? '10' : rank;
  }

  /// Get card display suit symbol (e.g., 'h' -> '♥', 'd' -> '♦')
  static String getSuitSymbol(String card) {
    if (card.isEmpty || card == '??') return '?';

    final engineFormat = toEngineFormat(card);
    if (engineFormat.isEmpty) return '?';

    final suit = engineFormat[engineFormat.length - 1];
    return _suitToSymbol(suit);
  }

  /// Get card suit color
  static int getSuitColor(String card) {
    if (card.isEmpty || card == '??') return 0xFF9E9E9E; // Grey

    final engineFormat = toEngineFormat(card);
    if (engineFormat.isEmpty) return 0xFF9E9E9E;

    final suit = engineFormat[engineFormat.length - 1];
    // Red for hearts and diamonds, black for clubs and spades
    return (suit == 'h' || suit == 'd') ? 0xFFFF0000 : 0xFF000000;
  }

  // Private helpers

  static bool _isValidRank(String rank) {
    final validRanks = [
      'a',
      'k',
      'q',
      'j',
      't',
      '9',
      '8',
      '7',
      '6',
      '5',
      '4',
      '3',
      '2',
    ];
    return validRanks.contains(rank.toLowerCase());
  }

  static bool _isValidSuit(String suit) {
    return ['h', 'd', 'c', 's'].contains(suit.toLowerCase());
  }

  static String _suitToSymbol(String suit) {
    switch (suit.toLowerCase()) {
      case 'h':
        return '♥';
      case 'd':
        return '♦';
      case 'c':
        return '♣';
      case 's':
        return '♠';
      default:
        return '?';
    }
  }
}
