import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/features/common/emoji_data.dart';
import 'package:task_manager/features/common/emoji_picker.dart';
import 'package:task_manager/l10n/app_localizations.dart';

void main() {
  test('every emoji of Unicode 15.1, skin tones included, each with its Portuguese words', () {
    final all = [for (final c in emojiCategories) ...c];
    expect(emojiCategories, hasLength(8));
    expect(all.length, greaterThan(3700));
    expect(all.toSet(), hasLength(all.length), reason: 'no emoji twice');
    expect(all.where((e) => !e.contains(' ')), isEmpty, reason: 'every one can be found');
    // The thumbs up in its five skin tones too, and Brazil's flag.
    expect(all.where((e) => e.startsWith('👍')), hasLength(6));
    expect(emojiCategories.last.any((e) => e.startsWith('🇧🇷')), isTrue);
  });

  testWidgets('emoji picker: categories, search in Portuguese without accents, Redefinir', (tester) async {
    String? picked = 'none';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(dark: true),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Builder(
          builder: (context) => TextButton(onPressed: () async => picked = await showEmojiPicker(context), child: const Text('abrir')),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Pessoas e Corpo'), findsOneWidget);
    expect(find.text('😀'), findsOneWidget);
    await tester.tap(find.byTooltip('Comida'));
    await tester.pumpAndSettle();
    expect(find.text('🍇'), findsOneWidget);

    // CLDR's words: "joinha" (the old list's) and "polegar" (Unicode's) find the thumbs up and its tones.
    await tester.enterText(find.byType(TextField), 'joinha');
    await tester.pumpAndSettle();
    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('👍'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'polegar para cima');
    await tester.pumpAndSettle();
    expect(find.text('👍🏽'), findsOneWidget);
    // Everyday words too, and an emoji pasted from elsewhere finds itself.
    await tester.enterText(find.byType(TextField), 'envergonhado');
    await tester.pumpAndSettle();
    expect(find.text('😳'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '😳');
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(GridView), matching: find.text('😳')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Cafe');
    await tester.pumpAndSettle();
    await tester.tap(find.text('☕'));
    await tester.pumpAndSettle();
    expect(picked, '☕');

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redefinir'));
    await tester.pumpAndSettle();
    expect(picked, '');
  });
}
