import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'app/app.dart';
import 'app/providers.dart';
import 'app/reminders.dart';
import 'data/attachment_store.dart';
import 'data/db/database.dart';
import 'data/subscription_store.dart';
import 'features/backup/auto_backup.dart';
import 'features/countdown/countdown_card.dart';
import 'features/mini_calendar/mini_calendar.dart';
import 'features/subscriptions/subscriptions.dart';
import 'core/app_folder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final reminders = await initializeReminders();
  final support = await appDataDirectory();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(AppDatabase()),
        reminderSetupProvider.overrideWithValue(reminders),
        attachmentStoreProvider.overrideWithValue(AttachmentStore(Directory(p.join(support.path, 'attachments')))),
        subscriptionStoreProvider.overrideWithValue(SubscriptionStore(Directory(p.join(support.path, 'calendars')))),
        countdownImagesProvider.overrideWithValue(Directory(p.join(support.path, 'countdown_images'))),
        autoBackupProvider.overrideWithValue(AutoBackup(Directory(p.join(support.path, 'backups')))),
      ],
      child: const TasksApp(),
    ),
  );
}

/// The desktop mini calendar's own engine (Windows; windows/runner/mini_window.cpp starts it): it
/// draws what the app writes for the calendar widgets and opens no database.
@pragma('vm:entry-point')
Future<void> miniCalendarMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  // A second entrypoint registers the Dart side of the plugins (path_provider) itself.
  DartPluginRegistrant.ensureInitialized();
  final support = await appDataDirectory();
  final host = ChannelMiniHost(support);
  runApp(MiniCalendarWindow(folder: support, host: host, settings: await host.load()));
}
