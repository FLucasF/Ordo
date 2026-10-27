import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/features/settings/notification_settings.dart';
import 'package:task_manager/features/settings/settings_dialog.dart';
import 'package:task_manager/platform/desktop_shell.dart';

void main() {
  testWidgets('Notificações: the mini calendar is a switch that follows the window', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    debugShowDesktopSettings = true;
    addTearDown(() {
      debugShowDesktopSettings = false;
      DesktopShell.miniCalendarOpen.value = false;
    });
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 20, 12)))],
        child: const TasksApp(initialLocation: '/q/today/tasks'),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    unawaited(showSettings(tester.element(find.byType(Scaffold).first), tab: SettingsTab.notifications));
    await tester.pumpAndSettle();
    final tile = find.widgetWithText(SwitchListTile, 'Mini calendário');
    await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).last);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(DesktopShell.miniCalendarOpen.value, isTrue);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    // Closed from its own × (the runner tells): the switch turns off.
    DesktopShell.miniCalendarOpen.value = false;
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  });
}
