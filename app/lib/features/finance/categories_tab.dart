import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../domain/finance/finance.dart';
import '../../domain/finance/finance_enums.dart';
import '../../domain/finance/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/reorderable_rows.dart';
import '../common/emoji_picker.dart';
import '../common/feedback.dart';
import '../common/shell_widgets.dart';
import 'finance_widgets.dart';

/// "Categorias" of [month]: expenses and income, each category with the month's total; one with a
/// limit shows how much of it is gone (orange from 80%, red past it).
class CategoriesBody extends ConsumerWidget {
  const CategoriesBody({super.key, required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final monthEntries = entriesOfMonth(s, month);
    int totalOf(String id) => monthEntries.where((e) => e.categoryId == id).fold(0, (sum, e) => sum + e.amount);

    Widget section(FinKind kind, String title) => BodyHeading(
      title,
      trailing: IconButton(
        tooltip: t.finNewCategory,
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.add, size: 18, color: tt.textSecondary),
        onPressed: () => unawaited(showCategoryForm(context, kind: kind)),
      ),
    );

    // Each kind's categories are put in order by dragging.
    Widget rows(FinKind kind) {
      final categories = s.categoriesOf(kind);
      return ReorderableRows(
        orders: [for (final c in categories) c.sortOrder],
        onReorder: (changed) => unawaited(
          ref.read(financeRepositoryProvider).reorderCategories({for (final e in changed.entries) categories[e.key].id: e.value}),
        ),
        rows: [
          for (final c in categories)
            (key: ValueKey(c.id), build: (handle) => _CategoryRow(category: c, total: totalOf(c.id), color: categoryColor(context, s, c), handle: handle)),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 0, narrow ? 12 : 20, 32),
      children: [
        section(FinKind.expense, t.finExpenses),
        rows(FinKind.expense),
        const SizedBox(height: 8),
        Divider(height: 1, color: tt.divider),
        section(FinKind.income, t.finIncomes),
        rows(FinKind.income),
      ],
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category, required this.total, required this.color, this.handle});

  final FinCategory category;
  final int total;

  /// The drag handle ([ReorderableRows]).
  final Widget? handle;

  /// The category's color: its dot, as in the panel and the charts.
  final Color color;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    if (!await confirm(context, message: t.finDeleteCategory(category.name), confirmLabel: t.actionDelete)) return;
    await ref.read(financeRepositoryProvider).deleteCategory(category.id);
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, Offset at) async {
    final t = AppLocalizations.of(context);
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'edit', height: 36, child: Text(t.actionEdit)),
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
        await showCategoryForm(context, editing: category, kind: category.kind);
      case 'delete':
        await _delete(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final limit = category.monthlyLimit;
    final status = limit == null ? null : LimitStatus(category: category, spent: total, limit: limit);
    final barColor = switch (status?.level) {
      LimitLevel.over => tt.overdue,
      LimitLevel.near => tt.palette.priorityMedium,
      _ => tt.primary,
    };
    return GestureDetector(
      onSecondaryTapUp: (d) => unawaited(_menu(context, ref, d.globalPosition)),
      onLongPressStart: (d) => unawaited(_menu(context, ref, d.globalPosition)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => unawaited(showCategoryForm(context, editing: category, kind: category.kind)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(handle == null ? 4 : 0, 8, 4, 8),
          child: Row(
            children: [
              if (handle case final handle?) SizedBox(width: 18, child: handle),
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${category.icon} ${category.name}'.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: tt.text, fontSize: TtText.body, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          status == null
                              ? t.finSpentThisMonth(formatMoney(total))
                              : t.finLimitProgress(formatMoney(total), formatMoney(status.limit)),
                          style: TextStyle(
                            fontSize: TtText.small,
                            color: status != null && status.level != LimitLevel.ok ? barColor : tt.textTertiary,
                          ),
                        ),
                        RowMenuButton(onMenu: (at) => unawaited(_menu(context, ref, at))),
                      ],
                    ),
                    if (status != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: status.share.clamp(0, 1).toDouble(),
                          minHeight: 5,
                          color: barColor,
                          backgroundColor: tt.fieldFill,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Nova categoria" / "Editar categoria": name, emoji and, for expenses, the monthly limit.
Future<void> showCategoryForm(BuildContext context, {FinCategory? editing, required FinKind kind}) => showFinanceDialog<void>(
  context,
  builder: (_) => _CategoryForm(editing: editing, kind: kind),
);

class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({this.editing, required this.kind});

  final FinCategory? editing;
  final FinKind kind;

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late final _limit = TextEditingController(
    text: widget.editing?.monthlyLimit == null ? '' : formatMoney(widget.editing!.monthlyLimit!, symbol: false),
  );
  late String _icon = widget.editing?.icon ?? '';

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _delete(FinCategory category) async {
    final t = AppLocalizations.of(context);
    if (!await confirm(context, message: t.finDeleteCategory(category.name), confirmLabel: t.actionDelete)) return;
    await ref.read(financeRepositoryProvider).deleteCategory(category.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    // An empty or zero limit means "Sem limite".
    final limit = widget.kind == FinKind.expense ? parseMoney(_limit.text) : null;
    final repo = ref.read(financeRepositoryProvider);
    final editing = widget.editing;
    if (editing == null) {
      await repo.createCategory(name: name, kind: widget.kind, icon: _icon, monthlyLimit: limit == 0 ? null : limit);
    } else {
      await repo.updateCategory(editing.id, name: name, icon: _icon, color: editing.color, monthlyLimit: limit == 0 ? null : limit);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FormHeader(
          title: widget.editing == null ? t.finNewCategory : t.finEditCategory,
          onSave: () => unawaited(_save()),
          onDelete: switch (widget.editing) {
            final category? => () => unawaited(_delete(category)),
            null => null,
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      autofocus: widget.editing == null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: t.finCategoryName, isDense: true),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => unawaited(_save()),
                    ),
                  ),
                ],
              ),
              if (widget.kind == FinKind.expense) ...[
                const SizedBox(height: 12),
                MoneyField(controller: _limit, label: t.finMonthlyLimit, onSubmitted: () => unawaited(_save())),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.finLimitHint,
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
