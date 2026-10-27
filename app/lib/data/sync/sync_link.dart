import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../db/database.dart';
import 'sync_crypto.dart';
import 'sync_engine.dart';

// Linked devices sync over the local network, with no server: each device listens on a TCP port and
// answers "who is there?" on a UDP port. Two devices are linked once: they agree on a secret with
// Diffie-Hellman and the person checks that both screens show the same 6-digit number. From then on,
// each session proves both sides know that secret and encrypts everything with keys made for it.
//
// On the wire, every message is a frame: 4 bytes of length (big-endian), then its bytes, gzip'ed and,
// once the session is secured, encrypted (ChaCha20) and followed by its HMAC.

/// The TCP port a device listens on (another one when it's taken).
const syncPort = 47811;

/// The UDP port a device answers [_hello] on.
const syncFindPort = 47812;

const _hello = 'ORDO-SYNC?1';
const _maxFrame = 512 * 1024 * 1024;

/// A device found on the network.
class FoundDevice {
  const FoundDevice({required this.id, required this.name, required this.address, required this.port});

  final String id;
  final String name;
  final InternetAddress address;
  final int port;

  @override
  bool operator ==(Object other) => other is FoundDevice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A sync that couldn't go on: [reason] says why, for the status shown.
class SyncFailure implements Exception {
  const SyncFailure(this.reason);

  /// 'unknown' (the other device no longer has this one linked), 'refused', 'proof' (not the device
  /// it says), 'busy', 'version' or 'network'.
  final String reason;

  @override
  String toString() => 'SyncFailure($reason)';
}

/// How a session went.
class SyncResult {
  const SyncResult({required this.received, required this.sent, required this.filesIn, required this.filesOut, required this.clockSkew});

  final MergeReport received;

  /// Rows sent to the other device.
  final int sent;
  final int filesIn;
  final int filesOut;

  /// How far the other device's clock is from this one's: the most recent edit wins, so a wrong clock
  /// matters.
  final Duration clockSkew;
}

/// Frames over a socket, plain at first and encrypted once [secure] is called.
class SyncChannel {
  SyncChannel(this.socket) {
    socket.listen(
      (chunk) {
        _buffer.add(chunk);
        _wake();
      },
      onDone: () {
        _closed = true;
        _wake();
      },
      onError: (Object _) {
        _closed = true;
        _wake();
      },
    );
  }

  final Socket socket;
  final _buffer = BytesBuilder(copy: false);
  bool _closed = false;
  Completer<void>? _waiting;
  Uint8List? _sendKey, _sendMac, _readKey, _readMac;
  int _sent = 0, _read = 0;

  void _wake() {
    _waiting?.complete();
    _waiting = null;
  }

  /// From now on every frame is encrypted and checked, each way with its own keys.
  void secure({required Uint8List sendKey, required Uint8List sendMac, required Uint8List readKey, required Uint8List readMac}) {
    _sendKey = sendKey;
    _sendMac = sendMac;
    _readKey = readKey;
    _readMac = readMac;
  }

  static Uint8List _nonce(int counter) => (ByteData(12)..setUint64(4, counter)).buffer.asUint8List();

  static Uint8List _counter(int n) => (ByteData(8)..setUint64(0, n)).buffer.asUint8List();

  Future<void> sendBytes(List<int> data) async {
    var frame = Uint8List.fromList(gzip.encode(data));
    if (_sendKey case final key?) {
      final n = _sent++;
      final cipher = chacha20(key, _nonce(n), frame);
      frame = Uint8List.fromList([...cipher, ...hmacSha256(_sendMac!, [..._counter(n), ...cipher])]);
    }
    socket.add((ByteData(4)..setUint32(0, frame.length)).buffer.asUint8List());
    socket.add(frame);
    await socket.flush();
  }

  Future<void> send(Map<String, Object?> message) => sendBytes(utf8.encode(jsonEncode(message)));

  Future<Uint8List> _take(int count) async {
    while (_buffer.length < count) {
      if (_closed) throw const SyncFailure('network');
      await (_waiting = Completer<void>()).future;
    }
    final data = _buffer.takeBytes();
    if (data.length > count) _buffer.add(data.sublist(count));
    return Uint8List.sublistView(data, 0, count);
  }

  Future<Uint8List> readBytes({Duration timeout = const Duration(seconds: 60)}) async {
    final length = (await _take(4).timeout(timeout)).buffer.asByteData().getUint32(0);
    if (length > _maxFrame) throw const SyncFailure('network');
    var frame = await _take(length).timeout(timeout);
    if (_readKey case final key?) {
      if (frame.length < 32) throw const SyncFailure('proof');
      final cipher = frame.sublist(0, frame.length - 32), mac = frame.sublist(frame.length - 32);
      final n = _read++;
      if (!sameBytes(mac, hmacSha256(_readMac!, [..._counter(n), ...cipher]))) throw const SyncFailure('proof');
      frame = chacha20(key, _nonce(n), cipher);
    }
    return Uint8List.fromList(gzip.decode(frame));
  }

  Future<Map<String, Object?>> read({Duration timeout = const Duration(seconds: 60)}) async {
    final message = jsonDecode(utf8.decode(await readBytes(timeout: timeout)));
    if (message is! Map<String, Object?>) throw const SyncFailure('version');
    if (message['err'] case final String reason) throw SyncFailure(reason);
    return message;
  }

  void close() => socket.destroy();
}

String _hex(List<int> bytes) => [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();

Uint8List _unhex(Object? s) {
  if (s is! String || s.length.isOdd) throw const SyncFailure('version');
  return Uint8List.fromList([for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)]);
}

/// The number both screens show while linking: from both devices' values, so a device in the middle
/// would show another one.
String linkCode(List<int> publicA, List<int> publicB, List<int> nonceA, List<int> nonceB) {
  final digest = sha256Of([...publicA, ...publicB, ...nonceA, ...nonceB]);
  final n = digest.buffer.asByteData().getUint32(0) % 1000000;
  return n.toString().padLeft(6, '0');
}

/// One device's side of the sync: its database, name and folders of files that travel too
/// (attachments, countdown pictures, backgrounds), by the prefix their names get on the wire.
class SyncHost {
  SyncHost({required this.db, required this.name, this.folders = const {}, DateTime Function()? now}) : engine = SyncEngine(db), _now = now ?? DateTime.now;

  final AppDatabase db;
  final SyncEngine engine;
  final String name;
  final Map<String, Directory> folders;
  final DateTime Function() _now;

  Future<List<LinkedDevice>> devices() => db.select(db.syncPeers).get();

  Future<LinkedDevice?> device(String id) => (db.select(db.syncPeers)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<void> forget(String id) => (db.delete(db.syncPeers)..where((d) => d.id.equals(id))).go();

  Future<void> _remember({required String id, required String name, required Uint8List secret, required String? address, required int? port}) =>
      db.into(db.syncPeers).insertOnConflictUpdate(
        SyncPeersCompanion.insert(
          id: id,
          name: name,
          secret: base64Encode(secret),
          address: Value(address),
          port: Value(port),
          pairedAt: _now().toUtc(),
        ),
      );

  // ---------------------------------------------------------------- linking

  /// Links to the device at [address]:[port]. [confirm] shows the number to check against the
  /// other screen and returns the person's answer. Returns the device linked.
  Future<FoundDevice> link(InternetAddress address, int port, Future<bool> Function(String otherName, String code) confirm) async {
    final channel = SyncChannel(await Socket.connect(address, port, timeout: const Duration(seconds: 8)));
    try {
      final myId = await engine.deviceId();
      final dh = DhKeyPair();
      final myPublic = bigIntBytes(dh.public), myNonce = randomBytes(16);
      // A commitment first: this device's value can't be chosen after seeing the other's.
      await channel.send({'op': 'link', 'v': 1, 'id': myId, 'name': name, 'commit': _hex(sha256Of([...myPublic, ...myNonce]))});
      final answer = await channel.read();
      final otherPublic = _unhex(answer['pub']), otherNonce = _unhex(answer['nonce']);
      final otherId = answer['id'], otherName = answer['name'];
      if (otherId is! String || otherName is! String) throw const SyncFailure('version');
      await channel.send({'pub': _hex(myPublic), 'nonce': _hex(myNonce)});
      final shared = dh.shared(bigIntFromBytes(otherPublic));
      if (shared == null) throw const SyncFailure('proof');
      final code = linkCode(myPublic, otherPublic, myNonce, otherNonce);
      final ok = await confirm(otherName, code);
      await channel.send({'ok': ok});
      if (!ok) throw const SyncFailure('refused');
      final theirs = await channel.read(timeout: const Duration(minutes: 3));
      if (theirs['ok'] != true) throw const SyncFailure('refused');
      final secret = hmacSha256(sha256Of(shared), [...utf8.encode('ordo-link'), ...myPublic, ...otherPublic, ...myNonce, ...otherNonce]);
      await _remember(id: otherId, name: otherName, secret: secret, address: address.address, port: port);
      return FoundDevice(id: otherId, name: otherName, address: address, port: port);
    } finally {
      channel.close();
    }
  }

  Future<void> _answerLink(SyncChannel channel, Map<String, Object?> hello, Future<bool> Function(String otherName, String code)? confirm) async {
    final otherId = hello['id'], otherName = hello['name'], commit = _unhex(hello['commit']);
    if (otherId is! String || otherName is! String) throw const SyncFailure('version');
    if (confirm == null) return channel.send({'err': 'busy'});
    final dh = DhKeyPair();
    final myPublic = bigIntBytes(dh.public), myNonce = randomBytes(16);
    await channel.send({'id': await engine.deviceId(), 'name': name, 'pub': _hex(myPublic), 'nonce': _hex(myNonce)});
    final reveal = await channel.read();
    final otherPublic = _unhex(reveal['pub']), otherNonce = _unhex(reveal['nonce']);
    if (!sameBytes(commit, sha256Of([...otherPublic, ...otherNonce]))) throw const SyncFailure('proof');
    final shared = dh.shared(bigIntFromBytes(otherPublic));
    if (shared == null) throw const SyncFailure('proof');
    final code = linkCode(otherPublic, myPublic, otherNonce, myNonce);
    final ok = await confirm(otherName, code);
    final theirs = await channel.read(timeout: const Duration(minutes: 3));
    // Kept before saying yes: when the other device hears it, the link exists on both.
    if (ok && theirs['ok'] == true) {
      final secret = hmacSha256(sha256Of(shared), [...utf8.encode('ordo-link'), ...otherPublic, ...myPublic, ...otherNonce, ...myNonce]);
      await _remember(id: otherId, name: otherName, secret: secret, address: channel.socket.remoteAddress.address, port: null);
    }
    await channel.send({'ok': ok});
  }

  // ---------------------------------------------------------------- syncing

  static Future<Socket> _connect(InternetAddress to, int port) async {
    try {
      return await Socket.connect(to, port, timeout: const Duration(seconds: 5));
    } on SocketException {
      throw const SyncFailure('network');
    }
  }

  /// Proves both sides know the secret and makes the session's keys. [initiator] is the device that
  /// connected.
  static void _secure(SyncChannel channel, Uint8List secret, Uint8List nonceI, Uint8List nonceR, {required bool initiator}) {
    Uint8List key(String label) => hmacSha256(secret, [...utf8.encode(label), ...nonceI, ...nonceR]);
    final (ir, irMac, ri, riMac) = (key('k-ir'), key('m-ir'), key('k-ri'), key('m-ri'));
    initiator ? channel.secure(sendKey: ir, sendMac: irMac, readKey: ri, readMac: riMac) : channel.secure(sendKey: ri, sendMac: riMac, readKey: ir, readMac: irMac);
  }

  /// Syncs with [device], at its last address or [address]/[port]. Both end with each other's changes.
  Future<SyncResult> syncWith(LinkedDevice device, {InternetAddress? address, int? port}) async {
    final to = address ?? InternetAddress.tryParse(device.address ?? '');
    final at = port ?? device.port;
    if (to == null || at == null) throw const SyncFailure('network');
    final channel = SyncChannel(await _connect(to, at));
    try {
      final secret = base64Decode(device.secret);
      final nonceI = randomBytes(16);
      await channel.send({'op': 'sync', 'v': 1, 'id': await engine.deviceId(), 'nonce': _hex(nonceI), 'time': _now().toUtc().toIso8601String()});
      final answer = await channel.read();
      final nonceR = _unhex(answer['nonce']);
      if (answer['id'] != device.id || !sameBytes(_unhex(answer['proof']), hmacSha256(secret, [...utf8.encode('R'), ...nonceI, ...nonceR]))) {
        throw const SyncFailure('proof');
      }
      final skew = _skew(answer['time']);
      await channel.send({'proof': _hex(hmacSha256(secret, [...utf8.encode('I'), ...nonceI, ...nonceR]))});
      _secure(channel, secret, nonceI, nonceR, initiator: true);

      final (mine, upTo) = await engine.changesSince(device.sentSeq);
      await channel.send({'changes': [for (final c in mine) c.toJson()], 'upTo': upTo, 'files': await _manifest()});
      final reply = await channel.read(timeout: const Duration(minutes: 5));
      if (reply['ack'] != upTo) throw const SyncFailure('version');
      await _confirmed(device.id, upTo, to.address, at);
      final report = await engine.apply(_changes(reply['changes']));
      final theirFiles = _names(reply['files']);
      final need = await _missing(theirFiles);
      await channel.send({'ack': reply['upTo'], 'need': need});
      final filesOut = await _sendFiles(channel, _names(reply['need']));
      final filesIn = await _receiveFiles(channel);
      return SyncResult(received: report, sent: mine.length, filesIn: filesIn, filesOut: filesOut, clockSkew: skew);
    } finally {
      channel.close();
    }
  }

  Future<void> _answerSync(SyncChannel channel, Map<String, Object?> hello) async {
    final id = hello['id'];
    final device = id is String ? await this.device(id) : null;
    if (device == null) return channel.send({'err': 'unknown'});
    final secret = base64Decode(device.secret);
    final nonceI = _unhex(hello['nonce']), nonceR = randomBytes(16);
    await channel.send({
      'id': await engine.deviceId(),
      'nonce': _hex(nonceR),
      'proof': _hex(hmacSha256(secret, [...utf8.encode('R'), ...nonceI, ...nonceR])),
      'time': _now().toUtc().toIso8601String(),
    });
    final proof = await channel.read();
    if (!sameBytes(_unhex(proof['proof']), hmacSha256(secret, [...utf8.encode('I'), ...nonceI, ...nonceR]))) throw const SyncFailure('proof');
    _secure(channel, secret, nonceI, nonceR, initiator: false);

    final theirs = await channel.read(timeout: const Duration(minutes: 5));
    await engine.apply(_changes(theirs['changes']));
    final (mine, upTo) = await engine.changesSince(device.sentSeq);
    final need = await _missing(_names(theirs['files']));
    await channel.send({'ack': theirs['upTo'], 'changes': [for (final c in mine) c.toJson()], 'upTo': upTo, 'files': await _manifest(), 'need': need});
    final done = await channel.read(timeout: const Duration(minutes: 5));
    if (done['ack'] == upTo) await _confirmed(device.id, upTo, channel.socket.remoteAddress.address, null);
    await _receiveFiles(channel);
    await _sendFiles(channel, _names(done['need']));
  }

  Duration _skew(Object? time) {
    final theirs = time is String ? DateTime.tryParse(time) : null;
    return theirs == null ? Duration.zero : theirs.difference(_now().toUtc());
  }

  Future<void> _confirmed(String id, int upTo, String address, int? port) => (db.update(db.syncPeers)..where((d) => d.id.equals(id))).write(
    SyncPeersCompanion(sentSeq: Value(upTo), lastSyncAt: Value(_now().toUtc()), address: Value(address), port: port == null ? const Value.absent() : Value(port)),
  );

  static List<RowChange> _changes(Object? list) => [
    for (final c in list is List ? list : const []) RowChange.fromJson((c as Map).cast<String, Object?>()),
  ];

  static List<String> _names(Object? list) => [for (final n in list is List ? list : const []) ?(n is String ? n : null)];

  // ---------------------------------------------------------------- files

  /// Every file of the folders that travel, as "prefix/relative/path".
  Future<List<String>> _manifest() async => [
    for (final MapEntry(key: prefix, value: dir) in folders.entries)
      if (dir.existsSync())
        for (final f in dir.listSync(recursive: true))
          if (f is File) '$prefix${p.relative(f.path, from: dir.path).replaceAll(r'\', '/')}',
  ];

  /// The local file for a name from the other device, or null when it isn't one of ours or tries to
  /// leave its folder.
  File? _fileFor(String name) {
    for (final MapEntry(key: prefix, value: dir) in folders.entries) {
      if (!name.startsWith(prefix)) continue;
      final relative = name.substring(prefix.length);
      final parts = relative.split('/');
      if (relative.isEmpty || parts.any((s) => s.isEmpty || s == '.' || s == '..') || relative.contains(r'\') || relative.contains(':')) return null;
      return File(p.joinAll([dir.path, ...parts]));
    }
    return null;
  }

  Future<List<String>> _missing(List<String> theirs) async => [
    for (final name in theirs)
      if (_fileFor(name) case final file? when !file.existsSync()) name,
  ];

  Future<int> _sendFiles(SyncChannel channel, List<String> names) async {
    var sent = 0;
    for (final name in names) {
      final file = _fileFor(name);
      if (file == null || !file.existsSync()) continue;
      await channel.send({'file': name});
      await channel.sendBytes(await file.readAsBytes());
      sent++;
    }
    await channel.send({'file': null});
    return sent;
  }

  Future<int> _receiveFiles(SyncChannel channel) async {
    var received = 0;
    while (true) {
      final header = await channel.read(timeout: const Duration(minutes: 5));
      final name = header['file'];
      if (name is! String) return received;
      final bytes = await channel.readBytes(timeout: const Duration(minutes: 5));
      final file = _fileFor(name);
      if (file == null || file.existsSync()) continue;
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      received++;
    }
  }

  // ---------------------------------------------------------------- serving

  /// Answers a device that connected: a sync, or a link when [confirmLink] can ask the person.
  /// [onSynced] runs after a sync, with the device.
  Future<void> serve(Socket socket, {Future<bool> Function(String otherName, String code)? confirmLink, void Function(String deviceId)? onSynced}) async {
    final channel = SyncChannel(socket);
    try {
      final hello = await channel.read(timeout: const Duration(seconds: 15));
      switch (hello['op']) {
        case 'sync':
          await _answerSync(channel, hello);
          if (hello['id'] case final String id) onSynced?.call(id);
        case 'link':
          await _answerLink(channel, hello, confirmLink);
        default:
          await channel.send({'err': 'version'});
      }
    } on Object {
      // A broken or hostile connection: nothing written outside the merge's transaction.
    } finally {
      channel.close();
    }
  }
}

/// This device listening for the others: the TCP server and the answers to [_hello].
class SyncListener {
  SyncListener({required this.host, required this.onConnection, this.port = syncPort, this.findPort = syncFindPort, InternetAddress? address})
    : address = address ?? InternetAddress.anyIPv4;

  final SyncHost host;
  final void Function(Socket socket) onConnection;
  final int port;
  final int findPort;
  final InternetAddress address;
  ServerSocket? _server;
  RawDatagramSocket? _udp;

  int get boundPort => _server!.port;

  Future<void> start() async {
    try {
      _server = await ServerSocket.bind(address, port);
    } on SocketException {
      _server = await ServerSocket.bind(address, 0);
    }
    _server!.listen(onConnection);
    try {
      final udp = await RawDatagramSocket.bind(address, findPort, reuseAddress: true);
      _udp = udp;
      final id = await host.engine.deviceId();
      udp.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = udp.receive();
        if (datagram == null || utf8.decode(datagram.data, allowMalformed: true) != _hello) return;
        udp.send(utf8.encode(jsonEncode({'app': 'ordo', 'id': id, 'name': host.name, 'port': boundPort})), datagram.address, datagram.port);
      });
    } on SocketException {
      // Not found by the others, but they still reach it at its last address.
    }
  }

  Future<void> stop() async {
    _udp?.close();
    _udp = null;
    await _server?.close();
    _server = null;
  }
}

/// The devices answering on the local network within [wait], this one left out ([selfId]).
Future<List<FoundDevice>> findDevices({required String selfId, Duration wait = const Duration(seconds: 2), int findPort = syncFindPort, List<InternetAddress>? targets}) async {
  final udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)..broadcastEnabled = true;
  final found = <FoundDevice>{};
  udp.listen((event) {
    if (event != RawSocketEvent.read) return;
    final datagram = udp.receive();
    if (datagram == null) return;
    try {
      final reply = jsonDecode(utf8.decode(datagram.data)) as Map<String, Object?>;
      final (id, name, port) = (reply['id'], reply['name'], reply['port']);
      if (reply['app'] != 'ordo' || id is! String || id == selfId || port is! int) return;
      found.add(FoundDevice(id: id, name: name is String ? name : '?', address: datagram.address, port: port));
    } on Object {
      // Not ours.
    }
  });
  final destinations = targets ??
      [
        InternetAddress('255.255.255.255'),
        for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4))
          for (final a in i.addresses)
            if (!a.isLoopback && !a.isLinkLocal) InternetAddress('${a.address.substring(0, a.address.lastIndexOf('.'))}.255'),
      ];
  for (var round = 0; round < 3; round++) {
    for (final to in destinations) {
      try {
        udp.send(utf8.encode(_hello), to, findPort);
      } on SocketException {
        // A network that doesn't allow it: the others may.
      }
    }
    await Future<void>.delayed(wait ~/ 3);
  }
  udp.close();
  return found.toList();
}
