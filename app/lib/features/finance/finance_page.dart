import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/finance_repository.dart';
import '../../data/preferences_repository.dart';
import '../../domain/finance/cards.dart';
import '../../domain/finance/finance.dart';
import '../../domain/finance/finance_enums.dart';
import '../../domain/finance/goals.dart';
import '../../domain/finance/loans.dart';
import '../../domain/finance/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/shell_widgets.dart';
import '../shell/app_shell.dart';
import 'cards_tab.dart';
import 'categories_tab.dart';
import 'entries_tab.dart';
import 'entry_form.dart';
import 'finance_widgets.dart';
import 'goals_tab.dart';
import 'loans_tab.dart';
import 'recurring_tab.dart';
import 'reports_tab.dart';

/// Tabs of Finanças (`/finance/{tab}`).
enum FinanceTab {
  entries('entries'),
  cards('cards'),
  recurring('recurring'),
  loans('loans'),
  goals('goals'),
  reports('reports'),
  categories('categories');

  const FinanceTab(this.route);
  final String route;

  static FinanceTab fromRoute(String? route) => values.where((t) => t.route == route).firstOrNull ?? entries;
}

String financeTabLabel(AppLocalizations t, FinanceTab tab) => switch (tab) {
  FinanceTab.entries => t.finTabEntries,
  FinanceTab.cards => t.finTabCards,
  FinanceTab.recurring => t.finTabRecurring,
  FinanceTab.loans => t.finTabLoans,
  FinanceTab.goals => t.finTabGoals,
  FinanceTab.reports => t.finTabReports,
  FinanceTab.categories => t.finTabCategories,
};

IconData financeTabIcon(FinanceTab tab) => switch (tab) {
  FinanceTab.entries => Icons.receipt_long_outlined,
  FinanceTab.cards => Icons.credit_card,
  FinanceTab.recurring => Icons.event_repeat_outlined,
  FinanceTab.loans => Icons.handshake_outlined,
  FinanceTab.goals => Icons.savings_outlined,
  FinanceTab.reports => Icons.insert_chart_outlined,
  FinanceTab.categories => Icons.category_outlined,
};

/// "Lançamentos" by month (the default), by year, or between two days.
enum EntryPeriod { month, year, custom }

/// The default categories, created the first time Finanças opens.
Future<void> seedFinanceCategories(FinanceRepository repo, PreferencesRepository prefs, AppLocalizations t) async {
  if (await prefs.financeCategoriesSeeded()) return;
  await repo.seedCategories([
    (name: t.finCatFood, icon: '🍽️', kind: FinKind.expense),
    (name: t.finCatMarket, icon: '🛒', kind: FinKind.expense),
    (name: t.finCatTransport, icon: '🚗', kind: FinKind.expense),
    (name: t.finCatHome, icon: '🏠', kind: FinKind.expense),
    (name: t.finCatBills, icon: '💡', kind: FinKind.expense),
    (name: t.finCatHealth, icon: '💊', kind: FinKind.expense),
    (name: t.finCatEducation, icon: '📚', kind: FinKind.expense),
    (name: t.finCatLeisure, icon: '🎉', kind: FinKind.expense),
    (name: t.finCatShopping, icon: '🛍️', kind: FinKind.expense),
    (name: t.finCatSubscriptions, icon: '📺', kind: FinKind.expense),
    (name: t.finCatOther, icon: '📦', kind: FinKind.expense),
    (name: t.finCatSalary, icon: '💰', kind: FinKind.income),
    (name: t.finCatExtra, icon: '💵', kind: FinKind.income),
    (name: t.finCatOther, icon: '📦', kind: FinKind.income),
  ]);
  await prefs.markFinanceCategoriesSeeded();
}

/// Finanças in the Calendar's look: a left panel (the months, the month's spending and the tab's own
/// list: categories, cards, bills, loan status), a top bar (title, "Este mês", ‹ ›, ⋯ and the tab's
/// "+ Novo …"), the tabs in sight under it and the tab below, laid out as the Agenda.
class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key, required this.tab});

  final FinanceTab tab;

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> {
  bool _panel = true;
  late DateTime _month = monthOf(ref.read(clockProvider).now());

  // Lançamentos.
  EntryPeriod _period = EntryPeriod.month;
  DateTimeRange? _custom;

  /// Categories unchecked in the panel ('' = "Sem categoria").
  Set<String> _hidden = {};
  FinKind? _kind;
  bool _searching = false;
  final _search = TextEditingController();

  // Cartões: the card and its invoice (null = the one taking purchases today).
  String? _cardId;
  DateTime? _invoice;
  bool _archivedCards = false;

  // Empréstimos.
  Set<LoanStatus> _statuses = {LoanStatus.onTime, LoanStatus.overdue};
  bool _byDue = true;

  // Caixinhas.
  bool _archivedGoals = false;

  // Relatórios: the month compared (the one before, to begin with).
  DateTime? _compare;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(seedFinanceCategories(ref.read(financeRepositoryProvider), ref.read(preferencesRepositoryProvider), AppLocalizations.of(context)));
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  DateTime get _today => startOfDay(ref.read(clockProvider).now());

  ({DateTime from, DateTime to}) get _entriesRange => switch (_period) {
    EntryPeriod.month => (from: _month, to: DateTime(_month.year, _month.month + 1, 0)),
    EntryPeriod.year => (from: DateTime(_month.year), to: DateTime(_month.year, 12, 31)),
    EntryPeriod.custom => (from: startOfDay(_custom!.start), to: startOfDay(_custom!.end)),
  };

  void _go(FinanceTab tab) => context.go(Routes.financeOf(tab.route));

  /// "+ Novo …" of the tab: a bill, a loan, a category, a purchase on the card shown (a card, without
  /// one) or an entry.
  Future<void> _create(FinanceSnapshot s) => switch (widget.tab) {
    FinanceTab.recurring => showRecurringForm(context),
    FinanceTab.loans => showLoanForm(context),
    FinanceTab.goals => showGoalForm(context),
    FinanceTab.categories => showCategoryForm(context, kind: FinKind.expense),
    FinanceTab.cards => switch (_card(s)) {
      final card? => showEntryForm(context, cardId: card.id),
      null => _cardAction('newCard', null),
    },
    _ => showEntryForm(context),
  };

  String _createLabel(AppLocalizations t, FinanceSnapshot s) => switch (widget.tab) {
    FinanceTab.recurring => t.finNewRecurring,
    FinanceTab.loans => t.finNewLoan,
    FinanceTab.goals => t.finNewGoal,
    FinanceTab.categories => t.finNewCategory,
    FinanceTab.cards => _card(s) == null ? t.finNewCard : t.finNewPurchase,
    _ => t.finNewEntry,
  };

  Future<void> _pickCustom() async {
    final range = _entriesRange;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: range.from, end: range.to),
    );
    if (picked != null) {
      setState(() {
        _custom = picked;
        _period = EntryPeriod.custom;
      });
    }
  }

  // ------------------------------------------------------------------ title and arrows

  String _title(AppLocalizations t, FinanceSnapshot s, bool narrow) {
    final dates = DateLabels(t);
    String month(DateTime m) {
      if (!narrow) return dates.monthTitle(m);
      final name = dates.monthLong(m);
      return '${name[0].toUpperCase()}${name.substring(1)}';
    }

    return switch (widget.tab) {
      FinanceTab.entries => switch (_period) {
        EntryPeriod.month => month(_month),
        EntryPeriod.year => '${_month.year}',
        EntryPeriod.custom => '${DateLabels.numeric(_entriesRange.from)} - ${DateLabels.numeric(_entriesRange.to)}',
      },
      FinanceTab.cards => switch (_card(s)) {
        final card? => narrow ? month(_invoiceOf(card)) : t.finInvoiceTitle(dates.monthTitle(_invoiceOf(card))),
        null => t.finTabCards,
      },
      FinanceTab.loans => t.finTabLoans,
      FinanceTab.goals => _archivedGoals ? '${t.finTabGoals} · ${t.finArchivedGoals}' : t.finTabGoals,
      _ => month(_month),
    };
  }

  bool get _hasArrows => switch (widget.tab) {
    FinanceTab.entries => _period != EntryPeriod.custom,
    FinanceTab.loans || FinanceTab.goals => false,
    _ => true,
  };

  void _step(FinanceSnapshot s, int delta) => setState(() {
    if (widget.tab == FinanceTab.cards) {
      if (_card(s) case final card?) {
        final m = _invoiceOf(card);
        _invoice = DateTime(m.year, m.month + delta);
      }
    } else if (widget.tab == FinanceTab.entries && _period == EntryPeriod.year) {
      _month = DateTime(_month.year + delta, _month.month);
    } else {
      _month = DateTime(_month.year, _month.month + delta);
    }
  });

  void _thisMonth() => setState(() {
    _month = monthOf(_today);
    _invoice = null;
    if (_period == EntryPeriod.custom) _period = EntryPeriod.month;
  });

  FinCard? _card(FinanceSnapshot s) {
    final cards = [
      for (final c in s.cards)
        if ((c.archivedAt != null) == _archivedCards) c,
    ];
    return cards.where((c) => c.id == _cardId).firstOrNull ?? cards.firstOrNull;
  }

  DateTime _invoiceOf(FinCard card) => _invoice ?? currentInvoiceMonth(card, _today);

  // ------------------------------------------------------------------ ⋯

  Future<void> _cardAction(String action, FinCard? card) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(financeRepositoryProvider);
    switch (action) {
      case 'newCard':
        final id = await showCardForm(context);
        if (id != null && mounted) setState(() => _cardId = id);
      case 'editCard' when card != null:
        await showCardForm(context, editing: card);
      case 'archiveCard' when card != null:
        await repo.archiveCard(card.id, archived: card.archivedAt == null);
      case 'deleteCard' when card != null:
        if (!await confirm(context, message: t.finDeleteCard(card.name), confirmLabel: t.actionDelete)) return;
        final deleted = await repo.deleteCard(card.id);
        if (!deleted && mounted) showToast(context, t.finCardDeleteBlocked);
    }
  }

  List<PopupMenuEntry<Object>> _moreItems(AppLocalizations t, FinanceSnapshot s, bool narrow) {
    PopupMenuItem<Object> item(Object value, String label) => PopupMenuItem<Object>(value: value, height: 36, child: Text(label));
    return switch (widget.tab) {
      FinanceTab.entries => [
        for (final (p, label) in [
          (EntryPeriod.month, t.finPeriodMonth),
          (EntryPeriod.year, t.finPeriodYear),
          (EntryPeriod.custom, t.searchDateCustom),
        ])
          CheckedPopupMenuItem<Object>(value: p, checked: _period == p, child: Text(label)),
        const PopupMenuDivider(),
        for (final (k, label) in [('all', t.finAllKinds), (FinKind.income, t.finIncomes), (FinKind.expense, t.finExpenses)])
          CheckedPopupMenuItem<Object>(value: k, checked: (_kind ?? 'all') == k, child: Text(label)),
        if (narrow) ...[
          const PopupMenuDivider(),
          item('search', t.navSearch),
          item('categories', t.finCategoriesFilter),
          item('thisMonth', t.finThisMonth),
        ],
      ],
      FinanceTab.cards => [
        if (narrow) ...[
          for (final c in s.cards)
            if ((c.archivedAt != null) == _archivedCards)
              CheckedPopupMenuItem<Object>(value: 'card:${c.id}', checked: _card(s)?.id == c.id, child: Text(c.name)),
          item('thisMonth', t.finCurrentInvoice),
          const PopupMenuDivider(),
        ],
        item('newCard', t.finNewCard),
        if (_card(s) case final card?) ...[
          item('editCard', t.finEditCard),
          item('archiveCard', card.archivedAt == null ? t.finArchive : t.finUnarchive),
          item('deleteCard', t.actionDelete),
        ],
        CheckedPopupMenuItem<Object>(value: 'archived', checked: _archivedCards, child: Text(t.finArchivedCards)),
      ],
      FinanceTab.loans => [
        CheckedPopupMenuItem<Object>(value: 'byDue', checked: _byDue, child: Text(t.finByDueMonth)),
        CheckedPopupMenuItem<Object>(value: 'byLent', checked: !_byDue, child: Text(t.finByLentMonth)),
        if (narrow) ...[
          const PopupMenuDivider(),
          for (final (st, label) in [
            (LoanStatus.onTime, t.finLoanOnTime),
            (LoanStatus.overdue, t.finLoansOverdue),
            (LoanStatus.paid, t.finLoansPaid),
          ])
            CheckedPopupMenuItem<Object>(value: st, checked: _statuses.contains(st), child: Text(label)),
        ],
      ],
      FinanceTab.goals => [CheckedPopupMenuItem<Object>(value: 'archivedGoals', checked: _archivedGoals, child: Text(t.finArchivedGoals))],
      _ => [if (narrow) item('thisMonth', t.finThisMonth)],
    };
  }

  Future<void> _onMore(Object v, FinanceSnapshot s) async {
    switch (v) {
      case EntryPeriod.custom:
        await _pickCustom();
      case final EntryPeriod p:
        setState(() {
          if (p == EntryPeriod.month && _period == EntryPeriod.custom) _month = monthOf(_today);
          _period = p;
        });
      case 'all':
        setState(() => _kind = null);
      case final FinKind k:
        setState(() => _kind = k);
      case 'search':
        setState(() => _searching = !_searching);
      case 'categories':
        await _categoriesDialog();
      case 'thisMonth':
        _thisMonth();
      case 'archived':
        setState(() {
          _archivedCards = !_archivedCards;
          _cardId = null;
          _invoice = null;
        });
      case final String c when c.startsWith('card:'):
        setState(() {
          _cardId = c.substring(5);
          _invoice = null;
        });
      case 'archivedGoals':
        setState(() => _archivedGoals = !_archivedGoals);
      case 'byDue':
        setState(() => _byDue = true);
      case 'byLent':
        setState(() => _byDue = false);
      case final LoanStatus st:
        setState(() => _statuses = _statuses.contains(st) ? ({..._statuses}..remove(st)) : {..._statuses, st});
      case final String action:
        await _cardAction(action, _card(s));
    }
  }

  // ------------------------------------------------------------------ panel

  List<Widget> _categoryRows(AppLocalizations t, FinanceSnapshot s, void Function(void Function()) update) {
    final month = _period == EntryPeriod.month ? _month : null;
    final spent = month == null ? const <String?, int>{} : spendingByCategory(s, month);
    Widget row(String id, String name, Color color) => PanelCheckRow(
      color: color,
      label: name,
      shown: !_hidden.contains(id),
      trailing: switch (spent[id.isEmpty ? null : id]) {
        final amount? when amount > 0 => formatMoney(amount, symbol: false),
        _ => null,
      },
      onChanged: (on) => update(() => _hidden = on ? ({..._hidden}..remove(id)) : {..._hidden, id}),
      onOnly: () => update(() => _hidden = {for (final c in s.categories) c.id, ''}..remove(id)),
    );
    return [
      for (final c in [...s.categoriesOf(FinKind.expense), ...s.categoriesOf(FinKind.income)])
        row(c.id, '${c.icon} ${c.name}'.trim(), categoryColor(context, s, c)),
      row('', t.finNoCategory, categoryColor(context, s, null)),
    ];
  }

  Future<void> _categoriesDialog() => showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) {
        final t = AppLocalizations.of(context);
        final s = ref.read(financeProvider).value ?? FinanceSnapshot.empty();
        return AlertDialog(
          title: Text(t.finTabCategories, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 320,
            child: ListView(
              shrinkWrap: true,
              children: _categoryRows(t, s, (change) {
                setState(change);
                setLocal(() {});
              }),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionOk))],
        );
      },
    ),
  );

  Widget _spending(AppLocalizations t, FinanceSnapshot s, DateTime month) {
    final spent = spendingByCategory(s, month);
    return PanelSection(
      title: t.finMonthSpending,
      children: [
        PanelBarSummary(
          period: DateLabels(t).monthTitle(month),
          slices: [
            for (final MapEntry(key: id, value: amount) in (spent.entries.toList()..sort((a, b) => b.value.compareTo(a.value))))
              if (id == null ? null : s.categoryById[id] case final c)
                (
                  name: c == null ? t.finNoCategory : '${c.icon} ${c.name}'.trim(),
                  value: amount.toDouble(),
                  color: categoryColor(context, s, c),
                  valueLabel: formatMoney(amount),
                ),
          ],
          empty: t.finNoExpenses,
          moreLabel: t.finMoreReports,
          onMore: () => _go(FinanceTab.reports),
        ),
      ],
    );
  }

  Widget _panelOf(AppLocalizations t, FinanceSnapshot s, DateTime today) {
    final tt = context.tt;
    final card = _card(s);
    final months = MonthGridPicker(
      selected: widget.tab == FinanceTab.cards && card != null ? _invoiceOf(card) : _month,
      today: today,
      onPick: (m) => setState(() {
        if (widget.tab == FinanceTab.cards) {
          _invoice = m;
        } else {
          _month = m;
          if (_period == EntryPeriod.custom) _period = EntryPeriod.month;
        }
      }),
    );
    final loans = loanSummaries(s, today);
    final children = <Widget>[
      if (widget.tab != FinanceTab.loans && widget.tab != FinanceTab.goals) months,
      switch (widget.tab) {
        FinanceTab.entries => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _spending(t, s, _month),
            PanelSection(title: t.finTabCategories, children: _categoryRows(t, s, setState)),
          ],
        ),
        FinanceTab.cards => PanelSection(
          title: _archivedCards ? t.finArchivedCards : t.finTabCards,
          action: IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            tooltip: t.finNewCard,
            icon: Icon(Icons.add, color: tt.textSecondary),
            onPressed: () => unawaited(_cardAction('newCard', null)),
          ),
          children: [
            for (final c in s.cards)
              if ((c.archivedAt != null) == _archivedCards)
                PanelNavRow(
                  icon: Icons.credit_card,
                  label: c.name,
                  selected: card?.id == c.id,
                  trailing: switch (invoiceOf(s, c, currentInvoiceMonth(c, today), today).remaining) {
                    final left when left > 0 => formatMoney(left, symbol: false),
                    _ => null,
                  },
                  onTap: () => setState(() {
                    _cardId = c.id;
                    _invoice = null;
                  }),
                ),
            if (s.cards.any((c) => c.archivedAt != null) || _archivedCards)
              PanelNavRow(
                icon: Icons.inventory_2_outlined,
                label: _archivedCards ? t.finTabCards : t.finArchivedCards,
                selected: false,
                onTap: () => setState(() {
                  _archivedCards = !_archivedCards;
                  _cardId = null;
                  _invoice = null;
                }),
              ),
          ],
        ),
        FinanceTab.recurring => PanelSection(
          title: t.finRecurringBills,
          children: [
            for (final r in s.recurrings)
              if (r.archivedAt == null)
                PanelNavRow(
                  label: r.description,
                  color: categoryColor(context, s, r.categoryId == null ? null : s.categoryById[r.categoryId]),
                  selected: false,
                  trailing: recurringWhen(t, r),
                  onTap: () => unawaited(showRecurringForm(context, editing: r)),
                ),
          ],
        ),
        FinanceTab.loans => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PanelSection(
              title: t.finSituation,
              children: [
                for (final (st, label, color) in [
                  (LoanStatus.onTime, t.finLoanOnTime, tt.primary),
                  (LoanStatus.overdue, t.finLoansOverdue, tt.overdue),
                  (LoanStatus.paid, t.finLoansPaid, tt.palette.green),
                ])
                  PanelCheckRow(
                    color: color,
                    label: label,
                    shown: _statuses.contains(st),
                    trailing: '${loans.where((l) => l.status == st).length}',
                    onChanged: (on) => setState(() => _statuses = on ? {..._statuses, st} : ({..._statuses}..remove(st))),
                    onOnly: () => setState(() => _statuses = {st}),
                  ),
              ],
            ),
            PanelSection(
              title: t.finGroupBy,
              children: [
                PanelNavRow(icon: Icons.event_outlined, label: t.finByDueMonth, selected: _byDue, onTap: () => setState(() => _byDue = true)),
                PanelNavRow(icon: Icons.handshake_outlined, label: t.finByLentMonth, selected: !_byDue, onTap: () => setState(() => _byDue = false)),
              ],
            ),
          ],
        ),
        FinanceTab.goals => PanelSection(
          title: _archivedGoals ? t.finArchivedGoals : t.finTabGoals,
          action: IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            tooltip: t.finNewGoal,
            icon: Icon(Icons.add, color: tt.textSecondary),
            onPressed: () => unawaited(showGoalForm(context)),
          ),
          children: [
            for (final g in goalSummaries(s, today, archived: _archivedGoals))
              PanelNavRow(
                label: '${g.goal.icon ?? ''} ${g.goal.name}'.trim(),
                color: goalColor(context, g.goal),
                selected: false,
                trailing: formatPercent((g.progress * 100).floor() * 100),
                onTap: () => unawaited(showGoalDetail(context, g.goal.id)),
              ),
            if (s.goals.any((g) => g.archivedAt != null) || _archivedGoals)
              PanelNavRow(
                icon: Icons.inventory_2_outlined,
                label: _archivedGoals ? t.finTabGoals : t.finArchivedGoals,
                selected: false,
                onTap: () => setState(() => _archivedGoals = !_archivedGoals),
              ),
          ],
        ),
        FinanceTab.reports || FinanceTab.categories => _spending(t, s, _month),
      },
    ];
    return ShellPanel(children: children);
  }

  // ------------------------------------------------------------------ body

  Widget _body(FinanceSnapshot s, DateTime today) => switch (widget.tab) {
    FinanceTab.entries => EntriesBody(
      range: _entriesRange,
      hiddenCategories: _hidden,
      kind: _kind,
      search: _searching ? _search.text : '',
      today: today,
    ),
    FinanceTab.cards => switch (_card(s)) {
      final card? => CardInvoiceBody(card: card, month: _invoiceOf(card), today: today),
      null => const NoCardsBody(),
    },
    FinanceTab.recurring => RecurringBody(month: _month, today: today),
    FinanceTab.loans => LoansBody(statuses: _statuses, byDue: _byDue, today: today),
    FinanceTab.goals => GoalsBody(archived: _archivedGoals, today: today),
    FinanceTab.reports => ReportsBody(
      month: _month,
      compare: _compare ?? DateTime(_month.year, _month.month - 1),
      onCompare: (m) => setState(() => _compare = m),
      today: today,
    ),
    FinanceTab.categories => CategoriesBody(month: _month),
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final hasPeriod = widget.tab != FinanceTab.loans && widget.tab != FinanceTab.goals && !(widget.tab == FinanceTab.cards && _card(s) == null);
    final more = _moreItems(t, s, narrow);

    final topBar = ShellTopBar(
      title: _title(t, s, narrow),
      onTogglePanel: () => setState(() => _panel = !_panel),
      onCreate: () => unawaited(_create(s)),
      createLabel: _createLabel(t, s),
      actions: [
        if (widget.tab == FinanceTab.entries && !narrow)
          IconButton(
            tooltip: t.navSearch,
            icon: Icon(_searching ? Icons.search_off : Icons.search, color: tt.textSecondary),
            onPressed: () => setState(() => _searching = !_searching),
          ),
        if (hasPeriod && !narrow) TodayPill(label: widget.tab == FinanceTab.cards ? t.finCurrentInvoice : t.finThisMonth, onPressed: _thisMonth),
        if (hasPeriod && _hasArrows) ShellArrows(onPrevious: () => _step(s, -1), onNext: () => _step(s, 1)),
        if (more.isNotEmpty)
          PopupMenuButton<Object>(
            tooltip: '',
            icon: Icon(Icons.more_horiz, color: tt.textSecondary),
            onSelected: (v) => unawaited(_onMore(v, s)),
            itemBuilder: (_) => _moreItems(t, s, narrow),
          ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShellTabs<FinanceTab>(
          selected: widget.tab,
          onSelected: _go,
          tabs: [for (final tab in FinanceTab.values) (value: tab, label: financeTabLabel(t, tab), icon: financeTabIcon(tab))],
        ),
        const SizedBox(height: 8),
        if (_searching && widget.tab == FinanceTab.entries)
          Padding(
            padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 0, narrow ? 12 : 20, 8),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: t.finSearchHint,
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                filled: true,
                fillColor: tt.fieldFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
        Expanded(child: _body(s, today)),
      ],
    );

    return ModuleScaffold(
      module: AppModule.finance,
      child: ShellLayout(
        panel: _panelOf(t, s, today),
        panelOpen: _panel,
        topBar: topBar,
        body: body,
        onCreate: () => unawaited(_create(s)),
        createLabel: _createLabel(t, s),
      ),
    );
  }
}
