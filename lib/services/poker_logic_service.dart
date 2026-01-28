import 'package:poker/poker.dart' as poker;

class PokerPlayerHand {
  final String name;
  final List<String> cards;

  PokerPlayerHand({required this.name, required this.cards});
}

class PokerHandEvaluation {
  final PokerPlayerHand player;
  final poker.MadeHand madeHand;
  final List<poker.Card> bestCards;
  final String translatedType;
  final String description;

  PokerHandEvaluation({
    required this.player,
    required this.madeHand,
    required this.bestCards,
    required this.translatedType,
    required this.description,
  });
}

class PokerShowdownResult {
  final PokerHandEvaluation winner;
  final List<PokerHandEvaluation> evaluations;
  final bool isTie;
  final List<PokerHandEvaluation> tiedPlayers;

  PokerShowdownResult({
    required this.winner,
    required this.evaluations,
    required this.isTie,
    required this.tiedPlayers,
  });
}

class PokerLogicService {
  PokerShowdownResult evaluateShowdown({
    required List<PokerPlayerHand> players,
    required List<String> boardCards,
  }) {
    if (players.length < 2) {
      throw ArgumentError('É necessário pelo menos 2 jogadores.');
    }
    if (boardCards.length != 5 || boardCards.any((c) => c.isEmpty)) {
      throw ArgumentError('A mesa deve ter 5 cartas válidas.');
    }

    final board = boardCards.map(_parseCard).toList();

    final evaluations = players.map((player) {
      if (player.cards.length != 2 || player.cards.any((c) => c.isEmpty)) {
        throw ArgumentError('O jogador ${player.name} deve ter 2 cartas.');
      }

      final playerCards = player.cards.map(_parseCard).toList();
      final allCards = [...playerCards, ...board];
      final bestCards = _findBestFiveCards(allCards);
      final madeHand = poker.MadeHand.best(
        poker.ImmutableCardSet.of(bestCards),
      );
      final translatedType = _translateHandType(madeHand, bestCards);
      final description = _buildHandDescription(madeHand, bestCards);

      return PokerHandEvaluation(
        player: player,
        madeHand: madeHand,
        bestCards: bestCards,
        translatedType: translatedType,
        description: description,
      );
    }).toList();

    evaluations.sort((a, b) => b.madeHand.power.compareTo(a.madeHand.power));
    final bestPower = evaluations.first.madeHand.power;
    final tied = evaluations
        .where((e) => e.madeHand.power == bestPower)
        .toList();

    return PokerShowdownResult(
      winner: evaluations.first,
      evaluations: evaluations,
      isTie: tied.length > 1,
      tiedPlayers: tied,
    );
  }

  String getWinningExplanation({required PokerShowdownResult result}) {
    if (result.isTie) {
      final names = result.tiedPlayers.map((e) => e.player.name).join(' e ');
      return 'Empate entre $names. Mãos: '
          '${result.tiedPlayers.map((e) => e.description).join(' | ')}';
    }

    final winner = result.winner;
    final loser = result.evaluations.firstWhere(
      (e) => e.player.name != winner.player.name,
    );

    // TASK 3: Enhanced explanation format with card details
    final winnerCards = winner.player.cards
        .map((c) => _formatCardDisplay(c))
        .join(', ');

    return 'Vencedor: ${winner.player.name} com ${winner.description} ($winnerCards). '
        'Venceu de: ${loser.player.name} que tinha ${loser.description}.';
  }

  /// TASK 3: Format card for display (e.g., "As" -> "A ♠")
  String _formatCardDisplay(String cardStr) {
    if (cardStr.length < 2) return cardStr;

    final rankRaw = cardStr.substring(0, cardStr.length - 1).toUpperCase();
    final suitChar = cardStr[cardStr.length - 1].toLowerCase();

    // Convert rank using map with fallback
    final rank = rankStringToPt(rankRaw);

    // Convert suit to symbol
    final suit = _getSuitSymbol(suitChar);

    return '$rank $suit';
  }

  /// Convert suit character to symbol
  String _getSuitSymbol(String suitChar) {
    switch (suitChar.toLowerCase()) {
      case 'h':
        return '♥';
      case 'd':
        return '♦';
      case 'c':
        return '♣';
      case 's':
        return '♠';
      default:
        return suitChar;
    }
  }

  poker.Card _parseCard(String value) {
    return poker.Card.parse(value);
  }

  List<poker.Card> _findBestFiveCards(List<poker.Card> cards) {
    if (cards.length < 5) {
      throw ArgumentError('É necessário pelo menos 5 cartas.');
    }

    poker.MadeHand? bestHand;
    List<poker.Card> bestCombo = [];

    for (final combo in _combinations(cards, 5)) {
      final hand = poker.MadeHand.best(poker.ImmutableCardSet.of(combo));
      if (bestHand == null || hand.power > bestHand.power) {
        bestHand = hand;
        bestCombo = combo;
      }
    }

    return bestCombo;
  }

  List<List<poker.Card>> _combinations(List<poker.Card> cards, int k) {
    final result = <List<poker.Card>>[];

    void backtrack(int start, List<poker.Card> current) {
      if (current.length == k) {
        result.add(List<poker.Card>.from(current));
        return;
      }
      for (var i = start; i < cards.length; i++) {
        current.add(cards[i]);
        backtrack(i + 1, current);
        current.removeLast();
      }
    }

    backtrack(0, []);
    return result;
  }

  String _translateHandType(poker.MadeHand hand, List<poker.Card> bestCards) {
    final english = _englishType(hand, bestCards);
    return _translateEnglishHandType(english);
  }

  String _englishType(poker.MadeHand hand, List<poker.Card> bestCards) {
    if (hand.type == poker.MadeHandType.straightFlush) {
      final highStraight = _getStraightHighRank(bestCards);
      if (highStraight == poker.Rank.ace && _containsTen(bestCards)) {
        return 'Royal Flush';
      }
      return 'Straight Flush';
    }

    switch (hand.type) {
      case poker.MadeHandType.quads:
        return 'Four of a Kind';
      case poker.MadeHandType.fullHouse:
        return 'Full House';
      case poker.MadeHandType.flush:
        return 'Flush';
      case poker.MadeHandType.straight:
        return 'Straight';
      case poker.MadeHandType.trips:
        return 'Three of a Kind';
      case poker.MadeHandType.twoPairs:
        return 'Two Pair';
      case poker.MadeHandType.pair:
        return 'Pair';
      case poker.MadeHandType.highcard:
      case poker.MadeHandType.straightFlush:
        return 'High Card';
    }
  }

  String _translateEnglishHandType(String english) {
    const map = {
      'Royal Flush': 'Royal Flush',
      'Straight Flush': 'Straight Flush',
      'Four of a Kind': 'Quadra',
      'Full House': 'Full House',
      'Flush': 'Flush',
      'Straight': 'Sequência',
      'Three of a Kind': 'Trinca',
      'Two Pair': 'Dois Pares',
      'Pair': 'Par',
      'High Card': 'Carta Alta',
    };

    return map[english] ?? english;
  }

  String _buildHandDescription(poker.MadeHand hand, List<poker.Card> cards) {
    final english = _englishType(hand, cards);
    final translated = _translateEnglishHandType(english);

    final rankCounts = <poker.Rank, int>{};
    for (final card in cards) {
      rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
    }

    poker.Rank? highCard;
    final sortedRanks = rankCounts.keys.toList()
      ..sort((a, b) => b.index.compareTo(a.index));
    highCard = sortedRanks.isNotEmpty ? sortedRanks.first : null;

    switch (hand.type) {
      case poker.MadeHandType.quads:
        final quadRank = _findRankByCount(rankCounts, 4);
        return '$translated de ${_rankPt(quadRank)}';
      case poker.MadeHandType.fullHouse:
        // Para Full House, precisa encontrar a trinca (3) e o par (2)
        // Ordena por frequência primeiro, depois por rank
        final ranksOrdered = rankCounts.entries.toList()
          ..sort((a, b) {
            if (a.value != b.value) {
              return b.value.compareTo(a.value); // Maior frequência primeiro
            }
            return b.key.index.compareTo(a.key.index); // Maior rank primeiro
          });

        final tripsRank = ranksOrdered.isNotEmpty ? ranksOrdered[0].key : null;
        final pairRank = ranksOrdered.length > 1 ? ranksOrdered[1].key : null;
        return '$translated de ${_rankPt(tripsRank)} com ${_rankPt(pairRank)}';
      case poker.MadeHandType.flush:
        return '$translated com ${_rankPt(highCard)}';
      case poker.MadeHandType.straight:
        final straightHigh = _getStraightHighRank(cards);
        return '$translated até ${_rankPt(straightHigh)}';
      case poker.MadeHandType.trips:
        final tripsRank = _findRankByCount(rankCounts, 3);
        return '$translated de ${_rankPt(tripsRank)}';
      case poker.MadeHandType.twoPairs:
        final pairs = _findRanksByCount(rankCounts, 2)
          ..sort((a, b) => b.index.compareTo(a.index));
        if (pairs.length >= 2) {
          return '$translated: ${_rankPt(pairs[0])} e ${_rankPt(pairs[1])}';
        }
        return translated;
      case poker.MadeHandType.pair:
        final pairRank = _findRankByCount(rankCounts, 2);
        return '$translated de ${_rankPt(pairRank)}';
      case poker.MadeHandType.highcard:
        return '$translated ${_rankPt(highCard)}';
      case poker.MadeHandType.straightFlush:
        final straightHigh = _getStraightHighRank(cards);
        if (english == 'Royal Flush') {
          return 'Royal Flush';
        }
        return '$translated de ${_rankPt(straightHigh)}';
    }
  }

  poker.Rank? _findRankByCount(Map<poker.Rank, int> counts, int count) {
    final ranks =
        counts.entries.where((e) => e.value == count).map((e) => e.key).toList()
          ..sort((a, b) => b.index.compareTo(a.index));
    return ranks.isNotEmpty ? ranks.first : null;
  }

  List<poker.Rank> _findRanksByCount(Map<poker.Rank, int> counts, int count) {
    final ranks = counts.entries
        .where((e) => e.value == count)
        .map((e) => e.key)
        .toList();
    return ranks;
  }

  poker.Rank _getStraightHighRank(List<poker.Card> cards) {
    final ranks = cards.map((c) => c.rank).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final hasWheel =
        ranks.contains(poker.Rank.ace) &&
        ranks.contains(poker.Rank.deuce) &&
        ranks.contains(poker.Rank.trey) &&
        ranks.contains(poker.Rank.four) &&
        ranks.contains(poker.Rank.five);

    if (hasWheel) {
      return poker.Rank.five;
    }

    return ranks.isNotEmpty ? ranks.last : poker.Rank.deuce;
  }

  bool _containsTen(List<poker.Card> cards) {
    return cards.any((c) => c.rank == poker.Rank.ten);
  }

  /// Mapa de conversão de ranks para Português
  /// Garante que 'T' sempre será exibido como '10'
  static const Map<String, String> rankToPortuguese = {
    'A': 'Ás',
    'K': 'Rei',
    'Q': 'Dama',
    'J': 'Valete',
    'T': '10', // CRUCIAL: T deve sempre ser exibido como 10
    '10': '10',
    '9': '9',
    '8': '8',
    '7': '7',
    '6': '6',
    '5': '5',
    '4': '4',
    '3': '3',
    '2': '2',
  };

  String _rankPt(poker.Rank? rank) {
    if (rank == null) return '';

    switch (rank) {
      case poker.Rank.ace:
        return 'Ás';
      case poker.Rank.king:
        return 'Rei';
      case poker.Rank.queen:
        return 'Dama';
      case poker.Rank.jack:
        return 'Valete';
      case poker.Rank.ten:
        return '10'; // T sempre retorna '10'
      case poker.Rank.nine:
        return '9';
      case poker.Rank.eight:
        return '8';
      case poker.Rank.seven:
        return '7';
      case poker.Rank.six:
        return '6';
      case poker.Rank.five:
        return '5';
      case poker.Rank.four:
        return '4';
      case poker.Rank.trey:
        return '3';
      case poker.Rank.deuce:
        return '2';
    }
  }

  /// TASK 3: Converte string de rank para Português com fallback robusto
  /// Nunca retorna vazio - garante que 'T' sempre vira '10'
  String rankStringToPt(String rankStr) {
    if (rankStr.isEmpty) return '';

    final normalized = rankStr.toUpperCase().trim();

    // CRITICAL: Ensure 'T' always becomes '10'
    if (normalized == 'T') return '10';

    // Try map lookup, fallback to normalized value
    return rankToPortuguese[normalized] ?? normalized;
  }
}
