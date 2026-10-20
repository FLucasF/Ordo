import 'recurrence.dart';

/// How a custom repetition is counted ("Personalizado").
enum RepeatBasis { dueDate, completion, specificDates }

enum RepeatUnit {
  day('DAILY'),
  week('WEEKLY'),
  month('MONTHLY'),
  year('YEARLY');

  const RepeatUnit(this.freq);
  final String freq;
}

/// Monthly and yearly variants: "Cada" (days of the month), "No" (Nth weekday), "Dia útil" (monthly only).
enum MonthlyKind { each, onWeekday, workday }

/// RRULE weekday codes indexed by [DateTime.weekday] - 1.
const byDayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// Google's monthly choices by weekday: "na quarta sexta-feira" (BYDAY=4FR) and, in the month's last
/// week, "na última sexta-feira" (BYDAY=-1FR).
({int nth, bool last}) weekdayInMonth(DateTime day) {
  final daysInMonth = DateTime(day.year, day.month + 1, 0).day;
  return (nth: (day.day - 1) ~/ 7 + 1, last: day.day + 7 > daysInMonth);
}

/// Form state of the "Personalizado" repetition dialog, convertible to and from the stored rule.
class CustomRepeatDraft {
  CustomRepeatDraft._(DateTime day)
    : weekdays = {day.weekday},
      monthDays = {day.day},
      ordinal = day.day > 28 ? -1 : (day.day - 1) ~/ 7 + 1,
      weekday = day.weekday,
      month = day.month,
      monthDay = day.day,
      dates = {DateTime(day.year, day.month, day.day)};

  /// Draft for [rule] (null or a preset: defaults taken from [day], the task's date).
  factory CustomRepeatDraft.fromRule(String? rule, RepeatFrom from, DateTime day) {
    final draft = CustomRepeatDraft._(day);
    if (rule == null) {
      // By due date it starts weekly, on the task's weekday: the days of the week in sight at once.
      if (from == RepeatFrom.completion) {
        draft.mode = RepeatBasis.completion;
      } else {
        draft.unit = RepeatUnit.week;
      }
      return draft;
    }
    final dates = specificDates(rule);
    if (dates != null) {
      draft
        ..mode = RepeatBasis.specificDates
        ..dates = dates.toSet();
      return draft;
    }
    draft.skipWeekends = skipsWeekends(rule);
    final parts = {
      for (final p in rule.split(';'))
        if (p.split('=') case [final key, final value]) key: value,
    };
    draft
      ..mode = from == RepeatFrom.completion ? RepeatBasis.completion : RepeatBasis.dueDate
      ..unit = RepeatUnit.values.where((u) => u.freq == parts['FREQ']).firstOrNull ?? RepeatUnit.day
      ..interval = int.tryParse(parts['INTERVAL'] ?? '') ?? 1;
    if (parts['BYMONTH'] case final String m) draft.month = int.tryParse(m) ?? draft.month;
    final byDay = parts['BYDAY'];
    final nthWeekday = byDay == null ? null : RegExp(r'^(-?\d)([A-Z]{2})$').firstMatch(byDay);
    if (parts['BYSETPOS'] case final String pos) {
      draft
        ..monthlyKind = MonthlyKind.workday
        ..firstWorkday = pos != '-1';
    } else if (nthWeekday != null) {
      draft
        ..monthlyKind = MonthlyKind.onWeekday
        ..ordinal = int.parse(nthWeekday.group(1)!)
        ..weekday = byDayCodes.indexOf(nthWeekday.group(2)!) + 1;
    } else if (byDay != null) {
      draft.weekdays = {for (final code in byDay.split(',')) byDayCodes.indexOf(code) + 1}..remove(0);
    }
    if (parts['BYMONTHDAY'] case final String days) {
      final list = [for (final d in days.split(',')) ?int.tryParse(d)];
      draft
        ..monthDays = list.toSet()
        ..monthDay = list.firstOrNull ?? draft.monthDay;
    }
    return draft;
  }

  RepeatBasis mode = RepeatBasis.dueDate;
  int interval = 1;
  RepeatUnit unit = RepeatUnit.day;

  /// Weekly: [DateTime.weekday] values.
  Set<int> weekdays;
  MonthlyKind monthlyKind = MonthlyKind.each;

  /// Monthly "Cada": days 1–31, -1 = "Último dia".
  Set<int> monthDays;

  /// "No": 1–4, -1 = "último"; with [weekday].
  int ordinal;
  int weekday;

  /// Monthly "Dia útil": first or last workday.
  bool firstWorkday = true;

  /// Yearly: month and, for "Cada", the day.
  int month;
  int monthDay;

  /// "Por datas específicas".
  Set<DateTime> dates;

  /// "Pular finais de semana": a Saturday or Sunday occurrence moves to Monday.
  bool skipWeekends = false;

  /// Where the dialog offers "Pular finais de semana": monthly by due date
  /// ("Cada" and "No") and daily by completion.
  bool get canSkipWeekends =>
      (mode == RepeatBasis.dueDate && unit == RepeatUnit.month && monthlyKind != MonthlyKind.workday) ||
      (mode == RepeatBasis.completion && unit == RepeatUnit.day);

  RepeatFrom get repeatFrom => mode == RepeatBasis.completion ? RepeatFrom.completion : RepeatFrom.dueDate;

  /// The rule to store, or null when nothing valid is chosen (no specific dates).
  String? toRule() {
    if (mode == RepeatBasis.specificDates) return dates.isEmpty ? null : specificDatesRule(dates);
    final rule = _rrule();
    return canSkipWeekends && skipWeekends ? withSkipWeekends(rule, skip: true) : rule;
  }

  String _rrule() {
    final effectiveUnit = mode == RepeatBasis.completion && unit == RepeatUnit.year ? RepeatUnit.month : unit;
    final base = 'FREQ=${effectiveUnit.freq};INTERVAL=${interval < 1 ? 1 : interval}';
    // By completion date there is no choice of days.
    if (mode == RepeatBasis.completion) return base;
    String nth(int n, int wd) => '$n${byDayCodes[wd - 1]}';
    return switch (effectiveUnit) {
      RepeatUnit.day => base,
      RepeatUnit.week =>
        weekdays.isEmpty
            ? base
            : '$base;BYDAY=${[for (var d = 1; d <= 7; d++)
                if (weekdays.contains(d)) byDayCodes[d - 1]].join(',')}',
      RepeatUnit.month => switch (monthlyKind) {
        MonthlyKind.each => '$base;BYMONTHDAY=${_sortedMonthDays().join(',')}',
        MonthlyKind.onWeekday => '$base;BYDAY=${nth(ordinal, weekday)}',
        MonthlyKind.workday => '$base;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=${firstWorkday ? 1 : -1}',
      },
      RepeatUnit.year =>
        monthlyKind == MonthlyKind.onWeekday ? '$base;BYMONTH=$month;BYDAY=${nth(ordinal, weekday)}' : '$base;BYMONTH=$month;BYMONTHDAY=$monthDay',
    };
  }

  List<int> _sortedMonthDays() {
    final days = monthDays.isEmpty ? {monthDay} : monthDays;
    return [...days.where((d) => d > 0).toList()..sort(), if (days.contains(-1)) -1];
  }
}
