class RuleFinderService {
  /// Retorna a explicação e exemplos baseados no nome da mão em Português
  /// O input [handName] deve vir do PokerLogicService (ex: "Dois Pares", "Full House")
  String getExplanationForHand(String handName) {
    // Normaliza para evitar erros de maiúsculas/minúsculas ou espaços extras
    final key = handName.trim();

    // Verifica se contém partes específicas para mapear corretamente
    if (key.contains('Royal Flush')) return _rules['Royal Flush']!;
    if (key.contains('Straight Flush')) return _rules['Straight Flush']!;
    if (key.contains('Quadra')) return _rules['Quadra']!;
    if (key.contains('Full House')) return _rules['Full House']!;
    if (key.contains('Flush')) return _rules['Flush']!;
    if (key.contains('Sequência')) return _rules['Sequência']!;
    if (key.contains('Trinca')) return _rules['Trinca']!;
    if (key.contains('Dois Pares')) return _rules['Dois Pares']!;
    if (key.contains('Um Par') || key.contains('Par de'))
      return _rules['Um Par']!;
    if (key.contains('Carta Alta')) return _rules['Carta Alta']!;

    return 'Regra não encontrada para: $handName';
  }

  static const Map<String, String> _rules = {
    'Royal Flush': '''
### 1. Royal Flush
A mão mais forte do poker.
São as 5 cartas mais altas do mesmo naipe em sequência.

* **Exemplo:** 10♠, J♠, Q♠, K♠, A♠.
* **Probabilidade:** Raríssimo. Imbatível.
''',

    'Straight Flush': '''
### 2. Straight Flush
Cinco cartas em sequência numérica e do mesmo naipe.

* **Exemplo:** 5♥, 6♥, 7♥, 8♥, 9♥.
* **Desempate:** Se dois jogadores tiverem, ganha quem tiver a carta mais alta na sequência.
''',

    'Quadra': '''
### 3. Quadra (Four of a Kind)
Quatro cartas do mesmo valor (Rank).

* **Exemplo:** 8♣, 8♦, 8♥, 8♠.
* **Desempate:** Ganha a quadra de valor maior. Se a quadra estiver na mesa (igual para todos), ganha quem tiver a quinta carta (Kicker) maior.
''',

    'Full House': '''
### 4. Full House
Uma Trinca combinada com um Par.

* **Exemplo:** Trinca de Reis (K, K, K) e Par de 7 (7, 7).
* **Desempate:** Primeiro compara-se a trinca. Se for igual, compara-se o par.
''',

    'Flush': '''
### 5. Flush
Cinco cartas do mesmo naipe, não importando a ordem numérica.

* **Exemplo:** 2♦, 5♦, 9♦, J♦, K♦.
* **Desempate:** Ganha quem tiver a carta mais alta do naipe. Se a primeira for igual, compara-se a segunda, e assim por diante.
''',

    'Sequência': '''
### 6. Sequência (Straight)
Cinco cartas em ordem numérica, mas de naipes diferentes.

* **Exemplo:** 5♣, 6♦, 7♠, 8♥, 9♣.
* **Nota:** O Ás pode ser usado antes do 2 (A-2-3-4-5) ou depois do Rei (10-J-Q-K-A).
* **Desempate:** Ganha a sequência que termina na carta mais alta.
''',

    'Trinca': '''
### 7. Trinca (Three of a Kind)
Três cartas do mesmo valor.

* **Exemplo:** 7♣, 7♦, 7♠.
* **Desempate:** Ganha a trinca maior. Se for igual, decidem as cartas restantes (Kickers).
''',

    'Dois Pares': '''
### 8. Dois Pares
Dois pares diferentes de cartas.

* **Exemplo:** Par de 10 (10, 10) e Par de 4 (4, 4).
* **Desempate:** Primeiro compara o par maior. Se igual, o par menor. Se ambos iguais, decide o Kicker (a 5ª carta).
''',

    'Um Par': '''
### 9. Um Par
Duas cartas do mesmo valor.

* **Exemplo:** 9♣, 9♥.
* **Desempate:** Ganha o par maior. Se os pares forem iguais, ganha quem tiver as cartas restantes (Kickers) mais altas.
''',

    'Carta Alta': '''
### 10. Carta Alta (High Card)
Quando não se forma nenhuma das combinações acima.
Vale a carta de maior valor na mão.

* **Ordem:** A (maior), K, Q, J, 10... até 2 (menor).
* **Desempate:** Compara-se a maior carta. Se empatar, a segunda maior, e assim por diante.
''',
  };
}
