import 'package:flutter/material.dart';

import 'screens.dart';
import 'state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  runApp(const AkibaApp());
}

class AkibaApp extends StatelessWidget {
  const AkibaApp({super.key});

  static const Color _seed = Color(0xFF0F7B5F);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        title: 'Akiba',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: _seed,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: _seed,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: app.onboarded ? const Shell() : const OnboardingScreen(),
      ),
    );
  }
}
