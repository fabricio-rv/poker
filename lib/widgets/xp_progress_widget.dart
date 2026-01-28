import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class XPProgressWidget extends StatefulWidget {
  final User user;

  const XPProgressWidget({Key? key, required this.user}) : super(key: key);

  @override
  State<XPProgressWidget> createState() => _XPProgressWidgetState();
}

class _XPProgressWidgetState extends State<XPProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimation =
        Tween<double>(begin: 0.0, end: widget.user.progressToNextLevel).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(XPProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.currentXP != widget.user.currentXP) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.user.progressToNextLevel,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Level badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nível ${user.level}',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.currentXP} XP',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                // Circular level indicator
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '${user.level}',
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progresso para Nível ${user.level + 1}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      '${(user.progressToNextLevel * 100).toInt()}%',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progressAnimation.value,
                        minHeight: 12,
                        backgroundColor: AppColors.darkGrey,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.gold,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${user.currentXP - user.xpForCurrentLevel} / ${user.xpForNextLevel - user.xpForCurrentLevel} XP',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
