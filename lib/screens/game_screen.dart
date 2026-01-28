import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../models/game_session.dart';
import '../utils/constants.dart';
import '../widgets/card_picker_sheet.dart';
import '../services/poker_logic_service.dart';
import 'home_screen.dart';

/// Tela principal do jogo em andamento
/// Implementa o Manager Mode com timer, blinds automáticos, eliminação, rebuys e dealer
class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Cartas do jogador no modo multiplayer
  String? _playerCard1;
  String? _playerCard2;

  // Cartas da mesa no modo juiz
  final List<String?> _boardCards = [null, null, null, null, null];

  // Estado de revelação das cartas da mesa (Flop, Turn, River)
  int _revealedBoardCards = 0;

  // Manager mode showdown state
  final List<String?> _managerBoardCards = [null, null, null, null, null];
  final Map<int, List<String?>> _managerPlayerHands =
      {}; // playerId -> [card1, card2]

  final PokerLogicService _pokerLogicService = PokerLogicService();

  @override
  void initState() {
    super.initState();
    // Verifica se o jogo acabou logo após iniciar (caso já tenha apenas 1 jogador)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (gameProvider.isGameFinished) {
        _showGameOverDialog(gameProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final confirm = await _showCancelConfirmation();
          if (confirm == true && mounted) {
            final gameProvider = Provider.of<GameProvider>(
              context,
              listen: false,
            );
            await gameProvider.cancelGame();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jogo em Andamento'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                final confirm = await _showCancelConfirmation();
                if (confirm == true && mounted) {
                  final gameProvider = Provider.of<GameProvider>(
                    context,
                    listen: false,
                  );
                  await gameProvider.cancelGame();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            final game = gameProvider.currentGame;

            if (game == null) {
              return const Center(child: Text('Erro: Nenhum jogo ativo'));
            }

            // Check if game is finished
            if (gameProvider.isGameFinished) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showGameOverDialog(gameProvider);
              });
            }

            if (game.gameMode == GameMode.manager) {
              return _buildManagerMode(gameProvider, game);
            } else {
              return _buildMultiplayerMode(gameProvider, game);
            }
          },
        ),
      ),
    );
  }

  Widget _buildManagerMode(GameProvider gameProvider, GameSession game) {
    return Column(
      children: [
        // Timer, Blinds e Próximo Nível
        _buildGameHeader(gameProvider),

        // Botão Rotacionar Dealer
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.darkGrey.withValues(alpha: 0.5),
          child: ElevatedButton.icon(
            onPressed: () => gameProvider.rotateDealer(),
            icon: const Icon(Icons.casino, size: 20),
            label: const Text('Rotacionar Dealer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),

        // MESA & TIRA-TEIMA Section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.layers, color: AppColors.gold, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'MESA & TIRA-TEIMA',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Board cards
                  Text('Cartas da Mesa', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Padding(
                        padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                        child: _buildCard(
                          isBoard: true,
                          cardValue: _managerBoardCards[index],
                          onTap: () => _pickManagerBoardCard(index),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Resolver showdown button (Always enabled)
                  ElevatedButton.icon(
                    onPressed: _showManagerShowdownDialog,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Resolver Vencedor (Final)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lista de Jogadores
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: game.players.length,
            itemBuilder: (context, index) {
              final player = game.players[index];
              final isDealer = gameProvider.dealerIndex == index;

              return Card(
                color: player.isEliminated
                    ? AppColors.darkGrey.withValues(alpha: 0.5)
                    : AppColors.cardBackground,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: player.isEliminated
                            ? Colors.grey
                            : AppColors.primary,
                        child: player.isEliminated
                            ? const Icon(Icons.close, color: Colors.white)
                            : Text(
                                player.username[0].toUpperCase(),
                                style: AppTextStyles.bodyLarge,
                              ),
                      ),
                      // Indicador de Dealer
                      if (isDealer && !player.isEliminated)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              'D',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    player.username,
                    style: AppTextStyles.heading3.copyWith(
                      decoration: player.isEliminated
                          ? TextDecoration.lineThrough
                          : null,
                      color: player.isEliminated ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(
                    player.rebuyCount > 0
                        ? 'Rebuys: ${player.rebuyCount}'
                        : player.isEliminated
                        ? 'Eliminado'
                        : 'Ativo',
                    style: AppTextStyles.caption,
                  ),
                  trailing: player.isEliminated
                      ? OutlinedButton.icon(
                          onPressed: () {
                            gameProvider.rebuyPlayer(player.userId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${player.username} voltou ao jogo!',
                                ),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.replay, size: 16),
                          label: const Text('Rebuy'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.highlight_off,
                            color: AppColors.error,
                            size: 32,
                          ),
                          onPressed: () {
                            _confirmElimination(
                              gameProvider,
                              player.userId,
                              player.username,
                            );
                          },
                        ),
                ),
              );
            },
          ),
        ),

        // Contador de jogadores ativos e botão de teste
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.darkGrey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text(
                    '${game.activePlayers.length} jogadores ativos',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplayerMode(GameProvider gameProvider, GameSession game) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Timer and Blinds header
          _buildGameHeader(gameProvider),

          // Player's cards section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Minhas Cartas',
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCard(
                      cardValue: _playerCard1,
                      onTap: () => _pickPlayerCard(1),
                    ),
                    const SizedBox(width: 16),
                    _buildCard(
                      cardValue: _playerCard2,
                      onTap: () => _pickPlayerCard(2),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Board cards
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Mesa',
                  style: AppTextStyles.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final isRevealed = index < _revealedBoardCards;
                    return Padding(
                      padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                      child: _buildCard(
                        isBoard: true,
                        cardValue: isRevealed ? _boardCards[index] : null,
                        onTap: isRevealed ? () => _pickBoardCard(index) : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Botão para revelar próxima fase (Flop/Turn/River)
          if (_revealedBoardCards < 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: _revealNextPhase,
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _revealedBoardCards == 0
                        ? 'Revelar Flop'
                        : _revealedBoardCards == 3
                        ? 'Revelar Turn'
                        : 'Revelar River',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Nota sobre Showdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              color: AppColors.primary.withValues(alpha: 0.7),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.gold,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Modo Multiplayer',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.gold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cada jogador vê apenas suas próprias cartas e a mesa compartilhada. O julgamento é feito no final na tela do juiz.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGameHeader(GameProvider gameProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkGrey, AppColors.cardBackground],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.attach_money, color: AppColors.gold, size: 40),
            const SizedBox(height: 12),
            Text(
              '\$ ${gameProvider.currentSmallBlind}/${gameProvider.currentBigBlind}',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.gold,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Blinds',
              style: AppTextStyles.caption.copyWith(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    bool isBoard = false,
    String? cardValue,
    VoidCallback? onTap,
  }) {
    final displayCard = cardValue != null;
    final suitSymbol = displayCard ? _getCardSuitSymbol(cardValue) : '?';
    final rank = displayCard ? _getCardRank(cardValue) : '?';
    final suitColor = displayCard ? _getCardSuitColor(cardValue) : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isBoard ? 50 : 80,
        height: isBoard ? 70 : 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null ? AppColors.gold : AppColors.darkGrey,
            width: onTap != null ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: displayCard
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rank,
                    style: TextStyle(
                      fontSize: isBoard ? 18 : 28,
                      fontWeight: FontWeight.bold,
                      color: suitColor,
                    ),
                  ),
                  Text(
                    suitSymbol,
                    style: TextStyle(
                      fontSize: isBoard ? 20 : 32,
                      color: suitColor,
                    ),
                  ),
                ],
              )
            : Center(
                child: Icon(
                  onTap != null ? Icons.add : Icons.question_mark,
                  size: isBoard ? 24 : 48,
                  color: onTap != null ? AppColors.gold : Colors.grey,
                ),
              ),
      ),
    );
  }

  String _getCardSuitSymbol(String card) {
    final suit = card[card.length - 1];
    switch (suit) {
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

  String _getCardRank(String card) {
    return card.substring(0, card.length - 1).toUpperCase();
  }

  Color _getCardSuitColor(String card) {
    final suit = card[card.length - 1];
    return (suit == 'h' || suit == 'd') ? Colors.red : Colors.black;
  }

  /// TASK 2: Visual card display for dialogs (white container with rank + suit icon)
  Widget _buildCardForDialog(String? cardValue) {
    final displayCard = cardValue != null;
    final suitSymbol = displayCard ? _getCardSuitSymbol(cardValue) : '?';
    final rank = displayCard ? _getCardRank(cardValue) : '?';
    final suitColor = displayCard ? _getCardSuitColor(cardValue) : Colors.grey;

    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: displayCard ? AppColors.gold : Colors.grey,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: displayCard
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rank,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: suitColor,
                  ),
                ),
                Text(
                  suitSymbol,
                  style: TextStyle(fontSize: 32, color: suitColor),
                ),
              ],
            )
          : Center(child: Icon(Icons.add, size: 40, color: Colors.grey)),
    );
  }

  Future<void> _pickPlayerCard(int cardIndex) async {
    final card = await CardPickerSheet.show(context);
    if (card == null) return;

    if (_isCardUsed(card)) {
      _showDuplicateCardSnack();
      return;
    }

    setState(() {
      if (cardIndex == 1) {
        _playerCard1 = card;
      } else {
        _playerCard2 = card;
      }
    });
    _recalculateOdds();
  }

  Future<void> _pickBoardCard(int index) async {
    final card = await CardPickerSheet.show(context);
    if (card == null) return;

    if (_isCardUsed(card)) {
      _showDuplicateCardSnack();
      return;
    }

    setState(() {
      _boardCards[index] = card;
    });
    _recalculateOdds();
  }

  bool _isCardUsed(String card) {
    final selected = <String?>[_playerCard1, _playerCard2, ..._boardCards];
    return selected.whereType<String>().contains(card);
  }

  void _showDuplicateCardSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Essa carta já foi selecionada.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _recalculateOdds() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    // Auto-calculation happens in provider when cards are set
    final playerCards = <String>[];
    if (_playerCard1 != null) playerCards.add(_playerCard1!);
    if (_playerCard2 != null) playerCards.add(_playerCard2!);

    final boardCards = _boardCards.whereType<String>().toList();

    if (playerCards.length == 2 && boardCards.isNotEmpty) {
      gameProvider.calculateWinProbability(
        playerCards: playerCards,
        boardCards: boardCards,
      );
    }
  }

  void _revealNextPhase() {
    setState(() {
      if (_revealedBoardCards == 0) {
        // Revelar Flop (3 cartas)
        _revealedBoardCards = 3;
      } else if (_revealedBoardCards == 3) {
        // Revelar Turn (4ª carta)
        _revealedBoardCards = 4;
      } else if (_revealedBoardCards == 4) {
        // Revelar River (5ª carta)
        _revealedBoardCards = 5;
      }
    });

    // Mock: Atualizar probabilidade após revelar cartas
    _recalculateOdds();
  }

  Future<void> _confirmElimination(
    GameProvider gameProvider,
    String userId,
    String playerName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Confirmar Eliminação'),
          ],
        ),
        content: Text(
          'Tem certeza que deseja eliminar $playerName?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await gameProvider.eliminatePlayer(userId);

      if (mounted) {
        // Vibração ao eliminar
        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$playerName foi eliminado'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Dialog de Game Over com celebração e distribuição de XP
  Future<void> _showGameOverDialog(GameProvider gameProvider) async {
    final game = gameProvider.currentGame;
    if (game == null) return;

    // Encontra o vencedor (último jogador ativo)
    final winner = game.players.firstWhere((p) => !p.isEliminated);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Column(
          children: [
            const Icon(Icons.emoji_events, color: AppColors.gold, size: 80),
            const SizedBox(height: 16),
            Text(
              '🎉 Fim de Jogo! 🎉',
              style: AppTextStyles.heading2.copyWith(color: AppColors.gold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Vencedor:',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              winner.username,
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.gold,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: AppColors.gold, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '+500 XP',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _finishGameAndAwardXP(gameProvider, winner.userId);
              },
              icon: const Icon(Icons.home),
              label: const Text('Voltar para Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Finaliza o jogo e distribui XP para todos os jogadores
  Future<void> _finishGameAndAwardXP(
    GameProvider gameProvider,
    String winnerId,
  ) async {
    final game = gameProvider.currentGame;
    if (game == null) return;

    // Finaliza o jogo
    await gameProvider.finishGame(winnerId);

    // Distribui XP para todos os jogadores
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    for (final player in game.players) {
      final isWinner = player.userId == winnerId;

      // Atualiza apenas o jogador atual (em produção, você enviaria para backend)
      if (player.userId == userProvider.currentUser?.id) {
        await userProvider.recordMatch(isWinner);
      }
    }

    if (mounted) {
      // Vibração de celebração
      HapticFeedback.heavyImpact();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Jogo finalizado! XP atualizado.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickManagerBoardCard(int index) async {
    final card = await CardPickerSheet.show(context);
    if (card == null) return;

    if (_isManagerCardUsed(card, excludeIndex: index)) {
      _showDuplicateCardSnack();
      return;
    }

    setState(() {
      _managerBoardCards[index] = card;
    });
  }

  bool _isManagerCardUsed(String card, {int? excludeIndex}) {
    final selected = <String?>[..._managerBoardCards];
    for (final hand in _managerPlayerHands.values) {
      selected.addAll(hand);
    }
    // Remove the excluded card at this index
    if (excludeIndex != null && excludeIndex < selected.length) {
      selected[excludeIndex] = null;
    }
    return selected.whereType<String>().contains(card);
  }

  Future<void> _showManagerShowdownDialog() async {
    // Validation 1: Check if all 5 board cards are placed
    if (_managerBoardCards.whereType<String>().length < 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coloque as 5 cartas da mesa primeiro.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final game = Provider.of<GameProvider>(context, listen: false).currentGame;
    if (game == null) return;

    // Validation 2: Check if there are at least 2 active players
    if (game.activePlayers.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione quem está na mão final.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Step 1: Choose which players are in the showdown
    final selectedPlayerIds = await _selectPlayersForShowdown(game);
    if (selectedPlayerIds == null || selectedPlayerIds.isEmpty) return;

    // Step 2: Input hands for each player
    final playerHands = <String, List<String>>{}; // playerId -> [card1, card2]

    for (final playerId in selectedPlayerIds) {
      final player = game.players.firstWhere((p) => p.userId == playerId);
      final hands = await _inputPlayerHand(player.username);

      if (hands == null || hands.length != 2) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Entrada cancelada')));
        }
        return;
      }

      // Check for duplicate cards
      final allCards = <String>[
        ..._managerBoardCards.whereType<String>(),
        ...playerHands.values.expand((h) => h),
        ...hands,
      ];
      final uniqueCards = allCards.toSet();
      if (allCards.length != uniqueCards.length) {
        if (mounted) {
          _showDuplicateCardSnack();
        }
        return;
      }

      playerHands[playerId] = hands;
    }

    // Step 3: Evaluate and show results
    final hands = playerHands.entries.map((e) {
      final player = game.players.firstWhere((p) => p.userId == e.key);
      return PokerPlayerHand(name: player.username, cards: e.value);
    }).toList();

    final boardCards = _managerBoardCards.whereType<String>().toList();
    final result = _pokerLogicService.evaluateShowdown(
      players: hands,
      boardCards: boardCards,
    );

    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Column(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.gold, size: 48),
              const SizedBox(height: 8),
              const Text('Resultado do Showdown'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VENCEDOR: ${result.winner.player.name}',
                  style: AppTextStyles.heading3.copyWith(color: AppColors.gold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mão: ${result.winner.description}',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cartas: ${result.winner.player.cards.join(', ')}',
                  style: AppTextStyles.caption,
                ),
                const Divider(color: Colors.white24, height: 20),
                ...result.evaluations
                    .where((e) => e.player.name != result.winner.player.name)
                    .map(
                      (e) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${e.player.name} - ${e.description}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );

      // Reset board for next hand
      setState(() {
        _managerBoardCards.fillRange(0, 5, null);
        _managerPlayerHands.clear();
      });
    }
  }

  Future<List<String>?> _selectPlayersForShowdown(GameSession game) {
    final activePlayers = game.activePlayers;
    final selected = <String>[];

    return showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Selecionar Jogadores'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: activePlayers.map((player) {
                return CheckboxListTile(
                  title: Text(player.username),
                  value: selected.contains(player.userId),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selected.add(player.userId);
                      } else {
                        selected.remove(player.userId);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selected.isNotEmpty
                  ? () => Navigator.pop(context, selected)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>?> _inputPlayerHand(String playerName) {
    String? card1;
    String? card2;

    return showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text('Cartas de $playerName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final card = await CardPickerSheet.show(context);
                        if (card != null && card != card2) {
                          setState(() {
                            card1 = card;
                          });
                        }
                      },
                      child: _buildCardForDialog(card1),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () async {
                        final card = await CardPickerSheet.show(context);
                        if (card != null && card != card1) {
                          setState(() {
                            card2 = card;
                          });
                        }
                      },
                      child: _buildCardForDialog(card2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: card1 != null && card2 != null
                  ? () => Navigator.pop(context, [card1!, card2!])
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showCancelConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Jogo'),
        content: const Text(
          'Tem certeza que deseja cancelar o jogo? '
          'Nenhum XP será concedido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar Jogando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancelar Jogo'),
          ),
        ],
      ),
    );
  }
}
