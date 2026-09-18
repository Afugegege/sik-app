import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // If .env file is missing, fallback gracefully
  }
  runApp(const SikApp());
}

class SikApp extends StatelessWidget {
  const SikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: '식 (sik)',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.buildTheme(appState.accentColor),
            home: const MainShell(),
          );
        },
      ),
    );
  }
}
