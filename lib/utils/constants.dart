import 'package:flutter/material.dart';

/// App color constants - Poker Dark Theme
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF722F37); // Wine/Burgundy
  static const Color secondary = Color(0xFF121212); // Black
  static const Color darkGrey = Color(0xFF1E1E1E);

  // Accent Colors
  static const Color gold = Color(0xFFFFD700); // Gold for wins/ranking
  static const Color white = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);

  // Card Colors
  static const Color cardBackground = Color(0xFF2A2A2A);

  // Chip Colors
  static const Color chipWhite = Colors.white;
  static const Color chipRed = Color(0xFFE53935);
  static const Color chipGreen = Color(0xFF4CAF50);
  static const Color chipBlue = Color(0xFF2196F3);
  static const Color chipBlack = Colors.black;
}

/// Text styles for the app
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    fontFamily: 'Roboto',
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    fontFamily: 'Roboto',
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    fontFamily: 'Roboto',
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.white,
    fontFamily: 'Roboto',
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.white,
    fontFamily: 'Roboto',
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Colors.grey,
    fontFamily: 'Roboto',
  );
}

/// Game constants
class GameConstants {
  // Chip values
  static const int chipWhiteValue = 1;
  static const int chipRedValue = 5;
  static const int chipGreenValue = 10;
  static const int chipBlueValue = 25;
  static const int chipBlackValue = 50;

  // Total physical chips available
  static const int totalPhysicalChips = 200;

  // XP System
  static const int baseXPPerMatch = 100;
  static const int winnerBonusXP = 500;
  static const int xpDivisor = 100;

  // Ranking calculation weights
  static const int winsMultiplier = 10;
  static const int matchesMultiplier = 2;
  static const int levelMultiplier = 5;
}
