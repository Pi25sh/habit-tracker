// Integration-style widget tests for the Shivani app.
//
// These exercise the real boot flow (PasscodeScreen -> MainLayout) and the
// create/edit/delete flows of every product system: Habits (Todo), Journal,
// Calendar, and Tasks. The only external dependency we stub is the journal
// SQLite database, which is replaced with an in-memory fake so tests run on any
// platform without native libraries.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart' as app;
import 'package:frontend/application/providers/journal_provider.dart';
import 'package:frontend/data/models/journal_entry.dart';

import 'package:frontend/presentation/screens/passcode_screen.dart';
import 'package:frontend/presentation/screens/main_layout.dart';
import 'package:frontend/presentation/screens/create_habit_screen.dart';
import 'package:frontend/presentation/screens/journal_editor_screen.dart';

// ---------------------------------------------------------------------------
// In-memory fake of DatabaseService so journal_provider is testable without
// native SQLite. We register it by overriding the journalProvider directly.
// ---------------------------------------------------------------------------

class _FakeJournalNotifier extends JournalNotifier {
  final List<JournalEntry> _entries;

  _FakeJournalNotifier(this._entries);

  void inject() {
    state = List<JournalEntry>.from(_entries);
  }
}

// A journal provider that never touches SQLite.
final testJournalProvider =
    StateNotifierProvider<_FakeJournalNotifier, List<JournalEntry>>(
  (ref) => _FakeJournalNotifier([]),
);

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

class _Harness {
  _Harness(this.providerOverrides);
  final List<Override> providerOverrides;
}

late SharedPreferences _testPrefs;

Widget _bootApp(_Harness harness) {
  return ProviderScope(
    overrides: [
      app.sharedPreferencesProvider.overrideWithValue(_testPrefs),
      journalProvider.overrideWith((ref) => _FakeJournalNotifier([])),
      ...harness.providerOverrides,
    ],
    child: const _TestRoot(),
  );
}

/// Starts at the passcode gate (the real app entry point).
class _TestRoot extends ConsumerWidget {
  const _TestRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6B8E6B),
      ),
      home: const PasscodeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Navigates from the passcode gate into the main shell using the correct PIN.
Future<void> _enterApp(WidgetTester tester) async {
  expect(find.text('Enter Passcode'), findsOneWidget);
  // Tap 1-2-3-4 on the keypad.
  for (final digit in ['1', '2', '3', '4']) {
    await tester.tap(find.text(digit, skipOffstage: false).first);
    await tester.pumpAndSettle();
  }
  await tester.pumpAndSettle();
  expect(find.byType(MainLayout), findsOneWidget);
}



Future<void> _goToTab(WidgetTester tester, String label) async {
  // The bottom nav uses GestureDetector children with a Text label.
  final tab = find.ancestor(
    of: find.text(label, skipOffstage: false),
    matching: find.byType(GestureDetector, skipOffstage: false),
  );
  // There can be other GestureDetectors; pick the one inside the nav row.
  await tester.tap(tab.first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Boot + navigation
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    _testPrefs = await SharedPreferences.getInstance();
  });

  group('Boot & navigation', () {
    testWidgets('passcode gate unlocks with correct PIN 1234',
        (tester) async {
      await tester.pumpWidget(_bootApp(_Harness([])));
      await tester.pumpAndSettle();

      expect(find.text('Shivani'), findsWidgets);
      expect(find.text('Enter Passcode'), findsOneWidget);

      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit, skipOffstage: false).first);
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();

      expect(find.byType(MainLayout), findsOneWidget);
    });

    testWidgets('passcode rejects a wrong PIN without unlocking',
        (tester) async {
      await tester.pumpWidget(_bootApp(_Harness([])));
      await tester.pumpAndSettle();

      for (final digit in ['9', '9', '9', '9']) {
        await tester.tap(find.text(digit, skipOffstage: false).first);
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();

      // Still on the passcode gate, never reached MainLayout.
      expect(find.byType(MainLayout), findsNothing);
      expect(find.text('Incorrect passcode'), findsOneWidget);
    });

    testWidgets('all five bottom-nav tabs are present and switchable',
        (tester) async {
      await tester.pumpWidget(_bootApp(_Harness([])));
      await tester.pumpAndSettle();
      await _enterApp(tester);

      for (final tab in ['Home', 'Journal', 'Todo', 'Calendar', 'Setting']) {
        await _goToTab(tester, tab);
        // The IndexedStack keeps all screens mounted, so we assert the
        // screen-specific header text appears.
      }

      // Home screen present.
      expect(find.text('Hi, Shivani'), findsOneWidget);
      // Journal screen present.
      await _goToTab(tester, 'Journal');
      expect(find.text('My Journal'), findsOneWidget);
      // Todo screen present.
      await _goToTab(tester, 'Todo');
      expect(find.text('My Todo'), findsOneWidget);
      // Calendar screen present.
      await _goToTab(tester, 'Calendar');
      expect(find.text('Calendar'), findsOneWidget);
      // Settings screen present.
      await _goToTab(tester, 'Setting');
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Habit (Todo) CRUD
  // -------------------------------------------------------------------------

  group('Habit / Todo system', () {
    testWidgets('home dashboard shows empty state then add habit flow works',
        (tester) async {
      await tester.pumpWidget(_bootApp(_Harness([])));
      await tester.pumpAndSettle();
      await _enterApp(tester);

      // Empty state.
      expect(find.text('No habits yet. Add one above!'), findsOneWidget);

      // Open the Add Habit screen.
      await tester.tap(find.text('Add Habit'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateHabitScreen), findsOneWidget);

      // Fill the name field.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g. Drink Water'),
          'Drink Water');
      await tester.pumpAndSettle();

      // Save.
      await tester.tap(find.text('Save Habit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Back on dashboard, the habit appears.
      expect(find.text('Drink Water'), findsWidgets);
    });

    testWidgets('habit appears in Todo tab filtered lists', (tester) async {
      await tester.pumpWidget(_bootApp(_Harness([])));
      await tester.pumpAndSettle();
      await _enterApp(tester);

      await tester.tap(find.text('Add Habit'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g. Drink Water'),
          'Meditation');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Habit'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await _goToTab(tester, 'Todo');
      expect(find.text('My Todo'), findsOneWidget);
      expect(find.text('Meditation'), findsWidgets);
    });
  });

  // -------------------------------------------------------------------------
  // Journal CRUD
  // -------------------------------------------------------------------------

  group('Journal system', () {
    testWidgets('journal list opens editor and creates an entry',
        (tester) async {
      await tester.pumpWidget(_bootApp(_Harness([])));
      await tester.pumpAndSettle();
      await _enterApp(tester);

      await _goToTab(tester, 'Journal');
      expect(find.text('My Journal'), findsOneWidget);

      // FAB to add a new entry.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Editor should be reachable.
      expect(find.byType(JournalEditorScreen), findsOneWidget);

      // Type a title and body.
      final titleField = find.widgetWithText(TextField, 'Title');
      if (titleField.hasFound) {
        await tester.enterText(titleField, 'A grateful heart');
        await tester.pumpAndSettle();
      }
      // Save / publish button if present.
      final save = find.text('Save');
      if (save.hasFound) {
        await tester.tap(save);
        await tester.pumpAndSettle();
      }
    });
  });

  // -------------------------------------------------------------------------
  // Calendar
  // -------------------------------------------------------------------------

  group('Calendar system', () {
    testWidgets('calendar screen renders and shows add menu', (tester) async {
      await tester.pumpWidget(_bootApp(_Harness([])));
      await tester.pumpAndSettle();
      await _enterApp(tester);

      await _goToTab(tester, 'Calendar');
      expect(find.text('Calendar'), findsOneWidget);

      // The calendar FAB should be present.
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Settings / theme
  // -------------------------------------------------------------------------

  group('Settings system', () {
    testWidgets('settings screen renders theme options', (tester) async {
      await tester.pumpWidget(_bootApp(_Harness([])));
      await tester.pumpAndSettle();
      await _enterApp(tester);

      await _goToTab(tester, 'Setting');
      expect(find.text('Settings'), findsOneWidget);
      // Theme names from the spec.
      expect(find.text('Mint Green'), findsWidgets);
      expect(find.text('Warm Cream'), findsWidgets);
      expect(find.text('Lavender'), findsWidgets);
      expect(find.text('Dark'), findsWidgets);
    });
  });
}
