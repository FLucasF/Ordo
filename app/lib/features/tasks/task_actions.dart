import 'dart:async';
import 'dart:io' show File;

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../focus/focus_estimate.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/time_zones.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/recurrence.dart';
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/feedback.dart';
import '../date_picker/date_picker.dart';
import '../common/labels.dart';
import '../focus/focus_page.dart';
import '../templates/templates.dart';
import '../activities/activities_dialog.dart';
import '../calendar/color_label_menu.dart';
import 'export_print.dart';

enum _MenuAction {
  select,
  activities,
  today,
  tomorrow,
  nextWeek,
  customDate,
  clearDate,
  priorityHigh,
  priorityMedium,
  priorityLow,
  priorityNone,
  addSubtask,
  linkParent,
  pin,
  focusPomo,
  focusStopwatch,
  focusEstimate,
  wontDo,
  reopen,
  moveTo,
  tags,
  color,
  attach,
  duplicate,
  saveTemplate,
  copyLink,
  convert,
  export,
  print,
  delete,
  restore,
  deleteForever,
}

/// Opens the task context menu at [position] and runs the chosen action.
/// [onAddSubtask] lets the caller open the detail with a new subtask focused.
/// [onSelect] adds "Selecionar" on top: a phone's way into the multi-selection.
Future<void> showTaskMenu(
  BuildContext context,
  WidgetRef ref,
  Task task,
  Offset position, {
  void Function(String newSubtaskId)? onAddSubtask,
  VoidCallback? onSelect,
}) async {
  final t = AppLocalizations.of(context);
  final tt = context.tt;
  final inTrash = task.deletedAt != null;

  PopupMenuItem<_MenuAction> item(_MenuAction a, String label, IconData icon, {Color? color}) => PopupMenuItem<_MenuAction>(
    value: a,
    height: 36,
    child: Row(
      children: [
        Icon(icon, size: 18, color: color ?? tt.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color),
          ),
        ),
      ],
    ),
  );

  PopupMenuEntry<_MenuAction> iconRow(String label, List<(_MenuAction, IconData, Color, String)> icons) => _IconRowEntry(label: label, icons: icons);

  final isNote = task.kind == TaskKind.note;
  final List<PopupMenuEntry<_MenuAction>> entries = inTrash
      ? [
          item(_MenuAction.restore, t.menuRestore, Icons.restore),
          item(_MenuAction.deleteForever, t.menuDeleteForever, Icons.delete_forever_outlined, color: tt.overdue),
        ]
      : [
          if (onSelect != null) ...[item(_MenuAction.select, t.menuSelect, Icons.checklist), const PopupMenuDivider(height: 8)],
          iconRow(t.menuDate, [
            (_MenuAction.today, Icons.wb_sunny_outlined, tt.textSecondary, t.dateToday),
            (_MenuAction.tomorrow, Icons.wb_twilight_outlined, tt.textSecondary, t.dateTomorrow),
            (_MenuAction.nextWeek, Icons.next_week_outlined, tt.textSecondary, t.dateNextWeek),
            (_MenuAction.customDate, Icons.calendar_month_outlined, tt.textSecondary, t.dateCustom),
            // With a date, a 5th icon clears it.
            if (task.dueDate != null) (_MenuAction.clearDate, Icons.event_busy_outlined, tt.textSecondary, t.dateClear),
          ]),
          // Notes have no priority, subtasks or "Não farei".
          if (!isNote)
            iconRow(t.menuPriority, [
              (_MenuAction.priorityHigh, Icons.flag, tt.priorityColor(Priority.high), t.priorityHigh),
              (_MenuAction.priorityMedium, Icons.flag, tt.priorityColor(Priority.medium), t.priorityMedium),
              (_MenuAction.priorityLow, Icons.flag, tt.priorityColor(Priority.low), t.priorityLow),
              (_MenuAction.priorityNone, Icons.outlined_flag, tt.priorityColor(Priority.none), t.priorityNone),
            ]),
          const PopupMenuDivider(height: 8),
          if (!isNote && task.status == TaskStatus.open) item(_MenuAction.addSubtask, t.menuAddSubtask, Icons.subdirectory_arrow_right),
          if (!isNote) item(_MenuAction.linkParent, t.menuLinkParent, Icons.account_tree_outlined),
          item(_MenuAction.pin, task.pinnedAt == null ? t.menuPin : t.menuUnpin, Icons.push_pin_outlined),
          if (!isNote && task.status == TaskStatus.open)
            item(_MenuAction.wontDo, t.menuWontDo, Icons.disabled_by_default_outlined)
          else if (!isNote)
            item(_MenuAction.reopen, t.menuReopen, Icons.replay),
          item(_MenuAction.moveTo, t.menuMoveTo, Icons.drive_file_move_outline),
          item(_MenuAction.tags, t.menuTags, Icons.sell_outlined),
          // Its color in the calendar (Google's event color and labels).
          item(_MenuAction.color, t.colorOfTask, Icons.palette_outlined, color: parseHexColor(task.color)),
          // "Começar o foco" › Pomo / Cronômetro, after Etiquetas (§27.9).
          if (task.status == TaskStatus.open) ...[
            item(_MenuAction.focusPomo, '${t.focusStartFocus} › ${t.focusStartPomo}', Icons.timer_outlined),
            item(_MenuAction.focusStopwatch, '${t.focusStartFocus} › ${t.focusStartStopwatch}', Icons.av_timer),
            item(_MenuAction.focusEstimate, '${t.focusStartFocus} › ${t.focusEstimate}', Icons.more_time),
          ],
          // A checklist task hides its content, where the attachment cards go.
          if (task.kind != TaskKind.checklist) item(_MenuAction.attach, t.menuAttach, Icons.attach_file),
          const PopupMenuDivider(height: 8),
          item(_MenuAction.duplicate, t.menuDuplicate, Icons.copy_outlined),
          item(_MenuAction.saveTemplate, t.templateSave, Icons.dashboard_customize_outlined),
          item(_MenuAction.copyLink, t.menuCopyLink, Icons.link),
          item(_MenuAction.convert, task.kind == TaskKind.note ? t.menuConvertToTask : t.menuConvertToNote, Icons.sticky_note_2_outlined),
          item(_MenuAction.export, t.menuExport, Icons.ios_share),
          item(_MenuAction.print, t.menuPrint, Icons.print_outlined),
          item(_MenuAction.activities, t.activityTaskTitle, Icons.history),
          item(_MenuAction.delete, t.menuDelete, Icons.delete_outline, color: tt.overdue),
        ];

  final action = await showMenu<_MenuAction>(
    context: context,
    position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
    constraints: const BoxConstraints(minWidth: 230, maxWidth: 300),
    items: entries,
  );
  if (action == null || !context.mounted) return;
  if (action == _MenuAction.select) return onSelect?.call();
  if (action == _MenuAction.color) return pickTaskColor(context, ref, task, position);
  await _runTaskAction(context, ref, task, action, onAddSubtask: onAddSubtask);
}

/// Google's color menu for [task], opened at [position]; "Salvo" with "Desfazer".
Future<void> pickTaskColor(BuildContext context, WidgetRef ref, Task task, Offset position) async {
  final picked = await showColorLabelMenu(context, near: position, current: task.color);
  if (picked is! ColorPicked || picked.color == task.color || !context.mounted) return;
  final repo = ref.read(repositoryProvider);
  await repo.setTaskColor(task.id, picked.color);
  if (context.mounted) {
    showToast(
      context,
      AppLocalizations.of(context).toastSaved,
      undo: () => repo.setTaskColor(task.id, task.color),
      redo: () => repo.setTaskColor(task.id, picked.color),
    );
  }
}

Future<void> _runTaskAction(
  BuildContext context,
  WidgetRef ref,
  Task task,
  _MenuAction action, {
  void Function(String newSubtaskId)? onAddSubtask,
}) async {
  final t = AppLocalizations.of(context);
  final repo = ref.read(repositoryProvider);
  final today = startOfDay(ref.read(clockProvider).now());
  switch (action) {
    case _MenuAction.today:
      await repo.setDueDate(task.id, today);
    case _MenuAction.tomorrow:
      await repo.setDueDate(task.id, today.add(const Duration(days: 1)));
    case _MenuAction.nextWeek:
      await repo.setDueDate(task.id, today.add(const Duration(days: 7)));
    case _MenuAction.customDate:
      await pickDueDate(context, ref, task);
    case _MenuAction.clearDate:
      await repo.setDueDate(task.id, null);
    case _MenuAction.attach:
      // "Carregar anexo": the files go to the end of the content as attachment cards.
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      await attachFiles(ref, task.id, [for (final f in result?.files ?? const <PlatformFile>[]) ?f.path]);
    case _MenuAction.priorityHigh:
      await repo.setPriority(task.id, Priority.high);
    case _MenuAction.priorityMedium:
      await repo.setPriority(task.id, Priority.medium);
    case _MenuAction.priorityLow:
      await repo.setPriority(task.id, Priority.low);
    case _MenuAction.priorityNone:
      await repo.setPriority(task.id, Priority.none);
    case _MenuAction.addSubtask:
      final id = await repo.createTask(listId: task.listId, parentId: task.id, sectionId: task.sectionId, atTop: false);
      onAddSubtask?.call(id);
    case _MenuAction.linkParent:
      await _linkParent(context, ref, task);
    case _MenuAction.pin:
      await repo.pinTask(task.id, pinned: task.pinnedAt == null);
    case _MenuAction.wontDo:
      await repo.markWontDo(task.id);
      if (context.mounted) showToast(context, t.toastWontDo, undo: () => repo.reopen(task.id), redo: () => repo.markWontDo(task.id));
    case _MenuAction.reopen:
      await repo.reopen(task.id);
    case _MenuAction.moveTo:
      await moveTaskTo(context, ref, task);
    case _MenuAction.tags:
      await editTaskTags(context, ref, task);
    case _MenuAction.color || _MenuAction.select:
      break; // Handled in showTaskMenu, which has the position and the selection callback.
    case _MenuAction.duplicate:
      await repo.duplicate(task.id);
    case _MenuAction.focusPomo:
      startFocusFor(context, ref, task, FocusMode.pomo);
    case _MenuAction.focusStopwatch:
      startFocusFor(context, ref, task, FocusMode.stopwatch);
    case _MenuAction.focusEstimate:
      await showEstimateDialog(context, ref, task);
    case _MenuAction.saveTemplate:
      await saveAsTemplate(context, ref, task);
    case _MenuAction.export:
      await showExportDialog(context, ref, task);
    case _MenuAction.print:
      await printTask(ref, AppLocalizations.of(context), task);
    case _MenuAction.activities:
      await showTaskActivities(context, task.id);
    case _MenuAction.copyLink:
      await Clipboard.setData(ClipboardData(text: Routes.of(ListScope(task.listId), taskId: task.id)));
      if (context.mounted) showToast(context, t.toastLinkCopied);
    case _MenuAction.convert:
      if (await guarded(context, () => repo.convert(task.id, task.kind == TaskKind.note ? TaskKind.text : TaskKind.note)) && context.mounted) {
        showToast(context, t.toastConverted);
      }
    case _MenuAction.delete:
      await deleteTask(context, ref, task);
    case _MenuAction.restore:
      await repo.restore(task.id);
      if (context.mounted) showToast(context, t.toastRestored);
    case _MenuAction.deleteForever:
      await repo.deleteForever(task.id);
  }
}

/// Complete with the "Tarefa concluída" toast and undo.
Future<void> toggleComplete(BuildContext context, WidgetRef ref, Task task) async {
  final repo = ref.read(repositoryProvider);
  if (task.status != TaskStatus.open) {
    await repo.reopen(task.id);
    return;
  }
  final t = AppLocalizations.of(context);
  await repo.complete(task.id);
  if (context.mounted) showToast(context, t.toastTaskCompleted, undo: () => repo.reopen(task.id), redo: () => repo.complete(task.id));
}

/// Delete without confirmation, with undo. Leaves the detail if it was open.
Future<void> deleteTask(BuildContext context, WidgetRef ref, Task task) async {
  final t = AppLocalizations.of(context);
  final repo = ref.read(repositoryProvider);
  await repo.delete(task.id);
  if (!context.mounted) return;
  final router = GoRouter.of(context);
  final location = router.state.uri.path;
  if (location.endsWith('/${task.id}')) router.go(location.substring(0, location.length - task.id.length - 1));
  showToast(context, t.toastTaskDeleted, undo: () => repo.restore(task.id), redo: () => repo.delete(task.id));
}

/// TickTick's full date picker (date, time, reminders, repetition) for one task.
Future<void> pickDueDate(BuildContext context, WidgetRef ref, Task task) async {
  final now = ref.read(clockProvider).now();
  final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
  final picked = await showTtDatePicker(
    context,
    now: now,
    withZone: ref.read(preferencesProvider).value?.timeZonePicker ?? false,
    initial: DateSelection(
      dueDate: task.dueDate?.toLocal(),
      startDate: task.startDate?.toLocal(),
      isAllDay: task.isAllDay,
      reminders: s.remindersOf(task.id).toSet(),
      repeatRule: task.repeatRule,
      repeatFrom: RepeatFrom.fromCode(task.repeatFrom),
      timeZone: task.isFloating ? null : task.timeZone,
      isFloating: task.isFloating,
    ),
  );
  if (picked == null) return;
  await ref
      .read(repositoryProvider)
      .setSchedule(
        task.id,
        dueDate: picked.dueDate,
        startDate: picked.startDate,
        isAllDay: picked.isAllDay,
        reminders: picked.reminders,
        repeatRule: picked.repeatRule,
        repeatFrom: picked.repeatFrom,
        // A floating task remembers the zone its clock time belongs to.
        timeZone: Value(picked.isFloating ? deviceZoneId() : picked.timeZone),
        isFloating: picked.isFloating,
      );
}

/// "Mover para": a list or one of its sections; [currentListId] is shown in bold.
Future<(String, String?)?> pickListTarget(BuildContext context, WidgetRef ref, {String? currentListId}) {
  final t = AppLocalizations.of(context);
  final labels = Labels(t);
  final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
  return showDialog<(String, String?)>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(t.menuMoveTo, style: const TextStyle(fontSize: 15)),
      children: [
        // Sublists right under their parent, indented.
        for (final (l, depth) in s.listTree(s.activeLists)) ...[
          SimpleDialogOption(
            padding: EdgeInsets.fromLTRB(24 + 20.0 * depth, 8, 24, 8),
            onPressed: () => Navigator.pop(context, (l.id, null)),
            child: Row(
              children: [
                Text(l.emoji ?? '•'),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    labels.listName(l),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: l.id == currentListId ? FontWeight.w600 : null),
                  ),
                ),
              ],
            ),
          ),
          for (final sec in s.sectionsOf(l.id))
            SimpleDialogOption(
              padding: EdgeInsets.fromLTRB(48 + 20.0 * depth, 6, 24, 6),
              onPressed: () => Navigator.pop(context, (l.id, sec.id)),
              child: Text(sec.name, style: TextStyle(color: context.tt.textSecondary)),
            ),
        ],
      ],
    ),
  );
}

/// "Mover para": picks a list (and section) and moves the task there, with a toast.
Future<void> moveTaskTo(BuildContext context, WidgetRef ref, Task task) async {
  final t = AppLocalizations.of(context);
  final picked = await pickListTarget(context, ref, currentListId: task.listId);
  if (picked == null) return;
  await ref.read(repositoryProvider).move(task.id, picked.$1, sectionId: picked.$2);
  final list = ref.read(snapshotProvider).value?.listById[picked.$1];
  if (context.mounted && list != null) showToast(context, t.toastMovedTo(Labels(t).listName(list)));
}

Future<void> editTaskTags(BuildContext context, WidgetRef ref, Task task) async {
  final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
  final result = await pickTags(context, ref, initial: {for (final tag in s.tagsOf(task.id)) tag.id});
  if (result != null) await ref.read(repositoryProvider).setTaskTags(task.id, result);
}

/// Tag chooser with a field to create a new tag; returns the chosen tag ids.
Future<Set<String>?> pickTags(BuildContext context, WidgetRef ref, {Set<String> initial = const {}}) async {
  final t = AppLocalizations.of(context);
  final selected = {...initial};
  final newTag = TextEditingController();
  final result = await showDialog<Set<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(t.menuTags, style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newTag,
                decoration: InputDecoration(hintText: t.detailAddTag, prefixText: '#'),
                onSubmitted: (name) async {
                  if (name.trim().isEmpty) return;
                  final id = await ref.read(repositoryProvider).createTag(name);
                  setState(() => selected.add(id));
                  newTag.clear();
                },
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: Consumer(
                  builder: (context, ref, _) {
                    final tags = ref.watch(snapshotProvider).value?.activeTags ?? const <Tag>[];
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        for (final tag in tags)
                          CheckboxListTile(
                            dense: true,
                            value: selected.contains(tag.id),
                            title: Text(tag.name),
                            onChanged: (v) => setState(() => v == true ? selected.add(tag.id) : selected.remove(tag.id)),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, selected), child: Text(t.actionOk)),
        ],
      ),
    ),
  );
  newTag.dispose();
  return result;
}

/// "Vincular Tarefa Pai": an open task of [listId] that is not in [exclude].
Future<String?> pickParentTask(BuildContext context, WidgetRef ref, {required String listId, required Set<String> exclude}) {
  final t = AppLocalizations.of(context);
  final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
  final candidates = s.tasks.where((c) => Snapshot.isOpen(c) && !exclude.contains(c.id) && c.listId == listId && c.kind != TaskKind.note).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(t.menuLinkParent, style: const TextStyle(fontSize: 15)),
      children: [
        for (final c in candidates)
          SimpleDialogOption(onPressed: () => Navigator.pop(context, c.id), child: Text(c.title.isEmpty ? t.untitled : c.title)),
      ],
    ),
  );
}

Future<void> _linkParent(BuildContext context, WidgetRef ref, Task task) async {
  final parentId = await pickParentTask(context, ref, listId: task.listId, exclude: {task.id});
  if (parentId != null && context.mounted) await guarded(context, () => ref.read(repositoryProvider).makeSubtask(task.id, parentId));
}

/// A menu row with a label and icon buttons (the context menu's Date and Priority rows).
class _IconRowEntry extends PopupMenuEntry<_MenuAction> {
  const _IconRowEntry({required this.label, required this.icons});

  final String label;
  final List<(_MenuAction, IconData, Color, String)> icons;

  @override
  double get height => 56;

  @override
  bool represents(_MenuAction? value) => false;

  @override
  State<_IconRowEntry> createState() => _IconRowEntryState();
}

class _IconRowEntryState extends State<_IconRowEntry> {
  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          Row(
            children: [
              for (final (action, icon, color, tooltip) in widget.icons)
                IconButton(
                  tooltip: tooltip,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(icon, size: 20, color: color),
                  onPressed: () => Navigator.pop(context, action),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Keeps unawaited futures explicit in widget callbacks.
void fireAndForget(Future<void> future) => unawaited(future);

/// Copies [paths] into the attachment store and adds a card for each at the end of the task's content
/// ("Carregar anexo" and files dropped on the detail).
Future<void> attachFiles(WidgetRef ref, String taskId, List<String> paths) async {
  if (paths.isEmpty) return;
  final repo = ref.read(repositoryProvider);
  final store = ref.read(attachmentStoreProvider);
  final cards = [for (final path in paths) '![file](${await store.add(File(path))})'];
  final content = (await repo.task(taskId)).content.trimRight();
  await repo.setContent(taskId, [if (content.isNotEmpty) content, ...cards].join('\n'));
}
