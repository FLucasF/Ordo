import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the ARB has no repeated keys (a repeat silently replaces the first text)', () {
    final raw = File('lib/l10n/app_pt.arb').readAsStringSync();
    // Top-level keys are indented by two spaces; placeholder names live deeper, inside "@key" objects.
    final keys = RegExp(r'^  "([^"]+)"\s*:', multiLine: true).allMatches(raw).map((m) => m.group(1)!).toList();
    final repeated = {for (final k in keys) k: keys.where((x) => x == k).length}..removeWhere((_, n) => n == 1);
    expect(keys, isNotEmpty);
    expect(repeated, isEmpty);
  });

  test('Latin has every text of Portuguese, with the same placeholders, and nothing more', () {
    Map<String, Object?> read(String name) => jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, Object?>;
    final pt = read('app_pt.arb'), la = read('app_la.arb');
    final ptKeys = {for (final k in pt.keys) if (!k.startsWith('@')) k};
    final laKeys = {for (final k in la.keys) if (!k.startsWith('@')) k};
    expect(laKeys.difference(ptKeys), isEmpty, reason: 'texts Portuguese no longer has');
    expect(ptKeys.difference(laKeys), isEmpty, reason: 'texts still to translate');
    // The placeholders each text declares in Portuguese appear in its Latin too.
    for (final MapEntry(:key, :value) in pt.entries) {
      if (!key.startsWith('@') || key.startsWith('@@')) continue;
      final placeholders = ((value! as Map)['placeholders'] as Map?)?.keys ?? const [];
      final text = la[key.substring(1)]! as String;
      for (final name in placeholders) {
        expect(text.contains('{$name'), isTrue, reason: '${key.substring(1)} lost {$name}');
      }
    }
  });
}
