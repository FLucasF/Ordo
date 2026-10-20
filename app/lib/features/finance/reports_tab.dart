import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../domain/finance/finance.dart';
import '../../domain/finance/goals.dart';
import '../../domain/finance/loans.dart';
import '../../domain/finance/money.dart';
import '../../domain/finance/reports.dart';
import '../../l10n/app_localizations.dart';
import '../common/shell_widgets.dart';
import '../statistics/charts.dart';
import 'finance_widgets.dart';
import 'loans_tab.dart';

/// "Relatórios" of [month] (chosen in the top bar or the panel): the expenses by category, income ×
/// expenses of the last 6 months, [month] against [compare] by category, and the loans.
class ReportsBody extends ConsumerStatefulWidget {
  const ReportsBody({super.key, required this.month, required this.compare, required this.onCompare, required this.today});

  final DateTime month;
  final DateTime compare;
  final ValueChanged<DateTime> onCompare;
  final DateTime today;

  @override
  ConsumerState<ReportsBody> createState() => _ReportsBodyState();
}

class _ReportsBodyState extends ConsumerState<ReportsBody> {
  /// "Receitas × despesas" by category ("Detalhado") or as one income and one expense ("Geral").
  bool _detailed = false;

  @override
  Widget build(BuildContext context) {
    final ReportsBody(:month, :compare, :onCompare, :today) = widget;
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final slices = expensesByCategory(s, month);
    final spent = slices.fold(0, (sum, x) => sum + x.amount);
    final months = monthlyFlows(s, month, 6);
    final compared = compareMonths(s, compare, month);
    // Lime: none of the categories' palette, so the loans' profit stands apart in both views.
    const interestColor = Color(0xFF9DCC1F);

    final legend = Column(
      children: [
        for (final slice in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: categoryColor(context, s, slice.category), shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${slice.category?.icon ?? ''} ${categoryName(t, slice.category)}'.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tt.text),
                  ),
                ),
                Text(
                  formatPercent((slice.amount * 100 / spent).round() * 100),
                  style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                ),
                const SizedBox(width: 12),
                Text(
                  formatMoney(slice.amount),
                  style: TextStyle(color: tt.text, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
    final donut = DonutChart(
      size: 150,
      parts: [for (final slice in slices) (slice.amount.toDouble(), categoryColor(context, s, slice.category))],
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.finExpenses, style: TextStyle(fontSize: 11, color: tt.textTertiary)),
          FittedBox(
            child: Text(
              formatMoney(spent),
              style: TextStyle(fontWeight: FontWeight.w700, color: tt.text),
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 0, narrow ? 12 : 20, 32),
      children: [
        BodyHeading(t.finByCategory),
        if (slices.isEmpty)
          Text(t.finNoExpenses, style: TextStyle(color: tt.textTertiary))
        else if (narrow)
          Column(children: [donut, const SizedBox(height: 12), legend])
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              donut,
              const SizedBox(width: 32),
              Flexible(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: legend),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Divider(height: 1, color: tt.divider),
        BodyHeading(
          t.finIncomeVsExpenses,
          trailing: SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: false, label: Text(t.finChartGeneral, style: const TextStyle(fontSize: 12))),
              ButtonSegment(value: true, label: Text(t.finChartDetailed, style: const TextStyle(fontSize: 12))),
            ],
            selected: {_detailed},
            onSelectionChanged: (v) => setState(() => _detailed = v.single),
          ),
        ),
        if (_detailed)
          ..._detailedChart(context, s, months, interestColor, narrow)
        else ...[
          PairedBarChart(
            labels: [for (final m in months) dates.monthShort(m.month).toUpperCase()],
            first: [
              for (final m in months) [(m.entriesIncome, tt.palette.green), (m.interest, interestColor)],
            ],
            second: [
              for (final m in months) [(m.totals.expense, tt.overdue)],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _LegendItem(color: tt.palette.green, name: t.finIncomes, amount: months.last.entriesIncome),
              _LegendItem(color: interestColor, name: t.finLoanInterest, amount: months.last.interest),
              _LegendItem(color: tt.overdue, name: t.finExpenses, amount: months.last.totals.expense),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            for (final m in months.reversed.take(3))
              Text(
                '${dates.monthShort(m.month)}: ${t.finBalance} ${formatMoney(m.totals.balance)}',
                style: TextStyle(fontSize: TtText.small, color: m.totals.balance < 0 ? tt.overdue : tt.textSecondary),
              ),
          ],
        ),
        // The goals apart: money set aside is a transfer, in none of the bars.
        if (s.goals.isNotEmpty)
          if (goalsSaved(s, month) case (:final total, :final inMonth))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t.finGoalsSavedLine(formatMoney(total), '${inMonth < 0 ? '-' : '+'}${formatMoney(inMonth.abs())}'),
                style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
              ),
            ),
        const SizedBox(height: 8),
        Divider(height: 1, color: tt.divider),
        BodyHeading(
          t.finCompareMonths,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.chevron_left, size: 18, color: tt.textSecondary),
                onPressed: () => onCompare(DateTime(compare.year, compare.month - 1)),
              ),
              Text(
                '${dates.monthTitle(compare)} ${t.finVersus} ${dates.monthTitle(month)}',
                style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.chevron_right, size: 18, color: tt.textSecondary),
                onPressed: () => onCompare(DateTime(compare.year, compare.month + 1)),
              ),
            ],
          ),
        ),
        if (compared.isEmpty)
          Text(t.finNoExpenses, style: TextStyle(color: tt.textTertiary))
        else
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _CompareTable(rows: compared, first: dates.monthShort(compare), second: dates.monthShort(month)),
            ),
          ),
        const SizedBox(height: 8),
        Divider(height: 1, color: tt.divider),
        BodyHeading(t.finLoansSummary),
        LoansFigures(overview: loansOverview(loanSummaries(s, today))),
      ],
    );
  }

  /// The bars split by category (the loans' profit a part of its own on top of the income) and,
  /// below them, what came in and went out in the report's month by category.
  List<Widget> _detailedChart(BuildContext context, FinanceSnapshot s, List<MonthFlow> months, Color interestColor, bool narrow) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    // The biggest of the six months at the bottom of the bars.
    List<String?> order(Map<String?, int> Function(MonthFlow m) of) {
      final sums = <String?, int>{};
      for (final m in months) {
        for (final MapEntry(key: id, value: amount) in of(m).entries) {
          sums[id] = (sums[id] ?? 0) + amount;
        }
      }
      return sums.keys.toList()..sort((a, b) => sums[b]!.compareTo(sums[a]!));
    }

    final incomeIds = order((m) => m.income), expenseIds = order((m) => m.expense);
    FinCategory? category(String? id) => id == null ? null : s.categoryById[id];
    Color color(String? id) => categoryColor(context, s, category(id));
    String name(String? id) => '${category(id)?.icon ?? ''} ${categoryName(t, category(id))}'.trim();
    final last = months.last;
    final incomeLines = [
      for (final id in incomeIds)
        if ((last.income[id] ?? 0) > 0) (color(id), name(id), last.income[id]!),
      if (last.interest > 0) (interestColor, t.finLoanInterest, last.interest),
    ]..sort((a, b) => b.$3.compareTo(a.$3));
    final expenseLines = [
      for (final id in expenseIds)
        if ((last.expense[id] ?? 0) > 0) (color(id), name(id), last.expense[id]!),
    ];

    Widget side(String title, List<(Color, String, int)> lines) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$title · ${dates.monthTitle(last.month)}',
          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        if (lines.isEmpty)
          Text('—', style: TextStyle(color: tt.textTertiary))
        else
          for (final (c, n, amount) in lines) _LegendItem(color: c, name: n, amount: amount, expand: true),
      ],
    );

    return [
      PairedBarChart(
        labels: [for (final m in months) dates.monthShort(m.month).toUpperCase()],
        first: [
          for (final m in months) [for (final id in incomeIds) (m.income[id] ?? 0, color(id)), (m.interest, interestColor)],
        ],
        second: [
          for (final m in months) [for (final id in expenseIds) (m.expense[id] ?? 0, color(id))],
        ],
      ),
      const SizedBox(height: 12),
      if (narrow)
        Column(children: [side(t.finIncomes, incomeLines), const SizedBox(height: 12), side(t.finExpenses, expenseLines)])
      else
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: side(t.finIncomes, incomeLines)),
                const SizedBox(width: 32),
                Expanded(child: side(t.finExpenses, expenseLines)),
              ],
            ),
          ),
        ),
    ];
  }
}

/// A color dot, a name and an amount; [expand] spreads them over a whole line.
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.name, required this.amount, this.expand = false});

  final Color color;
  final String name;
  final int amount;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final label = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: expand ? 3 : 0),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          if (expand) Expanded(child: label) else label,
          const SizedBox(width: 8),
          Text(
            formatMoney(amount),
            style: TextStyle(fontSize: TtText.small, color: tt.text, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.rows, required this.first, required this.second});

  final List<CategoryComparison> rows;
  final String first;
  final String second;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final head = TextStyle(fontSize: TtText.small, color: tt.textTertiary, fontWeight: FontWeight.w600);
    final firstTotal = rows.fold(0, (sum, r) => sum + r.first), secondTotal = rows.fold(0, (sum, r) => sum + r.second);

    Widget row(String name, int a, int b, {bool bold = false}) {
      final change = changeBasisPoints(a, b);
      final style = TextStyle(color: tt.text, fontWeight: bold ? FontWeight.w700 : FontWeight.w400);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
            ),
            Expanded(
              flex: 2,
              child: Text(formatMoney(a), textAlign: TextAlign.end, style: style),
            ),
            Expanded(
              flex: 2,
              child: Text(formatMoney(b), textAlign: TextAlign.end, style: style),
            ),
            SizedBox(
              width: 64,
              child: Text(
                change == null ? '—' : '${change > 0 ? '+' : ''}${formatPercent(change)}',
                textAlign: TextAlign.end,
                // Spending more is red; less, green.
                style: TextStyle(
                  fontSize: TtText.small,
                  color: change == null || change == 0
                      ? tt.textTertiary
                      : change > 0
                      ? tt.overdue
                      : tt.palette.green,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: Text(t.finCategory, style: head)),
            Expanded(
              flex: 2,
              child: Text(first, textAlign: TextAlign.end, style: head),
            ),
            Expanded(
              flex: 2,
              child: Text(second, textAlign: TextAlign.end, style: head),
            ),
            SizedBox(
              width: 64,
              child: Text(t.finChange, textAlign: TextAlign.end, style: head),
            ),
          ],
        ),
        for (final r in rows) row('${r.category?.icon ?? ''} ${categoryName(t, r.category)}'.trim(), r.first, r.second),
        Divider(color: tt.divider),
        row(t.finTotal, firstTotal, secondTotal, bold: true),
      ],
    );
  }
}

/// A bar's parts from the bottom up: an amount and its color.
typedef BarParts = List<(int, Color)>;

/// Two bars per label side by side (income and expenses of each month), each one stacked from its
/// parts.
class PairedBarChart extends StatelessWidget {
  const PairedBarChart({super.key, required this.labels, required this.first, required this.second, this.height = 170});

  final List<String> labels;
  final List<BarParts> first;
  final List<BarParts> second;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _PairedBarPainter(
          labels: labels,
          first: first,
          second: second,
          grid: tt.divider,
          label: TextStyle(fontSize: 11, color: tt.textTertiary),
        ),
      ),
    );
  }
}

class _PairedBarPainter extends CustomPainter {
  const _PairedBarPainter({required this.labels, required this.first, required this.second, required this.grid, required this.label});

  final List<String> labels;
  final List<BarParts> first;
  final List<BarParts> second;
  final Color grid;
  final TextStyle label;

  static int _sum(BarParts parts) => parts.fold(0, (sum, p) => sum + p.$1);

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final top = [...first, ...second].map(_sum).fold(0, math.max);
    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), Paint()..color = grid);
    if (labels.isEmpty) return;
    final slot = size.width / labels.length;
    final bar = math.min(18.0, slot / 3);
    for (var i = 0; i < labels.length; i++) {
      final center = slot * i + slot / 2;
      for (final (parts, dx) in [(first[i], -bar - 1), (second[i], 1.0)]) {
        final h = top == 0 ? 0.0 : chartHeight * _sum(parts) / top;
        if (h <= 0) continue;
        // The parts are cut to the whole bar's rounded top.
        canvas
          ..save()
          ..clipRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(center + dx, chartHeight - h, bar, h),
              topLeft: const Radius.circular(3),
              topRight: const Radius.circular(3),
            ),
          );
        var bottom = chartHeight;
        for (final (value, color) in parts) {
          if (value <= 0) continue;
          final part = chartHeight * value / top;
          canvas.drawRect(Rect.fromLTWH(center + dx, bottom - part, bar, part), Paint()..color = color);
          bottom -= part;
        }
        canvas.restore();
      }
      final text = TextPainter(
        text: TextSpan(text: labels[i], style: label),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: slot);
      text.paint(canvas, Offset(center - text.width / 2, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(_PairedBarPainter old) => old.first != first || old.second != second || old.labels != labels;
}
