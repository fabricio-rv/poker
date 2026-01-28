import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../models/game_session.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

/// Tela principal do jogo em andamento
/// Implementa o Manager Mode com timer, blinds automáticos, eliminação, rebuys e dealer
class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
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
              const SizedBox(height: 8),
              // Botão de teste para forçar aumento de blinds (desenvolvimento)
              TextButton.icon(
                onPressed: () => gameProvider.increaseBlindsManually(),
                icon: const Icon(Icons.fast_forward, size: 16),
                label: const Text('Forçar Próximo Nível (Teste)'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
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
    final nextBlind = gameProvider.nextBlindLevel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkGrey, AppColors.cardBackground],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Timer (Countdown)
              Column(
                children: [
                  const Icon(Icons.timer, color: AppColors.gold, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    gameProvider.formattedTime,
                    style: AppTextStyles.heading2.copyWith(
                      color: gameProvider.remainingSeconds <= 60
                          ? AppColors
                                .error // Vermelho quando falta menos de 1 min
                          : AppColors.gold,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tempo Restante',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),

              // Blinds Atuais
              Column(
                children: [
                  const Icon(
                    Icons.attach_money,
                    color: AppColors.gold,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${gameProvider.currentSmallBlind}/${gameProvider.currentBigBlind}',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.gold,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Nível ${gameProvider.currentBlindLevel}',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          // Próximo Nível de Blinds
          if (nextBlind != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, thickness: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_upward, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Próximo: ${nextBlind['small']}/${nextBlind['big']}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              '⚠️ Nível Máximo Atingido',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
