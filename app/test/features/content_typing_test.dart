import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';

void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 10, 21, 12));

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<String> pumpDetail(WidgetTester tester, Size size) async {
    final repo = Repository(db, clock: clock);
    final id = (await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'ELITE DA TROPA E ELITE DA TROPA 2')))!;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: TasksApp(initialLocation: '/p/inbox/tasks/$id'),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    return id;
  }

  /// Types [text] one letter at a time at the end of the content, as a person does.
  Future<void> type(WidgetTester tester, String text) async {
    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;
    for (final ch in text.split('')) {
      final node = editor.document.root.children.last;
      final offset = node.delta?.length ?? 0;
      editor.selection = Selection.collapsed(Position(path: node.path, offset: offset));
      final transaction = editor.transaction..insertText(node, offset, ch);
      await editor.apply(transaction);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('a click in the empty part of the notes box puts the caret at the end; tag and subtask are in the footer', (tester) async {
    await pumpDetail(tester, const Size(1365, 718));
    await type(tester, 'Primeira linha');
    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;
    editor.selection = null;
    await tester.pump();
    // The box is taller than the text (room to write): click near its bottom.
    final box = tester.getRect(find.byType(AppFlowyEditor));
    expect(box.height, greaterThanOrEqualTo(160));
    await tester.tapAt(Offset(box.left + 40, box.bottom - 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final last = editor.document.root.children.last;
    expect(editor.selection, Selection.collapsed(Position(path: last.path, offset: 'Primeira linha'.length)));
    // "+ Adicionar etiqueta" and "+ Adicionar subtarefa" left the middle of the detail for its footer.
    expect(find.widgetWithText(ActionChip, 'Adicionar etiqueta'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Adicionar subtarefa'), findsNothing);
    expect(find.byTooltip('Adicionar etiqueta'), findsOneWidget);
    expect(find.byTooltip('Adicionar subtarefa'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  });

  for (final (name, size) in [('desktop', const Size(1365, 718)), ('phone', const Size(400, 860))]) {
    testWidgets('$name: typing a long text in the notes, past several lines, never breaks; the placeholder goes at the first letter',
        (tester) async {
      final id = await pumpDetail(tester, size);
      expect(find.text('Digite o conteúdo ou use "/" para o menu'), findsOneWidget);
      await type(tester, 'L');
      expect(find.text('Digite o conteúdo ou use "/" para o menu'), findsNothing, reason: 'the placeholder over the text');
      await type(tester, 'ivro sobre o BOPE, a tropa de elite do Rio, contado por quem viveu as operações e os treinos, com muitos detalhes. ' * 4);
      expect(tester.takeException(), isNull);
      // Saved, and the editor shows all of it.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await tester.pump(const Duration(milliseconds: 100));
      final saved = (await tester.runAsync(() => Repository(db, clock: clock).task(id)))!.content;
      expect(saved, startsWith('Livro sobre o BOPE'));
      expect(saved.length, greaterThan(400));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(minutes: 2));
    });
  }
}
