import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/app/routes.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/views.dart';
import 'package:task_manager/features/appearance/backdrop.dart';
import 'package:task_manager/features/appearance/backgrounds.dart';
import 'package:task_manager/features/backup/backup_service.dart';
import 'package:task_manager/features/lists/list_dialog.dart';
import 'package:task_manager/features/settings/settings_dialog.dart';
import 'package:task_manager/features/sidebar/sidebar.dart';
import 'package:task_manager/features/tasks/task_list_pane.dart';

void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 9, 24, 12));

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('the background preferences round-trip; a bad dim falls back or is clamped', () async {
    final prefs = PreferencesRepository(db, clock: clock);
    var p = await prefs.watch().first;
    expect((p.background, p.backgroundDim), (null, 0.5));

    await prefs.setBackground(BuiltInGradient.ocean.code);
    await prefs.setBackgroundDim(0.3);
    p = await prefs.watch().first;
    expect((p.background, p.backgroundDim), ('gradient:ocean', 0.3));

    await prefs.setBackground('a1b2.jpg');
    await prefs.setBackgroundDim(5);
    p = await prefs.watch().first;
    expect((p.background, p.backgroundDim), ('a1b2.jpg', maxBackgroundDim));

    await prefs.setBackground(null);
    await db
        .into(db.preferences)
        .insertOnConflictUpdate(PreferencesCompanion.insert(name: 'appearance.backgroundDim', value: '"dark"', updatedAt: DateTime.utc(2026)));
    p = await prefs.watch().first;
    expect((p.background, p.backgroundDim), (null, 0.5));
  });

  test('a preset sets the color, the background and the corners together; they stay editable', () async {
    final prefs = PreferencesRepository(db, clock: clock);
    await prefs.setCustomAccent('#FF0000');
    await ThemePreset.night.apply(prefs);
    var p = await prefs.watch().first;
    expect((p.colorSeries, p.customAccent, p.background, p.cardStyle, p.theme), (ColorSeries.navy, null, 'gradient:night', true, ThemeChoice.dark));
    expect(
      [
        for (final preset in ThemePreset.values)
          if (preset.matches(p)) preset,
      ],
      [ThemePreset.night],
    );

    await prefs.setBackground(BuiltInGradient.peach.code);
    p = await prefs.watch().first;
    expect(ThemePreset.night.matches(p), isFalse);
    expect(p.colorSeries, ColorSeries.navy);

    await ThemePreset.standard.apply(prefs);
    p = await prefs.watch().first;
    expect((p.colorSeries, p.background, p.cardStyle, p.theme), (ColorSeries.standard, null, false, ThemeChoice.dark));
  });

  test('a list shows its own background, else its parent list\'s, else its folder\'s, else the app\'s', () async {
    final repo = Repository(db, clock: clock);
    final folder = await repo.createFolder('Faculdade');
    final inFolder = await repo.createList(name: 'Cálculo', folderId: folder);
    final own = await repo.createList(name: 'TCC', folderId: folder);
    final plain = await repo.createList(name: 'Simples', folderId: folder);
    final loose = await repo.createList(name: 'Casa');
    await repo.setFolderBackground(folder, BuiltInGradient.forest.code);
    await repo.setListBackground(own, 'foto.jpg');
    await repo.setListBackground(plain, noBackground);
    var s = await repo.loadSnapshot();
    const app = 'gradient:dawn';

    expect(backgroundFor(s, ListScope(inFolder), app: app), 'gradient:forest');
    expect(backgroundFor(s, ListScope(own), app: app), 'foto.jpg');
    expect(backgroundFor(s, ListScope(plain), app: app), isNull, reason: '"Nenhum" stops at the list');
    expect(backgroundFor(s, ListScope(loose), app: app), app);
    expect(backgroundFor(s, FolderScope(folder), app: app), 'gradient:forest');
    expect(backgroundFor(s, const SmartScope(SmartList.today), app: app), app);
    expect(backgroundFor(s, null, app: null), isNull);
    expect(backgroundFor(s, ListScope(loose), app: 'gradient:unknown'), isNull, reason: 'an unknown gradient paints nothing');

    // A sublist (schema v20) follows its parent.
    await (db.update(db.lists)..where((l) => l.id.equals(loose))).write(ListsCompanion(parentId: Value(own)));
    s = await repo.loadSnapshot();
    expect(backgroundFor(s, ListScope(loose), app: app), 'foto.jpg');

    await repo.setFolderBackground(folder, null);
    s = await repo.loadSnapshot();
    expect(backgroundFor(s, ListScope(inFolder), app: app), app);
  });

  test('the background pictures go in the backup and come back', () async {
    final temp = Directory.systemTemp.createTempSync('ordo_backgrounds_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final repo = Repository(db, clock: clock);
    final list = await repo.createList(name: 'Viagem');
    await repo.setListBackground(list, 'praia.jpg');
    final picturesA = Directory(p.join(temp.path, 'a'))..createSync();
    File(p.join(picturesA.path, 'praia.jpg')).writeAsBytesSync([7, 7, 7]);
    final bytes = await BackupService(db, tempDir: temp, folders: {'backgrounds/': picturesA}).export();

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    final picturesB = Directory(p.join(temp.path, 'b'));
    await BackupService(target, tempDir: temp, folders: {'backgrounds/': picturesB}).import(bytes);
    expect(File(p.join(picturesB.path, 'praia.jpg')).readAsBytesSync(), [7, 7, 7]);
    expect((await Repository(target).loadSnapshot()).listById[list]!.background, 'praia.jpg');
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  String? shownBackground(WidgetTester tester) {
    final layers = find.byType(BackgroundLayer);
    return layers.evaluate().isEmpty ? null : tester.widget<BackgroundLayer>(layers.first).code;
  }

  Future<String> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late String list;
    await tester.runAsync(() async {
      final repo = Repository(db, clock: clock);
      list = await repo.createList(name: 'Jardim');
      await repo.setListBackground(list, BuiltInGradient.forest.code);
      await PreferencesRepository(db, clock: clock).setBackground(BuiltInGradient.dawn.code);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: const TasksApp(initialLocation: Routes.initial),
      ),
    );
    await settle(tester);
    return list;
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  }

  testWidgets('wide: the app\'s background is behind the task list, an open list\'s replaces it; the sidebar stays solid', (tester) async {
    final list = await pumpApp(tester, const Size(1600, 1000));
    expect(shownBackground(tester), 'gradient:dawn');
    expect(find.ancestor(of: find.byType(TaskListPane), matching: find.byType(AppBackdrop)), findsOneWidget);
    expect(find.ancestor(of: find.byType(Sidebar), matching: find.byType(AppBackdrop)), findsNothing);
    // The list's body leaves its color out, so the background shows.
    final body = tester.widget<Container>(find.descendant(of: find.byType(TaskListPane), matching: find.byType(Container)).first);
    expect(body.color, Colors.transparent);

    GoRouter.of(tester.element(find.byType(TaskListPane))).go(Routes.of(ListScope(list)));
    await settle(tester);
    expect(shownBackground(tester), 'gradient:forest');

    // The modules show the app's.
    GoRouter.of(tester.element(find.byType(TaskListPane))).go(Routes.matrix);
    await settle(tester);
    expect(shownBackground(tester), 'gradient:dawn');
    await unmount(tester);
  });

  testWidgets('phone: the list\'s background replaces the app\'s; none set, nothing is painted', (tester) async {
    final list = await pumpApp(tester, const Size(400, 800));
    expect(shownBackground(tester), 'gradient:dawn');
    GoRouter.of(tester.element(find.byType(TaskListPane))).go(Routes.of(ListScope(list)));
    await settle(tester);
    expect(shownBackground(tester), 'gradient:forest');

    // Written from the test's own zone (the app holds the database there) and let run by [settle].
    Repository(db, clock: clock).setListBackground(list, null).ignore();
    PreferencesRepository(db, clock: clock).setBackground(null).ignore();
    await settle(tester);
    expect(find.byType(BackgroundLayer), findsNothing);
    final body = tester.widget<Container>(find.descendant(of: find.byType(TaskListPane), matching: find.byType(Container)).first);
    expect(body.color, isNot(Colors.transparent));
    await unmount(tester);
  });

  testWidgets('Aparência: a preset applies, then a gradient and the dim slider; the list form picks a background', (tester) async {
    final list = await pumpApp(tester, const Size(1600, 1000));
    showSettings(tester.element(find.byType(TaskListPane)), tab: SettingsTab.appearance).ignore();
    await tester.pumpAndSettle();
    expect(find.text('Temas prontos'), findsOneWidget);
    expect(find.text('Escurecer'), findsOneWidget, reason: 'a background is set, in the dark theme');

    await tester.ensureVisible(find.text('Natureza'));
    await tester.tap(find.text('Natureza'));
    await settle(tester);
    var prefs = (await tester.runAsync(() => PreferencesRepository(db).watch().first))!;
    expect((prefs.colorSeries, prefs.background, prefs.cardStyle), (ColorSeries.reed, 'gradient:forest', true));

    await tester.ensureVisible(find.byTooltip('Pêssego'));
    await tester.tap(find.byTooltip('Pêssego'));
    await settle(tester);
    prefs = (await tester.runAsync(() => PreferencesRepository(db).watch().first))!;
    expect((prefs.background, ThemePreset.nature.matches(prefs)), ('gradient:peach', false));

    await tester.ensureVisible(find.byType(Slider));
    await tester.drag(find.byType(Slider), const Offset(-400, 0));
    await settle(tester);
    prefs = (await tester.runAsync(() => PreferencesRepository(db).watch().first))!;
    expect(prefs.backgroundDim, 0);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    // "Editar lista": "Padrão" leaves the list to the folder's or the app's.
    final s = (await tester.runAsync(() => Repository(db).loadSnapshot()))!;
    final form = showListDialog(tester.element(find.byType(TaskListPane)), editing: s.listById[list]);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Padrão (o da pasta ou do app)'));
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect((await form)!.background, isNull);
    await unmount(tester);
  });
}
