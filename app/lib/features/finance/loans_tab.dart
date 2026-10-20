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
import '../../domain/finance/loans.dart';
import '../../domain/finance/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/shell_widgets.dart';
import 'finance_widgets.dart';

/// "Empréstimos": the figures (lent, to receive, profit received, late), then the loans by month
/// (of the due day or of the day lent), each on its day as in the Agenda. The status filter and the
/// grouping are in the left panel.
class LoansBody extends ConsumerWidget {
  const LoansBody({super.key, required this.statuses, required this.byDue, required this.today});

  final Set<LoanStatus> statuses;
  final bool byDue;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final loans = loanSummaries(s, today);
    final shown = [
      for (final l in loans)
        if (statuses.contains(l.status)) l,
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 4, narrow ? 12 : 20, 32),
      children: [
        LoansFigures(overview: loansOverview(loans)),
        const SizedBox(height: 12),
        Divider(height: 1, color: tt.divider),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              loans.isEmpty ? t.finNoLoans : t.finNoLoansHere,
              textAlign: TextAlign.center,
              style: TextStyle(color: tt.textTertiary),
            ),
          ),
        for (final group in loansByMonth(shown, byDue: byDue)) ...[
          // The month's count, what is left and the profit: beside the month, or under it on a phone.
          if (Text(
                '${t.finLoansCount(group.loans.length)} · ${t.finMonthLoanTotals(formatMoney(group.loans.fold(0, (sum, l) => sum + l.balance)), formatMoney(group.loans.fold(0, (sum, l) => sum + l.interest)))}',
                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
              )
              case final totals) ...[
            BodyHeading(dates.monthTitle(group.month), trailing: narrow ? null : totals),
            if (narrow) Padding(padding: const EdgeInsets.only(bottom: 4), child: totals),
          ],
          for (final (i, l) in group.loans.indexed) ...[
            if (i > 0) Divider(height: 1, color: tt.divider),
            AgendaBlock(
              day: finDay(byDue ? l.loan.dueOn : l.loan.lentOn),
              today: today,
              children: [_LoanLine(summary: l)],
            ),
          ],
        ],
      ],
    );
  }
}

/// The four figures of the loans (also on Relatórios).
class LoansFigures extends StatelessWidget {
  const LoansFigures({super.key, required this.overview});

  final LoansOverview overview;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return FigureStrip(
      figures: [
        (label: t.finLentOpen, value: formatMoney(overview.lentOpen), color: null, hint: t.finLoansCount(overview.open)),
        (
          label: t.finToReceive,
          value: formatMoney(overview.toReceive),
          color: tt.primary,
          hint: t.finInterestToCome(formatMoney(overview.interestToCome)),
        ),
        (
          label: t.finInterestReceived,
          value: formatMoney(overview.interestReceived),
          color: tt.palette.green,
          hint: t.finLentTotal(formatMoney(overview.lentTotal)),
        ),
        (
          label: t.finOverdueAmount,
          value: formatMoney(overview.overdue),
          color: overview.overdue > 0 ? tt.overdue : null,
          hint: t.finLoansCount(overview.overdueCount),
        ),
      ],
    );
  }
}

/// "Em dia", "Atrasado há N dias", "Quitado" and its color.
(String, Color) loanStatusLabel(BuildContext context, LoanSummary l) {
  final t = AppLocalizations.of(context);
  final tt = context.tt;
  return switch (l.status) {
    LoanStatus.onTime => (t.finLoanOnTime, tt.primary),
    LoanStatus.overdue => (t.finLoanLate(l.daysLate), tt.overdue),
    LoanStatus.paid => (t.finLoanPaid, tt.palette.green),
  };
}

/// Deletes a loan and its payments, after asking; then "Empréstimo excluído" with Desfazer. [close]
/// runs just before (the detail or the form closing itself).
Future<void> deleteLoan(BuildContext context, FinanceRepository repo, Loan loan, {VoidCallback? close}) async {
  final t = AppLocalizations.of(context);
  if (!await confirm(context, message: t.finDeleteLoan(loan.borrower), confirmLabel: t.actionDelete)) return;
  if (!context.mounted) return;
  final page = Navigator.of(context).context;
  close?.call();
  await repo.deleteLoan(loan.id);
  if (page.mounted) showToast(page, t.finLoanDeleted, undo: () => repo.restoreLoan(loan.id), redo: () => repo.deleteLoan(loan.id));
}

/// A loan as a line of the Agenda: the status' dot and word, the borrower, what is left and the
/// profit; a click opens its detail, its ⋯ also edits, records a payment or deletes.
class _LoanLine extends ConsumerWidget {
  const _LoanLine({required this.summary});

  final LoanSummary summary;

  Future<void> _menu(BuildContext context, WidgetRef ref, Offset at) async {
    final t = AppLocalizations.of(context);
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'open', height: 36, child: Text(t.calendarOpen)),
        PopupMenuItem(value: 'edit', height: 36, child: Text(t.finEditLoan)),
        if (summary.balance > 0) PopupMenuItem(value: 'pay', height: 36, child: Text(t.finAddLoanPayment)),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Text(t.actionDelete, style: TextStyle(color: context.tt.overdue)),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (picked) {
      case 'open':
        await showLoanDetail(context, summary.loan.id);
      case 'edit':
        await showLoanForm(context, editing: summary);
      case 'pay':
        await showFinanceDialog<void>(context, builder: (_) => _LoanPaymentForm(summary: summary));
      case 'delete':
        await deleteLoan(context, ref.read(financeRepositoryProvider), summary.loan);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final loan = summary.loan;
    final (status, color) = loanStatusLabel(context, summary);
    return AgendaLine(
      color: color,
      secondary: status,
      title: loan.borrower,
      subtitle: t.finProfit(formatMoney(summary.interest), formatPercent(summary.rate)),
      struck: summary.status == LoanStatus.paid,
      faded: summary.status == LoanStatus.paid,
      onTap: () => unawaited(showLoanDetail(context, loan.id)),
      onMenu: (at) => unawaited(_menu(context, ref, at)),
      trailing: Text(
        summary.status == LoanStatus.paid ? formatMoney(loan.total) : t.finLoanLeft(formatMoney(summary.balance)),
        style: TextStyle(color: summary.status == LoanStatus.overdue ? tt.overdue : tt.text, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// A loan: its numbers, its payments, "Registrar pagamento", Editar and Excluir.
Future<void> showLoanDetail(BuildContext context, String loanId) => showFinanceDialog<void>(context, builder: (_) => _LoanDetail(loanId: loanId));

class _LoanDetail extends ConsumerWidget {
  const _LoanDetail({required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final summary = loanSummaries(s, today).where((l) => l.loan.id == loanId).firstOrNull;
    if (summary == null) {
      // Deleted (from the form over it): nothing left to show.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) unawaited(Navigator.maybePop(context));
      });
      return const SizedBox.shrink();
    }
    final loan = summary.loan;
    final repo = ref.read(financeRepositoryProvider);
    final (status, color) = loanStatusLabel(context, summary);

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
              Expanded(
                child: Text(loan.borrower, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                tooltip: t.actionEdit,
                icon: Icon(Icons.edit_outlined, color: tt.textSecondary),
                onPressed: () => unawaited(showLoanForm(context, editing: summary)),
              ),
              IconButton(
                tooltip: t.actionDelete,
                icon: Icon(Icons.delete_outline, color: tt.textSecondary),
                onPressed: () => unawaited(deleteLoan(context, repo, loan, close: () => Navigator.pop(context))),
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
              Text(
                status,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              line(t.finLent, formatMoney(loan.principal)),
              line(t.finLoanTotal, formatMoney(loan.total)),
              line(t.finProfitLabel, '${formatMoney(summary.interest)} (${formatPercent(summary.rate)})', valueColor: tt.palette.green),
              line(t.finReceived, formatMoney(summary.received)),
              line(t.finInterestReceived, formatMoney(summary.interestReceived), valueColor: tt.palette.green),
              line(t.finLoanBalance, formatMoney(summary.balance), valueColor: summary.balance > 0 ? tt.overdue : null),
              line(t.finLentOn, DateLabels.numeric(finDay(loan.lentOn))),
              line(t.finDueDate, DateLabels.numeric(finDay(loan.dueOn))),
              if (loan.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(loan.note, style: TextStyle(color: tt.textSecondary)),
                ),
              const SizedBox(height: 16),
              if (summary.balance > 0)
                FilledButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t.finAddLoanPayment),
                  onPressed: () => unawaited(showFinanceDialog<void>(context, builder: (_) => _LoanPaymentForm(summary: summary))),
                ),
              if (summary.payments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
                  child: Text(
                    t.finPayments,
                    style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w600, color: tt.textSecondary),
                  ),
                ),
              for (final p in summary.payments)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () => unawaited(
                    showFinanceDialog<void>(
                      context,
                      builder: (_) => _LoanPaymentForm(summary: summary, editing: p),
                    ),
                  ),
                  leading: Icon(Icons.check_circle_outline, color: tt.palette.green),
                  title: Text(formatMoney(p.amount), style: TextStyle(color: tt.text)),
                  subtitle: Text(
                    [DateLabels.numeric(finDay(p.date)), if (p.note.isNotEmpty) p.note].join(' · '),
                    style: TextStyle(color: tt.textTertiary),
                  ),
                  trailing: IconButton(
                    tooltip: t.actionDelete,
                    icon: Icon(Icons.close, size: 18, color: tt.textTertiary),
                    onPressed: () async {
                      await repo.deleteLoanPayment(p.id);
                      if (context.mounted) {
                        showToast(
                          context,
                          t.finPaymentDeleted,
                          undo: () => repo.deleteLoanPayment(p.id, restore: true),
                          redo: () => repo.deleteLoanPayment(p.id),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Registrar pagamento"; [editing] a payment made.
class _LoanPaymentForm extends ConsumerStatefulWidget {
  const _LoanPaymentForm({required this.summary, this.editing});

  final LoanSummary summary;
  final LoanPayment? editing;

  @override
  ConsumerState<_LoanPaymentForm> createState() => _LoanPaymentFormState();
}

class _LoanPaymentFormState extends ConsumerState<_LoanPaymentForm> {
  late final _amount = TextEditingController(text: formatMoney(widget.editing?.amount ?? widget.summary.balance, symbol: false));
  late final _note = TextEditingController(text: widget.editing?.note ?? '');
  late DateTime _date = widget.editing == null ? startOfDay(ref.read(clockProvider).now()) : finDay(widget.editing!.date);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseMoney(_amount.text);
    if (amount == null || amount <= 0) return;
    final repo = ref.read(financeRepositoryProvider);
    if (widget.editing case final p?) {
      await repo.updateLoanPayment(p.id, amount: amount, date: _date, note: _note.text);
    } else {
      await repo.addLoanPayment(loanId: widget.summary.loan.id, amount: amount, date: _date, note: _note.text);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete(LoanPayment p) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(financeRepositoryProvider);
    final page = Navigator.of(context).context;
    Navigator.pop(context);
    await repo.deleteLoanPayment(p.id);
    if (page.mounted) {
      showToast(page, t.finPaymentDeleted, undo: () => repo.deleteLoanPayment(p.id, restore: true), redo: () => repo.deleteLoanPayment(p.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(
          title: widget.editing == null ? t.finAddLoanPayment : t.finEditPayment,
          onSave: () => unawaited(_save()),
          onDelete: switch (widget.editing) {
            final p? => () => unawaited(_delete(p)),
            null => null,
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.finLoanLeft(formatMoney(widget.summary.balance)), style: TextStyle(color: tt.textSecondary)),
              const SizedBox(height: 8),
              MoneyField(controller: _amount, label: t.finPaymentAmount, autofocus: true, onSubmitted: () => unawaited(_save())),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today_outlined, color: tt.textSecondary),
                title: Text(
                  t.finPaymentDate,
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

/// "Novo empréstimo" / "Editar empréstimo": the borrower, the amount lent and when, the due day,
/// and the interest either as a rate or as the total to receive (each fills the other in); the
/// profit shows below.
Future<void> showLoanForm(BuildContext context, {LoanSummary? editing}) =>
    showFinanceDialog<void>(context, builder: (_) => _LoanForm(editing: editing));

class _LoanForm extends ConsumerStatefulWidget {
  const _LoanForm({this.editing});

  final LoanSummary? editing;

  @override
  ConsumerState<_LoanForm> createState() => _LoanFormState();
}

class _LoanFormState extends ConsumerState<_LoanForm> {
  late final _loan = widget.editing?.loan;
  late final _borrower = TextEditingController(text: _loan?.borrower ?? '');
  late final _principal = TextEditingController(text: _loan == null ? '' : formatMoney(_loan.principal, symbol: false));
  late final _rate = TextEditingController(text: widget.editing == null ? '' : formatPercent(widget.editing!.rate).replaceAll('%', ''));
  late final _total = TextEditingController(text: _loan == null ? '' : formatMoney(_loan.total, symbol: false));
  late final _note = TextEditingController(text: _loan?.note ?? '');
  late DateTime _lentOn = _loan == null ? startOfDay(ref.read(clockProvider).now()) : finDay(_loan.lentOn);
  late DateTime _dueOn = _loan == null ? DateTime(_lentOn.year, _lentOn.month + 1, _lentOn.day) : finDay(_loan.dueOn);
  late bool _remind = _loan?.remind ?? true;
  bool _showError = false;

  @override
  void dispose() {
    for (final c in [_borrower, _principal, _rate, _total, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The rate typed: the total follows.
  void _fromRate() {
    final principal = parseMoney(_principal.text), rate = parsePercent(_rate.text);
    if (principal == null || rate == null) return setState(() {});
    _total.text = formatMoney(principal + (principal * rate / 10000).round(), symbol: false);
    setState(() => _showError = false);
  }

  /// The total typed: the rate follows.
  void _fromTotal() {
    final principal = parseMoney(_principal.text), total = parseMoney(_total.text);
    if (principal == null || principal == 0 || total == null) return setState(() {});
    _rate.text = formatPercent(((total - principal) * 10000 / principal).round()).replaceAll('%', '');
    setState(() => _showError = false);
  }

  Future<void> _save() async {
    final principal = parseMoney(_principal.text), total = parseMoney(_total.text);
    final borrower = _borrower.text.trim();
    if (borrower.isEmpty || principal == null || principal <= 0 || total == null || total < principal) {
      setState(() => _showError = true);
      return;
    }
    final repo = ref.read(financeRepositoryProvider);
    final loan = _loan;
    if (loan == null) {
      await repo.createLoan(
        borrower: borrower,
        principal: principal,
        total: total,
        lentOn: _lentOn,
        dueOn: _dueOn,
        note: _note.text,
        remind: _remind,
      );
    } else {
      await repo.updateLoan(
        loan.id,
        borrower: borrower,
        principal: principal,
        total: total,
        lentOn: _lentOn,
        dueOn: _dueOn,
        note: _note.text,
        remind: _remind,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final principal = parseMoney(_principal.text), total = parseMoney(_total.text);
    final profit = principal == null || total == null ? null : total - principal;

    Widget dateTile(String label, DateTime value, ValueChanged<DateTime> onPicked) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.event_outlined, color: tt.textSecondary),
      title: Text(
        label,
        style: TextStyle(color: tt.textSecondary, fontSize: TtText.small),
      ),
      subtitle: Text(DateLabels.numeric(value), style: TextStyle(color: tt.text)),
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked != null) setState(() => onPicked(picked));
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(
          title: _loan == null ? t.finNewLoan : t.finEditLoan,
          onSave: () => unawaited(_save()),
          onDelete: switch (_loan) {
            final loan? => () => unawaited(deleteLoan(context, ref.read(financeRepositoryProvider), loan, close: () => Navigator.pop(context))),
            null => null,
          },
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              TextField(
                controller: _borrower,
                autofocus: _loan == null,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: t.finBorrower, isDense: true),
              ),
              const SizedBox(height: 8),
              MoneyField(controller: _principal, label: t.finLent, onChanged: (_) => _rate.text.isEmpty ? _fromTotal() : _fromRate()),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rate,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: t.finInterestRate, suffixText: '%', isDense: true),
                      onChanged: (_) => _fromRate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MoneyField(controller: _total, label: t.finLoanTotal, onChanged: (_) => _fromTotal()),
                  ),
                ],
              ),
              if (profit != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    t.finProfitPreview(formatMoney(profit)),
                    style: TextStyle(color: profit < 0 ? tt.overdue : tt.palette.green, fontWeight: FontWeight.w600),
                  ),
                ),
              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.finLoanInvalid,
                    style: TextStyle(color: tt.overdue, fontSize: TtText.small),
                  ),
                ),
              dateTile(t.finLentOn, _lentOn, (d) => _lentOn = d),
              dateTile(t.finDueDate, _dueOn, (d) => _dueOn = d),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.finLoanRemind),
                value: _remind,
                onChanged: (v) => setState(() => _remind = v),
              ),
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
