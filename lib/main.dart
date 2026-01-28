import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <--- Importante: Core do Firebase
import 'firebase_options.dart'; // <--- Importante: O arquivo que você gerou no terminal
import 'package:provider/provider.dart';

// Seus imports de telas e providers
import 'screens/login_screen.dart';
import 'providers/user_provider.dart';
import 'providers/game_provider.dart';
import 'providers/ranking_provider.dart';
import 'utils/app_theme.dart';

void main() async {
  // 1. Garante que a engine do Flutter esteja pronta antes de chamar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa o Firebase com as configurações do seu projeto (Android, Web, etc.)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Roda o App
  runApp(const PokerHomeGameApp());
}

class PokerHomeGameApp extends StatelessWidget {
  const PokerHomeGameApp({super.key});

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
        theme:
            AppTheme.darkTheme, // Certifique-se que o AppTheme está configurado
        home: const LoginScreen(),
      ),
    );
  }
}
