import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/features/detail/content_editor.dart';
import 'package:task_manager/l10n/app_localizations.dart';

void main() {
  testWidgets('the notes box follows the text without dropping small at each key, and shrinks when lines go', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(dark: true),
        locale: const Locale('pt', 'BR'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Scaffold(
          body: SingleChildScrollView(
            child: ContentEditor(markdown: 'uma\n\nduas\n\ntrês\n\nquatro', placeholder: '', onChanged: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;
    double height() => tester.getSize(find.byType(AppFlowyEditor)).height;
    final four = height();
    expect(four, greaterThan(4 * 18));

    // Typing on the last line: after every key (and its frames) the box keeps the four lines.
    final heights = <double>[];
    for (var i = 0; i < 6; i++) {
      final last = editor.document.root.children.last;
      await editor.apply(editor.transaction..insertText(last, last.delta!.length, 'x'));
      await tester.pump();
      heights.add(height());
      await tester.pump();
      heights.add(height());
    }
    expect(heights.every((h) => (h - four).abs() < 1), isTrue, reason: 'heights while typing: $heights');

    // A new line makes it taller; deleting two lines makes it shorter.
    await editor.apply(editor.transaction..insertNode([4], paragraphNode(text: 'cinco')));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final five = height();
    expect(five, greaterThan(four));
    await editor.apply(editor.transaction..deleteNodes([editor.document.nodeAtPath([4])!, editor.document.nodeAtPath([3])!]));
    await tester.pump();
    await tester.pump();
    expect(height(), lessThan(four));
    expect(tester.takeException(), isNull);
  });
}
