import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/domain/recurrence.dart';
import 'package:task_manager/features/date_picker/custom_repeat_dialog.dart';
import 'package:task_manager/l10n/app_localizations.dart';

void main() {
  // Friday, 2026-09-25.
  final day = DateTime(2026, 9, 25);

  Future<({String rule, RepeatFrom from})?> open(WidgetTester tester, String? rule, Future<void> Function() act) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ({String rule, RepeatFrom from})? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(dark: false),
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showCustomRepeatDialog(context, rule: rule, from: RepeatFrom.dueDate, day: day, now: day),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await act();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('a new one opens weekly with the days of the week; a tap adds a day', (tester) async {
    final r = await open(tester, null, () async {
      expect(find.text('Sex'), findsOneWidget);
      await tester.tap(find.text('Seg'));
      await tester.pump();
    });
    expect(r!.rule, 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,FR');
  });

  testWidgets('from "every day", a weekday makes it weekly on that day; "Dias úteis" picks Monday to Friday', (tester) async {
    var r = await open(tester, 'FREQ=DAILY;INTERVAL=1', () async {
      await tester.tap(find.text('Qua'));
      await tester.pump();
    });
    expect(r!.rule, 'FREQ=WEEKLY;INTERVAL=1;BYDAY=WE');
    r = await open(tester, 'FREQ=DAILY;INTERVAL=1', () async {
      await tester.tap(find.text('Dias úteis'));
      await tester.pump();
    });
    expect(r!.rule, 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR');
  });
}
