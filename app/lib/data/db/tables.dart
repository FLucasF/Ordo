import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import 'converters.dart';

/// Columns shared by every syncable table: UUID v7 id, UTC created/updated times and
/// soft deletion (the Trash).
///
/// `sortOrder` columns use `integer()`: a native Dart `int` is 64-bit, enough for TickTick's 2^40
/// step (`int64()` would map to `BigInt`, only needed on the web, which the app doesn't target).
mixin SyncedRow on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Set when the item goes to the Trash; "Delete forever" removes the row.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// List folders.
class Folders extends Table with SyncedRow {
  TextColumn get name => text()();
  DateTimeColumn get pinnedAt => dateTime().nullable()();
  BoolColumn get isCollapsed => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer()();

  /// "Áreas" (schema v20): an emoji or icon, a color (`#RRGGBB`) and a background (see
  /// [Lists.background]) of the folder.
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get background => text().nullable()();
}

/// Lists (TickTick "projects").
@DataClassName('TaskList')
class Lists extends Table with SyncedRow {
  TextColumn get name => text()();
  TextColumn get emoji => text().nullable()();

  /// Hex color (`#RRGGBB`) or null ("none").
  TextColumn get color => text().nullable()();
  TextColumn get folderId => text().nullable().references(Folders, #id)();

  /// Sublists (schema v20): the list this one is inside (up to 3 levels); it keeps its parent's folder.
  TextColumn get parentId => text().nullable().references(Lists, #id)();

  /// The list's own background (schema v20): a built-in one's name ("gradient:dawn") or a picture's
  /// file name in the backgrounds folder; null = the app's.
  TextColumn get background => text().nullable()();
  TextColumn get kind => text().map(const TextCodeConverter<ListKind>(ListKind.fromCode)).withDefault(Constant(ListKind.tasks.code))();
  TextColumn get viewMode => text().map(const TextCodeConverter<ViewMode>(ViewMode.fromCode)).withDefault(Constant(ViewMode.list.code))();

  /// "Show in Smart List": whether the list's tasks appear in All/Today/Next 7 days.
  BoolColumn get showInSmartLists => boolean().withDefault(const Constant(true))();
  DateTimeColumn get pinnedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer()();

  // View options of the list.
  TextColumn get groupBy => text().map(const TextCodeConverter<Grouping>(Grouping.fromCode)).withDefault(Constant(Grouping.custom.code))();
  TextColumn get sortBy => text().map(const TextCodeConverter<Sorting>(Sorting.fromCode)).withDefault(Constant(Sorting.custom.code))();
  BoolColumn get showCompleted => boolean().withDefault(const Constant(true))();
  BoolColumn get showDetails => boolean().withDefault(const Constant(false))();
  BoolColumn get dateAsCountdown => boolean().withDefault(const Constant(false))();
}

/// List sections = Kanban columns. A task without a section is "unsectioned".
class Sections extends Table with SyncedRow {
  TextColumn get listId => text().references(Lists, #id)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer()();
}

/// Tasks, notes and subtasks.
class Tasks extends Table with SyncedRow {
  TextColumn get listId => text().references(Lists, #id)();
  TextColumn get sectionId => text().nullable().references(Sections, #id)();

  /// Parent task when this is a subtask (up to 5 levels).
  TextColumn get parentId => text().nullable().references(Tasks, #id)();
  TextColumn get kind => text().map(const TextCodeConverter<TaskKind>(TaskKind.fromCode)).withDefault(Constant(TaskKind.text.code))();
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Markdown content.
  TextColumn get content => text().withDefault(const Constant(''))();
  IntColumn get priority => integer().map(const IntCodeConverter<Priority>(Priority.fromCode)).withDefault(Constant(Priority.none.code))();
  IntColumn get status => integer().map(const IntCodeConverter<TaskStatus>(TaskStatus.fromCode)).withDefault(Constant(TaskStatus.open.code))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Start and due dates in UTC; for all-day tasks, local midnight of [timeZone] converted to UTC.
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(true))();
  TextColumn get timeZone => text().nullable()();

  /// Floating time ignores the time zone (a 9 AM task is at 9 AM in any zone).
  BoolColumn get isFloating => boolean().withDefault(const Constant(false))();
  DateTimeColumn get pinnedAt => dateTime().nullable()();

  /// Checklist progress, 0 to 100.
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer()();

  /// Repetition as an RRULE body (`FREQ=WEEKLY;BYDAY=TH`); `COUNT` = occurrences left (schema v2).
  TextColumn get repeatRule => text().nullable()();

  /// `dueDate` or `completion` (see `RepeatFrom`) (schema v2).
  TextColumn get repeatFrom => text().nullable()();

  /// A snoozed reminder fires again at this UTC time; the due date does not change (schema v3).
  DateTimeColumn get snoozeUntil => dateTime().nullable()();

  /// "Estimativa": Pomos or minutes of focus the task should take; at most one is set
  /// (schema v13).
  IntColumn get estimatedPomos => integer().nullable()();
  IntColumn get estimatedMinutes => integer().nullable()();

  /// Its own color in the calendar (`#RRGGBB`, Google Calendar's event color), over the list's; null =
  /// the default (schema v17).
  TextColumn get color => text().nullable()();
}

/// Task reminders, schema v2. [trigger] is an ISO-8601 duration relative to the due
/// date/time, as TickTick stores it: `PT0S` (on time), `-PT15M`, `-P1D`; for all-day tasks the time of
/// day is part of it, e.g. `PT9H` (on the day at 09:00) or `-PT15H` (one day before at 09:00).
class TaskReminders extends Table {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get trigger => text()();

  @override
  Set<Column<Object>> get primaryKey => {taskId, trigger};
}

/// Checklist-mode items.
class ChecklistItems extends Table with SyncedRow {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get title => text().withDefault(const Constant(''))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer()();

  /// Reminder of the item ("Lembrete em item de checklist"), UTC; all-day items remind
  /// at 09:00 (schema v4).
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(true))();
}

/// Tags, nestable through [parentId].
class Tags extends Table with SyncedRow {
  TextColumn get name => text().unique()();
  TextColumn get color => text().nullable()();
  TextColumn get parentId => text().nullable().references(Tags, #id)();
  DateTimeColumn get pinnedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer()();
}

/// Task × tag relation.
class TaskTags extends Table {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column<Object>> get primaryKey => {taskId, tagId};
}

/// Settings. The value is JSON; typed access goes through the preferences repository,
/// which validates each key. Nothing else reads this table directly.
class Preferences extends Table {
  TextColumn get name => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

/// Task templates, schema v5: title, content, checklist items and tags that a new
/// task copies ("Adicionar a partir do modelo").
@DataClassName('TaskTemplate')
class Templates extends Table with SyncedRow {
  TextColumn get name => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get kind => text().map(const TextCodeConverter<TaskKind>(TaskKind.fromCode)).withDefault(Constant(TaskKind.text.code))();

  /// Checklist items, one per line.
  TextColumn get items => text().withDefault(const Constant(''))();

  /// Tag ids, comma separated.
  TextColumn get tagIds => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer()();
}

/// Task comments, schema v6.
class Comments extends Table with SyncedRow {
  TextColumn get taskId => text().references(Tasks, #id)();
  TextColumn get body => text()();
}

/// Countdowns, schema v7. [date] is the local day at UTC midnight (a calendar date, not an
/// instant); [reminders] are ISO-8601 triggers from that day's midnight, comma separated.
class Countdowns extends Table with SyncedRow {
  TextColumn get name => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type =>
      text().map(const TextCodeConverter<CountdownType>(CountdownType.fromCode)).withDefault(Constant(CountdownType.countdown.code))();
  TextColumn get countMode => text().map(const TextCodeConverter<CountMode>(CountMode.fromCode)).withDefault(Constant(CountMode.standard.code))();
  BoolColumn get ignoreYear => boolean().withDefault(const Constant(false))();
  BoolColumn get showAge => boolean().withDefault(const Constant(false))();
  TextColumn get reminders => text().withDefault(const Constant(''))();
  TextColumn get repeatRule => text().nullable()();
  TextColumn get visibility => text()
      .map(const TextCodeConverter<CountdownVisibility>(CountdownVisibility.fromCode))
      .withDefault(Constant(CountdownVisibility.onTheDay.code))();

  /// Card layout (0-5) and color (hex).
  IntColumn get style => integer().withDefault(const Constant(0))();
  TextColumn get color => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get pinnedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer()();

  /// Emoji or text shown before the name, and the background picture's file name,
  /// schema v12.
  TextColumn get icon => text().nullable()();

  /// Background of a "Texto" icon (one letter on a colored circle), `#RRGGBB`.
  TextColumn get iconColor => text().nullable()();
  TextColumn get image => text().nullable()();

  /// "Modo de Contagem": Cronômetro counts up from the date instead of down to the
  /// next occurrence (schema v14).
  BoolColumn get countUp => boolean().withDefault(const Constant(false))();

  /// The project it counts down to (schema v20): a list or a folder, for its dashboard.
  TextColumn get listId => text().nullable()();
  TextColumn get folderId => text().nullable()();

  /// When the project was closed (or its day came), and its final report frozen then as JSON.
  DateTimeColumn get closedAt => dateTime().nullable()();
  TextColumn get report => text().nullable()();

  /// What it follows instead of a date (schema v21): a habit's streak, or that of a habit section
  /// (days in a row with all its habits done), toward [goalDays] days in a row.
  TextColumn get habitId => text().nullable()();
  TextColumn get habitSection => text().nullable()();
  IntColumn get goalDays => integer().nullable()();
}

/// Focus sessions ("Foco em registro"), schema v8. Times in UTC; [seconds] is the
/// focused time (pauses left out).
class FocusRecords extends Table with SyncedRow {
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get seconds => integer()();
  TextColumn get mode => text().map(const TextCodeConverter<FocusMode>(FocusMode.fromCode)).withDefault(Constant(FocusMode.pomo.code))();

  /// Linked task (or, from the Habits phase, habit), and the saved timer that ran it.
  TextColumn get taskId => text().nullable()();
  TextColumn get timerId => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// Habits, schema v9. [startDate] is a calendar day at UTC midnight.
class Habits extends Table with SyncedRow {
  TextColumn get name => text()();

  /// "Frase motivacional", shown under the name (schema v15).
  TextColumn get motto => text().withDefault(const Constant(''))();

  /// Emoji or one letter, on [color].
  TextColumn get icon => text().withDefault(const Constant(''))();
  TextColumn get color => text().nullable()();
  TextColumn get frequency =>
      text().map(const TextCodeConverter<HabitFrequency>(HabitFrequency.fromCode)).withDefault(Constant(HabitFrequency.daily.code))();

  /// Daily: the weekdays (1 = Monday … 7 = Sunday), comma separated; empty = every day.
  TextColumn get weekdays => text().withDefault(const Constant(''))();

  /// Weekly: times per week. Interval: every N days.
  IntColumn get perWeek => integer().withDefault(const Constant(3))();
  IntColumn get everyDays => integer().withDefault(const Constant(2))();
  TextColumn get goal => text().map(const TextCodeConverter<HabitGoal>(HabitGoal.fromCode)).withDefault(Constant(HabitGoal.checkIn.code))();
  RealColumn get goalAmount => real().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant(''))();
  TextColumn get checkMode =>
      text().map(const TextCodeConverter<HabitCheckMode>(HabitCheckMode.fromCode)).withDefault(Constant(HabitCheckMode.auto.code))();

  /// Amount added by each "Automático" check-in.
  RealColumn get step => real().withDefault(const Constant(1))();
  DateTimeColumn get startDate => dateTime()();

  /// "Dias de meta"; null = "Para sempre".
  IntColumn get targetDays => integer().nullable()();
  TextColumn get section => text().withDefault(const Constant('others'))();

  /// Reminder times "HH:mm", comma separated.
  TextColumn get reminders => text().withDefault(const Constant(''))();
  BoolColumn get autoShowLog => boolean().withDefault(const Constant(false))();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer()();

  /// The habit's tags (the tasks' tags), their ids comma separated (schema v21).
  TextColumn get tags => text().withDefault(const Constant(''))();
}

/// One day of a habit: the amount done (1 for a simple check-in), a manual
/// mark, and the "Registro de hábitos" (mood 1-5 and note).
@DataClassName('HabitCheckin')
class HabitCheckins extends Table with SyncedRow {
  TextColumn get habitId => text().references(Habits, #id)();
  DateTimeColumn get day => dateTime()();
  RealColumn get value => real().withDefault(const Constant(0))();
  TextColumn get mark => text().map(const TextCodeConverter<HabitMark>(HabitMark.fromCode)).withDefault(Constant(HabitMark.none.code))();
  IntColumn get mood => integer().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// Custom filters, smart lists of the user, schema v10. [rule] is a [FilterRule] as JSON.
@DataClassName('TaskFilter')
class Filters extends Table with SyncedRow {
  TextColumn get name => text()();
  TextColumn get rule => text()();
  DateTimeColumn get pinnedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer()();
}

/// "Atividades" of tasks and lists, schema v11. [detail] holds the new value
/// (title, list id, date, priority code) when the action has one.
class Activities extends Table with SyncedRow {
  TextColumn get taskId => text().nullable()();
  TextColumn get listId => text().nullable()();
  TextColumn get action => text().map(const TextCodeConverter<ActivityAction>(ActivityAction.fromCode))();
  TextColumn get detail => text().withDefault(const Constant(''))();
}
