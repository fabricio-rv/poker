import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/auth_service.dart';
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
  final _buyInController = TextEditingController();
  List<User> _allUsers = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _buyInController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final authService = AuthService();
    final users = await authService.getAllUsers();
    setState(() {
      _allUsers = users;
      _isLoadingUsers = false;
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
              // Step indicator
              _buildStepIndicator(),

              // Content
              Expanded(child: _buildStepContent(gameProvider)),

              // Navigation buttons
              _buildNavigationButtons(gameProvider),
            ],
          );
        },
      ),
    );
  }

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
          _buildStepDot(2, 'Aposta'),
          _buildStepLine(2),
          _buildStepDot(3, 'Fichas'),
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
                  color: isActive ? AppColors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.white : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppColors.primary : Colors.grey,
      ),
    );
  }

  Widget _buildStepContent(GameProvider gameProvider) {
    if (_isLoadingUsers && _currentStep == 1) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentStep) {
      case 0:
        return _buildModeSelection(gameProvider);
      case 1:
        return _buildPlayerSelection(gameProvider);
      case 2:
        return _buildBetConfiguration(gameProvider);
      case 3:
        return _buildChipCalculation(gameProvider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildModeSelection(GameProvider gameProvider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Selecione o Modo de Jogo', style: AppTextStyles.heading2),
          const SizedBox(height: 24),

          _buildModeCard(
            gameProvider,
            GameMode.multiplayer,
            'Multiplayer',
            'Cada um no seu celular',
            Icons.smartphone,
            'Cada jogador acompanha suas cartas e probabilidades em tempo real.',
          ),
          const SizedBox(height: 16),

          _buildModeCard(
            gameProvider,
            GameMode.manager,
            'Gerenciador',
            'Apenas um celular',
            Icons.manage_accounts,
            'Controle blinds, eliminações e rebuys em um único dispositivo.',
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    GameProvider gameProvider,
    GameMode mode,
    String title,
    String subtitle,
    IconData icon,
    String description,
  ) {
    final isSelected = gameProvider.selectedMode == mode;

    return Card(
      color: isSelected ? AppColors.primary : AppColors.cardBackground,
      child: InkWell(
        onTap: () => gameProvider.selectMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: isSelected ? AppColors.gold : AppColors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.heading3),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.gold,
                      size: 32,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSelection(GameProvider gameProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quem vai jogar?', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Text(
                'Selecione no mínimo 2 jogadores',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _allUsers.length,
            itemBuilder: (context, index) {
              final user = _allUsers[index];
              final isSelected = gameProvider.isPlayerSelected(user);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    gameProvider.togglePlayerSelection(user);
                  },
                  title: Text(user.username, style: AppTextStyles.heading3),
                  subtitle: Text(
                    'Nível ${user.level} • ${user.totalWins} vitórias',
                    style: AppTextStyles.caption,
                  ),
                  secondary: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                  activeColor: AppColors.gold,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBetConfiguration(GameProvider gameProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Aposta em Dinheiro?', style: AppTextStyles.heading2),
          const SizedBox(height: 24),

          SwitchListTile(
            value: gameProvider.hasMoneyBet,
            onChanged: (value) => gameProvider.setMoneyBet(value),
            title: Text(
              gameProvider.hasMoneyBet
                  ? 'Sim, vamos apostar dinheiro'
                  : 'Não, apenas por diversão',
              style: AppTextStyles.heading3,
            ),
            activeColor: AppColors.gold,
            secondary: Icon(
              gameProvider.hasMoneyBet
                  ? Icons.attach_money
                  : Icons.sports_esports,
              color: AppColors.primary,
              size: 32,
            ),
          ),

          if (gameProvider.hasMoneyBet) ...[
            const SizedBox(height: 24),
            Text('Valor do Buy-in', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _buyInController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Valor em R\$',
                prefixText: 'R\$ ',
                hintText: '50.00',
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                gameProvider.setBuyInAmount(amount);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChipCalculation(GameProvider gameProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Distribuição de Fichas', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            'Total de ${gameProvider.selectedPlayers.length} jogadores',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          if (gameProvider.calculatedChips == null)
            ElevatedButton.icon(
              onPressed: () => gameProvider.calculateChips(),
              icon: const Icon(Icons.calculate),
              label: const Text('Calcular Fichas'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            )
          else ...[
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Text(
                          'Entregue para cada jogador:',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildChipLine(
                      'Brancas (R\$ 1)',
                      gameProvider.calculatedChips!.whiteChips,
                      AppColors.chipWhite,
                    ),
                    _buildChipLine(
                      'Vermelhas (R\$ 5)',
                      gameProvider.calculatedChips!.redChips,
                      AppColors.chipRed,
                    ),
                    _buildChipLine(
                      'Verdes (R\$ 10)',
                      gameProvider.calculatedChips!.greenChips,
                      AppColors.chipGreen,
                    ),
                    _buildChipLine(
                      'Azuis (R\$ 25)',
                      gameProvider.calculatedChips!.blueChips,
                      AppColors.chipBlue,
                    ),
                    _buildChipLine(
                      'Pretas (R\$ 50)',
                      gameProvider.calculatedChips!.blackChips,
                      AppColors.chipBlack,
                    ),
                    const Divider(color: Colors.white38, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total por jogador:',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${gameProvider.calculatedChips!.totalChips} fichas',
                          style: AppTextStyles.bodyLarge.copyWith(
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
          ],
        ],
      ),
    );
  }

  Widget _buildChipLine(String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(
            '$count',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(GameProvider gameProvider) {
    final canProceed = _canProceedToNextStep(gameProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                child: const Text('Voltar'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canProceed
                  ? () async {
                      if (_currentStep < 3) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        // Start game
                        await gameProvider.startGame();
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GameScreen(),
                            ),
                          );
                        }
                      }
                    }
                  : null,
              child: Text(_currentStep == 3 ? 'Começar Jogo' : 'Próximo'),
            ),
          ),
        ],
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
        return true; // Can always proceed from bet config
      case 3:
        return gameProvider.calculatedChips != null;
      default:
        return false;
    }
  }
}
