import 'dart:convert';

import '../core/clock.dart';
import '../data/db/database.dart';
import 'countdown.dart';
import 'enums.dart';
import 'snapshot.dart';

// A countdown linked to a list or an area is a project (schema v20): its dashboard measures the
// project's tasks against the countdown's day. Everything here is pure, for the tests.

/// Whether the countdown counts down to a list or an area.
bool isProject(Countdown c) => c.listId != null || c.folderId != null;

/// The lists of the countdown's project: the list with its sublists, or the area's lists (their
/// sublists share the area). Empty when it is not linked or the list or area is gone.
List<TaskList> projectLists(Snapshot s, Countdown c) {
  if (c.listId case final id?) {
    final l = s.listById[id];
    if (l == null || l.deletedAt != null) return const [];
    return [l, ...s.sublistsDeep(id)];
  }
  if (c.folderId case final id?) {
    final f = s.folderById[id];
    if (f == null || f.deletedAt != null) return const [];
    return [for (final (l, _) in s.listTree(s.activeLists.where((l) => l.folderId == id))) l];
  }
  return const [];
}

/// The project's tasks that count: not deleted, not notes and not "won't do"; subtasks count too.
List<Task> projectTasks(Snapshot s, Countdown c) {
  final ids = {for (final l in projectLists(s, c)) l.id};
  return [
    for (final t in s.tasks)
      if (ids.contains(t.listId) && t.deletedAt == null && t.kind != TaskKind.note && t.status != TaskStatus.wontDo) t,
  ];
}

/// The project's last day: the countdown's day (its next occurrence when it repeats).
DateTime projectDeadline(Countdown c, DateTime now) => countdownStatus(c, now, countUp: false).target;

bool _done(Task t) => t.status == TaskStatus.completed;

DateTime _completedLocal(Task t) => (t.completedAt ?? t.updatedAt).toLocal();

/// Done / total of [tasks].
class ProjectProgress {
  const ProjectProgress({required this.done, required this.total});

  factory ProjectProgress.of(Iterable<Task> tasks) => ProjectProgress(done: tasks.where(_done).length, total: tasks.length);

  final int done;
  final int total;

  int get remaining => total - done;

  /// 0..1; an empty project is at 0.
  double get ratio => total == 0 ? 0 : done / total;
}

/// Progress of one part of the project: a section of a list, or its tasks without a section
/// ([sectionId] null).
class SectionProgress {
  const SectionProgress({required this.listId, required this.sectionId, required this.progress});

  final String listId;
  final String? sectionId;
  final ProjectProgress progress;
}

/// "Tarefas por seção": each list of the project in order, its tasks without a section first and then
/// each section; parts without tasks are left out.
List<SectionProgress> progressBySection(Snapshot s, List<TaskList> lists, List<Task> tasks) => [
  for (final l in lists) ...[
    if (tasks.where((t) => t.listId == l.id && !s.sectionsOf(l.id).any((sec) => sec.id == t.sectionId)).toList() case final loose
        when loose.isNotEmpty)
      SectionProgress(listId: l.id, sectionId: null, progress: ProjectProgress.of(loose)),
    for (final sec in s.sectionsOf(l.id))
      if (tasks.where((t) => t.listId == l.id && t.sectionId == sec.id).toList() case final inSection when inSection.isNotEmpty)
        SectionProgress(listId: l.id, sectionId: sec.id, progress: ProjectProgress.of(inSection)),
  ],
];

/// "Próximas com prazo": open tasks with a due date, the soonest (overdue ones) first.
List<Task> upcomingWithDeadline(Iterable<Task> tasks, {int limit = 5}) =>
    (tasks.where((t) => t.status == TaskStatus.open && t.dueDate != null).toList()..sort((a, b) => a.dueDate!.compareTo(b.dueDate!)))
        .take(limit)
        .toList();

// ------------------------------------------------------------------ accuracy

/// Whether [t] is done by its due date: an all-day task by the end of its day, a timed one by its
/// time.
bool _onTime(Task t) {
  final due = t.dueDate!.toLocal();
  final done = _completedLocal(t);
  return t.isAllDay ? !startOfDay(done).isAfter(startOfDay(due)) : !done.isAfter(due);
}

/// Whether the due date of [t] has passed at [now] (all-day: the day is over).
bool _duePassed(Task t, DateTime now) {
  final due = t.dueDate!.toLocal();
  return t.isAllDay ? startOfDay(now).isAfter(startOfDay(due)) : now.isAfter(due);
}

/// The accuracy of one task: 1 done by its due date, 0.5 done after it, 0 when the due date passed and
/// it is still open. Null when it doesn't count: no due date, or still open with the date ahead.
double? taskAccuracy(Task t, DateTime now) {
  if (t.dueDate == null || t.status == TaskStatus.wontDo) return null;
  if (_done(t)) return _onTime(t) ? 1 : 0.5;
  return _duePassed(t, now) ? 0 : null;
}

/// "Taxa de exatidão": the average of [taskAccuracy] over the tasks that count, how many were on time,
/// late or missed, and the late and missed ones ("atrasadas"), oldest due date first.
class Accuracy {
  const Accuracy({required this.rate, required this.onTime, required this.late, required this.missed, required this.lateTasks});

  factory Accuracy.of(Iterable<Task> tasks, DateTime now) {
    var sum = 0.0, onTime = 0, late = 0, missed = 0;
    final lateTasks = <Task>[];
    for (final t in tasks) {
      final score = taskAccuracy(t, now);
      if (score == null) continue;
      sum += score;
      if (score == 1) {
        onTime++;
      } else {
        score == 0.5 ? late++ : missed++;
        lateTasks.add(t);
      }
    }
    final counted = onTime + late + missed;
    lateTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return Accuracy(rate: counted == 0 ? null : sum / counted, onTime: onTime, late: late, missed: missed, lateTasks: lateTasks);
  }

  /// 0..1; null when no task counts yet.
  final double? rate;
  final int onTime;
  final int late;
  final int missed;
  final List<Task> lateTasks;

  int get counted => onTime + late + missed;
}

// ------------------------------------------------------------------ evolution and pace

/// Tasks completed on each local day from [from] to [to] (both included).
List<int> completionsPerDay(Iterable<Task> tasks, DateTime from, DateTime to) {
  final first = startOfDay(from);
  final days = daysBetween(first, startOfDay(to)) + 1;
  if (days <= 0) return const [];
  final counts = List<int>.filled(days, 0);
  for (final t in tasks.where(_done)) {
    final i = daysBetween(first, startOfDay(_completedLocal(t)));
    if (i >= 0 && i < days) counts[i]++;
  }
  return counts;
}

/// How the recent pace compares with the one needed: green, yellow or red.
enum PaceLevel { onTrack, close, behind }

/// "Ritmo": the tasks per day still needed to finish by the deadline, against the average of the last
/// 7 days.
class Pace {
  const Pace({required this.remaining, required this.daysLeft, required this.perDay, required this.recent, required this.level});

  final int remaining;
  final int daysLeft;

  /// Tasks a day still needed ("faça 2,3 tarefas por dia").
  final double perDay;

  /// Tasks a day done over the last 7 days (today included).
  final double recent;
  final PaceLevel level;
}

/// The pace toward [deadline] (a local day). On the day itself the whole rest is for today; null
/// once the day has passed. The recent pace is on track at or above the one needed, close from 60% of
/// it, behind below.
Pace? projectPace(Iterable<Task> tasks, DateTime deadline, DateTime now) {
  final today = startOfDay(now);
  final ahead = daysBetween(today, startOfDay(deadline));
  if (ahead < 0) return null;
  final daysLeft = ahead < 1 ? 1 : ahead;
  final remaining = tasks.where((t) => t.status == TaskStatus.open).length;
  final perDay = remaining / daysLeft;
  final recent = completionsPerDay(tasks, DateTime(today.year, today.month, today.day - 6), today).fold(0, (a, b) => a + b) / 7;
  final level = remaining == 0 || recent >= perDay
      ? PaceLevel.onTrack
      : recent >= perDay * 0.6
      ? PaceLevel.close
      : PaceLevel.behind;
  return Pace(remaining: remaining, daysLeft: daysLeft, perDay: perDay, recent: recent, level: level);
}

// ------------------------------------------------------------------ final report

/// Trophies of the final report.
enum Trophy {
  /// "Tudo concluído": every task of the project done.
  allDone,

  /// "Tudo no prazo": at least one task with a due date, and none late or missed.
  allOnTime,

  /// "Reta final forte": a project longer than a week, at least 3 tasks done in its last 7 days, and
  /// those days' daily average at or above the whole project's.
  strongFinish,

  /// "Sem atrasos 7 dias": tasks fell due in the last 7 days, and all were done by their due date.
  noLate7,
}

/// The final report ("post-mortem") of a project, frozen as JSON in the countdown when it closes.
class ProjectReport {
  const ProjectReport({
    required this.start,
    required this.end,
    required this.done,
    required this.total,
    required this.accuracy,
    required this.onTime,
    required this.late,
    required this.missed,
    required this.evolution,
    required this.bestDay,
    required this.bestDayCount,
    required this.trophies,
  });

  /// First and last day of the project (local days); [evolution] has one count per day between them,
  /// at most the last [maxDays].
  final DateTime start;
  final DateTime end;
  final int done;
  final int total;
  final double? accuracy;
  final int onTime;
  final int late;
  final int missed;
  final List<int> evolution;

  /// The day with the most tasks done (the first, on a tie); null when none was done.
  final DateTime? bestDay;
  final int bestDayCount;
  final Set<Trophy> trophies;

  static const maxDays = 90;

  /// The first day [evolution] covers.
  DateTime get evolutionStart => DateTime(end.year, end.month, end.day - evolution.length + 1);

  static String _day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDay(Object? raw) {
    if (raw is! String) return null;
    final d = DateTime.tryParse(raw);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  String encode() => jsonEncode({
    'v': 1,
    'start': _day(start),
    'end': _day(end),
    'done': done,
    'total': total,
    'accuracy': accuracy,
    'onTime': onTime,
    'late': late,
    'missed': missed,
    'evolution': evolution,
    'bestDay': bestDay == null ? null : _day(bestDay!),
    'bestDayCount': bestDayCount,
    'trophies': [for (final t in trophies) t.name],
  });

  /// The report stored in a countdown; null when there is none or it can't be read.
  static ProjectReport? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;
      final start = _parseDay(json['start']), end = _parseDay(json['end']);
      if (start == null || end == null) return null;
      int number(String key) => json[key] is num ? (json[key]! as num).toInt() : 0;
      return ProjectReport(
        start: start,
        end: end,
        done: number('done'),
        total: number('total'),
        accuracy: json['accuracy'] is num ? (json['accuracy']! as num).toDouble() : null,
        onTime: number('onTime'),
        late: number('late'),
        missed: number('missed'),
        evolution: [
          if (json['evolution'] case final List<Object?> days)
            for (final d in days) d is num ? d.toInt() : 0,
        ],
        bestDay: _parseDay(json['bestDay']),
        bestDayCount: number('bestDayCount'),
        trophies: {
          if (json['trophies'] case final List<Object?> names)
            for (final n in names) ?Trophy.values.where((t) => t.name == n).firstOrNull,
        },
      );
    } on FormatException {
      return null;
    }
  }
}

/// Freezes the report of a project that ran from [start] to [end] (local days): tasks done after
/// [end] don't count, and due dates are judged once that day is over (a task due on it and still open
/// is missed).
ProjectReport buildProjectReport(List<Task> tasks, {required DateTime start, required DateTime end}) {
  final first = startOfDay(start), last = startOfDay(end);
  final endOfLast = DateTime(last.year, last.month, last.day + 1);
  // As things stood at the end: a task done later is still open then.
  bool doneByEnd(Task t) => _done(t) && !startOfDay(_completedLocal(t)).isAfter(last);
  final asAtEnd = [for (final t in tasks) doneByEnd(t) || !_done(t) ? t : t.copyWith(status: TaskStatus.open)];
  final accuracy = Accuracy.of(asAtEnd, endOfLast);
  final span = first.isAfter(last) ? 1 : daysBetween(first, last) + 1;
  final perDay = completionsPerDay(asAtEnd, DateTime(last.year, last.month, last.day - (span - 1)), last);
  final done = asAtEnd.where(_done).length;

  var best = -1, bestCount = 0;
  for (var i = 0; i < perDay.length; i++) {
    if (perDay[i] > bestCount) (best, bestCount) = (i, perDay[i]);
  }
  final lastWeek = perDay.skip(perDay.length > 7 ? perDay.length - 7 : 0).fold(0, (a, b) => a + b);
  final weekStart = DateTime(last.year, last.month, last.day - 6);
  final dueLastWeek = [
    for (final t in asAtEnd)
      if (t.dueDate case final due? when !startOfDay(due.toLocal()).isBefore(weekStart) && !startOfDay(due.toLocal()).isAfter(last)) t,
  ];
  final trophies = {
    if (asAtEnd.isNotEmpty && done == asAtEnd.length) Trophy.allDone,
    if (accuracy.counted > 0 && accuracy.onTime == accuracy.counted) Trophy.allOnTime,
    if (span > 7 && lastWeek >= 3 && lastWeek / 7 >= done / span) Trophy.strongFinish,
    if (dueLastWeek.isNotEmpty && dueLastWeek.every((t) => taskAccuracy(t, endOfLast) == 1)) Trophy.noLate7,
  };
  final kept = perDay.length > ProjectReport.maxDays ? perDay.sublist(perDay.length - ProjectReport.maxDays) : perDay;
  return ProjectReport(
    start: first.isAfter(last) ? last : first,
    end: last,
    done: done,
    total: asAtEnd.length,
    accuracy: accuracy.rate,
    onTime: accuracy.onTime,
    late: accuracy.late,
    missed: accuracy.missed,
    evolution: kept,
    bestDay: best < 0 ? null : DateTime(last.year, last.month, last.day - (perDay.length - 1 - best)),
    bestDayCount: bestCount,
    trophies: trophies,
  );
}

/// When the project started: the countdown's creation or its first task's, whichever came first.
DateTime projectStart(Countdown c, Iterable<Task> tasks) {
  var start = c.createdAt.toLocal();
  for (final t in tasks) {
    final created = t.createdAt.toLocal();
    if (created.isBefore(start)) start = created;
  }
  return startOfDay(start);
}

/// Whether a linked countdown closes by itself: its day is over, it doesn't repeat and it never had a
/// report (reopening keeps the report, so a reopened project stays open).
bool closesByItself(Countdown c, DateTime now) =>
    isProject(c) &&
    c.closedAt == null &&
    c.report == null &&
    c.repeatRule == null &&
    c.archivedAt == null &&
    startOfDay(now).isAfter(countdownDate(c));
