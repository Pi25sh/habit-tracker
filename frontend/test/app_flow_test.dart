// Smoke tests for the current Habit Flow app boot flow.
//
// The app boots into a login gate (PasscodeScreen historically, now email +
// password) and navigates to a MainLayout with six bottom-nav tabs:
//   Dashboard | Journal | Bucket List | Thoughts | Calendar | Settings
//
// Every vertical (auth, habits, journal, tasks, calendar, settings) is
// offline-first: providers store locally and sync with the backend only when
// reachable. In widget tests all HTTP requests are short-circuited to a 400 by
// Flutter's test HttpOverrides, so login falls back to offline mode and the UI
// proceeds without a backend.

import 'dart:io';
import 'dart:typed_data' show ByteData;
import 'package:flutter/services.dart' show FontLoader;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart' as app;
import 'package:frontend/presentation/screens/passcode_screen.dart';
import 'package:frontend/presentation/screens/main_layout.dart';

late SharedPreferences _prefs;

Widget _bootApp() {
  return ProviderScope(
    overrides: [
      app.sharedPreferencesProvider.overrideWithValue(_prefs),
    ],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const PasscodeScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

/// Signs in through the email/password gate. Backend is unreachable in tests,
/// so the auth provider falls back to local-only mode and unlocks the app.
Future<void> _login(WidgetTester tester) async {
  expect(find.text('Habit Flow'), findsOneWidget);
  await tester.enterText(find.byType(TextField).at(0), 'shivani@example.com');
  await tester.enterText(find.byType(TextField).at(1), 'password123');
  await _tapLogin(tester);
  expect(find.byType(MainLayout), findsOneWidget);
}

/// Taps a bottom-nav icon. The IndexedStack keeps every tab mounted, but only
/// the selected child is onstage, so default finders skip the hidden tabs.
Future<void> _switchTo(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byIcon(icon));
  await tester.pumpAndSettle();
}

/// Configures a realistic phone-sized test surface (390 x 844 logical px).
/// The default 800 x 600 test surface is bigger horizontally and shorter than
/// most phones, which hides real layout decisions (the login form scrolls and
/// its Log In button sits below the fold on short viewports).
Future<void> _usePhoneSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = const Size(1170, 2532); // 390 x 844 logical
  addTearDown(tester.view.reset);
}

/// Scrolls to and taps the Log In button. On a phone-sized viewport the form
/// scrolls, so the button can be off-screen; ensureVisible brings it in first.
Future<void> _tapLogin(WidgetTester tester) async {
  final loginButton = find.text('Log In');
  await tester.ensureVisible(loginButton);
  await tester.pumpAndSettle();
  await tester.tap(loginButton);
  await tester.pumpAndSettle();
}

void main() {
  /// Loads the real Roboto typeface from the Flutter SDK cache so text measures
/// with realistic metrics in tests. Without a registered font, the test
/// binding renders every glyph as the square "Ahem" placeholder, which is
/// several times wider than real text and produces false overflow errors.
Future<void> loadRealFont() async {
  final sdk = Platform.environment['FLUTTER_ROOT'];
  if (sdk == null || sdk.isEmpty) return;
  final dir = Directory('$sdk/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;

  const weights = ['Regular', 'Italic', 'Medium', 'Bold', 'Light'];
  for (final weight in weights) {
    final file = File('${dir.path}/Roboto-$weight.ttf');
    if (!file.existsSync()) continue;
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  }
}

setUpAll(() async {
  // Never fetch fonts over the network in tests; fall back to the Roboto we
  // load above (Nunito/Kalam are not bundled, so the engine falls back to the
  // default family for those families' glyphs).
  GoogleFonts.config.allowRuntimeFetching = false;
  await loadRealFont();
  SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('Boot & login gate', () {
    testWidgets('renders the login screen without credentials prefilled',
        (tester) async {
      await _usePhoneSurface(tester);
      await tester.pumpWidget(_bootApp());
      await tester.pumpAndSettle();

      expect(find.text('Habit Flow'), findsOneWidget);
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.byType(MainLayout), findsNothing);
    });

    testWidgets('signing in unlocks the main layout', (tester) async {
      await _usePhoneSurface(tester);
      await tester.pumpWidget(_bootApp());
      await tester.pumpAndSettle();

      // Empty fields are rejected with a validation message.
      await _tapLogin(tester);
      expect(find.text('Please enter both email and password'), findsOneWidget);
      expect(find.byType(MainLayout), findsNothing);

      await _login(tester);
    });
  });

  group('Navigation', () {
    testWidgets('all six bottom-nav tabs are present and switchable',
        (tester) async {
      await _usePhoneSurface(tester);
      await tester.pumpWidget(_bootApp());
      await tester.pumpAndSettle();
      await _login(tester);

      // Dashboard (default tab 0)
      expect(find.textContaining('Shivani'), findsOneWidget);

      // Journal (tab 1)
      await _switchTo(tester, Icons.book_outlined);
      expect(find.text('My Journal'), findsOneWidget);

      // Bucket List (tab 2)
      await _switchTo(tester, Icons.event_note_outlined);
      expect(find.text('Bucket List'), findsOneWidget);

      // Thoughts (tab 3)
      await _switchTo(tester, Icons.chat_bubble_outline_rounded);
      // The Thoughts tab renders its own list; assert on its distinctive Add FAB.
      expect(find.text('Add Thought'), findsOneWidget);

      // Calendar (tab 4)
      await _switchTo(tester, Icons.calendar_today_outlined);
      expect(find.text('Calendar'), findsOneWidget);

      // Settings (tab 5)
      await _switchTo(tester, Icons.settings_outlined);
      expect(find.text('Settings'), findsOneWidget);

      // And back to the dashboard.
      await _switchTo(tester, Icons.home_outlined);
      expect(find.textContaining('Shivani'), findsOneWidget);
    });
  });
}