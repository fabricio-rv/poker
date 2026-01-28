import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/xp_progress_widget.dart';
import '../services/firestore_service.dart';
import '../models/game_session.dart';
import 'ranking_screen.dart';
import 'profile_screen.dart';
import 'game_setup_screen.dart';
import 'game_screen.dart';
import 'debug_poker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<GameSession>>? _sessionsSubscription;

  @override
  void initState() {
    super.initState();
    _setupAutoJoinListener();
  }

  /// Set up real-time listener for available sessions
  /// Auto-joins user to a game when they become a participant
  void _setupAutoJoinListener() {
    _sessionsSubscription = _firestoreService.getAvailableSessions().listen((
      sessions,
    ) {
      if (!mounted) return;

      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.currentUser?.id;

      if (currentUserId == null) return;

      // Check if current user is a participant in any waiting session
      for (final session in sessions) {
        final isParticipant = session.players.any(
          (player) => player.userId == currentUserId,
        );

        if (isParticipant && gameProvider.currentGame == null) {
          // Auto-navigate to game screen
          _autoJoinGame(session.id);
          break;
        }
      }
    });
  }

  /// Auto-join game when invited
  Future<void> _autoJoinGame(String sessionId) async {
    if (!mounted) return;

    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    try {
      // Join the session in the provider
      await gameProvider.joinSession(sessionId);

      if (mounted) {
        // Navigate to game screen
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const GameScreen()));
      }
    } catch (e) {
      print('Error auto-joining game: $e');
    }
  }

  @override
  void dispose() {
    _sessionsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos watch para que a tela reconstrua sempre que o estado do UserProvider mudar
    final userProvider = context.watch<UserProvider>();

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
      body: _buildBody(context, userProvider),
    );
  }

  Widget _buildBody(BuildContext context, UserProvider userProvider) {
    final user = userProvider.currentUser;

    // 1. ESTADO DE CARREGAMENTO: Evita mostrar erro enquanto o Firebase busca os dados
    if (userProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // 2. TRATAMENTO DE ERRO: Caso o documento realmente não exista no Firestore
    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Perfil não encontrado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Houve um atraso na sincronização com o banco de dados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => userProvider.refreshUser(),
                child: const Text('TENTAR NOVAMENTE'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. LAYOUT PRINCIPAL: Exibido apenas quando o usuário é carregado com sucesso
    return RefreshIndicator(
      onRefresh: () => userProvider.refreshUser(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: O campo corrigido é user.name (ou o campo que você definiu no Model)
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
                  MaterialPageRoute(builder: (_) => const GameSetupScreen()),
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 48, color: AppColors.white),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
