import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/features/common/feedback.dart';
import 'package:task_manager/l10n/app_localizations.dart';

void main() {
  testWidgets('a toast with Desfazer goes away on its own, after a few seconds', (tester) async {
    var undone = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showToast(context, 'Lançamento excluído', undo: () async => undone = true),
              child: const Text('apagar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apagar'));
    await tester.pumpAndSettle();
    expect(find.text('Desfazer'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Desfazer'), findsOneWidget, reason: 'still there to be reached');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Lançamento excluído'), findsNothing);
    expect(undone, isFalse);
  });
}
