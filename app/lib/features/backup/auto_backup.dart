import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Daily local backups, like the ones TickTick's desktop app keeps: at most one per day, the newest
/// [keep] kept, in [dir]. They restore through the same path as "Importar backups locais".
class AutoBackup {
  AutoBackup(this.dir, {this.keep = 7});

  final Directory dir;
  final int keep;

  /// "tarefas_auto_20260929.zip" (the day's), or with the time (a copy made before a sync).
  static final _name = RegExp(r'^tarefas_auto_(\d{4})(\d{2})(\d{2})(?:_(\d{2})(\d{2})(\d{2}))?\.zip$');

  static String _stamp(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';

  /// The backups, newest first, with the day each one was made.
  List<(DateTime, File)> list() {
    if (!dir.existsSync()) return const [];
    final out = <(DateTime, File)>[];
    for (final file in dir.listSync().whereType<File>()) {
      final m = _name.firstMatch(p.basename(file.path));
      if (m == null) continue;
      int part(int i) => int.parse(m.group(i) ?? '0');
      out.add((DateTime(part(1), part(2), part(3), part(4), part(5), part(6)), file));
    }
    return out..sort((a, b) => b.$1.compareTo(a.$1));
  }

  /// Makes today's backup with [export] unless it exists, then drops the oldest beyond [keep].
  /// Returns the new file, or null when today's was already there.
  Future<File?> runIfDue(DateTime now, Future<Uint8List> Function() export) async {
    final target = File(p.join(dir.path, 'tarefas_auto_${_stamp(now)}.zip'));
    if (target.existsSync()) return null;
    await dir.create(recursive: true);
    // Written aside and renamed, so a crash never leaves a half backup under a valid name.
    final partial = File('${target.path}.part');
    await partial.writeAsBytes(await export(), flush: true);
    await partial.rename(target.path);
    for (final (_, old) in list().skip(keep)) {
      await old.delete();
    }
    return target;
  }
}

extension AutoBackupNow on AutoBackup {
  /// A copy made now whatever the day (before this device's data is replaced by another's), listed
  /// and restored with the daily ones.
  Future<File> saveNow(DateTime now, Uint8List bytes) async {
    String two(int n) => n.toString().padLeft(2, '0');
    final target = File(p.join(dir.path, 'tarefas_auto_${AutoBackup._stamp(now)}_${two(now.hour)}${two(now.minute)}${two(now.second)}.zip'));
    await dir.create(recursive: true);
    final partial = File('${target.path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(target.path);
    return target;
  }
}

/// Where the daily backups go; null (tests, or before `main` sets it) turns them off.
final autoBackupProvider = Provider<AutoBackup?>((ref) => null);
