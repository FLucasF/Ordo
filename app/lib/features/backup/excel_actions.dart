import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/workbook_repository.dart';
import '../../data/xlsx/xlsx.dart';
import '../../domain/diet/diet.dart' show Meal;
import '../../domain/enums.dart';
import '../../domain/finance/finance_enums.dart';
import '../../domain/habits.dart';
import '../../domain/spreadsheet/workbook.dart';
import '../../domain/spreadsheet/workbook_import.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import 'auto_backup.dart';
import 'backup_actions.dart';

/// The workbook's texts in the language of [t].
class L10nWorkbookLabels implements WorkbookLabels {
  const L10nWorkbookLabels(this.t);
  final AppLocalizations t;

  @override
  String sheet(WorkbookSheet sheet) => switch (sheet) {
    WorkbookSheet.tasks => t.xlsxSheetTasks,
    WorkbookSheet.habits => t.xlsxSheetHabits,
    WorkbookSheet.entries => t.xlsxSheetEntries,
    WorkbookSheet.cards => t.xlsxSheetCards,
    WorkbookSheet.invoicePayments => t.xlsxSheetInvoicePayments,
    WorkbookSheet.loans => t.xlsxSheetLoans,
    WorkbookSheet.loanPayments => t.xlsxSheetLoanPayments,
    WorkbookSheet.goals => t.xlsxSheetGoals,
    WorkbookSheet.goalMoves => t.xlsxSheetGoalMoves,
    WorkbookSheet.diet => t.xlsxSheetDiet,
    WorkbookSheet.journal => t.xlsxSheetJournal,
  };

  @override
  String column(WorkbookColumn column) => switch (column) {
    WorkbookColumn.folder => t.xlsxColFolder,
    WorkbookColumn.list => t.xlsxColList,
    WorkbookColumn.section => t.xlsxColSection,
    WorkbookColumn.title => t.xlsxColTitle,
    WorkbookColumn.notes => t.xlsxColNotes,
    WorkbookColumn.status => t.xlsxColStatus,
    WorkbookColumn.priority => t.xlsxColPriority,
    WorkbookColumn.start => t.xlsxColStart,
    WorkbookColumn.due => t.xlsxColDue,
    WorkbookColumn.tags => t.xlsxColTags,
    WorkbookColumn.created => t.xlsxColCreated,
    WorkbookColumn.completed => t.xlsxColCompleted,
    WorkbookColumn.habit => t.xlsxColHabit,
    WorkbookColumn.date => t.xlsxColDate,
    WorkbookColumn.value => t.xlsxColValue,
    WorkbookColumn.goal => t.xlsxColGoal,
    WorkbookColumn.unit => t.xlsxColUnit,
    WorkbookColumn.mood => t.xlsxColMood,
    WorkbookColumn.note => t.xlsxColNote,
    WorkbookColumn.kind => t.xlsxColKind,
    WorkbookColumn.category => t.xlsxColCategory,
    WorkbookColumn.description => t.xlsxColDescription,
    WorkbookColumn.card => t.xlsxColCard,
    WorkbookColumn.invoice => t.xlsxColInvoice,
    WorkbookColumn.installment => t.xlsxColInstallment,
    WorkbookColumn.closingDay => t.xlsxColClosingDay,
    WorkbookColumn.dueDay => t.xlsxColDueDay,
    WorkbookColumn.creditLimit => t.xlsxColCreditLimit,
    WorkbookColumn.borrower => t.xlsxColBorrower,
    WorkbookColumn.lentOn => t.xlsxColLentOn,
    WorkbookColumn.principal => t.xlsxColPrincipal,
    WorkbookColumn.total => t.xlsxColTotal,
    WorkbookColumn.dueOn => t.xlsxColDueOn,
    WorkbookColumn.installments => t.xlsxColInstallments,
    WorkbookColumn.received => t.xlsxColReceived,
    WorkbookColumn.savingsGoal => t.xlsxColSavingsGoal,
    WorkbookColumn.saved => t.xlsxColSaved,
    WorkbookColumn.meal => t.xlsxColMeal,
    WorkbookColumn.food => t.xlsxColFood,
    WorkbookColumn.quantity => t.xlsxColQuantity,
    WorkbookColumn.measure => t.xlsxColMeasure,
    WorkbookColumn.grams => t.xlsxColGrams,
    WorkbookColumn.kcal => t.xlsxColKcal,
    WorkbookColumn.protein => t.xlsxColProtein,
    WorkbookColumn.carbs => t.xlsxColCarbs,
    WorkbookColumn.fat => t.xlsxColFat,
    WorkbookColumn.fiber => t.xlsxColFiber,
    WorkbookColumn.energy => t.xlsxColEnergy,
    WorkbookColumn.highlight => t.xlsxColHighlight,
  };

  @override
  String taskStatus(TaskStatus status) => switch (status) {
    TaskStatus.open => t.xlsxStatusOpen,
    TaskStatus.completed => t.xlsxStatusCompleted,
    TaskStatus.wontDo => t.xlsxStatusWontDo,
  };

  @override
  String priority(Priority priority) => switch (priority) {
    Priority.none => t.priorityNone,
    Priority.low => t.priorityLow,
    Priority.medium => t.priorityMedium,
    Priority.high => t.priorityHigh,
  };

  @override
  String finKind(FinKind kind) => kind == FinKind.income ? t.finIncome : t.finExpense;

  @override
  String habitState(HabitDayState state) => switch (state) {
    HabitDayState.done => t.habitExportDone,
    HabitDayState.partial => t.habitExportPartial,
    HabitDayState.skipped => t.habitExportSkipped,
    HabitDayState.failed => t.habitExportFailed,
    HabitDayState.open || HabitDayState.notRequired => '',
  };

  @override
  String meal(Meal meal) => switch (meal) {
    Meal.breakfast => t.dietMealBreakfast,
    Meal.morningSnack => t.dietMealMorningSnack,
    Meal.lunch => t.dietMealLunch,
    Meal.afternoonSnack => t.dietMealAfternoonSnack,
    Meal.dinner => t.dietMealDinner,
    Meal.supper => t.dietMealSupper,
  };

  @override
  String get inbox => t.inbox;
}

/// The labels the import accepts: the app's language first (it names the columns in the errors),
/// then every other one, so a workbook exported in Latin imports in Portuguese.
List<WorkbookLabels> _importLabels(AppLocalizations t) => [
  L10nWorkbookLabels(t),
  for (final locale in AppLocalizations.supportedLocales) L10nWorkbookLabels(lookupAppLocalizations(locale)),
];

String _stamp(DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
}

/// "Exportar para Excel": every module in one workbook, saved where the user picks.
Future<void> exportExcel(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context);
  final data = await loadWorkbookData(ref.read(databaseProvider));
  final bytes = encodeXlsx(buildWorkbook(data, L10nWorkbookLabels(t)));
  final path = await FilePicker.platform.saveFile(
    fileName: 'ordo_${_stamp(ref.read(clockProvider).now())}.xlsx',
    bytes: bytes,
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
  );
  // Desktop returns the chosen path; write it when the picker did not.
  if (path != null && !File(path).existsSync()) await File(path).writeAsBytes(bytes);
  if (path != null && context.mounted) showToast(context, t.xlsxExported);
}

/// "Importar do Excel": reads Tarefas and Lançamentos, shows what would come in and, once confirmed,
/// keeps a safety copy of the data and appends them.
Future<void> importExcel(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context);
  final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true);
  final bytes = picked?.files.single.bytes;
  if (bytes == null || !context.mounted) return;
  final db = ref.read(databaseProvider);
  final WorkbookPreview preview;
  try {
    preview = readWorkbook(decodeXlsx(bytes), _importLabels(t), knownCards: await cardNames(db));
  } on InvalidWorkbook {
    if (context.mounted) showToast(context, t.xlsxImportInvalid);
    return;
  }
  if (!context.mounted) return;
  if (preview.isEmpty && preview.errors.isEmpty) {
    showToast(context, t.xlsxImportNothing);
    return;
  }
  if (!await showWorkbookPreview(context, preview) || !context.mounted) return;
  // A copy of everything as it is now, listed in "Backups automáticos" to undo the import.
  if (ref.read(autoBackupProvider) case final auto?) {
    await auto.saveNow(ref.read(clockProvider).now(), await (await backupServiceOf(ref)).export(withFiles: false));
  }
  final result = await importWorkbook(db, preview, clock: ref.read(clockProvider));
  if (context.mounted) showToast(context, t.xlsxImportDone(t.xlsxImportTasks(result.tasks), t.xlsxImportEntries(result.entries)));
}

/// One error of the preview: "Tarefas, linha 5: sem título".
String rowErrorText(AppLocalizations t, RowError e) {
  final reason = switch (e.problem) {
    RowProblem.missingColumns => t.xlsxErrorMissingColumns(e.detail),
    RowProblem.noTitle => t.xlsxErrorNoTitle,
    RowProblem.badDate => t.xlsxErrorDate(e.detail),
    RowProblem.badAmount => t.xlsxErrorAmount(e.detail),
    RowProblem.badKind => t.xlsxErrorKind(e.detail),
    RowProblem.badStatus => t.xlsxErrorStatus(e.detail),
    RowProblem.badPriority => t.xlsxErrorPriority(e.detail),
    RowProblem.unknownCard => t.xlsxErrorCard(e.detail),
  };
  return t.xlsxErrorRow(L10nWorkbookLabels(t).sheet(e.sheet), e.row, reason);
}

/// The errors listed in the preview; the rest is counted.
const _shownErrors = 50;

/// "120 tarefas, 45 lançamentos; 3 linhas com erro", the errors and the skipped sheets. True to
/// import.
Future<bool> showWorkbookPreview(BuildContext context, WorkbookPreview preview) async {
  final t = AppLocalizations.of(context);
  final tt = context.tt;
  final small = TextStyle(fontSize: TtText.small, color: tt.textTertiary);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.xlsxImport, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.xlsxImportSummary(
                  t.xlsxImportTasks(preview.tasks.length),
                  t.xlsxImportEntries(preview.entries.length),
                  t.xlsxImportErrors(preview.errors.length),
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(t.xlsxImportSafety, style: small),
              if (preview.skippedSheets.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(t.xlsxImportSkipped(preview.skippedSheets.join(', ')), style: small),
              ],
              if (preview.errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final e in preview.errors.take(_shownErrors))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 6),
                          child: Icon(Icons.error_outline, size: 14, color: tt.overdue),
                        ),
                        Expanded(
                          child: Text(
                            rowErrorText(t, e),
                            style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (preview.errors.length > _shownErrors) Text(t.xlsxImportMoreErrors(preview.errors.length - _shownErrors), style: small),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.actionCancel)),
        FilledButton(onPressed: preview.isEmpty ? null : () => Navigator.pop(context, true), child: Text(t.importAction)),
      ],
    ),
  );
  return result ?? false;
}
