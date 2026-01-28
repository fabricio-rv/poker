import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/firestore_service.dart';
import '../models/game_session.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'game_screen.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({Key? key}) : super(key: key);

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int _currentStep = 0;
  List<User> _allUsers = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final firestoreService = FirestoreService();
    // Subscribe to rankings to get all users
    firestoreService.getRankings().listen((users) {
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Jogo')),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          return Column(
            children: [
              // Step indicator (3 steps)
              _buildStepIndicator(),

              // Content based on current step
              Expanded(child: _buildStepContent(gameProvider)),

              // Navigation buttons
              _buildNavigationButtons(gameProvider),
            ],
          );
        },
      ),
    );
  }

  // ==================== STEP INDICATOR ====================
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.darkGrey,
      child: Row(
        children: [
          _buildStepDot(0, 'Modo'),
          _buildStepLine(0),
          _buildStepDot(1, 'Jogadores'),
          _buildStepLine(1),
          _buildStepDot(2, 'Fichas'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primary : AppColors.darkGrey,
              border: Border.all(
                color: isCurrent ? AppColors.gold : Colors.grey,
                width: isCurrent ? 3 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isCurrent ? AppColors.gold : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Container(
        height: 2,
        color: isActive ? AppColors.primary : Colors.grey,
      ),
    );
  }

  // ==================== STEP CONTENT ====================
  Widget _buildStepContent(GameProvider gameProvider) {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentStep) {
      case 0:
        return _buildModoStep(gameProvider);
      case 1:
        return _buildJogadoresStep(gameProvider);
      case 2:
        return _buildFichasStep(gameProvider);
      default:
        return const Center(child: Text('Passo inválido'));
    }
  }

  // ==================== STEP 1: MODO ====================
  Widget _buildModoStep(GameProvider gameProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.gamepad, size: 80, color: AppColors.gold),
          const SizedBox(height: 24),
          Text(
            'Escolha o Modo de Jogo',
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Multiplayer option
                _buildModoCard(
                  title: 'Multiplayer',
                  subtitle:
                      'Cada jogador vê suas cartas\nHost controla o board',
                  icon: Icons.people,
                  isSelected: gameProvider.selectedMode == GameMode.multiplayer,
                  onTap: () => gameProvider.selectMode(GameMode.multiplayer),
                ),
                const SizedBox(height: 16),
                // Manager option
                _buildModoCard(
                  title: 'Gerenciador',
                  subtitle: 'Modo Juiz\nVocê controla tudo',
                  icon: Icons.gavel,
                  isSelected: gameProvider.selectedMode == GameMode.manager,
                  onTap: () => gameProvider.selectMode(GameMode.manager),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? AppColors.gold : Colors.grey,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.heading3.copyWith(
                      color: isSelected ? AppColors.gold : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.gold, size: 32),
          ],
        ),
      ),
    );
  }

  // ==================== STEP 2: JOGADORES ====================
  Widget _buildJogadoresStep(GameProvider gameProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selecione os Jogadores', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Text(
                'Mínimo 2 jogadores',
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _allUsers.length,
            itemBuilder: (context, index) {
              final user = _allUsers[index];
              final isSelected = gameProvider.isPlayerSelected(user);

              return Card(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.cardBackground,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? AppColors.gold
                        : AppColors.primary,
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.username,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      gameProvider.togglePlayerSelection(user);
                    },
                    activeColor: AppColors.gold,
                  ),
                  onTap: () {
                    gameProvider.togglePlayerSelection(user);
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            gameProvider.selectedPlayers.isEmpty
                ? 'Nenhum jogador selecionado'
                : 'Você (Host) + ${gameProvider.selectedPlayers.length} jogador(es) = ${gameProvider.selectedPlayers.length + 1} total',
            style: AppTextStyles.bodyLarge.copyWith(
              color: gameProvider.selectedPlayers.length >= 2
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== STEP 3: FICHAS (RESTORED UI) ====================
  Widget _buildFichasStep(GameProvider gameProvider) {
    if (gameProvider.selectedPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 64, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              'Selecione pelo menos 1 jogador',
              style: AppTextStyles.heading3,
            ),
          ],
        ),
      );
    }

    // Distribuição de fichas (inclui Host + jogadores selecionados)
    final playerCount =
        gameProvider.selectedPlayers.length + 1; // +1 para o Host
    final totalChipsPerPlayer = 200;
    final chipsPerPlayer = totalChipsPerPlayer ~/ playerCount;

    // Calculate chip distribution with proper ratios
    final distribution = _calculateChipDistribution(chipsPerPlayer);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main card with wine/maroon background and gold header
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF5A2D35), // Wine/Maroon color
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and text
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.gold,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Entregue para cada jogador:',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Chip distribution rows
                    _buildChipDistributionRow(
                      'Brancas',
                      distribution['white']!,
                      const Color(0xFFF5F5F5), // White
                    ),
                    const SizedBox(height: 12),
                    _buildChipDistributionRow(
                      'Vermelhas',
                      distribution['red']!,
                      const Color(0xFFD32F2F), // Red
                    ),
                    const SizedBox(height: 12),
                    _buildChipDistributionRow(
                      'Verdes',
                      distribution['green']!,
                      const Color(0xFF388E3C), // Green
                    ),
                    const SizedBox(height: 12),
                    _buildChipDistributionRow(
                      'Azuis',
                      distribution['blue']!,
                      const Color(0xFF1976D2), // Blue
                    ),
                    const SizedBox(height: 12),
                    _buildChipDistributionRow(
                      'Pretas',
                      distribution['black']!,
                      const Color(0xFF424242), // Black/Dark
                    ),

                    const SizedBox(height: 16),

                    // Divider
                    Divider(color: AppColors.gold.withOpacity(0.3), height: 1),

                    const SizedBox(height: 12),

                    // Total row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total por jogador:',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${distribution.values.reduce((a, b) => a + b)} fichas',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Build a single row for chip distribution
  /// Format: CircleAvatar(color) + Text("Brancas ($1)") + Spacer + Text("25", bold Yellow)
  Widget _buildChipDistributionRow(String colorName, int count, Color color) {
    return Row(
      children: [
        // Circle avatar with color
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Color name text
        Expanded(
          child: Text(
            colorName,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
        // Chip count (bold, yellow)
        Text(
          '$count',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Calculate chip distribution with proper ratios
  /// Ratio: 30% White, 30% Red, 20% Green, 10% Blue, 10% Black
  /// Example: 100 chips = 30 White, 30 Red, 20 Green, 10 Blue, 10 Black
  Map<String, int> _calculateChipDistribution(int totalChips) {
    int white = (totalChips * 0.30).round();
    int red = (totalChips * 0.30).round();
    int green = (totalChips * 0.20).round();
    int blue = (totalChips * 0.10).round();
    int black = (totalChips * 0.10).round();

    // Adjust for rounding errors to ensure total = totalChips
    final sum = white + red + green + blue + black;
    final difference = totalChips - sum;

    if (difference != 0) {
      black += difference;
    }

    return {
      'white': white,
      'red': red,
      'green': green,
      'blue': blue,
      'black': black,
    };
  }

  // ==================== NAVIGATION BUTTONS ====================
  Widget _buildNavigationButtons(GameProvider gameProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _currentStep--);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else
              const Expanded(child: SizedBox.shrink()),
            if (_currentStep > 0) const SizedBox(width: 12),
            // Next/Start button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _canProceedToNextStep(gameProvider)
                    ? () => _proceedToNextStep(gameProvider)
                    : null,
                icon: Icon(
                  _currentStep == 2 ? Icons.play_arrow : Icons.arrow_forward,
                ),
                label: Text(
                  _currentStep == 2 ? 'Começar Jogo' : 'Próximo',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == 2
                      ? const Color(0xFF8B2635) // Wine/Red for start button
                      : AppColors.primary,
                  disabledBackgroundColor: AppColors.darkGrey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceedToNextStep(GameProvider gameProvider) {
    switch (_currentStep) {
      case 0:
        return gameProvider.selectedMode != null;
      case 1:
        return gameProvider.selectedPlayers.length >= 2;
      case 2:
        return true; // Always can start if we reach step 3
      default:
        return false;
    }
  }

  Future<void> _proceedToNextStep(GameProvider gameProvider) async {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Start the game
      await _startGame(gameProvider);
    }
  }

  Future<void> _startGame(GameProvider gameProvider) async {
    try {
      // Calculate chips based on selected players
      gameProvider.calculateChips();

      // Start the game session
      await gameProvider.startGame();

      // Navigate to game screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GameScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao iniciar jogo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
