import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/sync/sync_link.dart';
import '../appearance/backgrounds.dart';
import '../countdown/countdown_card.dart';
import 'device_sync.dart' show syncDeviceName;

/// Where a linked device stands.
enum LinkState { waiting, syncing, synced, offline, failed }

/// A linked device's last sync: its state, when it last worked, and why it didn't ([SyncFailure.reason]).
@immutable
class LinkStatus {
  const LinkStatus(this.state, {this.at, this.reason, this.clockSkew = Duration.zero});

  final LinkState state;
  final DateTime? at;
  final String? reason;
  final Duration clockSkew;

  /// The other device's clock is off by more than two minutes.
  bool get clockOff => clockSkew.abs() > const Duration(minutes: 2);
}

/// Whether this app runs the automatic sync (main.dart turns it on; tests and the mini calendar don't).
final syncEnabledProvider = Provider<bool>((ref) => false);

/// The automatic sync with the linked devices.
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    SyncHost(
      db: ref.read(databaseProvider),
      name: syncDeviceName(),
      folders: {
        'attachments/': ref.read(attachmentStoreProvider).root,
        'countdown_images/': ref.read(countdownImagesProvider),
        'backgrounds/': ref.read(backgroundsDirProvider),
      },
    ),
  );
  ref.onDispose(() => unawaited(service.stop()));
  return service;
});

/// Keeps the linked devices in step while the app runs: it listens for them on the network and syncs
/// when it starts, comes back to the front, a few seconds after each change here, and every two
/// minutes. Each device is tried at its last address, and looked for on the network when it isn't
/// there.
class SyncService {
  SyncService(this.host);

  final SyncHost host;

  /// Each linked device's state, by its id.
  final status = ValueNotifier<Map<String, LinkStatus>>(const {});

  /// Asks the person about a link another device started: its name and the number to compare. Null
  /// (no screen yet) turns such links down.
  Future<bool> Function(String otherName, String code)? confirmLink;

  SyncListener? _listener;
  Timer? _timer, _soon;
  StreamSubscription<Object?>? _changes;
  bool _running = false, _again = false;
  int _lastSent = -1;

  Future<void> start() async {
    _listener = SyncListener(
      host: host,
      onConnection: (socket) => unawaited(
        host.serve(
          socket,
          confirmLink: confirmLink == null ? null : (name, code) => confirmLink!(name, code),
          onSynced: (id) => _set(id, LinkStatus(LinkState.synced, at: DateTime.now())),
        ),
      ),
    );
    try {
      await _listener!.start();
    } on Object catch (e) {
      // Another copy of the app holds the port and none was free: this one only reaches out.
      debugPrint('Sync not listening: $e');
      _listener = null;
    }
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => unawaited(syncNow()));
    _changes = host.db.tableUpdates().listen((_) => soon());
    unawaited(syncNow());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _soon?.cancel();
    await _changes?.cancel();
    await _listener?.stop();
  }

  /// A sync a few seconds from now (after a change here; more changes push it back).
  void soon() {
    _soon?.cancel();
    _soon = Timer(const Duration(seconds: 4), () async {
      // Only for a change of this device (a merge of the other's notifies too).
      if (await host.engine.lastSeq() != _lastSent) unawaited(syncNow());
    });
  }

  void _set(String id, LinkStatus s) => status.value = {...status.value, id: s};

  /// Syncs with every linked device now.
  Future<void> syncNow() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        final devices = await host.devices();
        if (devices.isEmpty) return;
        List<FoundDevice>? found;
        final upTo = await host.engine.lastSeq();
        for (final device in devices) {
          final before = status.value[device.id];
          _set(device.id, LinkStatus(LinkState.syncing, at: before?.at ?? device.lastSyncAt));
          try {
            SyncResult result;
            try {
              result = await host.syncWith(device);
            } on SyncFailure catch (f) {
              if (f.reason != 'network') rethrow;
              // Not at its last address: look for it on the network.
              found ??= await findDevices(selfId: await host.engine.deviceId());
              final match = found.where((d) => d.id == device.id).firstOrNull;
              if (match == null) {
                _set(device.id, LinkStatus(LinkState.offline, at: before?.at ?? device.lastSyncAt));
                continue;
              }
              result = await host.syncWith(device, address: match.address, port: match.port);
            }
            _set(device.id, LinkStatus(LinkState.synced, at: DateTime.now(), clockSkew: result.clockSkew));
          } on SyncFailure catch (f) {
            _set(device.id, LinkStatus(LinkState.failed, at: before?.at ?? device.lastSyncAt, reason: f.reason));
          } on Object catch (e) {
            debugPrint('Sync with ${device.name} failed: $e');
            _set(device.id, LinkStatus(LinkState.failed, at: before?.at ?? device.lastSyncAt, reason: 'network'));
          }
        }
        _lastSent = upTo;
      } while (_again);
    } finally {
      _running = false;
    }
  }
}
