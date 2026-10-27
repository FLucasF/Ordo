// A stand-in for the PC, to try the sync with the Android emulator by hand (not part of the suite):
//   PEER_DIR=<folder> flutter test test/manual/sync_peer_manual.dart
// It listens on the loopback (the emulator reaches it as 10.0.2.2), accepts a link, logs every sync
// to <folder>/peer.log and adds a task after three minutes.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/data/sync/sync_link.dart';

void main() {
  test('sync peer', () async {
    final dir = Directory(Platform.environment['PEER_DIR']!)..createSync(recursive: true);
    final log = File(p.join(dir.path, 'peer.log'));
    void say(String line) => log.writeAsStringSync('${DateTime.now().toIso8601String().substring(11, 19)} $line\n', mode: FileMode.append, flush: true);
    final db = AppDatabase(NativeDatabase(File(p.join(dir.path, 'peer.sqlite'))));
    final repo = Repository(db);
    Future<List<String>> titles() async => [for (final t in (await repo.loadSnapshot()).tasks) if (t.deletedAt == null) t.title];
    if (!(await titles()).contains('Tarefa do PC')) await repo.createTask(listId: inboxListId, title: 'Tarefa do PC');
    final attachments = Directory(p.join(dir.path, 'attachments'))..createSync(recursive: true);
    final host = SyncHost(db: db, name: 'PC de teste', folders: {'attachments/': attachments});
    final listener = SyncListener(
      host: host,
      address: InternetAddress.loopbackIPv4,
      findPort: 0,
      onConnection: (socket) => host.serve(
        socket,
        confirmLink: (name, code) async {
          say('LINK from "$name" code $code');
          return true;
        },
        onSynced: (id) async => say('SYNCED tasks: ${(await titles()).join(' | ')}'),
      ),
    );
    await listener.start();
    say('LISTENING on ${listener.boundPort}; tasks: ${(await titles()).join(' | ')}');
    await Future<void>.delayed(const Duration(minutes: 3));
    await repo.createTask(listId: inboxListId, title: 'Segunda do PC');
    say('ADDED "Segunda do PC"');
    await Future<void>.delayed(const Duration(minutes: 9));
    await listener.stop();
    await db.close();
  }, timeout: const Timeout(Duration(minutes: 14)));
}
