import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../models/game_session.dart';
import '../utils/constants.dart';
import '../utils/card_helper.dart';
import '../widgets/card_picker_sheet.dart';
import '../widgets/match_summary_overlay.dart';
import '../services/poker_logic_service.dart';
import 'home_screen.dart';

/// Tela principal do jogo em andamento
/// Implementa Manager Mode (Host) com timer, blinds, eliminação, rebuys
/// E Multiplayer Mode (Guest) com probabilidades e read-only board
class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Cartas do jogador (ambos os modos)
  String? _playerCard1;
  String? _playerCard2;

  // Services
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

      // REAL-TIME SYNC: Ensure session stream is active for all participants
      // GameProvider.joinSession() starts the Firestore listener automatically
      // This ensures all game state updates (board cards, dealer position, eliminations)
      // are synced in real-time to all devices in the session

      // NUCLEAR FIX: Listen for session cancellation
      // If Host cancels, all participants are redirected to Home immediately
      gameProvider.sessionCanceledStream.listen((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      });
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
          title: const Text('Sair'),
          leading: IconButton(
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
        ),
        body: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            final game = gameProvider.currentGame;
            final matchResult = gameProvider.matchResult;

            // CRITICAL: Show match summary overlay when game ends
            if (matchResult != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showMatchSummaryOverlay(context, gameProvider, matchResult);
              });
            }

            if (game == null) {
              return const Center(child: Text('Erro: Nenhum jogo ativo'));
            }

            // Check if game is finished
            if (gameProvider.isGameFinished) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showGameOverDialog(gameProvider);
              });
            }

            // Choose layout based on game mode
            if (game.gameMode == GameMode.manager) {
              return _buildManagerMode(gameProvider, game);
            } else {
              // Multiplayer mode - render based on isHost
              if (gameProvider.isHost) {
                return _buildHostMultiplayerMode(gameProvider, game);
              } else {
                return _buildGuestMultiplayerMode(gameProvider, game);
              }
            }
          },
        ),
      ),
    );
  }

  // ==================== MANAGER MODE ====================
  Widget _buildManagerMode(GameProvider gameProvider, GameSession game) {
    return Column(
      children: [
        // Clean header
        _buildCleanHeader(),

        // Botão Rotacionar Dealer
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: ElevatedButton.icon(
            onPressed: () => gameProvider.rotateDealer(),
            icon: const Icon(Icons.casino, size: 20),
            label: const Text('Rotacionar Dealer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                      final cardValue = index < game.boardCards.length
                          ? game.boardCards[index]
                          : '??';
                      return Padding(
                        padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                        child: _buildCard(
                          isBoard: true,
                          cardValue: cardValue,
                          onTap: () => _pickBoardCard(index, gameProvider),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Resolver showdown button
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showManagerShowdownDialog(gameProvider, game),
                          icon: const Icon(Icons.emoji_events, size: 24),
                          label: const Text(
                            'RESOLVER VENCEDOR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A2D35),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _cancelMatch(gameProvider),
                          icon: const Icon(Icons.cancel_outlined, size: 24),
                          label: const Text(
                            'CANCELAR PARTIDA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
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

        // Active players counter
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.darkGrey,
          child: Row(
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
        ),
      ],
    );
  }

  // ==================== HOST MULTIPLAYER MODE ====================
  Widget _buildHostMultiplayerMode(
    GameProvider gameProvider,
    GameSession game,
  ) {
    // NUCLEAR FIX: Check if current user is actually the Host
    final isHost = gameProvider.isCurrentUserHost;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Clean header
          _buildCleanHeader(),

          // MY CARDS SECTION - Always show for all participants
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
                      // Only Host can edit player cards
                      onTap: isHost ? () => _pickPlayerCard(1) : null,
                    ),
                    const SizedBox(width: 16),
                    _buildCard(
                      cardValue: _playerCard2,
                      // Only Host can edit player cards
                      onTap: isHost ? () => _pickPlayerCard(2) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // BOARD CARDS SECTION - Interactive ONLY for Host
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
                    // REACTIVE: Read from Firestore-synced boardCards
                    final boardCards = game.boardCards;
                    final hasCard = index < boardCards.length;
                    return Padding(
                      padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                      child: _buildCard(
                        isBoard: true,
                        cardValue: hasCard ? boardCards[index] : null,
                        // HOST-ONLY: Only Host can edit board cards
                        onTap: (isHost && hasCard)
                            ? () => _pickBoardCard(index, gameProvider)
                            : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // REVEAL BUTTONS - ONLY HOST
          if (isHost && game.boardCards.length < 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () => _revealNextPhase(gameProvider),
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    game.boardCards.isEmpty
                        ? 'Revelar Flop'
                        : game.boardCards.length == 3
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

          // RESOLVE & CANCEL BUTTONS - ONLY HOST
          if (isHost)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: game.boardCards.length == 5
                          ? () => _showManagerShowdownDialog(gameProvider, game)
                          : null,
                      icon: const Icon(Icons.emoji_events, size: 24),
                      label: const Text(
                        'RESOLVER VENCEDOR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: game.boardCards.length == 5
                            ? const Color(0xFF5A2D35)
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _cancelMatch(gameProvider),
                      icon: const Icon(Icons.cancel_outlined, size: 24),
                      label: const Text(
                        'CANCELAR PARTIDA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== GUEST MULTIPLAYER MODE ====================
  Widget _buildGuestMultiplayerMode(
    GameProvider gameProvider,
    GameSession game,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Clean header
          _buildCleanHeader(),

          // MY CARDS SECTION - INTERACTIVE
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

          // BOARD CARDS SECTION - READ-ONLY FOR GUEST
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
                    // REACTIVE: Read from Firestore-synced boardCards
                    final boardCards = game.boardCards;
                    final hasCard = index < boardCards.length;
                    return Padding(
                      padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                      child: _buildCard(
                        isBoard: true,
                        cardValue: hasCard ? boardCards[index] : null,
                        onTap: null, // READ-ONLY - no tap
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // WAITING MESSAGE - GUEST
          Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: AppColors.primary.withValues(alpha: 0.7),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.hourglass_empty,
                      color: AppColors.gold,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aguardando o Host...',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.gold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O Host controlará a revelação das cartas da mesa.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // SAFE EXIT BUTTON - GUEST ONLY
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showGuestExitConfirmation(context),
                icon: const Icon(Icons.exit_to_app, size: 20),
                label: const Text('SAIR SEM SALVAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildCleanHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkGrey, AppColors.cardBackground],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Text(
          'Jogo em Andamento',
          style: AppTextStyles.heading3.copyWith(color: AppColors.gold),
        ),
      ),
    );
  }

  /// Build card widget for player hand input dialogs
  Widget _buildCardForDialog(String? cardValue) {
    final displayCard = cardValue != null && cardValue != '??';
    late final String suitSymbol;
    late final String rank;
    late final Color suitColor;

    if (displayCard) {
      suitSymbol = CardHelper.getSuitSymbol(cardValue);
      rank = CardHelper.getRank(cardValue);
      suitColor = Color(CardHelper.getSuitColor(cardValue));
    } else {
      suitSymbol = '?';
      rank = '?';
      suitColor = Colors.grey;
    }

    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: displayCard ? Colors.white : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: displayCard ? suitColor : Colors.grey[600]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Text(
                  rank,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: displayCard ? suitColor : Colors.grey,
                  ),
                ),
                Text(
                  suitSymbol,
                  style: TextStyle(
                    fontSize: 16,
                    color: displayCard ? suitColor : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Text(
                  suitSymbol,
                  style: TextStyle(
                    fontSize: 16,
                    color: displayCard ? suitColor : Colors.grey,
                  ),
                ),
                Text(
                  rank,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: displayCard ? suitColor : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    bool isBoard = false,
    String? cardValue,
    VoidCallback? onTap,
  }) {
    final displayCard = cardValue != null && cardValue != '??';
    late final String suitSymbol;
    late final String rank;
    late final Color suitColor;

    if (displayCard) {
      suitSymbol = CardHelper.getSuitSymbol(cardValue);
      rank = CardHelper.getRank(cardValue);
      suitColor = Color(CardHelper.getSuitColor(cardValue));
    } else {
      suitSymbol = '?';
      rank = '?';
      suitColor = Colors.grey;
    }

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

  // ==================== CARD PICKING ====================

  Future<void> _pickPlayerCard(int cardIndex) async {
    final card = await CardPickerSheet.show(context);
    if (card == null) return;

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final boardCards = gameProvider.currentGame?.boardCards ?? [];

    if (_isCardUsed(card, boardCards)) {
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
  }

  Future<void> _pickBoardCard(int index, GameProvider gameProvider) async {
    final card = await CardPickerSheet.show(context);
    if (card == null) return;

    final game = gameProvider.currentGame;
    if (game == null) return;

    if (_isCardUsed(card, game.boardCards)) {
      _showDuplicateCardSnack();
      return;
    }

    // CRITICAL: Update Firestore, not local state - this syncs to all devices
    final updatedCards = List<String>.from(game.boardCards);
    if (index < updatedCards.length) {
      updatedCards[index] = card;
    }
    await gameProvider.updateBoardCards(updatedCards);
  }

  bool _isCardUsed(String card, List<String> boardCards) {
    final selected = <String?>[
      _playerCard1,
      _playerCard2,
      ...boardCards.map((c) => c as String?),
    ];
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

  Future<void> _revealNextPhase(GameProvider gameProvider) async {
    final game = gameProvider.currentGame;
    if (game == null) return;

    // Only host can reveal phases
    if (!gameProvider.isHost) return;

    final currentCount = game.boardCards.length;
    int newCount;

    if (currentCount == 0) {
      newCount = 3; // Flop
    } else if (currentCount == 3) {
      newCount = 4; // Turn
    } else if (currentCount == 4) {
      newCount = 5; // River
    } else {
      return; // Already at max
    }

    // CRITICAL: Sync to Firestore - adds placeholder cards that Host can edit
    final updatedCards = List<String>.from(game.boardCards);
    while (updatedCards.length < newCount) {
      updatedCards.add('??'); // Placeholder until Host picks actual card
    }
    await gameProvider.updateBoardCards(updatedCards);
  }

  // ==================== SHOWDOWN DIALOGS ====================

  /// Simplified showdown - Host selects finalistas, auto-evaluates winner from cards in Firestore
  Future<void> _showManagerShowdownDialog(
    GameProvider gameProvider,
    GameSession game,
  ) async {
    // Validate board cards are complete (from Firestore sync)
    if (game.boardCards.length != 5) {
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

    if (game.activePlayers.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pelo menos 2 jogadores precisam estar na mesa.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Step 1: Host selects which players are in the showdown (finalistas)
    final selectedPlayerIds = await _selectPlayersForShowdown(game);
    if (selectedPlayerIds == null || selectedPlayerIds.isEmpty) return;

    final playerHands = <String, List<String>>{};

    // Step 2: Get player hands (from Firestore or ask for them)
    // For now, we'll ask for hands - in future this could come from participants storage
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

      // Validate no duplicate cards
      final allCards = <String>[
        ...game.boardCards,
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

    // Step 3: Auto-evaluate winner using poker logic
    final hands = playerHands.entries.map((e) {
      final player = game.players.firstWhere((p) => p.userId == e.key);
      return PokerPlayerHand(name: player.username, cards: e.value);
    }).toList();

    final result = _pokerLogicService.evaluateShowdown(
      players: hands,
      boardCards: game.boardCards,
    );

    final winnerName = result.winner.player.name;
    final winningHandType = result.winner.translatedType;

    // Find winner's user ID
    String? winnerUserId;
    for (final entry in playerHands.entries) {
      final player = game.players.firstWhere((p) => p.userId == entry.key);
      if (player.username == winnerName) {
        winnerUserId = entry.key;
        break;
      }
    }

    // Step 4: Record match result with XP distribution
    if (winnerUserId != null) {
      await gameProvider.endGameWithFirebase(
        winnerId: winnerUserId,
        winningHandType: winningHandType,
      );
    }

    // Step 5: Show match summary overlay (automatically triggered by provider listener)
    // The overlay is shown automatically when GameProvider emits matchResult change
  }

  /// Alternative simpler flow for future: Cancel Match without resolving winner
  Future<void> _cancelMatch(GameProvider gameProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Cancelar Partida'),
          ],
        ),
        content: const Text(
          'Tem certeza que deseja cancelar esta partida?\n\n'
          'Nenhum XP será distribuído e a partida será encerrada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar Jogando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancelar Partida'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Set session status to finished without recording XP results
      await gameProvider.cancelGameWithoutWinner();

      if (mounted) {
        HapticFeedback.mediumImpact();
        // Return to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  // ==================== HELPER DIALOGS ====================

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

  Future<void> _showGameOverDialog(GameProvider gameProvider) async {
    final game = gameProvider.currentGame;
    if (game == null) return;

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

  Future<void> _finishGameAndAwardXP(
    GameProvider gameProvider,
    String winnerId,
  ) async {
    final game = gameProvider.currentGame;
    if (game == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // CRITICAL FIX: Use endGameWithFirebase for atomic batch XP distribution
    // This ensures all players get XP even if one device goes offline
    // For Manager Mode, winningHandType is not evaluated - use placeholder
    await gameProvider.endGameWithFirebase(
      winnerId: winnerId,
      winningHandType: 'Manager Game',
    );

    // CRITICAL: Refresh current user's data AFTER Firestore write completes
    // This ensures UI shows updated XP/wins/matches with proper Firebase latency handling
    await userProvider.refreshUser();

    if (mounted) {
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

  Future<void> _showGuestExitConfirmation(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Sair do Jogo'),
        content: const Text(
          'Se você sair agora, seus dados de XP e partida não serão salvos.\n\nDeseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Leave without saving stats
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
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

  /// Display match summary overlay with results
  Future<void> _showMatchSummaryOverlay(
    BuildContext context,
    GameProvider gameProvider,
    MatchResult matchResult,
  ) async {
    if (!mounted) return;

    // Convert match result to participant results for overlay
    final participantResults = matchResult.participantResults.entries.map((e) {
      final xpResult = e.value;
      return ParticipantResult(
        username: xpResult.username,
        previousXP: xpResult.previousXP,
        currentXP: xpResult.currentXP,
        isWinner: e.key == matchResult.winnerUserId,
      );
    }).toList();

    // Sort: winner first, then others
    participantResults.sort((a, b) {
      if (a.isWinner) return -1;
      if (b.isWinner) return 1;
      return 0;
    });

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MatchSummaryOverlay(
          winnerUsername: matchResult.winnerUsername,
          winningHandType: matchResult.winningHandType,
          participantResults: participantResults,
          isHost: gameProvider.isHost,
          onDismiss: () {
            gameProvider.clearMatchResult();
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );

    if (result == true && mounted) {
      // Return to home
      await gameProvider.leaveSession();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }
}
