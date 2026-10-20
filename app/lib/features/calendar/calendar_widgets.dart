import 'package:flutter/material.dart';

import '../../app/format/date_labels.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../domain/calendar.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/subscriptions.dart';
import '../../domain/finance/finance_calendar.dart';
import '../../domain/finance/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../date_picker/date_picker.dart';

/// What the calendar views do on a click, a drop or a resize; the page implements them.
class CalendarActions {
  const CalendarActions({
    required this.open,
    required this.create,
    required this.move,
    required this.resize,
    required this.colorOf,
    required this.showDay,
    this.menu = _noMenu,
    this.isSelected = _none,
    this.look = const CalendarLook(),
  });

  static bool _none(CalendarEntry _) => false;
  static void _noMenu(CalendarEntry _, Offset _) {}

  /// Right click on an entry, at [position] on the screen.
  final void Function(CalendarEntry entry, Offset position) menu;

  /// How the entries are drawn (view options).
  final CalendarLook look;

  /// Whether the entry is in the Ctrl+click selection (drawn with an outline).

  /// Opens the entry (the task's details popup beside [anchor], or the habit / countdown / focus
  /// module). [anchor] is where the entry is on the screen.
  final void Function(CalendarEntry entry, {Rect? anchor}) open;

  /// Opens the quick add with a date ("clique na timeline", "clique ao lado da data").
  final void Function(DateSelection schedule) create;

  /// A task dropped on [day]; [time] when dropped on the timeline.
  final void Function(String taskId, DateTime day, {DateTime? time}) move;

  /// The bottom edge of a timed task dragged to [end].
  final void Function(Task task, DateTime end) resize;
  final Color Function(CalendarEntry entry) colorOf;

  /// "+N" of a crowded month cell: the entries of that day.
  final void Function(DateTime day, List<CalendarEntry> entries) showDay;
  final bool Function(CalendarEntry entry) isSelected;
}

/// "Estilo" and "Mostrar ícones" of the view options. Entries look like Google
/// Calendar's: solid blocks of their color. Moderno shows the month's timed entries as a dot, the time
/// and the title; Clássico keeps them as bars.
class CalendarLook {
  const CalendarLook({this.classic = false, this.icons = false, this.pastBefore});

  final bool classic;
  final bool icons;

  /// "Reduzir o brilho de eventos passados": entries ending before this moment fade like completed ones.
  final DateTime? pastBefore;

  /// Faded: completed, or already over when past entries are dimmed.
  bool faded(CalendarEntry e) => e.isDone || (pastBefore != null && e.end.isBefore(pastBefore!));

  /// Fill of an entry: its color, solid; completed ones fade into the background.
  Color fill(Color color, {required bool done, required Color screen}) => Color.alphaBlend(color.withValues(alpha: done ? 0.4 : 1), screen);

  /// Text over [fill]: white or near black, whichever reads better on it.
  Color ink(Color color, {required bool done, required TtColors tt}) {
    final fill = this.fill(color, done: done, screen: tt.screen);
    return ThemeData.estimateBrightnessForColor(fill) == Brightness.dark ? Colors.white : const Color(0xDE000000);
  }
}

/// The icon of an entry's kind ("Mostrar ícones").
IconData calendarEntryIcon(CalendarEntry e) => switch (e.kind) {
  CalendarEntryKind.task || CalendarEntryKind.checklistItem => e.isDone ? Icons.check_box_outlined : Icons.check_box_outline_blank,
  CalendarEntryKind.habit => Icons.track_changes,
  CalendarEntryKind.countdown => Icons.hourglass_bottom,
  CalendarEntryKind.focus => Icons.timer_outlined,
  CalendarEntryKind.event => Icons.event,
  CalendarEntryKind.finance => Icons.payments_outlined,
};

/// Finanças' due days as all-day entries: "Aluguel · R$ 1.500,00", "Fatura Nubank · R$ 400,00",
/// "Cobrar João · R$ 800,00". The id is `kind:id` (bill, income, invoice or loan).
List<CalendarEntry> financeCalendarEntries(AppLocalizations t, List<FinanceDue> dues) => [
  for (final d in dues)
    CalendarEntry(
      kind: CalendarEntryKind.finance,
      id: '${d.kind.name}:${d.id}',
      title:
          '${switch (d.kind) {
            FinanceDueKind.bill || FinanceDueKind.income => d.name,
            FinanceDueKind.invoice => t.finCalendarInvoice(d.name),
            // Each installment of a loan on its own day: "Cobrar João 2/5".
            FinanceDueKind.loan => t.finCalendarLoan(d.installment == null ? d.name : '${d.name} ${d.installment}/${d.installments}'),
          }} · ${formatMoney(d.amount)}',
      start: d.day,
      end: d.day,
      isAllDay: true,
      isDone: d.done,
    ),
];

/// A bar of the calendar: title (with the time for timed entries in the grids), filled with the
/// entry's color; completed entries fade and are struck through.
class CalendarChip extends StatelessWidget {
  const CalendarChip({
    super.key,
    required this.entry,
    required this.color,
    this.showTime = true,
    this.height = 18,
    this.selected = false,
    this.look = const CalendarLook(),
    this.dot = false,
  });

  final CalendarEntry entry;
  final CalendarLook look;
  final Color color;
  final bool selected;
  final bool showTime;
  final double height;

  /// A timed entry in the month (Moderno): a dot of its color, the time and the title, no fill.
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final title = entry.title.isEmpty ? (entry.kind == CalendarEntryKind.focus ? t.calendarFocusRecord : t.untitled) : entry.title;
    final faded = look.faded(entry);
    final ink = look.ink(color, done: faded, tt: tt);
    final struck = entry.isDone && entry.kind != CalendarEntryKind.focus ? TextDecoration.lineThrough : null;
    if (dot) {
      final text = faded ? tt.textTertiary : tt.text;
      return Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: selected ? tt.selected : null, borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: look.fill(color, done: faded, screen: tt.screen),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (showTime) TextSpan(text: '${DateLabels.time(entry.start)} '),
                    TextSpan(
                      text: title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, height: 1.2, color: text, decoration: struck),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: look.fill(color, done: faded, screen: tt.screen),
        borderRadius: BorderRadius.circular(4),
        border: selected
            ? Border.all(color: context.tt.primary, width: 2)
            : (entry.isOccurrence ? Border.all(color: color.withValues(alpha: 0.5)) : null),
      ),
      child: Row(
        children: [
          if (look.icons) ...[Icon(calendarEntryIcon(entry), size: 11, color: ink), const SizedBox(width: 3)],
          Expanded(
            child: Text(
              showTime && !entry.isAllDay ? '${DateLabels.time(entry.start)} $title' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w500, color: ink, decoration: struck),
            ),
          ),
        ],
      ),
    );
  }
}

/// Makes [child] draggable as the id of [task]: at once with a mouse, after a long press on touch
/// screens (where a plain drag scrolls).
Widget calendarDraggable(BuildContext context, {required String taskId, required Widget feedback, required Widget child}) {
  final touch = Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS;
  final shown = Material(
    color: Colors.transparent,
    child: Opacity(opacity: 0.85, child: feedback),
  );
  return touch
      ? LongPressDraggable<String>(data: taskId, dragAnchorStrategy: pointerDragAnchorStrategy, feedback: shown, child: child)
      : Draggable<String>(data: taskId, dragAnchorStrategy: pointerDragAnchorStrategy, feedback: shown, child: child);
}

/// A drop target for task ids that highlights while a task hovers it.
class CalendarDropArea extends StatelessWidget {
  const CalendarDropArea({super.key, required this.onDrop, required this.child});

  /// Called with the task id and the pointer position (global).
  final void Function(String taskId, Offset globalPosition) onDrop;
  final Widget child;

  @override
  Widget build(BuildContext context) => DragTarget<String>(
    onAcceptWithDetails: (d) => onDrop(d.data, d.offset),
    builder: (context, candidates, _) => Container(color: candidates.isEmpty ? null : context.tt.primary.withValues(alpha: 0.08), child: child),
  );
}

/// Where [context]'s widget is on the screen, to place a popup beside it.
Rect? globalRectOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// An entry's color in the calendar (and in the phone's widget): a habit's, a countdown's, a subscribed
/// calendar's, Finanças' (bills red, invoices orange, money coming in green), or a task's own color
/// over its list's, tag's or priority's as the options say.
Color calendarEntryColor(CalendarEntry e, Snapshot s, CalendarOptions o, TtColors tt, List<CalendarSubscription> subscriptions) {
  switch (e.kind) {
    case CalendarEntryKind.habit:
      return parseHexColor(s.habits.where((h) => h.id == e.id).firstOrNull?.color) ?? tt.primary;
    case CalendarEntryKind.countdown:
      return parseHexColor(s.countdowns.where((c) => c.id == e.id).firstOrNull?.color) ?? tt.palette.priorityMedium;
    case CalendarEntryKind.focus:
      return tt.textTertiary;
    case CalendarEntryKind.event:
      return parseHexColor(subscriptions.where((c) => c.id == e.id).firstOrNull?.color) ?? tt.palette.green;
    case CalendarEntryKind.finance:
      return switch (e.id.split(':').first) {
        'bill' => tt.overdue,
        'invoice' => tt.palette.priorityMedium,
        _ => tt.palette.green,
      };
    case CalendarEntryKind.task || CalendarEntryKind.checklistItem:
      final task = e.task;
      if (task == null) return tt.primary;
      // The task's own color (Google's event color) over the list's.
      if (parseHexColor(task.color) case final own?) return own;
      return switch (o.colorBy) {
        CalendarColorBy.list => parseHexColor(s.listById[task.listId]?.color) ?? tt.primary,
        CalendarColorBy.tag => s.tagsOf(task.id).map((tag) => parseHexColor(tag.color)).nonNulls.firstOrNull ?? tt.primary,
        CalendarColorBy.priority => task.priority == Priority.none ? tt.primary : tt.priorityColor(task.priority),
      };
  }
}
