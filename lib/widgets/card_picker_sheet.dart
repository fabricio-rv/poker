import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget para seleção de cartas de baralho
/// Retorna uma string no formato "Ah" (Ás de Copas), "Ks" (Rei de Espadas), etc.
class CardPickerSheet {
  static Future<String?> show(BuildContext context) async {
    // Primeiro, seleciona o naipe
    final suit = await _showSuitPicker(context);
    if (suit == null) return null;

    // Depois, seleciona o valor da carta
    final rank = await _showRankPicker(context, suit);
    if (rank == null) return null;

    // Retorna no formato "Ah", "Ks", etc.
    return '$rank$suit';
  }

  static Future<String?> _showSuitPicker(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecione o Naipe', style: AppTextStyles.heading2),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2,
              children: [
                _buildSuitButton(context, '♥', 'h', Colors.red),
                _buildSuitButton(context, '♦', 'd', Colors.red),
                _buildSuitButton(context, '♣', 'c', Colors.black),
                _buildSuitButton(context, '♠', 's', Colors.black),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _buildSuitButton(
    BuildContext context,
    String symbol,
    String code,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context, code),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 2),
        ),
      ),
      child: Text(symbol, style: TextStyle(fontSize: 48, color: color)),
    );
  }

  static Future<String?> _showRankPicker(
    BuildContext context,
    String suit,
  ) async {
    final suitSymbol = _getSuitSymbol(suit);
    final suitColor = _getSuitColor(suit);

    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Selecione o Valor ', style: AppTextStyles.heading2),
                Text(
                  suitSymbol,
                  style: TextStyle(
                    fontSize: 24,
                    color: suitColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: [
                _buildRankButton(context, 'A'),
                _buildRankButton(context, 'K'),
                _buildRankButton(context, 'Q'),
                _buildRankButton(context, 'J'),
                _buildRankButton(context, 'T'),
                _buildRankButton(context, '9'),
                _buildRankButton(context, '8'),
                _buildRankButton(context, '7'),
                _buildRankButton(context, '6'),
                _buildRankButton(context, '5'),
                _buildRankButton(context, '4'),
                _buildRankButton(context, '3'),
                _buildRankButton(context, '2'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _buildRankButton(BuildContext context, String rank) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context, rank),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        rank,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  static String _getSuitSymbol(String code) {
    switch (code) {
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

  static Color _getSuitColor(String code) {
    return (code == 'h' || code == 'd') ? Colors.red : Colors.black;
  }
}
