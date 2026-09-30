import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

// Copying everything from one device to another over the home Wi-Fi, with no server or cloud: the
// device that receives listens (a TCP port, and a UDP port to be found) and shows a 6-digit code;
// the one that sends finds it on the network, asks for that code and sends its backup. The data
// never leaves the local network, and only while the receiving screen is open.
//
// On the wire: the sender writes one line of JSON ({"code", "name", "size"}) and then [size] bytes;
// the receiver answers one line: "OK", "CODE" (wrong code), "ERR <reason>" or "FULL" (too many
// tries).

/// The UDP port the receiver answers "who is there?" on.
const syncDiscoveryPort = 47810;

const _hello = 'TAREFAS?1';
const _maxTries = 5;

/// Biggest backup accepted (attachments included).
const _maxSize = 1024 * 1024 * 1024;

/// A device found on the network, ready to receive.
class SyncPeer {
  const SyncPeer({required this.name, required this.address, required this.port});

  final String name;
  final InternetAddress address;
  final int port;

  @override
  bool operator ==(Object other) => other is SyncPeer && other.address == address && other.port == port;

  @override
  int get hashCode => Object.hash(address, port);
}

/// How a send ended.
enum SyncOutcome { done, wrongCode, refused, failed }

/// This device's name for the other one.
String syncDeviceName() => Platform.isAndroid ? 'Celular Android' : Platform.localHostname;

/// This device's addresses on the local network (to type on the other one when it doesn't find it).
Future<List<InternetAddress>> localAddresses() async {
  final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
  return [
    for (final i in interfaces)
      for (final a in i.addresses)
        if (!a.isLoopback && !a.isLinkLocal) a,
  ];
}

/// The receiving side, while its screen is open. [onReceive] gets the backup and the sender's name,
/// and replaces this device's data with it; an exception there goes back to the sender as "ERR".
class SyncReceiver {
  SyncReceiver({required this.onReceive, this.discoveryPort = syncDiscoveryPort, String? code, String? name, InternetAddress? address})
    : code = code ?? _newCode(),
      name = name ?? syncDeviceName(),
      address = address ?? InternetAddress.anyIPv4;

  final Future<void> Function(Uint8List backup, String from) onReceive;
  final int discoveryPort;
  final String code;
  final String name;

  /// Where it listens: every network by default (the loopback in tests, to stay off the firewall).
  final InternetAddress address;

  ServerSocket? _server;
  RawDatagramSocket? _udp;
  int _wrongTries = 0;
  bool _busy = false;

  /// The TCP port it listens on, once started.
  int get port => _server!.port;

  static String _newCode() => Random.secure().nextInt(1000000).toString().padLeft(6, '0');

  Future<void> start() async {
    _server = await ServerSocket.bind(address, 0);
    _server!.listen((socket) => unawaited(_serve(socket)));
    // Being found is a nicety: without it, the address shown can be typed on the other device.
    try {
      final udp = await RawDatagramSocket.bind(address, discoveryPort, reuseAddress: true);
      _udp = udp;
      udp.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = udp.receive();
        if (datagram == null || utf8.decode(datagram.data, allowMalformed: true) != _hello) return;
        final reply = utf8.encode(jsonEncode({'app': 'tarefas', 'v': 1, 'name': name, 'port': port}));
        udp.send(reply, datagram.address, datagram.port);
      });
    } on SocketException {
      _udp = null;
    }
  }

  Future<void> stop() async {
    _udp?.close();
    _udp = null;
    await _server?.close();
    _server = null;
  }

  Future<void> _serve(Socket socket) async {
    final reader = _Reader(socket);
    Future<void> answer(String line) async {
      socket.write('$line\n');
      await socket.flush();
      await socket.close();
    }

    try {
      final header = jsonDecode(await reader.line(4096)) as Map<String, Object?>;
      if (_wrongTries >= _maxTries || _busy) return await answer('FULL');
      if (header['code'] != code) {
        _wrongTries++;
        return await answer('CODE');
      }
      final size = header['size'];
      if (size is! int || size <= 0 || size > _maxSize) return await answer('ERR size');
      _busy = true;
      final bytes = await reader.bytes(size);
      final from = header['name'] is String ? header['name']! as String : '?';
      try {
        await onReceive(bytes, from);
        await answer('OK');
      } on Object catch (e) {
        await answer('ERR $e');
      } finally {
        _busy = false;
      }
    } on Object {
      socket.destroy();
    }
  }
}

/// Looks for receivers on the local network: asks every [interval] and yields the list found so far.
Stream<List<SyncPeer>> discoverPeers({
  Duration interval = const Duration(milliseconds: 1500),
  int discoveryPort = syncDiscoveryPort,
  List<InternetAddress>? targets,
}) async* {
  final udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  udp.broadcastEnabled = true;
  final found = <SyncPeer>{};
  final controller = StreamController<List<SyncPeer>>();
  udp.listen((event) {
    if (event != RawSocketEvent.read) return;
    final datagram = udp.receive();
    if (datagram == null) return;
    try {
      final reply = jsonDecode(utf8.decode(datagram.data)) as Map<String, Object?>;
      final port = reply['port'];
      if (reply['app'] != 'tarefas' || port is! int) return;
      if (found.add(SyncPeer(name: '${reply['name'] ?? '?'}', address: datagram.address, port: port))) {
        controller.add(found.toList());
      }
    } on Object {
      // Not ours.
    }
  });
  // The whole-network broadcast, and each network's own (x.y.z.255, the usual home /24).
  Future<List<InternetAddress>> destinations() async =>
      targets ??
      [
        InternetAddress('255.255.255.255'),
        for (final a in await localAddresses()) InternetAddress('${a.address.substring(0, a.address.lastIndexOf('.'))}.255'),
      ];
  final hello = utf8.encode(_hello);
  Future<void> ask() async {
    for (final to in await destinations()) {
      try {
        udp.send(hello, to, discoveryPort);
      } on SocketException {
        // A network that doesn't allow it: the others may.
      }
    }
  }

  await ask();
  final timer = Timer.periodic(interval, (_) => unawaited(ask()));
  try {
    yield const [];
    yield* controller.stream;
  } finally {
    timer.cancel();
    udp.close();
    await controller.close();
  }
}

/// Sends [backup] to [peer] with the code shown there. Waits while the other device replaces its
/// data.
Future<SyncOutcome> sendBackup(SyncPeer peer, {required String code, required Uint8List backup, String? name}) async {
  Socket? socket;
  try {
    socket = await Socket.connect(peer.address, peer.port, timeout: const Duration(seconds: 8));
    socket.write('${jsonEncode({'code': code.trim(), 'name': name ?? syncDeviceName(), 'size': backup.length})}\n');
    socket.add(backup);
    await socket.flush();
    final reply = (await _Reader(socket).line(4096).timeout(const Duration(minutes: 5))).trim();
    return switch (reply) {
      'OK' => SyncOutcome.done,
      'CODE' => SyncOutcome.wrongCode,
      'FULL' => SyncOutcome.refused,
      _ => SyncOutcome.failed,
    };
  } on Object {
    return SyncOutcome.failed;
  } finally {
    socket?.destroy();
  }
}

/// Reads a line, then a number of bytes, from a socket.
class _Reader {
  _Reader(Stream<Uint8List> stream) {
    // Kept to the end: cancelling a socket's subscription would also close it for the answer.
    stream.listen(
      (chunk) {
        _buffer.add(chunk);
        _wake();
      },
      onDone: () {
        _done = true;
        _wake();
      },
      onError: (Object _) {
        _done = true;
        _wake();
      },
    );
  }

  final _buffer = BytesBuilder(copy: false);
  bool _done = false;
  Completer<void>? _waiting;

  void _wake() {
    _waiting?.complete();
    _waiting = null;
  }

  Future<void> _more() {
    if (_done) throw const SocketException('closed');
    return (_waiting = Completer<void>()).future;
  }

  /// Up to the first "\n" (not included); fails past [max] bytes.
  Future<String> line(int max) async {
    while (true) {
      final data = _buffer.toBytes();
      final end = data.indexOf(10);
      if (end >= 0) {
        _buffer.clear();
        _buffer.add(data.sublist(end + 1));
        return utf8.decode(data.sublist(0, end));
      }
      if (data.length > max) throw const FormatException('line too long');
      await _more();
    }
  }

  /// Exactly [count] bytes.
  Future<Uint8List> bytes(int count) async {
    while (_buffer.length < count) {
      await _more();
    }
    final data = _buffer.takeBytes();
    if (data.length > count) _buffer.add(data.sublist(count));
    return Uint8List.sublistView(data, 0, count);
  }
}
