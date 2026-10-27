import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import 'sync_dialog.dart';
import 'sync_service.dart';

/// The sync's state at a glance, in the icon bar and the drawer: shown only with a linked device. Its
/// tooltip says how each one is; a click opens "Sincronizar com outro aparelho".
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final service = ref.watch(syncServiceProvider);
    return StreamBuilder<List<LinkedDevice>>(
      stream: db.select(db.syncPeers).watch(),
      builder: (context, snapshot) {
        final devices = snapshot.data ?? const <LinkedDevice>[];
        if (devices.isEmpty) return const SizedBox.shrink();
        return ValueListenableBuilder<Map<String, LinkStatus>>(
          valueListenable: service.status,
          builder: (context, status, _) {
            final t = AppLocalizations.of(context);
            final tt = context.tt;
            final states = {for (final d in devices) status[d.id]?.state};
            final (icon, color) = states.contains(LinkState.syncing)
                ? (Icons.sync, tt.primary)
                : states.contains(LinkState.failed)
                ? (Icons.sync_problem, tt.overdue)
                : states.every((s) => s == LinkState.synced)
                ? (Icons.cloud_done_outlined, tt.textTertiary)
                : (Icons.cloud_off_outlined, tt.textTertiary);
            final now = DateTime.now();
            return IconButton(
              key: const ValueKey('syncIndicator'),
              tooltip: [for (final d in devices) '${d.name}: ${linkStatusText(t, d, status[d.id], now)}'].join('\n'),
              icon: Icon(icon, color: color, size: size),
              onPressed: () => unawaited(showDeviceSync(context)),
            );
          },
        );
      },
    );
  }
}
