import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/attachment_store.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/features/common/image_viewer.dart';

// A 1×1 PNG.
const _png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  late AppDatabase db;
  late Directory temp;
  final clock = FixedClock(DateTime(2026, 9, 24, 12));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    temp = Directory.systemTemp.createTempSync('tarefas_preview_');
  });
  tearDown(() async {
    await db.close();
    temp.deleteSync(recursive: true);
  });

  test('pictures are known by their extension', () {
    expect(['a.PNG', 'b.jpeg', 'c.webp', 'd.pdf', 'e', 'f.txt'].map(isImageName), [true, true, true, false, false, false]);
  });

  testWidgets('an attached picture shows itself in the notes; a click opens it over the window, Esc closes', (tester) async {
    final store = AttachmentStore(Directory(p.join(temp.path, 'attachments')));
    final repo = Repository(db, clock: clock);
    final id = await tester.runAsync(() async {
      final source = File(p.join(temp.path, 'foto da lousa.png'))..writeAsBytesSync(base64Decode(_png));
      final picture = await store.add(source);
      final text = File(p.join(temp.path, 'resumo.txt'))..writeAsStringSync('oi');
      final document = await store.add(text);
      return repo.createTask(listId: inboxListId, title: 'Aula', content: '![file]($picture)\n\n![file]($document)');
    });
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock), attachmentStoreProvider.overrideWithValue(store)],
        child: TasksApp(initialLocation: '/p/inbox/tasks/$id'),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    // The picture shows; the text file stays a card with its icon.
    expect(find.text('foto da lousa.png'), findsOneWidget);
    expect(find.text('resumo.txt'), findsOneWidget);
    final picture = find.byWidgetPredicate((w) => w is Image && w.image is ResizeImage);
    expect(picture, findsOneWidget);
    expect(find.byIcon(Icons.description), findsOneWidget);

    await tester.tap(picture);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  });
}
