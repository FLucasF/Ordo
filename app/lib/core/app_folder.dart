import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// The folder a debug build run with TAREFAS_DATA_DIR keeps its data in, so trying it on a computer
/// where Tarefas is installed leaves the installed app's data, notifications and settings alone.
String? get isolatedDataDir {
  if (!kDebugMode || kIsWeb) return null;
  final dir = Platform.environment['TAREFAS_DATA_DIR'];
  return dir == null || dir.isEmpty ? null : dir;
}

/// Where the app keeps its data (the database, attachments, backups, the widgets' file).
Future<Directory> appDataDirectory() async {
  if (isolatedDataDir case final dir?) return Directory(dir).create(recursive: true);
  return getApplicationSupportDirectory();
}
