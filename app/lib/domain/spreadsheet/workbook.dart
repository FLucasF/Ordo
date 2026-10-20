import '../../core/ids.dart';
import '../../data/db/database.dart';
import '../../data/xlsx/xlsx.dart';
import '../enums.dart';
import '../finance/finance_enums.dart';
import '../habits.dart';
import '../task_export.dart' show plainTextOf;

// "Exportar para Excel": one workbook, a sheet per module. The sheet and column names are screen text
// (in the app's language); [WorkbookLabels] gives them, and the import accepts the names of every
// language the app speaks, so a file exported in one imports in the other.

enum WorkbookSheet { tasks, habits, entries, cards, invoicePayments, loans, loanPayments, goals, goalMoves, diet, journal }

enum WorkbookColumn {
  folder,
  list,
  section,
  title,
  notes,
  status,
  priority,
  start,
  due,
  tags,
  created,
  completed,
  habit,
  date,
  value,
  goal,
  unit,
  mood,
  note,
  kind,
  category,
  description,
  card,
  invoice,
  installment,
  closingDay,
  dueDay,
  creditLimit,
  borrower,
  lentOn,
  principal,
  total,
  dueOn,
  installments,
  received,
  savingsGoal,
  saved,
  meal,
  food,
  quantity,
  measure,
  grams,
  kcal,
  protein,
  carbs,
  fat,
  fiber,
  energy,
  highlight,
}

/// The texts of the workbook, in one language.
abstract interface class WorkbookLabels {
  String sheet(WorkbookSheet sheet);
  String column(WorkbookColumn column);
  String taskStatus(TaskStatus status);
  String priority(Priority priority);
  String finKind(FinKind kind);

  /// Done, partial, skipped or failed; empty for the other days.
  String habitState(HabitDayState state);
  /// The label of a built-in meal's id ("breakfast" → "Café da manhã"); null for other ids.
  String? builtInMeal(String id);

  /// The Caixa de Entrada's name.
  String get inbox;
}

/// The columns of each sheet, in order, with their widths.
const workbookColumns = <WorkbookSheet, List<(WorkbookColumn, double)>>{
  WorkbookSheet.tasks: [
    (WorkbookColumn.folder, 16),
    (WorkbookColumn.list, 18),
    (WorkbookColumn.section, 16),
    (WorkbookColumn.title, 40),
    (WorkbookColumn.notes, 50),
    (WorkbookColumn.status, 14),
    (WorkbookColumn.priority, 12),
    (WorkbookColumn.start, 17),
    (WorkbookColumn.due, 17),
    (WorkbookColumn.tags, 20),
    (WorkbookColumn.created, 17),
    (WorkbookColumn.completed, 17),
  ],
  WorkbookSheet.habits: [
    (WorkbookColumn.habit, 26),
    (WorkbookColumn.date, 12),
    (WorkbookColumn.value, 10),
    (WorkbookColumn.goal, 10),
    (WorkbookColumn.unit, 12),
    (WorkbookColumn.status, 14),
    (WorkbookColumn.mood, 8),
    (WorkbookColumn.note, 40),
  ],
  WorkbookSheet.entries: [
    (WorkbookColumn.date, 12),
    (WorkbookColumn.kind, 10),
    (WorkbookColumn.category, 20),
    (WorkbookColumn.description, 36),
    (WorkbookColumn.value, 15),
    (WorkbookColumn.card, 16),
    (WorkbookColumn.invoice, 12),
    (WorkbookColumn.installment, 9),
    (WorkbookColumn.note, 36),
  ],
  WorkbookSheet.cards: [(WorkbookColumn.card, 20), (WorkbookColumn.closingDay, 18), (WorkbookColumn.dueDay, 18), (WorkbookColumn.creditLimit, 15)],
  WorkbookSheet.invoicePayments: [(WorkbookColumn.card, 20), (WorkbookColumn.invoice, 12), (WorkbookColumn.date, 12), (WorkbookColumn.value, 15)],
  WorkbookSheet.loans: [
    (WorkbookColumn.borrower, 24),
    (WorkbookColumn.lentOn, 14),
    (WorkbookColumn.principal, 16),
    (WorkbookColumn.total, 15),
    (WorkbookColumn.dueOn, 13),
    (WorkbookColumn.installments, 9),
    (WorkbookColumn.received, 15),
    (WorkbookColumn.note, 36),
  ],
  WorkbookSheet.loanPayments: [(WorkbookColumn.borrower, 24), (WorkbookColumn.date, 12), (WorkbookColumn.value, 15), (WorkbookColumn.note, 36)],
  WorkbookSheet.goals: [
    (WorkbookColumn.savingsGoal, 24),
    (WorkbookColumn.goal, 15),
    (WorkbookColumn.saved, 15),
    (WorkbookColumn.due, 12),
    (WorkbookColumn.note, 36),
  ],
  WorkbookSheet.goalMoves: [(WorkbookColumn.savingsGoal, 24), (WorkbookColumn.date, 12), (WorkbookColumn.value, 15), (WorkbookColumn.note, 36)],
  WorkbookSheet.diet: [
    (WorkbookColumn.date, 12),
    (WorkbookColumn.meal, 18),
    (WorkbookColumn.food, 36),
    (WorkbookColumn.quantity, 11),
    (WorkbookColumn.measure, 16),
    (WorkbookColumn.grams, 10),
    (WorkbookColumn.kcal, 9),
    (WorkbookColumn.protein, 13),
    (WorkbookColumn.carbs, 13),
    (WorkbookColumn.fat, 13),
    (WorkbookColumn.fiber, 13),
  ],
  WorkbookSheet.journal: [
    (WorkbookColumn.date, 12),
    (WorkbookColumn.mood, 8),
    (WorkbookColumn.energy, 9),
    (WorkbookColumn.notes, 60),
    (WorkbookColumn.highlight, 40),
  ],
};

/// The rows the workbook is made of, read straight from the database (deleted ones included; they are
/// left out here).
class WorkbookData {
  const WorkbookData({
    this.folders = const [],
    this.lists = const [],
    this.sections = const [],
    this.tasks = const [],
    this.checklistItems = const [],
    this.tags = const [],
    this.taskTags = const [],
    this.habits = const [],
    this.habitCheckins = const [],
    this.categories = const [],
    this.cards = const [],
    this.entries = const [],
    this.cardPayments = const [],
    this.loans = const [],
    this.loanPayments = const [],
    this.goals = const [],
    this.goalMoves = const [],
    this.dietMeals = const [],
    this.dietEntries = const [],
    this.journal = const [],
  });

  final List<Folder> folders;
  final List<TaskList> lists;
  final List<Section> sections;
  final List<Task> tasks;
  final List<ChecklistItem> checklistItems;
  final List<Tag> tags;
  final List<TaskTag> taskTags;
  final List<Habit> habits;
  final List<HabitCheckin> habitCheckins;
  final List<FinCategory> categories;
  final List<FinCard> cards;
  final List<FinEntry> entries;
  final List<FinCardPayment> cardPayments;
  final List<Loan> loans;
  final List<LoanPayment> loanPayments;
  final List<FinGoal> goals;
  final List<FinGoalMove> goalMoves;
  final List<DietMeal> dietMeals;
  final List<DietEntry> dietEntries;
  final List<JournalEntry> journal;
}

/// A day kept at UTC midnight (Finanças, Dieta, Diário, Hábitos) as an Excel date.
XlsxDate _day(DateTime stored) => XlsxDate(DateTime(stored.year, stored.month, stored.day));

/// An instant (UTC) in local time, with the time.
XlsxDate _instant(DateTime utc) => XlsxDate(utc.toLocal(), withTime: true);

/// A task's date: the day alone when it is all-day.
XlsxDate _taskDate(DateTime utc, {required bool allDay}) {
  final local = utc.toLocal();
  return allDay ? XlsxDate(DateTime(local.year, local.month, local.day)) : XlsxDate(local, withTime: true);
}

/// Amount of a nutrient in [grams] of a food with [per100g], to one decimal.
double? _nutrient(double? per100g, double grams) => per100g == null ? null : (per100g * grams / 10).round() / 10;

/// The sheets of the workbook, in the app's order.
List<XlsxSheet> buildWorkbook(WorkbookData d, WorkbookLabels l) {
  List<XlsxColumn> columns(WorkbookSheet s) => [for (final (c, width) in workbookColumns[s]!) XlsxColumn(l.column(c), width: width)];
  XlsxSheet sheet(WorkbookSheet s, List<List<Object?>> rows) => XlsxSheet(l.sheet(s), columns(s), rows);
  bool alive(DateTime? deletedAt) => deletedAt == null;

  // Tarefas, list by list in the sidebar's order.
  final lists = {
    for (final x in d.lists)
      if (alive(x.deletedAt)) x.id: x,
  };
  final folders = {for (final f in d.folders) f.id: f.name};
  final sections = {for (final s in d.sections) s.id: s.name};
  final tagNames = {for (final t in d.tags) t.id: t.name};
  final tagsOf = <String, List<String>>{};
  for (final tt in d.taskTags) {
    if (tagNames[tt.tagId] case final name?) (tagsOf[tt.taskId] ??= []).add(name);
  }
  final itemsOf = <String, List<ChecklistItem>>{};
  for (final i in d.checklistItems.where((i) => alive(i.deletedAt))) {
    (itemsOf[i.taskId] ??= []).add(i);
  }
  final tasks = d.tasks.where((t) => alive(t.deletedAt) && lists.containsKey(t.listId)).toList()
    ..sort((a, b) {
      final byList = lists[a.listId]!.sortOrder.compareTo(lists[b.listId]!.sortOrder);
      return byList != 0 ? byList : a.sortOrder.compareTo(b.sortOrder);
    });
  String notesOf(Task t) {
    final items = [...?itemsOf[t.id]]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return [if (t.content.trim().isNotEmpty) plainTextOf(t.content), for (final i in items) '${i.isCompleted ? '☑' : '☐'} ${i.title}'].join('\n');
  }

  final taskRows = [
    for (final t in tasks)
      () {
        final list = lists[t.listId]!;
        final due = t.dueDate;
        final start = t.startDate;
        return <Object?>[
          folders[list.folderId],
          list.id == inboxListId ? l.inbox : list.name,
          sections[t.sectionId],
          t.title,
          notesOf(t),
          l.taskStatus(t.status),
          l.priority(t.priority),
          // The start only when it differs from the due date (a task with one date has both equal).
          if (start != null && due != null && start != due) _taskDate(start, allDay: t.isAllDay) else null,
          if (due != null) _taskDate(due, allDay: t.isAllDay) else null,
          (tagsOf[t.id] ?? const []).join(', '),
          _instant(t.createdAt),
          if (t.completedAt case final c?) _instant(c) else null,
        ];
      }(),
  ];

  // Hábitos: every check-in, habit by habit.
  final habits = {
    for (final h in d.habits)
      if (alive(h.deletedAt)) h.id: h,
  };
  final checkins = d.habitCheckins.where((c) => alive(c.deletedAt) && habits.containsKey(c.habitId)).toList()
    ..sort((a, b) {
      final byHabit = habits[a.habitId]!.sortOrder.compareTo(habits[b.habitId]!.sortOrder);
      return byHabit != 0 ? byHabit : a.day.compareTo(b.day);
    });
  final habitRows = [
    for (final c in checkins)
      () {
        final h = habits[c.habitId]!;
        return <Object?>[
          h.name,
          _day(c.day),
          c.value,
          h.goal == HabitGoal.amount ? h.goalAmount : 1,
          h.unit,
          l.habitState(habitDayState(h, c, habitDay(c.day))),
          c.mood,
          c.note,
        ];
      }(),
  ];

  // Finanças.
  final categories = {for (final c in d.categories) c.id: c.name};
  final cards = {for (final c in d.cards) c.id: c.name};
  final entries = d.entries.where((e) => alive(e.deletedAt)).toList()
    ..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      final byCreation = a.createdAt.compareTo(b.createdAt);
      // Installments of one purchase share both; their number orders them.
      return byCreation != 0 ? byCreation : (a.installmentIndex ?? 0).compareTo(b.installmentIndex ?? 0);
    });
  final entryRows = [
    for (final e in entries)
      <Object?>[
        _day(e.date),
        l.finKind(e.kind),
        categories[e.categoryId],
        e.description,
        XlsxMoney(e.amount),
        cards[e.cardId],
        if (e.invoiceMonth case final m?) _day(m) else null,
        if (e.installmentIndex != null && e.installmentCount != null) '${e.installmentIndex}/${e.installmentCount}' else null,
        e.note,
      ],
  ];
  final cardRows = [
    for (final c in d.cards.where((c) => alive(c.deletedAt)).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
      <Object?>[c.name, c.closingDay, c.dueDay, if (c.creditLimit case final limit?) XlsxMoney(limit) else null],
  ];
  final paymentRows = [
    for (final p in d.cardPayments.where((p) => alive(p.deletedAt)).toList()..sort((a, b) => a.date.compareTo(b.date)))
      <Object?>[cards[p.cardId], _day(p.invoiceMonth), _day(p.date), XlsxMoney(p.amount)],
  ];
  final loans = d.loans.where((x) => alive(x.deletedAt)).toList()..sort((a, b) => a.lentOn.compareTo(b.lentOn));
  final loanNames = {for (final x in d.loans) x.id: x.borrower};
  final loanPayments = d.loanPayments.where((p) => alive(p.deletedAt) && loanNames.containsKey(p.loanId)).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final received = <String, int>{};
  for (final p in loanPayments) {
    received[p.loanId] = (received[p.loanId] ?? 0) + p.amount;
  }
  final loanRows = [
    for (final x in loans)
      <Object?>[
        x.borrower,
        _day(x.lentOn),
        XlsxMoney(x.principal),
        XlsxMoney(x.total),
        _day(x.dueOn),
        x.installments,
        XlsxMoney(received[x.id] ?? 0),
        x.note,
      ],
  ];
  final loanPaymentRows = [
    for (final p in loanPayments) <Object?>[loanNames[p.loanId], _day(p.date), XlsxMoney(p.amount), p.note],
  ];
  final goals = d.goals.where((g) => alive(g.deletedAt)).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final goalNames = {for (final g in d.goals) g.id: g.name};
  final moves = d.goalMoves.where((m) => alive(m.deletedAt) && goalNames.containsKey(m.goalId)).toList()..sort((a, b) => a.date.compareTo(b.date));
  final saved = <String, int>{};
  for (final m in moves) {
    saved[m.goalId] = (saved[m.goalId] ?? 0) + m.amount;
  }
  final goalRows = [
    for (final g in goals)
      <Object?>[g.name, XlsxMoney(g.target), XlsxMoney(saved[g.id] ?? 0), if (g.dueOn case final due?) _day(due) else null, g.note],
  ];
  final moveRows = [
    for (final m in moves) <Object?>[goalNames[m.goalId], _day(m.date), XlsxMoney(m.amount), m.note],
  ];

  // Dieta: the meal's own name, or the built-in one's label.
  final mealOrder = {for (final m in d.dietMeals) m.id: m.sortOrder};
  String mealName(String id) {
    final own = d.dietMeals.where((m) => m.id == id && m.name.isNotEmpty).firstOrNull;
    if (own != null) return own.name;
    return l.builtInMeal(id) ?? id;
  }

  final dietEntries = d.dietEntries.where((e) => alive(e.deletedAt)).toList()
    ..sort((a, b) {
      final byDay = a.day.compareTo(b.day);
      if (byDay != 0) return byDay;
      final byMeal = (mealOrder[a.meal] ?? 0).compareTo(mealOrder[b.meal] ?? 0);
      return byMeal != 0 ? byMeal : a.sortOrder.compareTo(b.sortOrder);
    });
  final dietRows = [
    for (final e in dietEntries)
      <Object?>[
        _day(e.day),
        mealName(e.meal),
        e.name,
        e.quantity,
        e.measureName ?? 'g',
        e.grams,
        _nutrient(e.kcal, e.grams),
        _nutrient(e.protein, e.grams),
        _nutrient(e.carbs, e.grams),
        _nutrient(e.fat, e.grams),
        _nutrient(e.fiber, e.grams),
      ],
  ];
  final journalRows = [
    for (final j in d.journal.where((j) => alive(j.deletedAt)).toList()..sort((a, b) => a.day.compareTo(b.day)))
      <Object?>[_day(j.day), j.mood, j.energy, plainTextOf(j.notes), j.highlight],
  ];

  return [
    sheet(WorkbookSheet.tasks, taskRows),
    sheet(WorkbookSheet.habits, habitRows),
    sheet(WorkbookSheet.entries, entryRows),
    sheet(WorkbookSheet.cards, cardRows),
    sheet(WorkbookSheet.invoicePayments, paymentRows),
    sheet(WorkbookSheet.loans, loanRows),
    sheet(WorkbookSheet.loanPayments, loanPaymentRows),
    sheet(WorkbookSheet.goals, goalRows),
    sheet(WorkbookSheet.goalMoves, moveRows),
    sheet(WorkbookSheet.diet, dietRows),
    sheet(WorkbookSheet.journal, journalRows),
  ];
}
