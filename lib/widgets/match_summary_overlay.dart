import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Match Summary Overlay - Displays results before returning to home
/// Shows winner, winning hand, XP earnings for all participants
class MatchSummaryOverlay extends StatefulWidget {
  final String winnerUsername;
  final String winningHandType; // e.g., "Full House", "Flush"
  final List<ParticipantResult> participantResults;
  final bool isHost;
  final VoidCallback onDismiss;

  const MatchSummaryOverlay({
    Key? key,
    required this.winnerUsername,
    required this.winningHandType,
    required this.participantResults,
    required this.isHost,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<MatchSummaryOverlay> createState() => _MatchSummaryOverlayState();
}

/// Data class for participant XP results
class ParticipantResult {
  final String username;
  final int previousXP;
  final int currentXP;
  final bool isWinner;

  ParticipantResult({
    required this.username,
    required this.previousXP,
    required this.currentXP,
    required this.isWinner,
  });

  int get xpGained => currentXP - previousXP;
}

class _MatchSummaryOverlayState extends State<MatchSummaryOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Timer _autoCloseTimer;

  int _countdown = 10;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _confettiController.forward();

    // Auto-close timer for non-hosts (or after countdown for hosts)
    if (!widget.isHost) {
      _startAutoClose();
    } else {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _countdown--;
        });
        if (_countdown <= 0) {
          _autoCloseTimer.cancel();
          widget.onDismiss();
        }
      }
    });
  }

  void _startAutoClose() {
    _autoCloseTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    _autoCloseTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Confetti background (optional animation)
          if (true) ...[_buildConfettiLayer()],

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeController.drive(Tween(begin: 0.0, end: 1.0)),
              child: ScaleTransition(
                scale: _scaleController.drive(Tween(begin: 0.8, end: 1.0)),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy icon & title
                        _buildWinnerSection(),

                        const SizedBox(height: 32),

                        // Winning hand
                        _buildWinningHandSection(),

                        const SizedBox(height: 32),

                        // XP Results
                        _buildXPResultsSection(),

                        const SizedBox(height: 40),

                        // Action buttons
                        if (widget.isHost)
                          _buildHostButton()
                        else
                          _buildGuestAutoClose(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfettiLayer() {
    return Positioned.fill(
      child: ScaleTransition(
        scale: _confettiController.drive(Tween(begin: 1.0, end: 1.2)),
        child: CustomPaint(
          painter: ConfettiPainter(animation: _confettiController),
        ),
      ),
    );
  }

  Widget _buildWinnerSection() {
    final isCancelled = widget.winnerUsername == 'Partida Cancelada';

    return Column(
      children: [
        ScaleTransition(
          scale: _scaleController.drive(Tween(begin: 0.5, end: 1.0)),
          child: Icon(
            isCancelled ? Icons.cancel_outlined : Icons.emoji_events,
            color: isCancelled ? AppColors.warning : AppColors.gold,
            size: 80,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isCancelled ? 'Partida Cancelada' : 'Vencedor',
          style: AppTextStyles.heading2.copyWith(
            color: isCancelled ? AppColors.warning : AppColors.gold,
          ),
        ),
        if (!isCancelled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              border: Border.all(color: AppColors.gold, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.winnerUsername,
              style: AppTextStyles.heading3.copyWith(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWinningHandSection() {
    final isCancelled = widget.winnerUsername == 'Partida Cancelada';

    if (isCancelled) {
      return const SizedBox.shrink(); // Don't show winning hand for cancelled matches
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.gold, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Mão Vencedora',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.winningHandType,
            style: AppTextStyles.heading2.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildXPResultsSection() {
    final isCancelled = widget.winnerUsername == 'Partida Cancelada';

    if (isCancelled) {
      // For cancelled matches, show that no XP was awarded
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'A partida foi cancelada',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum XP foi distribuído aos participantes.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resultado da Partida',
            style: AppTextStyles.heading3.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 16),
          ...widget.participantResults.map(
            (result) => _buildParticipantXPRow(result),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantXPRow(ParticipantResult result) {
    final isWinner = result.isWinner;
    final xpGained = result.xpGained;
    final xpColor = isWinner ? AppColors.success : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isWinner ? AppColors.gold : Colors.transparent,
          width: isWinner ? 1 : 0,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Winner badge
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.star, color: AppColors.gold, size: 20),
            ),

          // Username
          Expanded(
            flex: 2,
            child: Text(
              result.username,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          // XP progression
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${result.previousXP}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 14, color: xpColor),
                    const SizedBox(width: 8),
                    Text(
                      '${result.currentXP}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '+$xpGained XP',
                  style: AppTextStyles.caption.copyWith(
                    color: xpColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onDismiss,
            icon: const Icon(Icons.home, size: 24),
            label: Text(
              'Voltar para Home ($_countdown)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestAutoClose() {
    return Center(
      child: Text(
        'Redirecionando para Home em 8 segundos...',
        style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Simple confetti painter for celebration effect
class ConfettiPainter extends CustomPainter {
  final Animation<double> animation;

  ConfettiPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final colors = [
      AppColors.gold,
      AppColors.success,
      AppColors.primary,
      Colors.red,
      Colors.purple,
    ];

    // Draw simple confetti particles
    final random = DateTime.now().microsecond % 1000;
    for (int i = 0; i < 50; i++) {
      final x =
          (size.width * (i % 10) / 10) +
          (random * 2 % (size.width / 10)).toDouble();
      final y = (size.height * animation.value) - (random * i % size.height);

      paint.color = colors[i % colors.length].withOpacity(0.6);

      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
