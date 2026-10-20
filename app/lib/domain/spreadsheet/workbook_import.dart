import '../../data/xlsx/xlsx.dart';
import '../diet/diet.dart' show foldForSearch;
import '../enums.dart';
import '../finance/finance_enums.dart';
import '../finance/money.dart';
import '../import/imported_task.dart';
import 'workbook.dart';

// "Importar do Excel": reads Tarefas and Lançamentos from a workbook laid out like the exported one
// (or the user's own, with the same column names). Nothing is written here; the result is the preview
// shown before importing. The other sheets are reported as skipped.

/// A "lançamento" read from a row, before it is written.
class ImportedEntry {
  const ImportedEntry({
    required this.row,
    required this.kind,
    required this.amount,
    required this.date,
    this.description = '',
    this.category,
    this.card,
    this.invoiceMonth,
    this.installmentIndex,
    this.installmentCount,
    this.note = '',
  });

  /// Its row in the sheet.
  final int row;
  final FinKind kind;

  /// Cents, positive.
  final int amount;

  /// The local day.
  final DateTime date;
  final String description;
  final String? category;
  final String? card;

  /// The first day of the invoice's month; null = the one of [date].
  final DateTime? invoiceMonth;
  final int? installmentIndex;
  final int? installmentCount;
  final String note;
}

/// A card of the workbook's "Cartões" sheet, created when an imported entry uses it and the app has
/// no card of that name.
class ImportedCard {
  const ImportedCard({required this.name, required this.closingDay, required this.dueDay, this.creditLimit});
  final String name;
  final int closingDay;
  final int dueDay;
  final int? creditLimit;
}

enum RowProblem { missingColumns, noTitle, badDate, badAmount, badKind, badStatus, badPriority, unknownCard }

/// A row that will not be imported, and why. [detail] is the column, the value or the missing
/// columns, depending on [problem].
class RowError {
  const RowError(this.sheet, this.row, this.problem, [this.detail = '']);
  final WorkbookSheet sheet;
  final int row;
  final RowProblem problem;
  final String detail;

  @override
  String toString() => '${sheet.name}:$row ${problem.name} $detail';
}

/// What the workbook would import.
class WorkbookPreview {
  const WorkbookPreview({
    this.tasks = const [],
    this.entries = const [],
    this.cards = const [],
    this.errors = const [],
    this.skippedSheets = const [],
  });

  final List<ImportedTask> tasks;
  final List<ImportedEntry> entries;
  final List<ImportedCard> cards;
  final List<RowError> errors;

  /// Names of the sheets with rows that are not imported (Hábitos, Dieta…).
  final List<String> skippedSheets;

  bool get isEmpty => tasks.isEmpty && entries.isEmpty;
}

/// Lowercase, without accents nor anything but letters and digits: "Criada em" = "criadaem".
String _key(String text) => foldForSearch(text).replaceAll(RegExp('[^a-z0-9]'), '');

String _text(Object? cell) => switch (cell) {
  null => '',
  final double d when d == d.roundToDouble() && d.abs() < 1e15 => d.round().toString(),
  final bool b => b ? 'TRUE' : 'FALSE',
  _ => '$cell'.trim(),
};

/// A date cell: an Excel serial, or a text "25/09/2026", "25/09/2026 14:30", "2026-09-25" or
/// "2026-09-25T14:30". The bool says whether it had a time. Null when it is not a date.
(DateTime, bool)? parseCellDate(Object? cell) {
  if (cell is double) {
    if (cell < 1 || cell > 2958465) return null;
    final d = fromExcelSerial(cell);
    return (d, d.hour != 0 || d.minute != 0 || d.second != 0);
  }
  final text = _text(cell);
  final br = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?$').firstMatch(text);
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[T\s](\d{1,2}):(\d{2})(?::(\d{2}))?)?$').firstMatch(text);
  final m = br ?? iso;
  if (m == null) return null;
  final (year, month, day) = br != null
      ? (int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!))
      : (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  final hour = int.parse(m[4] ?? '0'), minute = int.parse(m[5] ?? '0'), second = int.parse(m[6] ?? '0');
  if (month < 1 || month > 12 || day < 1 || day > 31 || hour > 23 || minute > 59 || second > 59) return null;
  final date = DateTime(year, month, day, hour, minute, second);
  // 31/02 would roll into March.
  if (date.month != month || date.day != day) return null;
  return (date, m[4] != null);
}

/// A money cell in cents, with its sign: a number (reais) or a text such as "R$ 1.234,56" or "-12,5".
int? parseCellMoney(Object? cell) {
  if (cell is double) return cell.isFinite ? (cell * 100).round() : null;
  var text = _text(cell).replaceAll(RegExp(r'\s'), '');
  final negative = text.startsWith('-') || text.startsWith('R\$-') || (text.startsWith('(') && text.endsWith(')'));
  text = text.replaceAll(RegExp(r'[-()]'), '');
  final cents = parseMoney(text);
  return cents == null ? null : (negative ? -cents : cents);
}

/// Reads the Tarefas and Lançamentos of [tables]. Sheet and column names may be in any of the
/// languages of [labels]. [knownCards] are the app's card names; an entry on another card is an
/// error unless the workbook's "Cartões" sheet has it.
WorkbookPreview readWorkbook(List<XlsxTable> tables, List<WorkbookLabels> labels, {Iterable<String> knownCards = const []}) {
  WorkbookSheet? sheetOf(XlsxTable t) {
    final name = _key(t.name);
    for (final s in WorkbookSheet.values) {
      if (labels.any((l) => _key(l.sheet(s)) == name)) return s;
    }
    return null;
  }

  /// Header cell → column, among the sheet's columns.
  Map<WorkbookColumn, int> headerOf(WorkbookSheet sheet, XlsxTable t) {
    final out = <WorkbookColumn, int>{};
    if (t.rows.isEmpty) return out;
    final header = t.rows.first;
    for (var i = 0; i < header.cells.length; i++) {
      final text = _key(_text(header[i]));
      if (text.isEmpty) continue;
      for (final (c, _) in workbookColumns[sheet]!) {
        if (!out.containsKey(c) && labels.any((l) => _key(l.column(c)) == text)) out[c] = i;
      }
    }
    return out;
  }

  final sheets = <WorkbookSheet, XlsxTable>{};
  final skipped = <String>[];
  for (final t in tables) {
    final s = sheetOf(t);
    final imported = (s == WorkbookSheet.tasks || s == WorkbookSheet.entries) && !sheets.containsKey(s);
    // Cartões is only read for the cards of the entries; its rows are not imported.
    if (imported || (s == WorkbookSheet.cards && !sheets.containsKey(s))) sheets[s!] = t;
    if (!imported && t.rows.length > 1) skipped.add(t.name);
  }
  // A workbook of one sheet named otherwise is told by its columns.
  if (sheets.isEmpty && tables.length == 1) {
    final t = tables.single;
    if (headerOf(WorkbookSheet.tasks, t).containsKey(WorkbookColumn.title)) {
      sheets[WorkbookSheet.tasks] = t;
      skipped.clear();
    } else if (headerOf(WorkbookSheet.entries, t).keys.toSet().containsAll({WorkbookColumn.date, WorkbookColumn.value})) {
      sheets[WorkbookSheet.entries] = t;
      skipped.clear();
    }
  }

  final errors = <RowError>[];
  Set<String> keysOf<T>(Iterable<T> values, String Function(WorkbookLabels, T) label) => {
    for (final v in values)
      for (final l in labels) _key(label(l, v)),
  };
  T? matchLabel<T>(String text, Iterable<T> values, String Function(WorkbookLabels, T) label) {
    final key = _key(text);
    for (final v in values) {
      if (labels.any((l) => _key(label(l, v)) == key)) return v;
    }
    return null;
  }

  // ---------------------------------------------------------------- Tarefas
  final tasks = <ImportedTask>[];
  if (sheets[WorkbookSheet.tasks] case final t?) {
    const sheet = WorkbookSheet.tasks;
    final cols = headerOf(sheet, t);
    if (!cols.containsKey(WorkbookColumn.title)) {
      errors.add(RowError(sheet, t.rows.firstOrNull?.number ?? 1, RowProblem.missingColumns, labels.first.column(WorkbookColumn.title)));
    } else {
      for (final row in t.rows.skip(1)) {
        Object? cell(WorkbookColumn c) => cols[c] == null ? null : row[cols[c]!];
        String text(WorkbookColumn c) => _text(cell(c));
        final title = text(WorkbookColumn.title);
        if (title.isEmpty) {
          errors.add(RowError(sheet, row.number, RowProblem.noTitle));
          continue;
        }
        RowError? problem;
        (DateTime, bool)? date(WorkbookColumn c) {
          if (text(c).isEmpty) return null;
          final parsed = parseCellDate(cell(c));
          if (parsed == null) problem ??= RowError(sheet, row.number, RowProblem.badDate, labels.first.column(c));
          return parsed;
        }

        final statusText = text(WorkbookColumn.status);
        final status = statusText.isEmpty ? TaskStatus.open : matchLabel(statusText, TaskStatus.values, (l, s) => l.taskStatus(s));
        if (status == null) problem ??= RowError(sheet, row.number, RowProblem.badStatus, statusText);
        final priorityText = text(WorkbookColumn.priority);
        final priority = priorityText.isEmpty
            ? Priority.none
            : matchLabel(priorityText, Priority.values, (l, p) => l.priority(p)) ??
                  Priority.values.where((p) => '${p.code}' == priorityText).firstOrNull;
        if (priority == null) problem ??= RowError(sheet, row.number, RowProblem.badPriority, priorityText);
        final start = date(WorkbookColumn.start);
        final due = date(WorkbookColumn.due);
        final created = date(WorkbookColumn.created);
        final completed = date(WorkbookColumn.completed);
        if (problem != null) {
          errors.add(problem!);
          continue;
        }
        final list = text(WorkbookColumn.list);
        tasks.add(
          ImportedTask(
            title: title,
            folderName: text(WorkbookColumn.folder).isEmpty ? null : text(WorkbookColumn.folder),
            // The Caixa de Entrada by its name in any language.
            listName: list.isEmpty ? null : (labels.any((l) => _key(l.inbox) == _key(list)) ? 'inbox' : list),
            sectionName: text(WorkbookColumn.section).isEmpty ? null : text(WorkbookColumn.section),
            content: text(WorkbookColumn.notes),
            tags: [
              for (final tag in text(WorkbookColumn.tags).split(RegExp('[,;]')))
                if (tag.trim().replaceFirst('#', '').trim() case final name when name.isNotEmpty) name,
            ],
            // One date only: it is the due date. All-day unless one of them has a time.
            dueDate: (due ?? start)?.$1,
            startDate: due == null ? null : start?.$1,
            isAllDay: !((due?.$2 ?? false) || (start?.$2 ?? false)),
            priority: priority!.code,
            status: switch (status!) {
              TaskStatus.open => ImportedStatus.open,
              TaskStatus.completed => ImportedStatus.completed,
              TaskStatus.wontDo => ImportedStatus.wontDo,
            },
            createdAt: created?.$1,
            completedAt: completed?.$1,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------- Cartões (for the entries)
  final cards = <String, ImportedCard>{};
  if (sheets[WorkbookSheet.cards] case final t?) {
    final cols = headerOf(WorkbookSheet.cards, t);
    for (final row in t.rows.skip(1)) {
      Object? cell(WorkbookColumn c) => cols[c] == null ? null : row[cols[c]!];
      final name = _text(cell(WorkbookColumn.card));
      final closing = int.tryParse(_text(cell(WorkbookColumn.closingDay)));
      final due = int.tryParse(_text(cell(WorkbookColumn.dueDay)));
      if (name.isEmpty || closing == null || due == null || closing < 1 || closing > 31 || due < 1 || due > 31) continue;
      final limit = parseCellMoney(cell(WorkbookColumn.creditLimit));
      cards[_key(name)] ??= ImportedCard(name: name, closingDay: closing, dueDay: due, creditLimit: limit == null || limit <= 0 ? null : limit);
    }
  }

  // ---------------------------------------------------------------- Lançamentos
  final entries = <ImportedEntry>[];
  final usedCards = <String, ImportedCard>{};
  if (sheets[WorkbookSheet.entries] case final t?) {
    const sheet = WorkbookSheet.entries;
    final cols = headerOf(sheet, t);
    final missing = [WorkbookColumn.date, WorkbookColumn.value].where((c) => !cols.containsKey(c));
    final known = {for (final c in knownCards) _key(c)};
    final incomeKeys = {
      ...keysOf([FinKind.income], (l, k) => l.finKind(k)),
      'income',
    };
    final expenseKeys = {
      ...keysOf([FinKind.expense], (l, k) => l.finKind(k)),
      'expense',
    };
    if (missing.isNotEmpty) {
      errors.add(RowError(sheet, t.rows.firstOrNull?.number ?? 1, RowProblem.missingColumns, missing.map(labels.first.column).join(', ')));
    } else {
      for (final row in t.rows.skip(1)) {
        Object? cell(WorkbookColumn c) => cols[c] == null ? null : row[cols[c]!];
        String text(WorkbookColumn c) => _text(cell(c));
        final date = parseCellDate(cell(WorkbookColumn.date));
        if (date == null) {
          errors.add(RowError(sheet, row.number, RowProblem.badDate, labels.first.column(WorkbookColumn.date)));
          continue;
        }
        final cents = parseCellMoney(cell(WorkbookColumn.value));
        if (cents == null || cents == 0) {
          errors.add(RowError(sheet, row.number, RowProblem.badAmount, text(WorkbookColumn.value)));
          continue;
        }
        // Without a kind, the sign tells it: negative is an expense.
        final kindText = _key(text(WorkbookColumn.kind));
        final kind = kindText.isEmpty
            ? (cents < 0 ? FinKind.expense : FinKind.income)
            : incomeKeys.contains(kindText)
            ? FinKind.income
            : expenseKeys.contains(kindText)
            ? FinKind.expense
            : null;
        if (kind == null) {
          errors.add(RowError(sheet, row.number, RowProblem.badKind, text(WorkbookColumn.kind)));
          continue;
        }
        final card = text(WorkbookColumn.card);
        if (card.isNotEmpty && !known.contains(_key(card))) {
          final fromSheet = cards[_key(card)];
          if (fromSheet == null) {
            errors.add(RowError(sheet, row.number, RowProblem.unknownCard, card));
            continue;
          }
          usedCards[_key(card)] = fromSheet;
        }
        final invoice = text(WorkbookColumn.invoice).isEmpty ? null : parseCellDate(cell(WorkbookColumn.invoice));
        final part = RegExp(r'^(\d{1,2})\s*/\s*(\d{1,2})$').firstMatch(text(WorkbookColumn.installment));
        final index = part == null ? null : int.parse(part[1]!), count = part == null ? null : int.parse(part[2]!);
        // Installments belong to card purchases.
        final validPart = card.isNotEmpty && index != null && count != null && count > 1 && index >= 1 && index <= count;
        final category = text(WorkbookColumn.category);
        entries.add(
          ImportedEntry(
            row: row.number,
            kind: kind,
            amount: cents.abs(),
            date: DateTime(date.$1.year, date.$1.month, date.$1.day),
            description: text(WorkbookColumn.description),
            category: category.isEmpty ? null : category,
            card: card.isEmpty ? null : card,
            invoiceMonth: card.isEmpty || invoice == null ? null : DateTime(invoice.$1.year, invoice.$1.month),
            installmentIndex: validPart ? index : null,
            installmentCount: validPart ? count : null,
            note: text(WorkbookColumn.note),
          ),
        );
      }
    }
  }

  errors.sort((a, b) => a.sheet != b.sheet ? a.sheet.index.compareTo(b.sheet.index) : a.row.compareTo(b.row));
  return WorkbookPreview(tasks: tasks, entries: entries, cards: usedCards.values.toList(), errors: errors, skippedSheets: skipped);
}
