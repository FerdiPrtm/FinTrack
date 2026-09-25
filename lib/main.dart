import 'package:flutter/material.dart';

import 'app_state.dart';
import 'db.dart';
import 'screens/auth.dart';
import 'screens/shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await FinDb.open();
  await AppState.boot(db);
  runApp(const FinTrackApp());
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return MaterialApp(
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          return app.user != null ? const HomeShell() : const AuthScreen();
        },
      ),
    );
  }
}