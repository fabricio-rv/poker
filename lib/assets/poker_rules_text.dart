/// Knowledge Base - Artigo sobre Regras de Poker
/// Cole o artigo completo abaixo dentro das aspas triplas

const String pokerRulesArticle = """
Guia Completo de Regras e Estratégias do Nosso Poker

Muitos consideram que o poker é um jogo que não depende tanto da sorte como outros jogos. Para ser um vencedor, o primeiro passo é entender a hierarquia das mãos e as regras específicas desta mesa.

1. Ranking das Mãos (Da mais forte para a mais fraca)

A classificação das mãos no poker corresponde à probabilidade de formar as respetivas mãos. Quanto mais rara, mais forte.

1. Royal Flush (A Mão Invencível)
É a mão mais forte do poker. Consiste em uma sequência do 10 ao Ás (10, J, Q, K, A), todas do mesmo naipe. É extremamente rara.
Exemplo: A♥ K♥ Q♥ J♥ 10♥.

2. Straight Flush
Cinco cartas consecutivas do mesmo naipe (que não sejam Royal).
Exemplo: 8♣ 7♣ 6♣ 5♣ 4♣.
Critério de Desempate: Ganha quem tiver a carta mais alta na ponta da sequência.

3. Quadra (Four of a Kind)
Quatro cartas do mesmo valor (Rank).
Exemplo: 10♠ 10♦ 10♥ 10♣.
Critério de Desempate: Ganha a quadra de valor maior. Se a quadra for comunitária (igual para todos), ganha quem tiver a quinta carta (Kicker) maior.

4. Full House
Uma Trinca (três cartas iguais) combinada com um Par.
Exemplo: K♠ K♦ K♣ (Trinca) + 2♥ 2♣ (Par).
Importante: O Full House de Reis ganha do Full House de Damas (a trinca define a força).

5. Flush (5 Cartas)
Cinco cartas do mesmo naipe, não importa a ordem numérica.
Exemplo: A♥ J♥ 8♥ 4♥ 2♥.
Critério de Desempate: Se dois jogadores têm Flush, ganha quem tem a carta mais alta do naipe. Se a mais alta for igual, compara-se a segunda, e assim por diante.

6. Sequência (Straight - 5 Cartas)
Cinco cartas em ordem numérica consecutiva, mas de naipes diferentes.
Exemplo: 6♠ 5♣ 4♦ 3♥ 2♠.
Nota: O Ás pode ser usado como carta baixa (A-2-3-4-5) ou alta (10-J-Q-K-A).

7. Trinca (Three of a Kind)
Três cartas do mesmo valor.
Exemplo: 9♠ 9♦ 9♥.
Critério de Desempate: Ganha a trinca maior.

8. Dois Pares
Dois pares de cartas de valores diferentes.
Exemplo: 10♦ 10♣ (Par de 10) e 9♠ 9♦ (Par de 9).
Critério de Desempate: Primeiro compara-se o par maior. Se for igual, compara-se o par menor. Se ambos forem iguais, ganha quem tiver a quinta carta (Kicker) maior.

9. Par (One Pair)
Duas cartas do mesmo valor.
Exemplo: A♠ A♦.
Critério de Desempate: Ganha o par maior. Se empatar, ganha a carta lateral (Kicker) mais alta.

2. Regras Especiais da Casa (Mãos de 3 Cartas)

Nesta mesa, jogamos com regras customizadas que valorizam combinações parciais. Estas mãos são consideradas "Jogadas de Valor", mas são mais fracas que um Par completo.

10. Mini-Flush (3 Cartas)
Três cartas do mesmo naipe.
Valor: Esta mão ganha de uma "Mini-Sequência" e ganha de "Carta Alta", mas perde para qualquer "Par".
Exemplo: K♥ 9♥ 2♥.

11. Mini-Sequência (3 Cartas)
Três cartas consecutivas de naipes variados.
Valor: Esta mão ganha de "Carta Alta", mas perde para "Mini-Flush" e "Par".
Exemplo: 4♣ 5♦ 6♠.

12. Carta Alta (High Card)
Se você não formou nenhuma das mãos acima (nem sequer as mãos especiais de 3 cartas), vale a sua carta mais alta isolada.
Ordem de Força: A (Maior) > K > Q > J > 10 > 9 > 8 > 7 > 6 > 5 > 4 > 3 > 2 (Menor).

3. Dinâmica do Jogo

O Pré-Flop
Cada jogador recebe 2 cartas fechadas. É feita a primeira rodada de apostas antes de ver as cartas da mesa.

O Flop
O dealer vira 3 cartas comunitárias na mesa. Todos podem usá-las. Segue-se uma rodada de apostas.

O Turn
A 4ª carta comunitária é virada. Mais apostas.

O River
A 5ª e última carta é virada. Rodada final de apostas.

O Showdown (Tira-Teima)
Se sobrar mais de um jogador, todos mostram as cartas. O sistema (ou o Juiz no Modo Gerenciador) avalia a melhor combinação de 5 cartas possível para cada jogador, considerando as regras acima.

4. Probabilidades Curiosas
Royal Flush: A chance é de 0,00015%. Alguns jogam a vida toda e nunca fazem um.
Flush vs Full House: Muita gente confunde, mas o Full House é mais forte (e mais raro) que o Flush.
Sorte ou Perícia? A curto prazo, sorte conta. A longo prazo, entender estas probabilidades e saber a hora de desistir faz de você um vencedor.
""";
