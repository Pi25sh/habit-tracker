import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/models/habit.dart';
import 'data/models/note_record.dart';
import 'core/theme/theme_provider.dart';
import 'presentation/screens/passcode_screen.dart';

import 'application/services/notification_service.dart';

import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enterprise Security: Crash Logging & Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      // In production, log to crashlytics or custom service without stack trace
      debugPrint('Caught error in release mode: ${details.exception}');
    } else {
      // In debug, print full stack trace
      FlutterError.presentError(details);
    }
  };
  
  // Initialize Notifications
  await NotificationService().init();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const HabiiApp(),
    ),
  );
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class HabiiApp extends ConsumerWidget {
  const HabiiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Habii',
      theme: AppTheme.getTheme(currentTheme),
      home: const PasscodeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
