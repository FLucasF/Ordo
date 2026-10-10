import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/calendar.dart';
import 'package:task_manager/l10n/app_localizations.dart';
import 'package:task_manager/l10n/app_localizations_pt.dart';
import 'package:task_manager/platform/calendar_home_widget.dart';

void main() {
  test('the widget gets each day with its entries: all-day ones first, then by time, in their colors', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 10, 5, 8);
    final repo = Repository(db, clock: FixedClock(now));
    await repo.createTask(listId: inboxListId, title: 'Reunião', dueDate: DateTime(2026, 10, 6, 15), isAllDay: false);
    await repo.createTask(listId: inboxListId, title: 'Café', dueDate: DateTime(2026, 10, 6, 9), isAllDay: false);
    await repo.createTask(
      listId: inboxListId,
      title: 'Trabalho',
      startDate: DateTime(2026, 10, 6, 8),
      dueDate: DateTime(2026, 10, 6, 12),
      isAllDay: false,
    );
    await repo.createTask(
      listId: inboxListId,
      title: 'Plantão',
      startDate: DateTime(2026, 10, 6, 22),
      dueDate: DateTime(2026, 10, 7, 6),
      isAllDay: false,
    );
    await repo.createTask(listId: inboxListId, title: 'Aniversário', dueDate: DateTime(2026, 10, 6));
    await repo.createTask(listId: inboxListId, title: 'Longe demais', dueDate: DateTime(2027, 6, 1));
    final snapshot = await repo.loadSnapshot();
    final AppLocalizations t = AppLocalizationsPt();
    final data = calendarWidgetData(
      snapshot: snapshot,
      options: const CalendarOptions(),
      subscriptions: const [],
      colors: buildTheme(dark: true).extension<TtColors>()!,
      t: t,
      now: now,
    );
    final days = data['days']! as Map<String, Object?>;
    final tuesday = days['2026-10-06']! as List<Object?>;
    expect([for (final e in tuesday) (e! as Map)['t']], ['Aniversário', 'Trabalho', 'Café', 'Reunião', 'Plantão']);
    expect([for (final e in tuesday) (e! as Map)['s']], [-1, 8 * 60, 9 * 60, 15 * 60, 22 * 60]);
    // The end: that day's (a task without a duration takes the calendar's 30 minutes), midnight when it goes on.
    expect([for (final e in tuesday) (e! as Map)['e']], [-1, 12 * 60, 9 * 60 + 30, 15 * 60 + 30, 24 * 60]);
    // The next day it is there all day.
    final wednesday = [for (final e in days['2026-10-07']! as List<Object?>) e! as Map];
    expect([for (final e in wednesday) (e['t'], e['s'], e['e'])], [('Plantão', -1, -1)]);
    expect((tuesday.first! as Map)['c'], matches(RegExp(r'^#[0-9A-F]{6}$')));
    expect(days.containsKey('2027-06-01'), isFalse, reason: 'beyond the four months written');
    final labels = data['labels']! as Map<String, Object?>;
    expect((labels['months']! as List).first, 'janeiro');
    expect(labels['month'], 'Mês');
  });
}
