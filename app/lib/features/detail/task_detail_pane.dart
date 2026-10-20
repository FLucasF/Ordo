import 'dart:async';
import 'dart:io' show File;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/date_labels.dart';
import '../focus/focus_estimate.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/reminders.dart';
import '../../domain/task_dates.dart';
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/labels.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_row.dart';
import '../editor/markdown_codec.dart' show noteStats;
import '../templates/templates.dart';
import 'checklist_editor.dart';
import 'comments.dart';
import 'content_editor.dart';

/// Right column: task detail. Without a task, shows an empty illustration like TickTick.
class TaskDetailPane extends ConsumerWidget {
  const TaskDetailPane({super.key, required this.scope, required this.taskId, this.onClose});

  final Scope scope;
  final String? taskId;

  /// The ✕ that closes the detail open on its own (full screen on a phone, a floating window).
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final task = taskId == null ? null : s.taskById[taskId];
    if (task == null) {
      return ColoredBox(
        color: tt.screen,
        child: Center(child: Icon(Icons.checklist_rtl, size: 120, color: tt.divider)),
      );
    }
    return ColoredBox(
      color: tt.screen,
      child: _Detail(key: ValueKey(task.id), task: task, snapshot: s, scope: scope, onClose: onClose),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({super.key, required this.task, required this.snapshot, required this.scope, this.onClose});

  final Task task;
  final Snapshot snapshot;
  final Scope scope;
  final VoidCallback? onClose;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  late final TextEditingController _title = TextEditingController(text: widget.task.title);
  final _titleFocus = FocusNode();

  /// The comment field is open above the footer.
  bool _commenting = false;

  /// The "A" formatting bar over the content.
  bool _formatting = false;
  Timer? _titleDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.task.title.isEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _titleFocus.requestFocus());
  }

  @override
  void didUpdateWidget(_Detail old) {
    super.didUpdateWidget(old);
    if (!_titleFocus.hasFocus && _title.text != widget.task.title) _title.text = widget.task.title;
  }

  @override
  void dispose() {
    if (_titleDebounce?.isActive ?? false) {
      _titleDebounce!.cancel();
      unawaited(ref.read(repositoryProvider).setTitle(widget.task.id, _title.text));
    }
    _title.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// The header's checkbox. Completing a task open on its own (full screen on a phone, a floating
  /// window) also closes it; the toast keeps "Desfazer".
  Future<void> _toggle(Task task) async {
    final closing = widget.onClose != null && task.status == TaskStatus.open;
    await toggleComplete(context, ref, task);
    if (closing && mounted) widget.onClose!();
  }

  void _onTitleChanged(String v) {
    _titleDebounce?.cancel();
    _titleDebounce = Timer(const Duration(milliseconds: 400), () => unawaited(ref.read(repositoryProvider).setTitle(widget.task.id, v)));
  }

  String get _routeBase => Routes.of(widget.scope);

  /// "Adicionar subtarefa" (also "/ Subtarefa"): a new subtask, opened for its title.
  Future<void> _addSubtask(Task task) async {
    final id = await ref.read(repositoryProvider).createTask(listId: task.listId, parentId: task.id, sectionId: task.sectionId, atTop: false);
    if (mounted) context.go('$_routeBase/$id');
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    final labels = Labels(t);
    final task = widget.task;
    final s = widget.snapshot;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = startOfDay(now);
    final due = task.dueDate?.toLocal();
    final closed = task.status != TaskStatus.open;
    final overdue = due != null && !closed && daysBetween(today, due) < 0;
    final ancestors = s.ancestorsOf(task);
    final children = s.childrenOf(task.id);
    final tags = s.tagsOf(task.id);
    final list = s.listById[task.listId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: checkbox · date · priority flag (48 px, 24 px side padding, measured); the close button
        // (full screen on a phone, a floating window) at the far end, away from the checkbox.
        SizedBox(
          height: TtSizes.detailBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // A finger-sized target around the checkbox.
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => fireAndForget(_toggle(task)),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: TaskCheckbox(status: task.status, priority: task.priority, kind: task.kind, onTap: () => fireAndForget(_toggle(task))),
                    ),
                  ),
                ),
                Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 12), color: tt.divider),
                // Date, its reminder/repeat icons and, below, a pending snooze ("adiar até 19:03").
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: due == null ? tt.textTertiary : (overdue ? tt.overdue : tt.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      onPressed: () => fireAndForget(pickDueDate(context, ref, task)),
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  due == null
                                      ? (task.kind == TaskKind.note ? t.detailSetReminder : t.detailDueDatePlaceholder)
                                      : task.hasDuration
                                      ? labels.dates.detailRange(task.startLocal!, due, isAllDay: task.isAllDay, today: today)
                                      : labels.dates.detailDate(due, isAllDay: task.isAllDay, today: today),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: TtText.body),
                                ),
                              ),
                              if (due != null && ReminderPresets.firing(s.remindersOf(task.id)).isNotEmpty)
                                const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.alarm, size: 14)),
                              if (due != null && task.repeatRule != null)
                                const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.repeat, size: 14)),
                            ],
                          ),
                          if (due != null && task.snoozeUntil != null && task.snoozeUntil!.isAfter(now))
                            Text(
                              t.snoozedUntil(DateLabels.time(task.snoozeUntil!.toLocal())),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // (i) of a note: words, characters, created and modified.
                if (task.kind == TaskKind.note)
                  IconButton(
                    tooltip: t.noteInfo,
                    icon: Icon(Icons.info_outline, color: tt.textSecondary, size: 18),
                    onPressed: () => unawaited(showNoteInfo(context, task)),
                  ),
                PopupMenuButton<Priority>(
                  tooltip: t.menuPriority,
                  icon: Icon(task.priority == Priority.none ? Icons.outlined_flag : Icons.flag, color: tt.priorityColor(task.priority), size: 20),
                  onSelected: (p) => fireAndForget(ref.read(repositoryProvider).setPriority(task.id, p)),
                  itemBuilder: (_) => [
                    for (final p in Priority.values.reversed)
                      PopupMenuItem(
                        value: p,
                        height: 36,
                        child: Row(
                          children: [
                            Icon(Icons.flag, size: 18, color: tt.priorityColor(p)),
                            const SizedBox(width: 10),
                            Text(labels.priority(p)),
                          ],
                        ),
                      ),
                  ],
                ),
                if (widget.onClose != null)
                  IconButton(
                    tooltip: t.actionClose,
                    icon: Icon(Icons.close, color: tt.textSecondary, size: 22),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _FileDrop(
            enabled: task.kind != TaskKind.checklist,
            onFiles: (paths) => attachFiles(ref, task.id, paths),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                if (ancestors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Wrap(
                      children: [
                        for (final a in ancestors)
                          InkWell(
                            onTap: () => context.go('$_routeBase/${a.id}'),
                            child: Text(
                              '${a.title.isEmpty ? t.untitled : a.title}  ›  ',
                              style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                            ),
                          ),
                      ],
                    ),
                  ),
                // "Focado em ⏱ 20m/50m" above the title.
                if (focusEstimateLabel(t, task, ref.watch(taskFocusProvider)[task.id]) case final focused?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${t.estimateFocused} $focused',
                      style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _title,
                        focusNode: _titleFocus,
                        // The title wraps but is one paragraph: Enter (the phone's key too) ends the
                        // editing instead of breaking the line, and a pasted break becomes a space.
                        maxLines: null,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' ')],
                        onSubmitted: (_) => _titleFocus.unfocus(),
                        style: TextStyle(
                          fontSize: TtText.detailTitle,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          color: closed ? tt.textTertiary : tt.text,
                        ),
                        decoration: InputDecoration(hintText: t.detailTitlePlaceholder, border: InputBorder.none, isCollapsed: true),
                        onChanged: _onTitleChanged,
                      ),
                    ),
                    if (task.kind != TaskKind.note)
                      IconButton(
                        tooltip: t.detailChecklistTooltip,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.checklist, size: 20, color: task.kind == TaskKind.checklist ? tt.primary : tt.textTertiary),
                        onPressed: () => fireAndForget(ref.read(repositoryProvider).toggleChecklist(task.id)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (task.kind == TaskKind.checklist)
                  ChecklistEditor(taskId: task.id, items: s.itemsOf(task.id))
                else
                  ContentEditor(
                    markdown: task.content,
                    placeholder: task.kind == TaskKind.note ? t.detailNotePlaceholder : t.detailContentPlaceholder,
                    onChanged: (md) => fireAndForget(ref.read(repositoryProvider).setContent(task.id, md)),
                    taskId: task.id,
                    attachments: ref.read(attachmentStoreProvider),
                    showFormatBar: _formatting,
                    onImmersive: () => unawaited(showImmersiveWriting(context, ref, task)),
                    now: ref.read(clockProvider).now,
                    onAddSubtask: task.status == TaskStatus.open ? () => unawaited(_addSubtask(task)) : null,
                    onAddTag: () => unawaited(editTaskTags(context, ref, task)),
                    templateMarkdown: () async {
                      final template = await pickTemplate(context, notes: task.kind == TaskKind.note);
                      return template == null ? null : templateAsMarkdown(template);
                    },
                    // A linked task opens in a floating popup, editable, without leaving this one.
                    onOpenTask: (id) {
                      final linked = ref.read(snapshotProvider).value?.taskById[id];
                      if (linked != null && linked.deletedAt == null) unawaited(showTaskPopup(context, linked));
                    },
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in tags)
                      Chip(
                        label: Text(tag.name, style: const TextStyle(fontSize: TtText.small)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: (parseHexColor(tag.color) ?? tt.textTertiary).withValues(alpha: 0.2),
                        side: BorderSide.none,
                      ),
                    ActionChip(
                      avatar: Icon(Icons.add, size: 14, color: tt.textTertiary),
                      label: Text(
                        t.detailAddTag,
                        style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                      ),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: tt.divider),
                      onPressed: () => fireAndForget(editTaskTags(context, ref, task)),
                    ),
                  ],
                ),
                if (task.kind != TaskKind.note) ...[
                  const SizedBox(height: 16),
                  Divider(color: tt.divider, height: 1),
                  const SizedBox(height: 8),
                  for (final c in children)
                    InkWell(
                      onTap: () => context.go('$_routeBase/${c.id}'),
                      child: SizedBox(
                        height: 36,
                        child: Row(
                          children: [
                            TaskCheckbox(
                              status: c.status,
                              priority: c.priority,
                              kind: c.kind,
                              onTap: () => fireAndForget(toggleComplete(context, ref, c)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.title.isEmpty ? t.untitled : c.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: TtText.body, color: c.status == TaskStatus.open ? tt.text : tt.textTertiary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  TextButton.icon(
                    style: TextButton.styleFrom(alignment: Alignment.centerLeft, foregroundColor: tt.primary, padding: EdgeInsets.zero),
                    onPressed: () => unawaited(_addSubtask(task)),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(t.detailAddSubtask, style: const TextStyle(fontSize: TtText.body)),
                  ),
                ],
                CommentsSection(taskId: task.id),
              ],
            ),
          ),
        ),
        if (_commenting) CommentInput(taskId: task.id, onClose: () => setState(() => _commenting = false)),
        // Footer: list selector · "…" (48 px, measured).
        SizedBox(
          height: TtSizes.detailBarHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 24, 0),
            child: Row(
              children: [
                // A long list name shrinks (…) before the buttons on a narrow screen.
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: tt.textSecondary),
                      onPressed: () => fireAndForget(_openMenuAtFooter(context)),
                      icon: Icon(Icons.drive_file_move_outline, size: 18, color: tt.textTertiary),
                      label: Text(
                        list == null ? '' : labels.listName(list),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: TtText.body),
                      ),
                    ),
                  ),
                ),
                if (task.kind != TaskKind.checklist)
                  IconButton(
                    tooltip: t.formatBar,
                    icon: Icon(Icons.text_format, color: _formatting ? tt.primary : tt.textSecondary, size: 20),
                    onPressed: () => setState(() => _formatting = !_formatting),
                  ),
                IconButton(
                  tooltip: t.commentHint,
                  icon: Icon(Icons.chat_bubble_outline, color: _commenting ? tt.primary : tt.textSecondary, size: 18),
                  onPressed: () => setState(() => _commenting = !_commenting),
                ),
                Builder(
                  builder: (context) => IconButton(
                    tooltip: t.menuMore,
                    icon: Icon(Icons.more_horiz, color: tt.textSecondary, size: 18),
                    onPressed: () {
                      final box = context.findRenderObject()! as RenderBox;
                      fireAndForget(
                        showTaskMenu(context, ref, task, box.localToGlobal(Offset.zero), onAddSubtask: (id) => context.go('$_routeBase/$id')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openMenuAtFooter(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    await showTaskMenu(context, ref, widget.task, box.localToGlobal(Offset(24, box.size.height - 300)));
  }
}

/// Words, characters, "Criado" and "Modificado" of a note.
Future<void> showNoteInfo(BuildContext context, Task task) {
  final t = AppLocalizations.of(context);
  final tt = context.tt;
  final stats = noteStats(task.content);
  String when(DateTime d) => '${DateLabels.numeric(d.toLocal())} ${DateLabels.time(d.toLocal())}';
  Widget row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: tt.textSecondary)),
        ),
        Text(value, style: TextStyle(color: tt.text)),
      ],
    ),
  );
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row(t.noteWords, '${stats.words}'),
            row(t.noteCharacters, '${stats.characters}'),
            row(t.noteCreated, when(task.createdAt)),
            row(t.noteModified, when(task.updatedAt)),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionOk))],
    ),
  );
}

/// "Escrita Imersiva": the task's content full screen, with nothing else around.
Future<void> showImmersiveWriting(BuildContext context, WidgetRef ref, Task task) => showDialog<void>(
  context: context,
  builder: (context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Dialog.fullscreen(
      backgroundColor: tt.screen,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: t.actionClose,
              icon: Icon(Icons.fullscreen_exit, color: tt.textSecondary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                  children: [
                    Text(
                      task.title.isEmpty ? t.untitled : task.title,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: tt.text),
                    ),
                    const SizedBox(height: 16),
                    ContentEditor(
                      markdown: ref.read(snapshotProvider).value?.taskById[task.id]?.content ?? task.content,
                      placeholder: t.detailContentPlaceholder,
                      onChanged: (md) => fireAndForget(ref.read(repositoryProvider).setContent(task.id, md)),
                      taskId: task.id,
                      attachments: ref.read(attachmentStoreProvider),
                      showFormatBar: true,
                      now: ref.read(clockProvider).now,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  },
);

/// The full detail over a page with no room for it (Matriz, Calendário): a floating window, or the
/// whole screen on a phone.
Future<void> showTaskDetailDialog(BuildContext context, Task task) => showDialog<void>(
  context: context,
  builder: (context) {
    if (MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint) {
      return Dialog.fullscreen(
        child: SafeArea(
          child: TaskDetailPane(scope: ListScope(task.listId), taskId: task.id, onClose: () => Navigator.pop(context)),
        ),
      );
    }
    return Dialog(
      child: SizedBox(
        width: 560,
        height: 680,
        child: TaskDetailPane(scope: ListScope(task.listId), taskId: task.id),
      ),
    );
  },
);

/// A task's full detail in a floating window (the "[[link]]" popup).
Future<void> showTaskPopup(BuildContext context, Task task) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: 640,
      height: 640,
      child: TaskDetailPane(scope: ListScope(task.listId), taskId: task.id, onClose: () => Navigator.pop(context)),
    ),
  ),
);

/// Files dropped from the system on the detail become attachment cards (the editor's
/// drag and drop). Off while a dialog or popup covers the pane, so one drop never lands twice.
class _FileDrop extends StatefulWidget {
  const _FileDrop({required this.enabled, required this.onFiles, required this.child});

  /// Off for checklist tasks: their content, where the cards go, is hidden.
  final bool enabled;
  final Future<void> Function(List<String> paths) onFiles;
  final Widget child;

  @override
  State<_FileDrop> createState() => _FileDropState();
}

class _FileDropState extends State<_FileDrop> {
  bool _over = false;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return DropTarget(
      enable: widget.enabled && (ModalRoute.of(context)?.isCurrent ?? true),
      onDragEntered: (_) => setState(() => _over = true),
      onDragExited: (_) => setState(() => _over = false),
      onDragDone: (details) {
        setState(() => _over = false);
        final paths = [
          for (final f in details.files)
            if (f.path.isNotEmpty && File(f.path).existsSync()) f.path,
        ];
        unawaited(widget.onFiles(paths));
      },
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: _over ? Border.all(color: tt.primary, width: 2) : null,
          color: _over ? tt.primary.withValues(alpha: 0.06) : null,
        ),
        child: widget.child,
      ),
    );
  }
}
