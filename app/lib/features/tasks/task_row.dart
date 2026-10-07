import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../focus/focus_estimate.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/task_dates.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/labels.dart';

/// Task checkbox: the border takes the priority color; notes show a note icon.
class TaskCheckbox extends StatelessWidget {
  const TaskCheckbox({
    super.key,
    required this.status,
    required this.priority,
    required this.kind,
    required this.onTap,
    this.size = TtSizes.checkbox,
  });

  final TaskStatus status;
  final Priority priority;
  final TaskKind kind;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    if (kind == TaskKind.note) return Icon(Icons.sticky_note_2_outlined, size: size, color: tt.textTertiary);
    final closed = status != TaskStatus.open;
    final color = closed ? tt.textFaint : tt.priorityColor(priority);
    return InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(4),
          color: closed ? color : (priority == Priority.none ? null : color.withValues(alpha: 0.1)),
        ),
        child: switch (status) {
          TaskStatus.completed => Icon(Icons.check, size: size - 4, color: tt.screen),
          TaskStatus.wontDo => Icon(Icons.close, size: size - 4, color: tt.screen),
          TaskStatus.open => kind == TaskKind.checklist ? Icon(Icons.format_list_bulleted, size: size - 6, color: color) : null,
        },
      ),
    );
  }
}

/// One task row of the list. 40 px high, like the webapp.
class TaskRowTile extends ConsumerStatefulWidget {
  const TaskRowTile({
    super.key,
    required this.row,
    required this.selected,
    required this.now,
    required this.showDetails,
    required this.onTap,
    required this.onToggleComplete,
    required this.onToggleCollapse,
    required this.onMenu,
    this.countdown = false,
    this.longPressMenu = true,
  });

  final TaskRow row;
  final bool selected;
  final DateTime now;
  final bool showDetails;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onToggleCollapse;
  final void Function(Offset globalPosition) onMenu;

  /// Show the date as a countdown ("em 3 dias").
  final bool countdown;

  /// A long press opens [onMenu]; off where the long press starts a drag instead.
  final bool longPressMenu;

  @override
  ConsumerState<TaskRowTile> createState() => _TaskRowTileState();
}

class _TaskRowTileState extends ConsumerState<TaskRowTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    final row = widget.row;
    final task = row.task;
    final closed = task.status != TaskStatus.open;
    final prefs = ref.watch(preferencesProvider).value;
    final strike = prefs?.strikeCompleted ?? false;
    // "Cor da Lista": a stripe with the list's color on rows outside the list.
    final listColor = (prefs?.showListColor ?? true) ? parseHexColor(row.list?.color) : null;
    final indent = 16.0 + TtSizes.subtaskIndent * row.depth;
    final titleLeft = indent + TtSizes.checkbox + 7;
    final today = startOfDay(widget.now);
    final due = task.dueDate?.toLocal();
    // Red only for earlier days: a task due today whose time has passed stays blue, as in TickTick.
    final overdue = due != null && !closed && daysBetween(today, due) < 0;
    final snippet = widget.showDetails ? _details(task) : null;

    return GestureDetector(
      onSecondaryTapDown: (d) => widget.onMenu(d.globalPosition),
      onLongPressStart: widget.longPressMenu ? (d) => widget.onMenu(d.globalPosition) : null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: TtSizes.rowHeight + (snippet == null ? 0 : 16)),
            decoration: BoxDecoration(color: widget.selected ? tt.selected : (_hover ? tt.hover : null), borderRadius: BorderRadius.circular(4)),
            child: Stack(
              children: [
                if (listColor != null)
                  Positioned(
                    left: 2,
                    top: 8,
                    bottom: 8,
                    width: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: listColor, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(left: indent, right: 30),
                  child: Row(
                    children: [
                      TaskCheckbox(status: task.status, priority: task.priority, kind: task.kind, onTap: widget.onToggleComplete),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                task.title.isEmpty ? t.untitled : task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: TtText.body,
                                  height: 21 / 14,
                                  color: closed || task.title.isEmpty ? tt.textTertiary : tt.text,
                                  decoration: task.status == TaskStatus.wontDo || (task.status == TaskStatus.completed && strike)
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (snippet != null)
                                Text(
                                  snippet,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                                ),
                            ],
                          ),
                        ),
                      ),
                      ..._trailing(context, tt, today, overdue),
                    ],
                  ),
                ),
                if (row.hasChildren)
                  Positioned(
                    left: indent - 18,
                    top: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: widget.onToggleCollapse,
                      child: Icon(row.isCollapsed ? Icons.chevron_right : Icons.expand_more, size: 16, color: tt.textTertiary),
                    ),
                  ),
                Positioned(
                  left: titleLeft,
                  right: 30,
                  bottom: 0,
                  child: Container(height: 1, color: tt.divider),
                ),
                // "…" on hover: the same menu as the right click.
                if (_hover)
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Builder(
                        builder: (context) => InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () {
                            final box = context.findRenderObject()! as RenderBox;
                            widget.onMenu(box.localToGlobal(box.size.bottomLeft(Offset.zero)));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(Icons.more_horiz, size: 16, color: tt.textTertiary),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Mostrar detalhes": the first open checklist item ("- item B") or the first line
  /// of the content, and the subtasks done ("1/3").
  String? _details(Task task) {
    final s = ref.read(snapshotProvider).value;
    if (s == null) return null;
    final firstItem = task.kind == TaskKind.checklist ? s.itemsOf(task.id).where((i) => !i.isCompleted).firstOrNull : null;
    final line = firstItem != null ? '- ${firstItem.title}' : task.content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).firstOrNull;
    final children = [
      for (final c in s.childrenOf(task.id))
        if (c.deletedAt == null) c,
    ];
    final count = children.isEmpty ? null : '${children.where((c) => c.status != TaskStatus.open).length}/${children.length}';
    final parts = [?line, ?count];
    return parts.isEmpty ? null : parts.join('   ');
  }

  List<Widget> _trailing(BuildContext context, TtColors tt, DateTime today, bool overdue) {
    // A time already past today is late too: "20:47" or, as a countdown, "4 M" in red.
    final dueAt = widget.row.task.dueDate?.toLocal();
    final late = overdue || (!widget.row.task.isAllDay && dueAt != null && dueAt.isBefore(widget.now));
    final row = widget.row;
    final task = row.task;
    final labels = Labels(AppLocalizations.of(context));
    final due = task.dueDate?.toLocal();
    final small = TextStyle(fontSize: TtText.small, color: tt.textTertiary);
    final maxTags = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint ? 0 : 3;
    // "Estimativa": "🍅 1/3" or "⏱ 20m/50m".
    final estimate = task.estimatedPomos != null || task.estimatedMinutes != null
        ? focusEstimateLabel(AppLocalizations.of(context), task, ref.watch(taskFocusProvider)[task.id])
        : null;
    return [
      if (estimate != null)
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(estimate, style: small),
        ),
      // On the phone the tags become a "+N" badge.
      for (final tag in row.tags.take(maxTags))
        Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: (parseHexColor(tag.color) ?? tt.textTertiary).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(tag.name, style: TextStyle(fontSize: 11, color: tt.textSecondary)),
        ),
      if (row.tags.length > maxTags)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('+${row.tags.length - maxTags}', style: TextStyle(fontSize: 11, color: tt.textTertiary)),
        ),
      if (row.list != null)
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(labels.listName(row.list!), style: small),
        ),
      if (row.hasChildren)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(Icons.account_tree_outlined, size: 14, color: tt.textTertiary),
        ),
      if (row.hasAttachment)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(Icons.attach_file, size: 14, color: tt.textTertiary),
        ),
      if (row.hasContent)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(Icons.notes, size: 14, color: tt.textTertiary),
        ),
      if (row.checklistProgress != null)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              value: row.checklistProgress! / 100,
              strokeWidth: 2.5,
              color: tt.textTertiary,
              backgroundColor: tt.divider,
            ),
          ),
        ),
      if (due != null && row.hasReminders)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(Icons.alarm, size: 14, color: tt.textTertiary),
        ),
      if (due != null && task.repeatRule != null)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(Icons.repeat, size: 14, color: tt.textTertiary),
        ),
      if (due != null)
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(switch ((task.hasDuration, widget.countdown)) {
            (true, false) => labels.dates.rowRange(task.startLocal!, due, isAllDay: task.isAllDay, today: today),
            // A task under way counts down to its end.
            (_, true) => labels.dates.rowCountdown(
              task.hasDuration && task.startLocal!.isAfter(today) ? task.startLocal! : due,
              isAllDay: task.isAllDay,
              today: today,
              now: widget.now,
            ),
            _ => labels.dates.rowDate(due, isAllDay: task.isAllDay, today: today),
          }, style: TextStyle(fontSize: TtText.small, color: task.status != TaskStatus.open ? tt.textTertiary : (late ? tt.overdue : tt.primary))),
        ),
    ];
  }
}

/// Keeps the date label logic reachable for widgets that only need the formatter.
DateLabels dateLabelsOf(BuildContext context) => DateLabels(AppLocalizations.of(context));
