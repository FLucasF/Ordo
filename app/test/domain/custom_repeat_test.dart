import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/custom_repeat.dart';
import 'package:task_manager/domain/recurrence.dart';

void main() {
  // Friday, 2026-09-25 (the 4th Friday of the month).
  final day = DateTime(2026, 9, 25);

  CustomRepeatDraft draft([String? rule, RepeatFrom from = RepeatFrom.dueDate]) => CustomRepeatDraft.fromRule(rule, from, day);

  test('defaults come from the task date', () {
    final d = draft();
    expect(d.weekdays, {DateTime.friday});
    expect(d.monthDays, {25});
    expect((d.ordinal, d.weekday), (4, DateTime.friday));
    // A new one by due date starts weekly on the task's weekday; by completion, daily.
    expect(d.toRule(), 'FREQ=WEEKLY;INTERVAL=1;BYDAY=FR');
    expect(draft(null, RepeatFrom.completion).toRule(), 'FREQ=DAILY;INTERVAL=1');
  });

  test('builds every variant', () {
    final d = draft()
      ..unit = RepeatUnit.week
      ..interval = 2
      ..weekdays = {DateTime.sunday, DateTime.monday};
    expect(d.toRule(), 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,SU');

    d
      ..unit = RepeatUnit.month
      ..interval = 1
      ..monthDays = {-1, 15, 1};
    expect(d.toRule(), 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=1,15,-1');
    d.monthlyKind = MonthlyKind.onWeekday;
    expect(d.toRule(), 'FREQ=MONTHLY;INTERVAL=1;BYDAY=4FR');
    d
      ..monthlyKind = MonthlyKind.workday
      ..firstWorkday = false;
    expect(d.toRule(), 'FREQ=MONTHLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1');

    d
      ..unit = RepeatUnit.year
      ..monthlyKind = MonthlyKind.each;
    expect(d.toRule(), 'FREQ=YEARLY;INTERVAL=1;BYMONTH=9;BYMONTHDAY=25');
    d
      ..monthlyKind = MonthlyKind.onWeekday
      ..month = 11
      ..ordinal = 4
      ..weekday = DateTime.thursday;
    expect(d.toRule(), 'FREQ=YEARLY;INTERVAL=1;BYMONTH=11;BYDAY=4TH');

    d.mode = RepeatBasis.completion;
    expect(d.toRule(), 'FREQ=MONTHLY;INTERVAL=1', reason: 'no years nor days by completion');
    expect(d.repeatFrom, RepeatFrom.completion);

    d
      ..mode = RepeatBasis.specificDates
      ..dates = {};
    expect(d.toRule(), isNull);
    d.dates = {DateTime(2026, 10, 3), DateTime(2026, 9, 30)};
    expect(d.toRule(), 'DATES=20260930,20261003');
  });

  test('reads back what it builds', () {
    for (final rule in [
      'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,SU',
      'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=1,15,-1',
      'FREQ=MONTHLY;INTERVAL=3;BYDAY=-1SA',
      'FREQ=MONTHLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=1',
      'FREQ=YEARLY;INTERVAL=1;BYMONTH=11;BYDAY=4TH',
      'FREQ=YEARLY;INTERVAL=1;BYMONTH=2;BYMONTHDAY=29',
      'DATES=20260930,20261003',
    ]) {
      expect(draft(rule).toRule(), rule);
      expect(isValidRule(rule), isTrue, reason: rule);
    }
    expect(draft('FREQ=DAILY;INTERVAL=3', RepeatFrom.completion).mode, RepeatBasis.completion);
  });
}
