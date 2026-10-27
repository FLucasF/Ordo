import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

// The sync's cryptography, from standard pieces: Diffie-Hellman on RFC 3526's 2048-bit group to agree
// on a secret when two devices are linked, HMAC-SHA256 to prove who is talking and check every
// message, and ChaCha20 (RFC 8439) to encrypt them. No library beyond `crypto` (SHA-256 / HMAC).

final _random = Random.secure();

/// [length] random bytes.
Uint8List randomBytes(int length) => Uint8List.fromList(List.generate(length, (_) => _random.nextInt(256)));

Uint8List hmacSha256(List<int> key, List<int> message) => Uint8List.fromList(Hmac(sha256, key).convert(message).bytes);

Uint8List sha256Of(List<int> message) => Uint8List.fromList(sha256.convert(message).bytes);

/// Equal byte lists, in a time that doesn't tell where they differ.
bool sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

// ------------------------------------------------------------------ ChaCha20 (RFC 8439)

int _rotl(int v, int n) => ((v << n) | (v >> (32 - n))) & 0xffffffff;

void _quarter(Uint32List s, int a, int b, int c, int d) {
  s[a] = s[a] + s[b];
  s[d] = _rotl(s[d] ^ s[a], 16);
  s[c] = s[c] + s[d];
  s[b] = _rotl(s[b] ^ s[c], 12);
  s[a] = s[a] + s[b];
  s[d] = _rotl(s[d] ^ s[a], 8);
  s[c] = s[c] + s[d];
  s[b] = _rotl(s[b] ^ s[c], 7);
}

/// One 64-byte block of ChaCha20's key stream.
Uint8List chacha20Block(Uint8List key, int counter, Uint8List nonce) {
  assert(key.length == 32 && nonce.length == 12);
  final k = key.buffer.asByteData(key.offsetInBytes), n = nonce.buffer.asByteData(nonce.offsetInBytes);
  final init = Uint32List(16)
    ..[0] = 0x61707865
    ..[1] = 0x3320646e
    ..[2] = 0x79622d32
    ..[3] = 0x6b206574;
  for (var i = 0; i < 8; i++) {
    init[4 + i] = k.getUint32(i * 4, Endian.little);
  }
  init[12] = counter;
  for (var i = 0; i < 3; i++) {
    init[13 + i] = n.getUint32(i * 4, Endian.little);
  }
  final s = Uint32List.fromList(init);
  for (var i = 0; i < 10; i++) {
    _quarter(s, 0, 4, 8, 12);
    _quarter(s, 1, 5, 9, 13);
    _quarter(s, 2, 6, 10, 14);
    _quarter(s, 3, 7, 11, 15);
    _quarter(s, 0, 5, 10, 15);
    _quarter(s, 1, 6, 11, 12);
    _quarter(s, 2, 7, 8, 13);
    _quarter(s, 3, 4, 9, 14);
  }
  final out = ByteData(64);
  for (var i = 0; i < 16; i++) {
    out.setUint32(i * 4, (s[i] + init[i]) & 0xffffffff, Endian.little);
  }
  return out.buffer.asUint8List();
}

/// [data] encrypted (or decrypted: the same operation) with ChaCha20, the block counter from
/// [counter].
Uint8List chacha20(Uint8List key, Uint8List nonce, Uint8List data, {int counter = 1}) {
  final out = Uint8List(data.length);
  for (var offset = 0, block = counter; offset < data.length; offset += 64, block++) {
    final stream = chacha20Block(key, block, nonce);
    final end = min(offset + 64, data.length);
    for (var i = offset; i < end; i++) {
      out[i] = data[i] ^ stream[i - offset];
    }
  }
  return out;
}

// ------------------------------------------------------------------ Diffie-Hellman (RFC 3526, group 14)

final _prime = BigInt.parse(
  'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B22514A08798E3404DD'
  'EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED'
  'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3DC2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F'
  '83655D23DCA3AD961C62F356208552BB9ED529077096966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B'
  'E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF6955817183995497CEA956AE515D2261898FA0510'
  '15728E5A8AACAA68FFFFFFFFFFFFFFFF',
  radix: 16,
);
final _generator = BigInt.two;

/// One side of a Diffie-Hellman exchange: [public] goes to the other device; [shared] turns its public
/// value into the secret both now know.
class DhKeyPair {
  DhKeyPair() : _private = _fromBytes(randomBytes(32)) {
    public = _generator.modPow(_private, _prime);
  }

  final BigInt _private;
  late final BigInt public;

  /// The shared secret, or null when [other] can't be a public value (a broken or hostile peer).
  Uint8List? shared(BigInt other) {
    if (other <= BigInt.one || other >= _prime - BigInt.one) return null;
    return bigIntBytes(other.modPow(_private, _prime));
  }
}

BigInt _fromBytes(List<int> bytes) => bytes.fold(BigInt.zero, (v, b) => (v << 8) | BigInt.from(b));

/// [v] as 256 big-endian bytes (the group's size).
Uint8List bigIntBytes(BigInt v) {
  final out = Uint8List(256);
  var x = v;
  for (var i = 255; i >= 0 && x > BigInt.zero; i--) {
    out[i] = (x & BigInt.from(0xff)).toInt();
    x >>= 8;
  }
  return out;
}

BigInt bigIntFromBytes(List<int> bytes) => _fromBytes(bytes);
