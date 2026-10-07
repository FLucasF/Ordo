import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/domain/views.dart';
import 'package:task_manager/features/date_picker/date_picker.dart';
import 'package:task_manager/features/tasks/quick_add_modal.dart';

void main() {
  testWidgets('phone: the quick add with a date fits (tools on a line, Cancelar and Adicionar below)', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 5, 12)))],
        child: const TasksApp(initialLocation: '/calendar/d'),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    showQuickAddModal(
      tester.element(find.byType(Scaffold).first),
      target: const AddTarget(listId: inboxListId, hint: AddPlainHint()),
      schedule: DateSelection(dueDate: DateTime(2026, 10, 6)),
    ).ignore();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    final add = tester.getRect(find.text('Adicionar'));
    final date = tester.getRect(find.textContaining('out'));
    expect(add.top, greaterThan(date.top), reason: 'Adicionar goes under the tools');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  });
}
