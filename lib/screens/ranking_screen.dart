import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ranking_provider.dart';
import '../utils/constants.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<RankingProvider>(context, listen: false).loadRankings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: Consumer<RankingProvider>(
        builder: (context, rankingProvider, child) {
          if (rankingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Category tabs
              Container(
                color: AppColors.darkGrey,
                child: Row(
                  children: [
                    _buildTab(
                      context,
                      rankingProvider,
                      RankingCategory.overall,
                      'Geral',
                    ),
                    _buildTab(
                      context,
                      rankingProvider,
                      RankingCategory.wins,
                      'Vitórias',
                    ),
                    _buildTab(
                      context,
                      rankingProvider,
                      RankingCategory.xp,
                      'XP',
                    ),
                    _buildTab(
                      context,
                      rankingProvider,
                      RankingCategory.matches,
                      'Partidas',
                    ),
                  ],
                ),
              ),

              // Rankings list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rankingProvider.getTopUsers(5).length,
                  itemBuilder: (context, index) {
                    final user = rankingProvider.getTopUsers(5)[index];
                    final position = index + 1;
                    final value = rankingProvider.getCategoryValue(
                      user,
                      rankingProvider.currentCategory,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: _buildPositionBadge(position),
                        title: Text(
                          user.username,
                          style: AppTextStyles.heading3,
                        ),
                        subtitle: Text(
                          'Nível ${user.level}',
                          style: AppTextStyles.caption,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              value.toString(),
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.gold,
                              ),
                            ),
                            Text(
                              _getCategoryLabel(
                                rankingProvider.currentCategory,
                              ),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    RankingProvider provider,
    RankingCategory category,
    String label,
  ) {
    final isSelected = provider.currentCategory == category;

    return Expanded(
      child: InkWell(
        onTap: () => provider.changeCategory(category),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.gold : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? AppColors.gold : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildPositionBadge(int position) {
    Color badgeColor;
    IconData? icon;

    if (position == 1) {
      badgeColor = AppColors.gold;
      icon = Icons.emoji_events;
    } else if (position == 2) {
      badgeColor = Colors.grey;
    } else if (position == 3) {
      badgeColor = Colors.brown;
    } else {
      badgeColor = AppColors.darkGrey;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
      child: Center(
        child: icon != null
            ? Icon(icon, color: AppColors.white, size: 28)
            : Text('$position', style: AppTextStyles.heading3),
      ),
    );
  }

  String _getCategoryLabel(RankingCategory category) {
    switch (category) {
      case RankingCategory.overall:
        return 'pontos';
      case RankingCategory.wins:
        return 'vitórias';
      case RankingCategory.xp:
        return 'XP';
      case RankingCategory.matches:
        return 'partidas';
    }
  }
}
