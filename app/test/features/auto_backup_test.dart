import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/features/backup/auto_backup.dart';
import 'package:task_manager/features/backup/backup_actions.dart';
import 'package:task_manager/l10n/app_localizations.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('auto_backup'));
  tearDown(() => dir.delete(recursive: true));

  test('one backup per day; the newest 7 stay; other files are left alone', () async {
    final auto = AutoBackup(Directory(p.join(dir.path, 'backups')));
    var exports = 0;
    Future<Uint8List> export() async {
      exports++;
      return Uint8List.fromList([1, 2, 3]);
    }

    expect(auto.list(), isEmpty, reason: 'no folder yet');
    final first = await auto.runIfDue(DateTime(2026, 9, 25, 9), export);
    expect(p.basename(first!.path), 'tarefas_auto_20260925.zip');
    expect(await auto.runIfDue(DateTime(2026, 9, 25, 18), export), isNull, reason: 'already made today');
    expect(exports, 1);

    File(p.join(auto.dir.path, 'notas.txt')).writeAsStringSync('meu arquivo');
    for (var day = 26; day <= 33; day++) {
      await auto.runIfDue(DateTime(2026, 9, day), export);
    }
    final kept = auto.list();
    expect(kept, hasLength(7));
    expect(kept.first.$1, DateTime(2026, 10, 3), reason: 'newest first');
    expect(kept.last.$1, DateTime(2026, 9, 27));
    expect(File(p.join(auto.dir.path, 'notas.txt')).existsSync(), isTrue);
    expect(auto.dir.listSync().where((f) => f.path.endsWith('.part')), isEmpty);
  });

  test('a copy made before a sync is listed with its time, newest first, next to the daily ones', () async {
    final auto = AutoBackup(Directory(p.join(dir.path, 'backups')));
    await auto.runIfDue(DateTime(2026, 9, 29, 8), () async => Uint8List(10));
    await auto.saveNow(DateTime(2026, 9, 29, 21, 5, 30), Uint8List(20));
    final listed = auto.list();
    expect(listed.map((b) => b.$1), [DateTime(2026, 9, 29, 21, 5, 30), DateTime(2026, 9, 29)]);
    expect(listed.first.$2.lengthSync(), 20);
    // The daily one is still made once a day.
    expect(await auto.runIfDue(DateTime(2026, 9, 29, 22), () async => Uint8List(1)), isNull);
  });

  testWidgets('"Backups automáticos" lists the kept copies with "Restaurar"', (tester) async {
    final auto = AutoBackup(Directory(p.join(dir.path, 'backups')));
    await tester.runAsync(() => auto.runIfDue(DateTime(2026, 9, 25), () async => Uint8List(2048)));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [autoBackupProvider.overrideWithValue(auto)],
        child: MaterialApp(
          theme: buildTheme(dark: true),
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          home: Consumer(
            builder: (context, ref, _) => TextButton(onPressed: () => showAutoBackups(context, ref), child: const Text('abrir')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Backups automáticos'), findsOneWidget);
    expect(find.text('25/09/2026'), findsOneWidget);
    expect(find.text('2,0 KB'), findsOneWidget);
    expect(find.text('Restaurar'), findsOneWidget);
  });
}
