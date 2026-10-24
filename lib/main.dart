import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/rules/disposal_rules_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline rules engine
  await DisposalRulesService.instance.initialize();

  // Gracefully initialize Firebase if configured
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization skipped or pending configuration: $e");
  }

  runApp(const EcoMindApp());
}

class EcoMindApp extends StatelessWidget {
  const EcoMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
