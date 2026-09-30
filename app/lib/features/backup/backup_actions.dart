import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../data/attachment_store.dart';
import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../settings/settings_dialog.dart';
import '../countdown/countdown_card.dart' show countdownImagesProvider;
import '../subscriptions/subscriptions.dart' show subscriptionStoreProvider;
import '../sync/sync_dialog.dart';
import 'auto_backup.dart';
import 'backup_service.dart';

/// Account menu (avatar): Configurações, Estatísticas and Sincronizar aparelhos. Backup lives in
/// Settings → Conta.
void showAccountMenu(BuildContext context, WidgetRef ref, Offset position) {
  final t = AppLocalizations.of(context);
  unawaited(() async {
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(value: 'settings', height: 36, child: Text(t.settingsTitle)),
        PopupMenuItem(value: 'statistics', height: 36, child: Text(t.statsTitle)),
        PopupMenuItem(value: 'sync', height: 36, child: Text(t.syncMenu)),
      ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'settings':
        await showSettings(context);
      case 'statistics':
        context.go(Routes.statisticsOf('overview'));
      case 'sync':
        await showDeviceSync(context);
    }
  }());
}

/// The backup of this app's data: the database, the attachments and the other folders.
Future<BackupService> backupServiceOf(WidgetRef ref) async => BackupService(
  ref.read(databaseProvider),
  tempDir: await getTemporaryDirectory(),
  attachments: ref.read(attachmentStoreProvider),
  folders: {'countdown_images/': ref.read(countdownImagesProvider), 'calendars/': ref.read(subscriptionStoreProvider).dir},
);

/// "Gerar Backup": saves a zip with the database and the attachments.
Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context);
  final bytes = await (await backupServiceOf(ref)).export();
  final now = DateTime.now();
  final stamp =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
      '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  final path = await FilePicker.platform.saveFile(
    fileName: 'tarefas_backup_$stamp.zip',
    bytes: bytes,
    type: FileType.custom,
    allowedExtensions: ['zip'],
  );
  if (path != null && context.mounted) showToast(context, t.backupSaved);
}

/// "Importar backups locais": replaces everything with a backup zip, after confirming.
Future<void> importBackup(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context);
  final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip'], withData: true);
  final bytes = picked?.files.single.bytes;
  if (bytes == null || !context.mounted) return;
  if (!await confirm(context, message: t.backupImportConfirm)) return;
  try {
    await (await backupServiceOf(ref)).import(bytes);
    if (context.mounted) showToast(context, t.backupImported);
  } on InvalidBackup {
    if (context.mounted) showToast(context, t.backupInvalid);
  }
}

/// The day's automatic backup; errors only go to the log, the app carries on.
Future<void> runAutoBackup(WidgetRef ref) async {
  final auto = ref.read(autoBackupProvider);
  if (auto == null) return;
  try {
    final service = await backupServiceOf(ref);
    await auto.runIfDue(DateTime.now(), () => service.export(withFiles: false));
  } on Object catch (e) {
    debugPrint('Automatic backup failed: $e');
  }
}

/// "Backups automáticos": the kept copies, newest first, each with "Restaurar".
Future<void> showAutoBackups(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context);
  final backups = ref.read(autoBackupProvider)?.list() ?? const [];
  final picked = await showDialog<File>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.settingsAutoBackup, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.settingsAutoBackupHint),
            const SizedBox(height: 8),
            if (backups.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(t.autoBackupNone))
            else
              for (final (day, file) in backups)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  // A copy made before a sync has its time too.
                  title: Text(
                    day == DateTime(day.year, day.month, day.day)
                        ? DateLabels.numeric(day, withYear: true)
                        : '${DateLabels.numeric(day, withYear: true)} ${day.hour.toString().padLeft(2, '0')}:${day.minute.toString().padLeft(2, '0')}',
                  ),
                  subtitle: Text(AttachmentStore.formatSize(file.lengthSync())),
                  trailing: TextButton(onPressed: () => Navigator.pop(context, file), child: Text(t.autoBackupRestore)),
                ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose))],
    ),
  );
  if (picked == null || !context.mounted) return;
  if (!await confirm(context, message: t.backupImportConfirm)) return;
  try {
    await (await backupServiceOf(ref)).import(await picked.readAsBytes());
    if (context.mounted) showToast(context, t.backupImported);
  } on InvalidBackup {
    if (context.mounted) showToast(context, t.backupInvalid);
  }
}
