import 'package:poker/poker.dart' as poker;

class PokerPlayerHand {
  final String name;
  final List<String> cards;

  PokerPlayerHand({required this.name, required this.cards});
}

class PokerHandEvaluation {
  final PokerPlayerHand player;
  final poker.MadeHand madeHand;
  final List<poker.Card> bestCards; // As 5 cartas que formam o jogo
  final List<poker.Card>
  structuredCards; // Cartas ordenadas por força (ex: Trinca antes do Par)
  final String translatedType;
  final String description;

  PokerHandEvaluation({
    required this.player,
    required this.madeHand,
    required this.bestCards,
    required this.structuredCards,
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

      // 1. Encontra a melhor combinação de 5 cartas
      final bestCards = _findBestFiveCards(allCards);

      // 2. Cria o objeto MadeHand do pacote poker
      final madeHand = poker.MadeHand.best(
        poker.ImmutableCardSet.of(bestCards),
      );

      // 3. ESTRUTURA AS CARTAS (CORREÇÃO FUNDAMENTAL)
      // Ordena por importância: Trinca antes de Par, Par antes de Kicker
      final structuredCards = _getStructuredCards(madeHand, bestCards);

      // 4. Traduz e Descreve
      final translatedType = _getHandRankPortuguese(madeHand.type);
      final description = _buildHandDescription(madeHand, structuredCards);

      return PokerHandEvaluation(
        player: player,
        madeHand: madeHand,
        bestCards: bestCards,
        structuredCards: structuredCards,
        translatedType: translatedType,
        description: description,
      );
    }).toList();

    // Ordena as avaliações (Vencedor no índice 0)
    evaluations.sort((a, b) => _compareEvaluations(b, a));

    // Verifica empates
    final bestEval = evaluations.first;
    final tied = evaluations
        .where((e) => _compareEvaluations(e, bestEval) == 0)
        .toList();

    return PokerShowdownResult(
      winner: evaluations.first,
      evaluations: evaluations,
      isTie: tied.length > 1,
      tiedPlayers: tied,
    );
  }

  /// Avalia uma mão única (usado na calculadora de probabilidade)
  PokerHandEvaluation evaluateHand({
    required String playerName,
    required List<String> playerCards,
    required List<String> boardCards,
  }) {
    final pCards = playerCards.map(_parseCard).toList();
    final bCards = boardCards.map(_parseCard).toList();
    final allCards = [...pCards, ...bCards];

    final bestCards = _findBestFiveCards(allCards);
    final madeHand = poker.MadeHand.best(poker.ImmutableCardSet.of(bestCards));

    final structuredCards = _getStructuredCards(madeHand, bestCards);
    final translatedType = _getHandRankPortuguese(madeHand.type);
    final description = _buildHandDescription(madeHand, structuredCards);

    return PokerHandEvaluation(
      player: PokerPlayerHand(name: playerName, cards: playerCards),
      madeHand: madeHand,
      bestCards: bestCards,
      structuredCards: structuredCards,
      translatedType: translatedType,
      description: description,
    );
  }

  /// Compara duas mãos avaliadas (público)
  /// Retorna: >0 se A vence, <0 se B vence, 0 se empate
  int compareHands(PokerHandEvaluation a, PokerHandEvaluation b) {
    return _compareEvaluations(a, b);
  }

  // --- LÓGICA DE COMPARAÇÃO (O JUIZ) ---

  /// Compara duas avaliações. Retorna >0 se A ganha, <0 se B ganha, 0 se empate.
  int _compareEvaluations(PokerHandEvaluation a, PokerHandEvaluation b) {
    // 1. Compara a força do Tipo da Mão (ex: Full House > Flush)
    final strengthA = _getHandTypeStrength(a.madeHand.type);
    final strengthB = _getHandTypeStrength(b.madeHand.type);

    if (strengthA != strengthB) {
      return strengthA.compareTo(strengthB);
    }

    // 2. Se o tipo é igual, compara as CARTAS ESTRUTURADAS carta por carta
    for (int i = 0; i < 5; i++) {
      final rankA = _getRankValue(a.structuredCards[i].rank);
      final rankB = _getRankValue(b.structuredCards[i].rank);

      final diff = rankA.compareTo(rankB);
      if (diff != 0) {
        return diff; // Encontrou a carta de desempate
      }
    }

    return 0; // Empate total
  }

  /// Reorganiza as cartas baseado na força lógica da mão (Frequência > Valor)
  List<poker.Card> _getStructuredCards(
    poker.MadeHand hand,
    List<poker.Card> cards,
  ) {
    final rankCounts = <poker.Rank, int>{};
    for (final c in cards) {
      rankCounts[c.rank] = (rankCounts[c.rank] ?? 0) + 1;
    }

    final sortedRanks = rankCounts.keys.toList()
      ..sort((a, b) {
        final countA = rankCounts[a]!;
        final countB = rankCounts[b]!;
        // 1. Quem tem mais cartas iguais vem primeiro (Trinca > Par > Kicker)
        if (countA != countB) {
          return countB.compareTo(countA);
        }
        // 2. Se a quantidade é igual, vale o Rank maior (Ás > Rei)
        return _getRankValue(b).compareTo(_getRankValue(a));
      });

    final structured = <poker.Card>[];
    for (final rank in sortedRanks) {
      final cardsWithRank = cards.where((c) => c.rank == rank).toList();
      structured.addAll(cardsWithRank);
    }

    return structured;
  }

  int _getRankValue(poker.Rank rank) {
    // Garante que Ás (index 12 no pacote) seja tratado como 14 (o maior)
    if (rank.index == 12) return 14;
    return rank.index + 2;
  }

  int _getHandTypeStrength(poker.MadeHandType type) {
    switch (type) {
      case poker.MadeHandType.highcard:
        return 0;
      case poker.MadeHandType.pair:
        return 1;
      case poker.MadeHandType.twoPairs:
        return 2;
      case poker.MadeHandType.trips:
        return 3;
      case poker.MadeHandType.straight:
        return 4;
      case poker.MadeHandType.flush:
        return 5;
      case poker.MadeHandType.fullHouse:
        return 6;
      case poker.MadeHandType.quads:
        return 7;
      case poker.MadeHandType.straightFlush:
        return 8;
    }
  }

  // --- TRADUÇÃO E TEXTOS ---

  String _getHandRankPortuguese(poker.MadeHandType type) {
    switch (type) {
      case poker.MadeHandType.highcard:
        return 'Carta Alta';
      case poker.MadeHandType.pair:
        return 'Um Par';
      case poker.MadeHandType.twoPairs:
        return 'Dois Pares';
      case poker.MadeHandType.trips:
        return 'Trinca';
      case poker.MadeHandType.straight:
        return 'Sequência';
      case poker.MadeHandType.flush:
        return 'Flush';
      case poker.MadeHandType.fullHouse:
        return 'Full House';
      case poker.MadeHandType.quads:
        return 'Quadra';
      case poker.MadeHandType.straightFlush:
        return 'Straight Flush';
    }
  }

  String _buildHandDescription(
    poker.MadeHand hand,
    List<poker.Card> structuredCards,
  ) {
    // Usa as cartas já estruturadas para descrever corretamente
    switch (hand.type) {
      case poker.MadeHandType.highcard:
        final high = _rankPt(structuredCards[0].rank);
        final kicker = _rankPt(structuredCards[1].rank);
        return 'Carta Alta ($high) com Kicker $kicker';

      case poker.MadeHandType.pair:
        final pairRank = _rankPt(structuredCards[0].rank);
        final kicker = _rankPt(structuredCards[2].rank);
        return 'Par de $pairRank (Kicker $kicker)';

      case poker.MadeHandType.twoPairs:
        final highPair = _rankPt(structuredCards[0].rank);
        final lowPair = _rankPt(structuredCards[2].rank);
        return 'Dois Pares: $highPair e $lowPair';

      case poker.MadeHandType.trips:
        final rank = _rankPt(structuredCards[0].rank);
        return 'Trinca de $rank';

      case poker.MadeHandType.straight:
        final high = _rankPt(structuredCards[0].rank);
        return 'Sequência até $high';

      case poker.MadeHandType.flush:
        final high = _rankPt(structuredCards[0].rank);
        return 'Flush com $high maior';

      case poker.MadeHandType.fullHouse:
        final trips = _rankPt(structuredCards[0].rank);
        final pair = _rankPt(structuredCards[3].rank);
        return 'Full House de $trips com $pair';

      case poker.MadeHandType.quads:
        final rank = _rankPt(structuredCards[0].rank);
        return 'Quadra de $rank';

      case poker.MadeHandType.straightFlush:
        return 'Straight Flush';
    }
  }

  String getWinningExplanation({required PokerShowdownResult result}) {
    if (result.isTie) {
      final names = result.tiedPlayers.map((e) => e.player.name).join(' e ');
      return 'Empate entre $names.';
    }

    final winner = result.winner;
    final loser = result.evaluations.firstWhere(
      (e) => e.player.name != winner.player.name,
      orElse: () => result.evaluations.last,
    );

    final sb = StringBuffer();
    sb.writeln('Vencedor: ${winner.player.name}');
    sb.writeln('Mão: ${winner.description}');

    if (winner.madeHand.type != loser.madeHand.type) {
      sb.write(
        'Motivo: ${winner.translatedType} vence ${loser.translatedType}.',
      );
    } else {
      sb.write(
        'Motivo: ${winner.player.name} tem cartas de desempate (kickers) maiores.',
      );
    }

    return sb.toString();
  }

  // --- HELPERS ---

  poker.Card _parseCard(String value) => poker.Card.parse(value);

  String _rankPt(poker.Rank rank) {
    final char = _rankToChar(rank);
    return char == 'T' ? '10' : _translateRankName(char);
  }

  String _translateRankName(String char) {
    switch (char) {
      case 'A':
        return 'Ás';
      case 'K':
        return 'Rei';
      case 'Q':
        return 'Dama';
      case 'J':
        return 'Valete';
      case 'T':
        return '10';
      default:
        return char;
    }
  }

  String _rankToChar(poker.Rank rank) {
    const ranks = [
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'T',
      'J',
      'Q',
      'K',
      'A',
    ];
    if (rank.index >= 0 && rank.index < ranks.length) {
      return ranks[rank.index];
    }
    return '?';
  }

  List<poker.Card> _findBestFiveCards(List<poker.Card> cards) {
    if (cards.length < 5) return cards;

    poker.MadeHand? bestHand;
    List<poker.Card> bestCombo = [];

    // Gera combinações simples de 5 cartas
    final combos = _combinations(cards, 5);
    for (final combo in combos) {
      final hand = poker.MadeHand.best(poker.ImmutableCardSet.of(combo));
      if (bestHand == null || hand.power > bestHand.power) {
        bestHand = hand;
        bestCombo = combo;
      }
    }
    return bestCombo;
  }

  List<List<poker.Card>> _combinations(List<poker.Card> list, int k) {
    var combos = <List<poker.Card>>[];
    void f(List<poker.Card> l, int c, int start) {
      if (c == 0) {
        combos.add(List.from(l));
        return;
      }
      for (int i = start; i <= list.length - c; i++) {
        l.add(list[i]);
        f(l, c - 1, i + 1);
        l.removeLast();
      }
    }

    f([], k, 0);
    return combos;
  }
}
