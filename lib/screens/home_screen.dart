import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import '../widgets/xp_progress_widget.dart';
import 'ranking_screen.dart';
import 'profile_screen.dart';
import 'game_setup_screen.dart';
import 'debug_poker_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Laboratório de Testes',
            icon: const Icon(Icons.bug_report, size: 20),
            color: Colors.white70,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DebugPokerScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;

          if (user == null) {
            return const Center(child: Text('Erro: Usuário não encontrado'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with greeting
                Text('Olá, ${user.username}!', style: AppTextStyles.heading1),
                const SizedBox(height: 24),

                // XP Progress Card
                XPProgressWidget(user: user),
                const SizedBox(height: 32),

                // Menu Cards
                _buildMenuCard(
                  context,
                  title: 'INICIAR JOGO',
                  icon: Icons.play_circle_filled,
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GameSetupScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildMenuCard(
                  context,
                  title: 'RANKING',
                  icon: Icons.emoji_events,
                  color: AppColors.gold,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RankingScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildMenuCard(
                  context,
                  title: 'PERFIL & CONQUISTAS',
                  icon: Icons.person,
                  color: AppColors.darkGrey,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 48, color: AppColors.white),
              const SizedBox(width: 24),
              Expanded(child: Text(title, style: AppTextStyles.heading2)),
              const Icon(Icons.arrow_forward_ios, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}
