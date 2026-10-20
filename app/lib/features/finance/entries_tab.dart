import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../domain/finance/finance.dart';
import '../../domain/finance/finance_enums.dart';
import '../../domain/finance/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/shell_widgets.dart';
import 'entry_form.dart';
import 'finance_widgets.dart';
import 'goals_tab.dart';

/// "Lançamentos": the period's figures (Receitas, Despesas, Saldo) and its entries laid out as the
/// Agenda: each day with its entries; a card's purchases come together on their invoice's due day.
class EntriesBody extends ConsumerWidget {
  const EntriesBody({super.key, required this.range, required this.hiddenCategories, required this.kind, required this.search, required this.today});

  final ({DateTime from, DateTime to}) range;

  /// Unchecked in the panel ('' = "Sem categoria").
  final Set<String> hiddenCategories;
  final FinKind? kind;
  final String search;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final inPeriod = filterEntries(s, EntryFilter(from: range.from, to: range.to));
    final shown = [
      for (final e in filterEntries(s, EntryFilter(from: range.from, to: range.to, kind: kind, text: search)))
        if (!hiddenCategories.contains(e.categoryId ?? '')) e,
    ];
    final totals = totalsOf(inPeriod);
    // The goals' moves are transfers: in the days, never in the figures, and only among all kinds.
    final words = search.trim().toLowerCase();
    final goals = {for (final g in s.goals) g.id: g};
    final moves = [
      for (final m in s.goalMoves)
        if (kind == null &&
            goals[m.goalId] != null &&
            !finDay(m.date).isBefore(range.from) &&
            !finDay(m.date).isAfter(range.to) &&
            (words.isEmpty || goals[m.goalId]!.name.toLowerCase().contains(words) || m.note.toLowerCase().contains(words)))
          m,
    ];
    final groups = groupEntries(s, shown, moves: moves);

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 4, narrow ? 12 : 20, 32),
      children: [
        FigureStrip(
          figures: [
            (label: t.finIncomes, value: formatMoney(totals.income), color: tt.palette.green, hint: null),
            (label: t.finExpenses, value: formatMoney(totals.expense), color: tt.overdue, hint: null),
            (label: t.finBalance, value: formatMoney(totals.balance), color: totals.balance < 0 ? tt.overdue : null, hint: null),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: tt.divider),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              t.finEntriesEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: tt.textTertiary),
            ),
          ),
        for (final (i, g) in groups.indexed) ...[
          if (i > 0) Divider(height: 1, color: tt.divider),
          AgendaBlock(
            day: g.day,
            today: today,
            // An invoice's block names its card under the due day.
            label: g.card?.name,
            // A plain day: its "+" (and the day itself) starts an entry on it.
            onAdd: g.card == null ? () => unawaited(showEntryForm(context, date: g.day)) : null,
            addTooltip: t.finNewEntryOnDay,
            children: [
              for (final e in g.entries) EntryLine(entry: e, snapshot: s, inInvoice: g.card != null),
              for (final m in g.moves) GoalMoveLine(move: m, goal: goals[m.goalId]!),
            ],
          ),
        ],
      ],
    );
  }
}

/// An entry as a line of the Agenda: the category's dot, the category (or the purchase day, under an
/// invoice), the description and the amount; a click edits, its ⋯ (the right click, a long press)
/// opens Editar · Duplicar · Deletar.
class EntryLine extends ConsumerWidget {
  const EntryLine({super.key, required this.entry, required this.snapshot, this.inInvoice = false, this.showCard = true});

  final FinEntry entry;
  final FinanceSnapshot snapshot;
  final bool inInvoice;

  /// Off on the card's own screen, where its name is the heading.
  final bool showCard;

  Future<void> _menu(BuildContext context, WidgetRef ref, Offset at) async {
    final t = AppLocalizations.of(context);
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'edit', height: 36, child: Text(t.actionEdit)),
        PopupMenuItem(value: 'copy', height: 36, child: Text(t.finDuplicate)),
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
        await showEntryForm(context, editing: entry);
      case 'copy':
        await showEntryForm(context, copy: entry);
      case 'delete':
        await deleteEntry(context, ref.read(financeRepositoryProvider), entry);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final category = entry.categoryId == null ? null : snapshot.categoryById[entry.categoryId];
    final card = entry.cardId == null ? null : snapshot.cardById[entry.cardId];
    final name = categoryName(t, category);
    final details = [
      if (entry.installmentIndex case final i?) '$i/${entry.installmentCount}',
      if (card != null && !inInvoice && showCard) card.name,
      if (inInvoice && entry.description.isNotEmpty) name,
      if (entry.note.isNotEmpty) entry.note,
    ];
    return AgendaLine(
      color: categoryColor(context, snapshot, category),
      secondary: inInvoice ? DateLabels.numeric(finDay(entry.date), withYear: false) : '${category?.icon ?? ''} $name'.trim(),
      title: entry.description.isNotEmpty ? entry.description : name,
      subtitle: details.isEmpty ? null : details.join(' · '),
      trailing: Text(
        signedMoney(entry.kind, entry.amount),
        style: TextStyle(color: finKindColor(context, entry.kind), fontSize: TtText.body, fontWeight: FontWeight.w600),
      ),
      onTap: () => unawaited(showEntryForm(context, editing: entry)),
      onMenu: (at) => unawaited(_menu(context, ref, at)),
    );
  }
}
