import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../backup/auto_backup.dart';
import '../backup/backup_actions.dart';
import 'device_sync.dart';

/// "Sincronizar com outro aparelho": one device sends everything it has, the other becomes equal to
/// it (after a safety copy of its own data), over the home Wi-Fi.
Future<void> showDeviceSync(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) {
    const body = _SyncDialog();
    if (MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint) return const Dialog.fullscreen(child: SafeArea(child: body));
    return Dialog(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640), child: body),
    );
  },
);

enum _Stage { choose, receive, send }

class _SyncDialog extends ConsumerStatefulWidget {
  const _SyncDialog();

  @override
  ConsumerState<_SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends ConsumerState<_SyncDialog> {
  _Stage _stage = _Stage.choose;

  // Receiving.
  SyncReceiver? _receiver;
  List<InternetAddress> _addresses = const [];
  bool _receiving = false;
  String? _receivedFrom;
  bool _receiveFailed = false;

  // Sending.
  StreamSubscription<List<SyncPeer>>? _search;
  List<SyncPeer> _peers = const [];
  SyncPeer? _peer;
  final _code = TextEditingController();
  final _address = TextEditingController();
  bool _typing = false;
  bool _sending = false;
  SyncOutcome? _outcome;

  @override
  void dispose() {
    unawaited(_receiver?.stop());
    unawaited(_search?.cancel());
    _code.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _startReceiving() async {
    setState(() => _stage = _Stage.receive);
    final receiver = SyncReceiver(onReceive: _replaceData);
    await receiver.start();
    final addresses = await localAddresses();
    if (!mounted) return unawaited(receiver.stop());
    setState(() {
      _receiver = receiver;
      _addresses = addresses;
    });
  }

  /// The other device's backup replaces this one's data, after a copy of this one's.
  Future<void> _replaceData(Uint8List backup, String from) async {
    if (mounted) setState(() => _receiving = true);
    try {
      final service = await backupServiceOf(ref);
      if (ref.read(autoBackupProvider) case final auto?) await auto.saveNow(DateTime.now(), await service.export());
      await service.import(backup);
      if (mounted) {
        setState(() {
          _receiving = false;
          _receivedFrom = from;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _receiving = false;
          _receiveFailed = true;
        });
      }
      rethrow;
    }
  }

  void _startSending() {
    setState(() => _stage = _Stage.send);
    _search = discoverPeers().listen((peers) {
      if (mounted) setState(() => _peers = peers);
    });
  }

  /// "192.168.0.10:50000" typed: the peer to send to.
  SyncPeer? _typedPeer() {
    final text = _address.text.trim();
    final colon = text.lastIndexOf(':');
    if (colon <= 0) return null;
    final address = InternetAddress.tryParse(text.substring(0, colon));
    final port = int.tryParse(text.substring(colon + 1));
    if (address == null || port == null || port <= 0 || port > 65535) return null;
    return SyncPeer(name: address.address, address: address, port: port);
  }

  Future<void> _send() async {
    final peer = _peer;
    if (peer == null || _code.text.trim().length != 6) return;
    setState(() {
      _sending = true;
      _outcome = null;
    });
    final backup = await (await backupServiceOf(ref)).export();
    final outcome = await sendBackup(peer, code: _code.text, backup: backup);
    if (mounted) {
      setState(() {
        _sending = false;
        _outcome = outcome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
          child: Row(
            children: [
              if (_stage != _Stage.choose && !_sending && !_receiving)
                IconButton(
                  tooltip: t.actionBack,
                  icon: Icon(Icons.arrow_back, color: tt.textSecondary),
                  onPressed: () {
                    unawaited(_receiver?.stop());
                    unawaited(_search?.cancel());
                    setState(() {
                      _receiver = null;
                      _search = null;
                      _peer = null;
                      _outcome = null;
                      _receivedFrom = null;
                      _receiveFailed = false;
                      _stage = _Stage.choose;
                    });
                  },
                ),
              Expanded(
                child: Text(t.syncTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                tooltip: t.actionClose,
                icon: Icon(Icons.close, color: tt.textSecondary),
                onPressed: _sending || _receiving ? null : () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: switch (_stage) {
              _Stage.choose => _choose(t, tt),
              _Stage.receive => _receive(t, tt),
              _Stage.send => _sendBody(t, tt),
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _choose(AppLocalizations t, TtColors tt) {
    Widget option(IconData icon, String title, String hint, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: tt.fieldFill,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: tt.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: tt.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
    return [
      Text(t.syncIntro, style: TextStyle(color: tt.textSecondary)),
      const SizedBox(height: 6),
      option(Icons.upload_rounded, t.syncSend, t.syncSendHint, _startSending),
      option(Icons.download_rounded, t.syncReceive, t.syncReceiveHint, () => unawaited(_startReceiving())),
      const SizedBox(height: 14),
      Text(
        t.syncSameWifi,
        style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
      ),
    ];
  }

  List<Widget> _receive(AppLocalizations t, TtColors tt) {
    final receiver = _receiver;
    if (_receivedFrom case final from?) return [_result(tt, true, t.syncReceived(from))];
    if (_receiveFailed) return [_result(tt, false, t.syncReceiveFailed)];
    if (receiver == null || _receiving) {
      return [
        const SizedBox(height: 24),
        const Center(child: CircularProgressIndicator()),
        if (_receiving) ...[const SizedBox(height: 12), Text(t.syncReceiving, textAlign: TextAlign.center)],
      ];
    }
    final code = '${receiver.code.substring(0, 3)} ${receiver.code.substring(3)}';
    return [
      Text(t.syncWaiting(receiver.name), style: TextStyle(color: tt.textSecondary)),
      const SizedBox(height: 16),
      Center(
        child: SelectableText(
          code,
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: 4, color: tt.text),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t.syncWaitingOther, style: TextStyle(color: tt.textSecondary)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_addresses.isNotEmpty)
        Text(
          t.syncAddress(receiver.name, _addresses.map((a) => '${a.address}:${receiver.port}').join('  ·  ')),
          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
        ),
      if (Platform.isWindows) ...[
        const SizedBox(height: 6),
        Text(
          t.syncFirewall,
          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
        ),
      ],
    ];
  }

  List<Widget> _sendBody(AppLocalizations t, TtColors tt) {
    if (_outcome == SyncOutcome.done) return [_result(tt, true, t.syncDone(_peer?.name ?? ''))];
    final peer = _peer;
    if (peer == null) {
      return [
        Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(t.syncSearching, style: TextStyle(color: tt.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final p in _peers)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(p.name == 'Celular Android' ? Icons.smartphone : Icons.computer, color: tt.primary),
            title: Text(p.name),
            subtitle: Text(p.address.address, style: TextStyle(color: tt.textTertiary)),
            trailing: Icon(Icons.chevron_right, color: tt.textTertiary),
            onTap: () => setState(() => _peer = p),
          ),
        const SizedBox(height: 8),
        if (!_typing)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.keyboard_outlined, size: 18),
              label: Text(t.syncTypeAddress),
              onPressed: () => setState(() => _typing = true),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _address,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(labelText: t.syncAddressLabel, isDense: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _typedPeer() == null ? null : () => setState(() => _peer = _typedPeer()), child: Text(t.actionOk)),
            ],
          ),
      ];
    }
    return [
      Text(t.syncEnterCode(peer.name), style: TextStyle(color: tt.textSecondary)),
      const SizedBox(height: 12),
      TextField(
        controller: _code,
        autofocus: true,
        enabled: !_sending,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, letterSpacing: 6, fontWeight: FontWeight.w600),
        decoration: InputDecoration(labelText: t.syncCodeLabel, isDense: true),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => unawaited(_send()),
      ),
      const SizedBox(height: 16),
      if (_sending) ...[
        const LinearProgressIndicator(),
        const SizedBox(height: 8),
        Text(t.syncSending, style: TextStyle(color: tt.textSecondary)),
      ] else
        FilledButton.icon(
          icon: const Icon(Icons.upload_rounded, size: 18),
          label: Text(t.syncSendButton),
          onPressed: _code.text.trim().length == 6 ? () => unawaited(_send()) : null,
        ),
      if (_outcome case final outcome? when outcome != SyncOutcome.done) ...[
        const SizedBox(height: 12),
        Text(switch (outcome) {
          SyncOutcome.wrongCode => t.syncWrongCode,
          SyncOutcome.refused => t.syncRefused,
          _ => t.syncFailed,
        }, style: TextStyle(color: tt.overdue)),
      ],
    ];
  }

  Widget _result(TtColors tt, bool ok, String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(ok ? Icons.check_circle : Icons.error_outline, size: 56, color: ok ? tt.palette.green : tt.overdue),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: tt.text),
        ),
      ],
    ),
  );
}
