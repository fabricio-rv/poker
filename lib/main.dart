import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'providers/user_provider.dart';
import 'providers/game_provider.dart';
import 'providers/ranking_provider.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const PokerHomeGameApp());
}

class PokerHomeGameApp extends StatelessWidget {
  const PokerHomeGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => RankingProvider()),
      ],
      child: MaterialApp(
        title: 'Poker Home Game Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
