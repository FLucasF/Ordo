import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/attachment_store.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/data/subscription_store.dart';
import 'package:task_manager/features/backup/auto_backup.dart';
import 'package:task_manager/features/backup/backup_service.dart';
import 'package:task_manager/features/countdown/countdown_card.dart' show countdownImagesProvider;
import 'package:task_manager/features/subscriptions/subscriptions.dart' show subscriptionStoreProvider;
import 'package:task_manager/features/sync/device_sync.dart';
import 'package:task_manager/features/sync/sync_dialog.dart';
import 'package:task_manager/l10n/app_localizations.dart';

void main() {
  test('a backup goes to the receiver with its code; a wrong code is refused, and after 5 it stops listening', () async {
    final received = <(Uint8List, String)>[];
    final receiver = SyncReceiver(
      onReceive: (bytes, from) async => received.add((bytes, from)),
      discoveryPort: 47899,
      code: '123456',
      name: 'PC',
      address: InternetAddress.loopbackIPv4,
    );
    await receiver.start();
    addTearDown(receiver.stop);
    final peer = SyncPeer(name: 'PC', address: InternetAddress.loopbackIPv4, port: receiver.port);
    final backup = Uint8List.fromList(List.generate(300000, (i) => i % 251));

    expect(await sendBackup(peer, code: '654321', backup: backup, name: 'Celular'), SyncOutcome.wrongCode);
    expect(received, isEmpty);
    expect(await sendBackup(peer, code: ' 123456 ', backup: backup, name: 'Celular'), SyncOutcome.done);
    expect(received.single.$2, 'Celular');
    expect(received.single.$1, backup);

    for (var i = 0; i < 4; i++) {
      await sendBackup(peer, code: '000000', backup: backup);
    }
    expect(await sendBackup(peer, code: '123456', backup: backup), SyncOutcome.refused);
    expect(received, hasLength(1));
  });

  test('a failure while replacing the data goes back to the sender', () async {
    final receiver = SyncReceiver(
      onReceive: (_, _) async => throw StateError('schema'),
      discoveryPort: 47898,
      code: '111111',
      address: InternetAddress.loopbackIPv4,
    );
    await receiver.start();
    addTearDown(receiver.stop);
    final peer = SyncPeer(name: 'x', address: InternetAddress.loopbackIPv4, port: receiver.port);
    expect(await sendBackup(peer, code: '111111', backup: Uint8List(10)), SyncOutcome.failed);
  });

  test('the sender finds the receiver by asking on the network', () async {
    final receiver = SyncReceiver(onReceive: (_, _) async {}, discoveryPort: 47897, name: 'DESKTOP-LUCAS', address: InternetAddress.loopbackIPv4);
    await receiver.start();
    addTearDown(receiver.stop);
    final found = await discoverPeers(
      discoveryPort: 47897,
      interval: const Duration(milliseconds: 200),
      targets: [InternetAddress.loopbackIPv4],
    ).firstWhere((peers) => peers.isNotEmpty).timeout(const Duration(seconds: 5));
    expect(found.single.name, 'DESKTOP-LUCAS');
    expect(found.single.port, receiver.port);
  });

  testWidgets('"Receber neste aparelho": the code on screen takes the other device\'s data, after a safety copy', (tester) async {
    final clock = FixedClock(DateTime(2026, 9, 29, 21));
    final here = AppDatabase(NativeDatabase.memory());
    final phone = AppDatabase(NativeDatabase.memory());
    addTearDown(here.close);
    addTearDown(phone.close);
    final dir = (await tester.runAsync(() => Directory.systemTemp.createTemp('sync_test')))!;
    addTearDown(() => dir.deleteSync(recursive: true));
    Directory sub(String name) => Directory(p.join(dir.path, name))..createSync(recursive: true);
    final auto = AutoBackup(sub('backups'));
    // The backup's scratch folder (path_provider has no plugin in tests).
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (_) async => dir.path);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), null));
    await tester.runAsync(() async {
      await Repository(here, clock: clock).createTask(listId: inboxListId, title: 'Só no PC');
      await Repository(phone, clock: clock).createTask(listId: inboxListId, title: 'Do celular');
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(here),
          clockProvider.overrideWithValue(clock),
          autoBackupProvider.overrideWithValue(auto),
          attachmentStoreProvider.overrideWithValue(AttachmentStore(sub('attachments'))),
          countdownImagesProvider.overrideWithValue(sub('images')),
          subscriptionStoreProvider.overrideWithValue(SubscriptionStore(sub('calendars'))),
        ],
        child: MaterialApp(
          theme: buildTheme(dark: true),
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          home: Builder(
            builder: (context) => TextButton(onPressed: () => showDeviceSync(context), child: const Text('abrir')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar deste aparelho'), findsOneWidget);
    await tester.tap(find.text('Receber neste aparelho'));
    for (var i = 0; i < 10 && find.byType(SelectableText).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    final code = tester.widget<SelectableText>(find.byType(SelectableText)).data!.replaceAll(' ', '');
    expect(code, hasLength(6));
    final address = RegExp(r':(\d+)').firstMatch(tester.widget<Text>(find.textContaining('Digitar endereço')).data!)!;
    final port = int.parse(address.group(1)!);

    // The screen's receiver lives in the test's clock: pumped while the other side sends.
    SyncOutcome? outcome;
    final backup = (await tester.runAsync(() => BackupService(phone, tempDir: dir).export()))!;
    unawaited(
      sendBackup(
        SyncPeer(name: 'x', address: InternetAddress.loopbackIPv4, port: port),
        code: code,
        backup: backup,
        name: 'Celular Android',
      ).then((o) => outcome = o),
    );
    for (var i = 0; i < 100 && outcome == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
    expect(outcome, SyncOutcome.done);
    await tester.pump();
    expect(find.text('Pronto! Este aparelho ficou igual a "Celular Android".'), findsOneWidget);
    final titles = await tester.runAsync(() async => [for (final t in await here.select(here.tasks).get()) t.title]);
    expect(titles, ['Do celular']);
    // The safety copy of what was here.
    expect(auto.list(), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
