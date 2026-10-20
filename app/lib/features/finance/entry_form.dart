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
import '../../domain/finance/finance_enums.dart';
import '../../domain/finance/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import 'finance_widgets.dart';

/// "Novo lançamento" / "Editar lançamento". [copy] starts a new one from an existing entry
/// ("Duplicar"); [cardId] starts a purchase on that card; [date] a new one on that day (the "+" of a
/// day in Lançamentos, the Calendar's "Novo lançamento neste dia").
Future<void> showEntryForm(
  BuildContext context, {
  FinEntry? editing,
  FinEntry? copy,
  FinKind kind = FinKind.expense,
  String? cardId,
  DateTime? date,
}) => showFinanceDialog<void>(
  context,
  builder: (_) => _EntryForm(editing: editing, copy: copy, kind: kind, cardId: cardId, date: date),
);

/// Deletes an entry: of a purchase in installments, asks for this one or all of them; then "Lançamento
/// excluído" with Desfazer. [close] runs just before (a form closing itself).
Future<void> deleteEntry(BuildContext context, FinanceRepository repo, FinEntry entry, {VoidCallback? close}) async {
  final t = AppLocalizations.of(context);
  var ids = [entry.id];
  final group = entry.installmentGroup;
  if (group != null) {
    final all = await repo.installmentIds(group);
    if (!context.mounted) return;
    final every = await showDialog<bool>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(t.finDeleteInstallments),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(context, false), child: Text(t.finDeleteOneInstallment)),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, true), child: Text(t.finDeleteAllInstallments(all.length))),
        ],
      ),
    );
    if (every == null) return;
    if (every) ids = all;
  }
  if (!context.mounted) return;
  // The toast outlives the line (and the form): it goes to the page.
  final page = Navigator.of(context).context;
  close?.call();
  await repo.deleteEntries(ids);
  if (page.mounted) showToast(page, t.finEntryDeleted, undo: () => repo.restoreEntries(ids), redo: () => repo.deleteEntries(ids));
}

/// After a new expense: a toast when its category is near or past the month's limit.
void showLimitAlert(BuildContext context, FinanceSnapshot s, String categoryId, DateTime month) {
  final t = AppLocalizations.of(context);
  final status = limitsOfMonth(s, month).where((l) => l.category.id == categoryId).firstOrNull;
  if (status == null || status.level == LimitLevel.ok) return;
  final spent = formatMoney(status.spent), limit = formatMoney(status.limit);
  showToast(
    context,
    status.level == LimitLevel.over
        ? t.finLimitOver(status.category.name, spent, limit)
        : t.finLimitNear(status.category.name, formatPercent((status.share * 100).floor() * 100), spent, limit),
  );
}

class _EntryForm extends ConsumerStatefulWidget {
  const _EntryForm({this.editing, this.copy, required this.kind, this.cardId, this.date});

  final FinEntry? editing;
  final FinEntry? copy;
  final FinKind kind;
  final String? cardId;
  final DateTime? date;

  @override
  ConsumerState<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends ConsumerState<_EntryForm> {
  late final FinEntry? _from = widget.editing ?? widget.copy;
  late FinKind _kind = _from?.kind ?? widget.kind;
  late final _amount = TextEditingController(text: _from == null ? '' : formatMoney(_from.amount, symbol: false));
  late final _description = TextEditingController(text: _from?.description ?? '');
  late final _note = TextEditingController(text: _from?.note ?? '');
  late DateTime _date = switch ((widget.date, _from)) {
    (final day?, _) => startOfDay(day),
    (null, final from?) => finDay(from.date),
    (null, null) => startOfDay(ref.read(clockProvider).now()),
  };
  late String? _categoryId = _from?.categoryId;
  late String? _cardId = _from?.cardId ?? widget.cardId;
  int _installments = 1;
  bool _showError = false;

  bool get _isNew => widget.editing == null;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseMoney(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _showError = true);
      return;
    }
    final repo = ref.read(financeRepositoryProvider);
    // Income never goes on a card.
    final cardId = _kind == FinKind.expense ? _cardId : null;
    final editing = widget.editing;
    final String savedId;
    if (editing == null) {
      final ids = await repo.addEntry(
        kind: _kind,
        amount: amount,
        date: _date,
        description: _description.text,
        categoryId: _categoryId,
        cardId: cardId,
        installments: _installments,
        note: _note.text,
      );
      savedId = ids.first;
    } else {
      await repo.updateEntry(
        editing.id,
        kind: _kind,
        amount: amount,
        date: _date,
        description: _description.text,
        categoryId: _categoryId,
        cardId: cardId,
        note: _note.text,
      );
      savedId = editing.id;
    }
    if (!mounted) return;
    // The toast outlives the form: it goes to the page under it.
    final pageContext = Navigator.of(context).context;
    Navigator.pop(context);
    final categoryId = _categoryId;
    if (_kind != FinKind.expense || categoryId == null) return;
    final s = await repo.load();
    final saved = s.entries.where((e) => e.id == savedId).firstOrNull;
    if (saved != null && pageContext.mounted) showLimitAlert(pageContext, s, categoryId, monthOf(countDay(s, saved)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final categories = s.categoriesOf(_kind);
    // A category of the other kind (after switching Receita/Despesa) no longer fits.
    final categoryId = categories.any((c) => c.id == _categoryId) ? _categoryId : null;
    final cards = [
      for (final c in s.cards)
        if (c.archivedAt == null || c.id == _cardId) c,
    ];
    final cardId = cards.any((c) => c.id == _cardId) ? _cardId : null;
    final amount = parseMoney(_amount.text) ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(
          title: _isNew ? t.finNewEntry : t.finEditEntry,
          onSave: () => unawaited(_save()),
          onDelete: switch (widget.editing) {
            final entry? => () => unawaited(deleteEntry(context, ref.read(financeRepositoryProvider), entry, close: () => Navigator.pop(context))),
            null => null,
          },
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              SegmentedButton<FinKind>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: FinKind.expense, label: Text(t.finExpense)),
                  ButtonSegment(value: FinKind.income, label: Text(t.finIncome)),
                ],
                selected: {_kind},
                onSelectionChanged: (v) => setState(() => _kind = v.first),
              ),
              const SizedBox(height: 12),
              MoneyField(
                controller: _amount,
                label: t.finAmount,
                autofocus: _isNew,
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
              TextField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: t.finDescription, isDense: true),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today_outlined, color: tt.textSecondary),
                title: Text(
                  t.finDate,
                  style: TextStyle(color: tt.textSecondary, fontSize: TtText.small),
                ),
                subtitle: Text(
                  DateLabels.numeric(_date),
                  style: TextStyle(color: tt.text, fontSize: TtText.body),
                ),
                onTap: () => unawaited(_pickDate()),
              ),
              DropdownButtonFormField<String?>(
                initialValue: categoryId,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.finCategory, isDense: true),
                items: [
                  DropdownMenuItem(value: null, child: Text(t.finNoCategory)),
                  for (final c in categories) DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'.trim())),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              if (_kind == FinKind.expense && cards.isNotEmpty) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: cardId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: t.finCard, isDense: true),
                  items: [
                    DropdownMenuItem(value: null, child: Text(t.finNoCard)),
                    for (final c in cards) DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _cardId = v),
                ),
                // Installments only when buying: an installment already saved keeps its series.
                if (cardId != null && _isNew) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _installments,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t.finInstallments, isDense: true),
                    items: [
                      for (var n = 1; n <= 24; n++)
                        DropdownMenuItem(value: n, child: Text(t.finInstallmentsValue(n, formatMoney(splitCents(amount, n).first)))),
                    ],
                    onChanged: (v) => setState(() => _installments = v ?? 1),
                  ),
                ],
              ],
              const SizedBox(height: 8),
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
