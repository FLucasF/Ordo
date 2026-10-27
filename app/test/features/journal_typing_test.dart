import 'package:appflowy_editor/appflowy_editor.dart' hide Document;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/journal_repository.dart';

void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 20, 21));

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester, [int steps = 8]) async {
    for (var i = 0; i < steps; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Types [text] one letter at a time at the end of the notes, as a person does.
  Future<void> type(WidgetTester tester, String text) async {
    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;
    for (final ch in text.split('')) {
      final node = editor.document.root.children.last;
      final offset = node.delta?.length ?? 0;
      editor.selection = Selection.collapsed(Position(path: node.path, offset: offset));
      await editor.apply(editor.transaction..insertText(node, offset, ch));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final (name, size) in [('desktop', const Size(1600, 1000)), ('laptop', const Size(1365, 718)), ('phone', const Size(400, 860))]) {
    testWidgets('$name: the day\'s notes take a long text, past the visible part of the page, without freezing', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Opens the database outside the test's fake clock.
      await tester.runAsync(() => db.customSelect('SELECT 1').get());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
          child: TasksApp(initialLocation: '/journal'),
        ),
      );
      await settle(tester, 10);
      const line = 'Hoje acordei cedo, fui correr no parque e depois escrevi um pouco sobre o livro que estou lendo. ';
      for (var i = 0; i < 6; i++) {
        await type(tester, line);
        final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;
        final node = editor.document.root.children.last;
        await editor.apply(editor.transaction..insertNode(node.path.next, paragraphNode()));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await type(tester, 'Fim.');
      expect(tester.takeException(), isNull);
      // The save after a pause in typing.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await settle(tester, 3);
      final notes = (await tester.runAsync(() => JournalRepository(db, clock: clock).load()))!.on(DateTime(2026, 10, 20))?.notes ?? '';
      expect(notes, startsWith('Hoje acordei cedo'));
      // The caret's line is on screen: the page followed the text down.
      final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;
      final caret = editor.selectionRects().last;
      expect(caret.bottom, lessThanOrEqualTo(size.height));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(minutes: 2));
    });
  }
}
