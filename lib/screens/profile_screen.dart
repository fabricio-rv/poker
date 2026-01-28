import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
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
                // Avatar and name
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: AppTextStyles.heading1.copyWith(fontSize: 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(user.username, style: AppTextStyles.heading1),
                      const SizedBox(height: 8),
                      Text(
                        'Nível ${user.level}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Vitórias',
                        user.totalWins.toString(),
                        Icons.emoji_events,
                        AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Partidas',
                        user.totalMatches.toString(),
                        Icons.casino,
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'XP Total',
                        user.currentXP.toString(),
                        Icons.star,
                        AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Taxa de Vitória',
                        '${user.winRate.toStringAsFixed(1)}%',
                        Icons.trending_up,
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildStatCard(
                  'Pontuação Geral',
                  user.rankingScore.toString(),
                  Icons.emoji_events,
                  AppColors.gold,
                ),
                const SizedBox(height: 32),

                // Additional info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informações', style: AppTextStyles.heading3),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Entrou em',
                          DateFormat('dd/MM/yyyy').format(user.joinDate),
                        ),
                        const Divider(),
                        _buildInfoRow('Nível Atual', user.level.toString()),
                        const Divider(),
                        _buildInfoRow(
                          'XP até próximo nível',
                          '${1000 - (user.currentXP % 1000)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar Perfil'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sair da Conta'),
                        content: const Text('Tem certeza que deseja sair?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sair'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await userProvider.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da Conta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.heading2.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
