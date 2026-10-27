import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/data/sync/sync_crypto.dart';

Uint8List _hex(String s) {
  final clean = s.replaceAll(RegExp(r'[^0-9a-f]'), '');
  return Uint8List.fromList([for (var i = 0; i < clean.length; i += 2) int.parse(clean.substring(i, i + 2), radix: 16)]);
}

void main() {
  final key = Uint8List.fromList(List.generate(32, (i) => i));

  test('ChaCha20 block function: RFC 8439 §2.3.2', () {
    final block = chacha20Block(key, 1, _hex('00 00 00 09 00 00 00 4a 00 00 00 00'));
    expect(block.sublist(0, 16), _hex('10 f1 e7 e4 d1 3b 59 15 50 0f dd 1f a3 20 71 c4'));
  });

  test('ChaCha20 encryption: RFC 8439 §2.4.2, and back', () {
    final nonce = _hex('00 00 00 00 00 00 00 4a 00 00 00 00');
    final plain = Uint8List.fromList(
      utf8.encode("Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."),
    );
    final cipher = chacha20(key, nonce, plain);
    expect(cipher.sublist(0, 16), _hex('6e 2e 35 9a 25 68 f9 80 41 ba 07 28 dd 0d 69 81'));
    expect(chacha20(key, nonce, cipher), plain);
  });

  test('Diffie-Hellman: both sides get the same secret; a bad public value is refused', () {
    final a = DhKeyPair(), b = DhKeyPair();
    final fromA = a.shared(bigIntFromBytes(bigIntBytes(b.public)));
    final fromB = b.shared(a.public);
    expect(fromA, isNotNull);
    expect(sameBytes(fromA!, fromB!), isTrue);
    expect(a.shared(BigInt.one), isNull);
  });
}
