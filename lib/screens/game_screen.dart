import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../models/game_session.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (gameProvider.isGameActive) {
        gameProvider.incrementTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final confirm = await _showCancelConfirmation();
        return confirm ?? false;
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
                _showWinnerSelection(gameProvider);
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
        // Timer and Blinds header
        _buildGameHeader(gameProvider),

        // Players list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: game.players.length,
            itemBuilder: (context, index) {
              final player = game.players[index];

              return Card(
                color: player.isEliminated
                    ? AppColors.darkGrey.withOpacity(0.5)
                    : AppColors.cardBackground,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
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
                          },
                          icon: const Icon(Icons.replay, size: 16),
                          label: const Text('Rebuy'),
                          style: OutlinedButton.styleFrom(
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
                            _confirmElimination(gameProvider, player.userId);
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
                    _buildCard(),
                    const SizedBox(width: 16),
                    _buildCard(),
                  ],
                ),
              ],
            ),
          ),

          // Win probability
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Probabilidade de Vitória',
                          style: AppTextStyles.bodyLarge,
                        ),
                        Text(
                          '${gameProvider.winProbability.toStringAsFixed(1)}%',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: gameProvider.winProbability / 100,
                        minHeight: 20,
                        backgroundColor: AppColors.darkGrey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProbabilityColor(gameProvider.winProbability),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                  children: [
                    _buildCard(isBoard: true),
                    const SizedBox(width: 8),
                    _buildCard(isBoard: true),
                    const SizedBox(width: 8),
                    _buildCard(isBoard: true),
                    const SizedBox(width: 8),
                    _buildCard(isBoard: true),
                    const SizedBox(width: 8),
                    _buildCard(isBoard: true),
                  ],
                ),
              ],
            ),
          ),

          // Mock update button
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: () {
                gameProvider.mockCalculateOdds();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar Probabilidades'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHeader(GameProvider gameProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.darkGrey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Timer
          Column(
            children: [
              const Icon(Icons.timer, color: AppColors.gold, size: 32),
              const SizedBox(height: 8),
              Text(
                gameProvider.formattedTime,
                style: AppTextStyles.heading2.copyWith(color: AppColors.gold),
              ),
              Text('Tempo', style: AppTextStyles.caption),
            ],
          ),

          // Blinds
          Column(
            children: [
              const Icon(Icons.attach_money, color: AppColors.gold, size: 32),
              const SizedBox(height: 8),
              Text(
                '${gameProvider.currentSmallBlind}/${gameProvider.currentBigBlind}',
                style: AppTextStyles.heading2.copyWith(color: AppColors.gold),
              ),
              Text('Blinds', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({bool isBoard = false}) {
    return Container(
      width: isBoard ? 50 : 80,
      height: isBoard ? 70 : 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkGrey, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.question_mark,
          size: isBoard ? 24 : 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Color _getProbabilityColor(double probability) {
    if (probability >= 70) return AppColors.success;
    if (probability >= 40) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _confirmElimination(
    GameProvider gameProvider,
    String userId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminação'),
        content: const Text('Tem certeza que deseja eliminar este jogador?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await gameProvider.eliminatePlayer(userId);
    }
  }

  Future<void> _showWinnerSelection(GameProvider gameProvider) async {
    final game = gameProvider.currentGame;
    if (game == null) return;

    final winner = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Fim de Jogo!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: AppColors.gold, size: 64),
            const SizedBox(height: 16),
            const Text('Quem venceu?', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            ...game.players.map((player) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(player.username[0].toUpperCase()),
                ),
                title: Text(player.username),
                onTap: () => Navigator.pop(context, player.userId),
              );
            }).toList(),
          ],
        ),
      ),
    );

    if (winner != null && mounted) {
      await gameProvider.finishGame(winner);

      // Award XP to all players
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      for (final player in game.players) {
        final isWinner = player.userId == winner;
        // This is a simplified version - in production you'd update all users
        if (player.userId == userProvider.currentUser?.id) {
          await userProvider.recordMatch(isWinner);
        }
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jogo finalizado! XP atualizado.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
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
