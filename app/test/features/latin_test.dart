import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/app/reminders.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 9, 12));

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async {
    appLocale = const Locale('pt', 'BR');
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  test('Latin plurals and dates read well', () {
    final t = lookupAppLocalizations(const Locale('la'));
    expect(t.searchResultCount(0), 'Nullum pensum');
    expect(t.searchResultCount(1), 'Unum pensum');
    expect(t.searchResultCount(5), '5 pensa');
    expect(t.dateFull('Dies Veneris', 9, 'october', 2026), 'Dies Veneris, 9 october 2026');
  });

  testWidgets('in Latin the app opens, with the system pickers in Portuguese, and the texts outside the screen follow', (tester) async {
    final repo = Repository(db, clock: clock);
    await tester.runAsync(() async {
      await PreferencesRepository(db, clock: clock).setLanguage(AppLanguage.latin);
      await repo.createTask(listId: inboxListId, title: 'Legere', dueDate: DateTime(2026, 10, 9));
    });
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: const TasksApp(initialLocation: '/q/today/tasks'),
      ),
    );
    await settle(tester);
    expect(find.text('Hodie'), findsWidgets);
    expect(find.text('Legere'), findsOneWidget);
    // Notifications, the tray and the widgets use the chosen language too.
    expect(reminderTexts.trayOpen, 'Ordinem aperi');
    // Flutter's own texts (here a tooltip of the system) come in Portuguese, without errors.
    expect(MaterialLocalizations.of(tester.element(find.text('Legere'))).okButtonLabel, 'OK');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  });
}
