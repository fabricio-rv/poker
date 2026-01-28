import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/card_picker_sheet.dart';
import '../services/poker_logic_service.dart';

class DebugPokerScreen extends StatefulWidget {
  const DebugPokerScreen({Key? key}) : super(key: key);

  @override
  State<DebugPokerScreen> createState() => _DebugPokerScreenState();
}

class _DebugPokerScreenState extends State<DebugPokerScreen> {
  final _playerACards = <String?>[null, null];
  final _playerBCards = <String?>[null, null];
  final _boardCards = <String?>[null, null, null, null, null];

  String _resultText = 'Selecione as cartas e clique em SIMULAR MÃO.';

  final _pokerService = PokerLogicService();

  bool get _allSelected {
    return _playerACards.every((c) => c != null) &&
        _playerBCards.every((c) => c != null) &&
        _boardCards.every((c) => c != null);
  }

  List<String> _selectedCards() {
    return [
      ..._playerACards.whereType<String>(),
      ..._playerBCards.whereType<String>(),
      ..._boardCards.whereType<String>(),
    ];
  }

  Future<void> _pickCard(List<String?> target, int index) async {
    final card = await CardPickerSheet.show(context);
    if (card == null) return;

    final selected = _selectedCards();
    if (selected.contains(card)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Essa carta já foi selecionada.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      target[index] = card;
    });
  }

  void _simulateHand() {
    if (!_allSelected) return;

    try {
      final result = _pokerService.evaluateShowdown(
        players: [
          PokerPlayerHand(
            name: 'Player A',
            cards: _playerACards.whereType<String>().toList(),
          ),
          PokerPlayerHand(
            name: 'Player B',
            cards: _playerBCards.whereType<String>().toList(),
          ),
        ],
        boardCards: _boardCards.whereType<String>().toList(),
      );

      setState(() {
        _resultText = _pokerService.getWinningExplanation(result: result);
      });
    } catch (e) {
      setState(() {
        _resultText = 'Erro ao simular: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laboratório de Testes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Player A',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _buildCardRow(
              _playerACards,
              (index) => _pickCard(_playerACards, index),
            ),
            const SizedBox(height: 24),
            Text(
              'Player B',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _buildCardRow(
              _playerBCards,
              (index) => _pickCard(_playerBCards, index),
            ),
            const SizedBox(height: 24),
            Text(
              'Mesa',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _buildBoardRow(
              _boardCards,
              (index) => _pickCard(_boardCards, index),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _allSelected ? _simulateHand : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
              ),
              child: const Text('SIMULAR MÃO'),
            ),
            const SizedBox(height: 24),
            Card(
              color: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _resultText,
                  style: AppTextStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRow(
    List<String?> cards,
    Future<void> Function(int index) onPick,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(cards.length, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index < cards.length - 1 ? 12 : 0),
          child: _buildCardSlot(cards[index], () => onPick(index)),
        );
      }),
    );
  }

  Widget _buildBoardRow(
    List<String?> cards,
    Future<void> Function(int index) onPick,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(cards.length, (index) {
        return _buildCardSlot(cards[index], () => onPick(index), isBoard: true);
      }),
    );
  }

  Widget _buildCardSlot(
    String? card,
    VoidCallback onTap, {
    bool isBoard = false,
  }) {
    final suitSymbol = card != null ? _getSuitSymbol(card) : '?';
    final rank = card != null ? card.substring(0, card.length - 1) : '?';
    final suitColor = card != null ? _getSuitColor(card) : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isBoard ? 50 : 80,
        height: isBoard ? 70 : 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: card == null
              ? Icon(Icons.add, color: AppColors.gold, size: isBoard ? 20 : 28)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rank.toUpperCase(),
                      style: TextStyle(
                        fontSize: isBoard ? 16 : 22,
                        fontWeight: FontWeight.bold,
                        color: suitColor,
                      ),
                    ),
                    Text(
                      suitSymbol,
                      style: TextStyle(
                        fontSize: isBoard ? 18 : 26,
                        color: suitColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _getSuitSymbol(String card) {
    final suit = card[card.length - 1];
    switch (suit) {
      case 'h':
        return '♥';
      case 'd':
        return '♦';
      case 'c':
        return '♣';
      case 's':
        return '♠';
      default:
        return '?';
    }
  }

  Color _getSuitColor(String card) {
    final suit = card[card.length - 1];
    return (suit == 'h' || suit == 'd') ? Colors.red : Colors.black;
  }
}
