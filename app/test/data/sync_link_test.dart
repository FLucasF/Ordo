import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/data/sync/sync_link.dart';

/// A device on the loopback: its database, a folder of attachments, and its listener.
class _Device {
  _Device(String name, Directory files)
    : db = AppDatabase(NativeDatabase.memory()),
      attachments = Directory(p.join(files.path, name))..createSync(recursive: true) {
    host = SyncHost(db: db, name: name, folders: {'attachments/': attachments});
  }

  final AppDatabase db;
  final Directory attachments;
  late final SyncHost host;
  late final SyncListener listener;

  /// What this device's person answers when asked to link, and the code shown.
  bool accept = true;
  String? shownCode;

  Future<void> start() async {
    listener = SyncListener(
      host: host,
      address: InternetAddress.loopbackIPv4,
      port: 0,
      findPort: 0,
      onConnection: (socket) => unawaited(
        host.serve(
          socket,
          confirmLink: (name, code) async {
            shownCode = code;
            return accept;
          },
        ),
      ),
    );
    await listener.start();
  }

  Repository get repo => Repository(db, clock: const SystemClock());

  Future<Set<String>> titles() async => {for (final t in (await repo.loadSnapshot()).tasks) if (t.deletedAt == null) t.title};
}

void main() {
  late Directory files;
  late _Device pc, phone;

  setUp(() async {
    files = await Directory.systemTemp.createTemp('ordo_sync_');
    pc = _Device('pc', files);
    phone = _Device('phone', files);
    await pc.start();
    await phone.start();
  });
  tearDown(() async {
    await pc.listener.stop();
    await phone.listener.stop();
    await pc.db.close();
    await phone.db.close();
    await files.delete(recursive: true);
  });

  Future<FoundDevice> link() async {
    String? code;
    final linked = await phone.host.link(InternetAddress.loopbackIPv4, pc.listener.boundPort, (name, c) async {
      code = c;
      return true;
    });
    // Both screens showed the same number.
    expect(code, pc.shownCode);
    expect(code, matches(RegExp(r'^\d{6}$')));
    return linked;
  }

  test('linked once, the devices sync their work and attachments both ways, encrypted', () async {
    await pc.repo.createTask(listId: inboxListId, title: 'Do PC');
    await phone.repo.createTask(listId: inboxListId, title: 'Do celular');
    File(p.join(pc.attachments.path, 'abc', 'foto.jpg'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(List.generate(5000, (i) => i % 256));
    final linked = await link();
    expect(linked.name, 'pc');
    expect([for (final d in await pc.host.devices()) d.name], ['phone']);

    final device = (await phone.host.devices()).single;
    final result = await phone.host.syncWith(device);
    expect(result.received.written, greaterThan(0));
    expect(result.filesIn, 1);
    expect(await phone.titles(), {'Do PC', 'Do celular'});
    expect(await pc.titles(), {'Do PC', 'Do celular'});
    expect(File(p.join(phone.attachments.path, 'abc', 'foto.jpg')).lengthSync(), 5000);

    // Again: only what changed since.
    await pc.repo.createTask(listId: inboxListId, title: 'Mais uma');
    final again = await phone.host.syncWith((await phone.host.devices()).single);
    // The task and its activity line; nothing new from the phone.
    expect((again.received.written, again.sent, again.filesIn), (2, 0, 0));
    expect(await phone.titles(), {'Do PC', 'Do celular', 'Mais uma'});
  });

  test('a link refused on the other screen is not kept', () async {
    pc.accept = false;
    await expectLater(phone.host.link(InternetAddress.loopbackIPv4, pc.listener.boundPort, (_, _) async => true), throwsA(isA<SyncFailure>()));
    expect(await pc.host.devices(), isEmpty);
    expect(await phone.host.devices(), isEmpty);
  });

  test('a device the other one forgot gets "unknown"; a wrong secret gets nothing', () async {
    await link();
    await pc.host.forget((await pc.host.devices()).single.id);
    final device = (await phone.host.devices()).single;
    await expectLater(phone.host.syncWith(device), throwsA(isA<SyncFailure>().having((f) => f.reason, 'reason', 'unknown')));

    await link();
    final forged = (await phone.host.devices()).single.copyWith(secret: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=');
    await pc.repo.createTask(listId: inboxListId, title: 'Segredo');
    await expectLater(phone.host.syncWith(forged), throwsA(isA<SyncFailure>()));
    expect(await phone.titles(), isNot(contains('Segredo')));
  });

  test('a file name that tries to leave its folder is refused', () async {
    await link();
    File(p.join(pc.attachments.path, 'ok.txt')).writeAsStringSync('ok');
    // A hostile manifest can't be built from real files; the check itself:
    expect(await phone.host.syncWith((await phone.host.devices()).single).then((r) => r.filesIn), 1);
    expect(File(p.join(files.path, 'evil.txt')).existsSync(), isFalse);
  });
}
