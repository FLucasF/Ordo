import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/finance_repository.dart';
import '../../domain/finance/finance.dart';
import '../../domain/finance/goals.dart';
import '../../domain/finance/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/emoji_picker.dart';
import '../common/feedback.dart';
import '../common/shell_widgets.dart';
import 'finance_widgets.dart';

/// A goal's own color, or the app's blue.
Color goalColor(BuildContext context, FinGoal goal) => parseHexColor(goal.color) ?? context.tt.primary;

/// "Caixinhas": what is saved and what is left, then each goal with its bar, "Guardar" and
/// "Retirar". The money moved is a transfer: it is never income nor an expense.
class GoalsBody extends ConsumerWidget {
  const GoalsBody({super.key, required this.archived, required this.today});

  /// The archived goals instead of the ones in use.
  final bool archived;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final goals = goalSummaries(s, today, archived: archived);
    final saved = goals.fold(0, (sum, g) => sum + g.saved), left = goals.fold(0, (sum, g) => sum + g.left);
    final targets = goals.fold(0, (sum, g) => sum + g.goal.target);

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 4, narrow ? 12 : 20, 32),
      children: [
        FigureStrip(
          figures: [
            (label: t.finGoalSaved, value: formatMoney(saved), color: tt.palette.green, hint: t.finGoalsCount(goals.length)),
            (label: t.finGoalLeftLabel, value: formatMoney(left), color: null, hint: t.finGoalTargetsHint(formatMoney(targets))),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: tt.divider),
        if (goals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              s.goals.isEmpty ? t.finNoGoals : t.finNoGoalsHere,
              textAlign: TextAlign.center,
              style: TextStyle(color: tt.textTertiary),
            ),
          ),
        for (final (i, g) in goals.indexed) ...[if (i > 0) Divider(height: 1, color: tt.divider), GoalRow(summary: g)],
      ],
    );
  }
}

/// "Faltam R$ X · Guarde R$ Y por mês até 31/12/2026", "Meta alcançada" or "A data-alvo passou".
String goalStatusText(AppLocalizations t, GoalSummary g) {
  if (g.reached) return t.finGoalReached;
  final parts = [t.finGoalLeft(formatMoney(g.left))];
  if (g.goal.dueOn case final due?) {
    parts.add(
      g.pastDue ? t.finGoalPastDue(DateLabels.numeric(finDay(due))) : t.finGoalPerMonth(formatMoney(g.perMonth!), DateLabels.numeric(finDay(due))),
    );
  }
  return parts.join(' · ');
}

/// A goal's emoji on a circle of its color.
class GoalIcon extends StatelessWidget {
  const GoalIcon({super.key, required this.goal, this.size = 40});

  final FinGoal goal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = goalColor(context, goal);
    final icon = goal.icon ?? '';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
      child: icon.isEmpty ? Icon(Icons.savings_outlined, size: size * 0.5, color: color) : Text(icon, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// The bar of a goal, in its color.
class GoalBar extends StatelessWidget {
  const GoalBar({super.key, required this.summary});

  final GoalSummary summary;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: LinearProgressIndicator(
      value: summary.progress,
      minHeight: 6,
      color: summary.reached ? context.tt.palette.green : goalColor(context, summary.goal),
      backgroundColor: context.tt.fieldFill,
    ),
  );
}

/// Deletes a goal and its moves, after asking; then "Caixinha excluída" with Desfazer. [close] runs
/// just before (the detail or the form closing itself).
Future<void> deleteGoal(BuildContext context, FinanceRepository repo, FinGoal goal, {VoidCallback? close}) async {
  final t = AppLocalizations.of(context);
  if (!await confirm(context, message: t.finDeleteGoal(goal.name), confirmLabel: t.actionDelete)) return;
  if (!context.mounted) return;
  final page = Navigator.of(context).context;
  close?.call();
  await repo.deleteGoal(goal.id);
  if (page.mounted) showToast(page, t.finGoalDeleted, undo: () => repo.restoreGoal(goal.id), redo: () => repo.deleteGoal(goal.id));
}

/// "Arquivar" / "Desarquivar", with Desfazer.
Future<void> archiveGoal(BuildContext context, FinanceRepository repo, FinGoal goal) async {
  final t = AppLocalizations.of(context);
  final archived = goal.archivedAt == null;
  // The toast outlives the goal's line: it goes to the page.
  final page = Navigator.of(context).context;
  await repo.archiveGoal(goal.id, archived: archived);
  if (archived && page.mounted) {
    showToast(page, t.finGoalArchived, undo: () => repo.archiveGoal(goal.id, archived: false), redo: () => repo.archiveGoal(goal.id, archived: true));
  }
}

/// The menu of a goal: Abrir, Guardar, Retirar, Editar, Arquivar, Deletar.
Future<void> showGoalMenu(BuildContext context, WidgetRef ref, GoalSummary summary, Offset at) async {
  final t = AppLocalizations.of(context);
  final goal = summary.goal;
  final picked = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
    items: [
      PopupMenuItem(value: 'open', height: 36, child: Text(t.calendarOpen)),
      PopupMenuItem(value: 'in', height: 36, child: Text(t.finGoalSave)),
      if (summary.saved > 0) PopupMenuItem(value: 'out', height: 36, child: Text(t.finGoalWithdraw)),
      PopupMenuItem(value: 'edit', height: 36, child: Text(t.actionEdit)),
      PopupMenuItem(value: 'archive', height: 36, child: Text(goal.archivedAt == null ? t.finArchive : t.finUnarchive)),
      PopupMenuItem(
        value: 'delete',
        height: 36,
        child: Text(t.actionDelete, style: TextStyle(color: context.tt.overdue)),
      ),
    ],
  );
  if (!context.mounted) return;
  final repo = ref.read(financeRepositoryProvider);
  switch (picked) {
    case 'open':
      await showGoalDetail(context, goal.id);
    case 'in':
      await showGoalMoveForm(context, goal: goal, withdraw: false);
    case 'out':
      await showGoalMoveForm(context, goal: goal, withdraw: true);
    case 'edit':
      await showGoalForm(context, editing: goal);
    case 'archive':
      await archiveGoal(context, repo, goal);
    case 'delete':
      await deleteGoal(context, repo, goal);
  }
}

/// A goal in the list: its emoji, name, "R$ 300,00 de R$ 1.000,00", the bar and what is left; a
/// click opens its detail; "Guardar", "Retirar" and the ⋯ beside it.
class GoalRow extends ConsumerWidget {
  const GoalRow({super.key, required this.summary});

  final GoalSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final goal = summary.goal;
    void menu(Offset at) => unawaited(showGoalMenu(context, ref, summary, at));
    final buttons = [
      TextButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: Text(t.finGoalSave),
        onPressed: () => unawaited(showGoalMoveForm(context, goal: goal, withdraw: false)),
      ),
      if (summary.saved > 0)
        TextButton.icon(
          icon: const Icon(Icons.remove, size: 16),
          label: Text(t.finGoalWithdraw),
          onPressed: () => unawaited(showGoalMoveForm(context, goal: goal, withdraw: true)),
        ),
    ];
    return GestureDetector(
      onSecondaryTapUp: (d) => menu(d.globalPosition),
      onLongPressStart: (d) => menu(d.globalPosition),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => unawaited(showGoalDetail(context, goal.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoalIcon(goal: goal),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: tt.text, fontSize: TtText.body, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            t.finGoalProgress(formatMoney(summary.saved), formatMoney(goal.target)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                          ),
                        ),
                        RowMenuButton(onMenu: menu),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GoalBar(summary: summary),
                    const SizedBox(height: 4),
                    Text(
                      goalStatusText(t, summary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: TtText.small,
                        color: summary.reached
                            ? tt.palette.green
                            : summary.pastDue
                            ? tt.overdue
                            : tt.textTertiary,
                      ),
                    ),
                    if (narrow) Wrap(children: buttons),
                  ],
                ),
              ),
              if (!narrow) ...[const SizedBox(width: 12), ...buttons],
            ],
          ),
        ),
      ),
    );
  }
}

/// A move as a line of Lançamentos: "Guardado" / "Retirado", the goal and the amount, without a sign
/// (a transfer); a click edits it; its ⋯ edits, opens the goal or deletes.
class GoalMoveLine extends ConsumerWidget {
  const GoalMoveLine({super.key, required this.move, required this.goal});

  final FinGoalMove move;
  final FinGoal goal;

  Future<void> _menu(BuildContext context, WidgetRef ref, Offset at) async {
    final t = AppLocalizations.of(context);
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'edit', height: 36, child: Text(t.actionEdit)),
        PopupMenuItem(value: 'open', height: 36, child: Text(t.calendarOpen)),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Text(t.actionDelete, style: TextStyle(color: context.tt.overdue)),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (picked) {
      case 'edit':
        await showGoalMoveForm(context, goal: goal, editing: move);
      case 'open':
        await showGoalDetail(context, goal.id);
      case 'delete':
        await deleteGoalMove(context, ref.read(financeRepositoryProvider), move);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return AgendaLine(
      color: goalColor(context, goal),
      secondary: move.amount >= 0 ? t.finGoalSaved : t.finGoalTakenOut,
      title: '${goal.icon ?? ''} ${goal.name}'.trim(),
      subtitle: move.note.isEmpty ? null : move.note,
      trailing: Text(
        formatMoney(move.amount.abs()),
        style: TextStyle(color: tt.textSecondary, fontSize: TtText.body, fontWeight: FontWeight.w600),
      ),
      onTap: () => unawaited(showGoalMoveForm(context, goal: goal, editing: move)),
      onMenu: (at) => unawaited(_menu(context, ref, at)),
    );
  }
}

/// Deletes a move, then "Movimento excluído" with Desfazer. [close] runs just before.
Future<void> deleteGoalMove(BuildContext context, FinanceRepository repo, FinGoalMove move, {VoidCallback? close}) async {
  final t = AppLocalizations.of(context);
  final page = Navigator.of(context).context;
  close?.call();
  await repo.deleteGoalMove(move.id);
  if (page.mounted) {
    showToast(page, t.finGoalMoveDeleted, undo: () => repo.deleteGoalMove(move.id, restore: true), redo: () => repo.deleteGoalMove(move.id));
  }
}

// ------------------------------------------------------------------ detail

/// A goal: its numbers, "Guardar", "Retirar" and its moves (a click edits one, its X deletes it).
Future<void> showGoalDetail(BuildContext context, String goalId) => showFinanceDialog<void>(context, builder: (_) => _GoalDetail(goalId: goalId));

class _GoalDetail extends ConsumerWidget {
  const _GoalDetail({required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final summary = [...goalSummaries(s, today), ...goalSummaries(s, today, archived: true)].where((g) => g.goal.id == goalId).firstOrNull;
    if (summary == null) {
      // Deleted (from the form over it): nothing left to show.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) unawaited(Navigator.maybePop(context));
      });
      return const SizedBox.shrink();
    }
    final goal = summary.goal;
    final repo = ref.read(financeRepositoryProvider);

    Widget line(String label, String value, {Color? valueColor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: tt.textSecondary)),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor ?? tt.text, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
          child: Row(
            children: [
              GoalIcon(goal: goal, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: t.actionEdit,
                icon: Icon(Icons.edit_outlined, color: tt.textSecondary),
                onPressed: () => unawaited(showGoalForm(context, editing: goal)),
              ),
              IconButton(
                tooltip: t.actionDelete,
                icon: Icon(Icons.delete_outline, color: tt.textSecondary),
                onPressed: () => unawaited(deleteGoal(context, repo, goal, close: () => Navigator.pop(context))),
              ),
              IconButton(
                tooltip: t.actionClose,
                icon: Icon(Icons.close, color: tt.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              const SizedBox(height: 8),
              GoalBar(summary: summary),
              const SizedBox(height: 6),
              Text(
                goalStatusText(t, summary),
                style: TextStyle(color: summary.pastDue ? tt.overdue : (summary.reached ? tt.palette.green : tt.textSecondary)),
              ),
              const SizedBox(height: 8),
              line(t.finGoalSaved, formatMoney(summary.saved), valueColor: tt.palette.green),
              line(t.finGoalTarget, formatMoney(goal.target)),
              line(t.finGoalLeftLabel, formatMoney(summary.left)),
              if (goal.dueOn case final due?) line(t.finGoalDueOn, DateLabels.numeric(finDay(due))),
              if (goal.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(goal.note, style: TextStyle(color: tt.textSecondary)),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(t.finGoalSave),
                      onPressed: () => unawaited(showGoalMoveForm(context, goal: goal, withdraw: false)),
                    ),
                  ),
                  if (summary.saved > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.remove, size: 18),
                        label: Text(t.finGoalWithdraw),
                        onPressed: () => unawaited(showGoalMoveForm(context, goal: goal, withdraw: true)),
                      ),
                    ),
                  ],
                ],
              ),
              if (summary.moves.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                  child: Text(
                    t.finGoalMoves,
                    style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w600, color: tt.textSecondary),
                  ),
                ),
              for (final m in summary.moves)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () => unawaited(showGoalMoveForm(context, goal: goal, editing: m)),
                  leading: Icon(m.amount >= 0 ? Icons.south_west : Icons.north_east, color: m.amount >= 0 ? tt.palette.green : tt.textSecondary),
                  title: Text('${m.amount >= 0 ? '+' : '-'}${formatMoney(m.amount.abs())}', style: TextStyle(color: tt.text)),
                  subtitle: Text(
                    [DateLabels.numeric(finDay(m.date)), if (m.note.isNotEmpty) m.note].join(' · '),
                    style: TextStyle(color: tt.textTertiary),
                  ),
                  trailing: IconButton(
                    tooltip: t.actionDelete,
                    icon: Icon(Icons.close, size: 18, color: tt.textTertiary),
                    onPressed: () => unawaited(deleteGoalMove(context, repo, m)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ moves

/// "Guardar em …" / "Retirar de …"; [editing] a move made (it can switch between the two).
Future<void> showGoalMoveForm(BuildContext context, {required FinGoal goal, bool withdraw = false, FinGoalMove? editing}) => showFinanceDialog<void>(
  context,
  builder: (_) => _GoalMoveForm(goal: goal, withdraw: editing == null ? withdraw : editing.amount < 0, editing: editing),
);

class _GoalMoveForm extends ConsumerStatefulWidget {
  const _GoalMoveForm({required this.goal, required this.withdraw, this.editing});

  final FinGoal goal;
  final bool withdraw;
  final FinGoalMove? editing;

  @override
  ConsumerState<_GoalMoveForm> createState() => _GoalMoveFormState();
}

class _GoalMoveFormState extends ConsumerState<_GoalMoveForm> {
  late bool _withdraw = widget.withdraw;
  late final _amount = TextEditingController(text: widget.editing == null ? '' : formatMoney(widget.editing!.amount.abs(), symbol: false));
  late final _note = TextEditingController(text: widget.editing?.note ?? '');
  late DateTime _date = widget.editing == null ? startOfDay(ref.read(clockProvider).now()) : finDay(widget.editing!.date);
  bool _showError = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseMoney(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _showError = true);
      return;
    }
    final signed = _withdraw ? -amount : amount;
    final repo = ref.read(financeRepositoryProvider);
    if (widget.editing case final m?) {
      await repo.updateGoalMove(m.id, amount: signed, date: _date, note: _note.text);
    } else {
      await repo.addGoalMove(goalId: widget.goal.id, amount: signed, date: _date, note: _note.text);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final editing = widget.editing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(
          title: editing != null
              ? t.finEditGoalMove
              : _withdraw
              ? t.finGoalMoveOut(widget.goal.name)
              : t.finGoalMoveIn(widget.goal.name),
          onSave: () => unawaited(_save()),
          onDelete: editing == null
              ? null
              : () => unawaited(deleteGoalMove(context, ref.read(financeRepositoryProvider), editing, close: () => Navigator.pop(context))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(t.finGoalSave)),
                  ButtonSegment(value: true, label: Text(t.finGoalWithdraw)),
                ],
                selected: {_withdraw},
                onSelectionChanged: (v) => setState(() => _withdraw = v.single),
              ),
              const SizedBox(height: 12),
              MoneyField(
                controller: _amount,
                label: t.finAmount,
                autofocus: true,
                onChanged: (_) => setState(() => _showError = false),
                onSubmitted: () => unawaited(_save()),
              ),
              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.finInvalidAmount,
                    style: TextStyle(color: tt.overdue, fontSize: TtText.small),
                  ),
                ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today_outlined, color: tt.textSecondary),
                title: Text(
                  t.finDate,
                  style: TextStyle(color: tt.textSecondary, fontSize: TtText.small),
                ),
                subtitle: Text(DateLabels.numeric(_date), style: TextStyle(color: tt.text)),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              TextField(
                controller: _note,
                decoration: InputDecoration(labelText: t.finNote, isDense: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ form

/// "Nova caixinha" / "Editar caixinha": emoji, name, color, the target in R$, an optional target
/// day and a note.
Future<void> showGoalForm(BuildContext context, {FinGoal? editing}) => showFinanceDialog<void>(context, builder: (_) => _GoalForm(editing: editing));

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({this.editing});

  final FinGoal? editing;

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  late final _goal = widget.editing;
  late final _name = TextEditingController(text: _goal?.name ?? '');
  late final _target = TextEditingController(text: _goal == null ? '' : formatMoney(_goal.target, symbol: false));
  late final _note = TextEditingController(text: _goal?.note ?? '');
  late String _icon = _goal?.icon ?? '';
  late String? _color = _goal?.color;
  late DateTime? _dueOn = _goal?.dueOn == null ? null : finDay(_goal!.dueOn!);
  bool _showError = false;

  @override
  void dispose() {
    for (final c in [_name, _target, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim(), target = parseMoney(_target.text);
    if (name.isEmpty || target == null || target <= 0) {
      setState(() => _showError = true);
      return;
    }
    final repo = ref.read(financeRepositoryProvider);
    if (_goal case final goal?) {
      await repo.updateGoal(goal.id, name: name, target: target, icon: _icon, color: _color, dueOn: _dueOn, note: _note.text);
    } else {
      await repo.createGoal(name: name, target: target, icon: _icon, color: _color, dueOn: _dueOn, note: _note.text);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final goal = _goal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(
          title: goal == null ? t.finNewGoal : t.finEditGoal,
          onSave: () => unawaited(_save()),
          onDelete: goal == null
              ? null
              : () => unawaited(deleteGoal(context, ref.read(financeRepositoryProvider), goal, close: () => Navigator.pop(context))),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Row(
                children: [
                  // The emoji: a click opens the picker.
                  Tooltip(
                    message: t.finIcon,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () async {
                        final picked = await showEmojiPicker(context);
                        if (picked != null) setState(() => _icon = picked);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: tt.fieldFill, shape: BoxShape.circle),
                        child: _icon.isEmpty
                            ? Icon(Icons.add_reaction_outlined, color: tt.textTertiary)
                            : Text(_icon, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      autofocus: goal == null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: t.finGoalName, isDense: true),
                      onChanged: (_) => setState(() => _showError = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MoneyField(controller: _target, label: t.finGoalTarget, onChanged: (_) => setState(() => _showError = false)),
              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.finGoalInvalid,
                    style: TextStyle(color: tt.overdue, fontSize: TtText.small),
                  ),
                ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.flag_outlined, color: tt.textSecondary),
                title: Text(
                  t.finGoalDueOn,
                  style: TextStyle(color: tt.textSecondary, fontSize: TtText.small),
                ),
                subtitle: Text(_dueOn == null ? t.finGoalNoDue : DateLabels.numeric(_dueOn!), style: TextStyle(color: tt.text)),
                trailing: _dueOn == null
                    ? null
                    : IconButton(
                        tooltip: t.finGoalNoDue,
                        icon: Icon(Icons.close, size: 18, color: tt.textTertiary),
                        onPressed: () => setState(() => _dueOn = null),
                      ),
                onTap: () async {
                  final today = startOfDay(ref.read(clockProvider).now());
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueOn ?? DateTime(today.year + 1, today.month, today.day),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _dueOn = picked);
                },
              ),
              const SizedBox(height: 4),
              Text(
                t.finGoalColor,
                style: TextStyle(color: tt.textSecondary, fontSize: TtText.small),
              ),
              const SizedBox(height: 6),
              ColorChoice(value: _color, onChanged: (c) => setState(() => _color = c)),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(labelText: t.finNote, isDense: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
