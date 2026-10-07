import 'dart:async';

import 'package:file_picker/file_picker.dart';

import 'dart:io' show File;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/preferences_repository.dart';
import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../domain/countdown.dart';
import '../../domain/enums.dart';
import '../../domain/task_dates.dart';
import '../../domain/habits.dart';
import '../../domain/snapshot.dart';
import '../../domain/subscriptions.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/feedback.dart';
import '../common/labels.dart';
import '../lists/list_dialog.dart';
import '../subscriptions/subscriptions.dart';
import '../date_picker/date_picker.dart';
import '../templates/templates.dart';
import '../habits/habit_widgets.dart';
import 'export_print.dart';
import 'kanban_board.dart';
import '../activities/activities_dialog.dart';
import 'list_rows.dart';
import 'quick_add_input.dart';
import 'section_menu.dart';
import 'task_actions.dart';
import 'task_row.dart';
import 'timeline_board.dart';

/// Middle column: header, add field and the grouped task list.
class TaskListPane extends ConsumerWidget {
  const TaskListPane({super.key, required this.scope, required this.selectedTaskId, required this.onToggleSidebar, this.isNarrow = false});

  final Scope scope;
  final String? selectedTaskId;
  final VoidCallback onToggleSidebar;
  final bool isNarrow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final labels = Labels(t);
    final tt = context.tt;
    final snapshot = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final view = ref.watch(viewProvider(scope));
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    // "Contagem Regressiva" section of Hoje and Próximos 7 dias.
    final days = switch (scope) {
      SmartScope(smartList: SmartList.today) => 1,
      SmartScope(smartList: SmartList.next7Days) => 7,
      _ => 0,
    };
    final today = startOfDay(now);
    // Events of the subscribed calendars in Hoje and Próximos 7 dias.
    final events = days == 0 ? const <SubscribedEvent>[] : subscribedEventsBetween(ref, today, today.add(Duration(days: days)));
    final countdowns = [
      for (final c in snapshot.countdowns)
        if (List.generate(days, (i) => today.add(Duration(days: i))).any((day) => countdownShowsOn(c, day, now))) c,
    ]..sort((a, b) => countdownStatus(a, now).target.compareTo(countdownStatus(b, now).target));
    // "Hábito" in Hoje / Próximos 7 dias: today's habits with their check-in.
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final habits = days == 0 || !prefs.habitsInToday || !prefs.has(AppFeature.habit)
        ? const <Habit>[]
        : [
            for (final h in snapshot.habits)
              if (h.archivedAt == null && habitIsDue(h, today)) h,
          ];
    // Kanban on phones too, like TickTick's Android app: the columns scroll sideways.
    final mode = ref.watch(viewModeProvider(scope));
    final kanban = mode == ViewMode.kanban && !(scope is SmartScope && (scope as SmartScope).smartList.isReadOnly);
    // "Linha do tempo": lists, folders and filters, on wide windows.
    final timeline = !isNarrow && mode == ViewMode.timeline && supportsTimeline(scope);

    return Container(
      color: tt.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(title: labels.scopeTitle(snapshot, scope), scope: scope, onToggleSidebar: onToggleSidebar),
          // The hint names the "Lista padrão" where the task will go.
          if (view?.addTarget case final target? when !kanban)
            _AddTaskField(target: target, hint: labels.addHint(withDefaultList(target, prefs.taskDefaults, snapshot).hint, snapshot)),
          if (scope case SmartScope(smartList: SmartList.completed || SmartList.wontDo))
            _ClosedFilterBar(list: (scope as SmartScope).smartList, snapshot: snapshot, today: today),
          Expanded(
            child: view == null
                ? const SizedBox.shrink()
                : kanban
                ? KanbanBoard(scope: scope, view: view, selectedTaskId: selectedTaskId)
                : timeline
                ? TimelineBoard(scope: scope, view: view)
                : view.isEmpty && countdowns.isEmpty && habits.isEmpty && events.isEmpty
                ? _EmptyState(texts: labels.emptyState(view.emptyState))
                // Slivers, so only the rows on screen are built: lists with thousands of tasks stay smooth.
                : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.only(left: 2, right: 2, bottom: 40),
                        sliver: SliverMainAxisGroup(
                          slivers: [
                            for (final group in view.groups)
                              _Group(
                                group: group,
                                scope: scope,
                                title: labels.header(group.header, snapshot, now),
                                selectedTaskId: selectedTaskId,
                                now: now,
                                showDetails: ref.watch(viewOptionsProvider(scope)).showDetails,
                                isNarrow: isNarrow,
                              ),
                            if (habits.isNotEmpty)
                              SliverToBoxAdapter(
                                child: _HabitSection(habits: habits, snapshot: snapshot, day: today),
                              ),
                            if (events.isNotEmpty)
                              SliverToBoxAdapter(
                                child: SubscribedEventsSection(events: events, today: today),
                              ),
                            if (countdowns.isNotEmpty && prefs.has(AppFeature.countdown))
                              SliverToBoxAdapter(
                                child: _CountdownSection(countdowns: countdowns, now: now),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.title, required this.scope, required this.onToggleSidebar});

  final String title;
  final Scope scope;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    final isTrash = scope == const SmartScope(SmartList.trash);
    final canSort = scope is! SmartScope || !(scope as SmartScope).smartList.isReadOnly;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu_open, color: tt.textSecondary, size: 20),
            onPressed: onToggleSidebar,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: TtText.listTitle, fontWeight: FontWeight.w600, color: tt.text),
            ),
          ),
          if (isTrash)
            IconButton(
              tooltip: t.emptyTrashTooltip,
              icon: Icon(Icons.delete_sweep_outlined, color: tt.textSecondary, size: 20),
              onPressed: () async {
                if (await confirm(context, message: t.emptyTrashConfirm, confirmLabel: t.menuDeleteForever)) {
                  await ref.read(repositoryProvider).emptyTrash();
                }
              },
            ),
          // "Experimente Tarefas Sugeridas" (Hoje only).
          if (scope == const SmartScope(SmartList.today))
            IconButton(
              tooltip: t.suggestedTasks,
              icon: Icon(Icons.lightbulb_outline, color: tt.textSecondary, size: 20),
              onPressed: () => unawaited(showDialog<void>(context: context, builder: (_) => const _SuggestedTasks())),
            ),
          if (canSort)
            IconButton(
              tooltip: t.sortButtonTooltip,
              icon: Icon(Icons.swap_vert, color: tt.textSecondary, size: 20),
              onPressed: () => _showSortMenu(context, ref),
            ),
          if (canSort)
            IconButton(
              icon: Icon(Icons.more_horiz, color: tt.textSecondary, size: 20),
              onPressed: () => _showMoreMenu(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _setOptions(WidgetRef ref, ViewOptions options) => setScopeViewOptions(ref, scope, options);

  Future<void> _showSortMenu(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final current = ref.read(viewOptionsProvider(scope));
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset(box.size.width - 60, box.size.height));
    final inList = scope is ListScope;
    final groupings = {
      // Outside a list: "Lista" instead of "Personalizado".
      if (inList) Grouping.custom: t.optionCustom else Grouping.list: t.optionList,
      Grouping.date: t.optionDate,
      Grouping.modifiedTime: t.optionModifiedTime,
      Grouping.tag: t.optionTag,
      Grouping.priority: t.optionPriority,
      Grouping.none: t.optionNone,
    };
    final sortings = {
      Sorting.custom: t.optionCustom,
      Sorting.date: t.optionDate,
      Sorting.modifiedTime: t.optionModifiedTime,
      Sorting.createdTime: t.optionCreatedTime,
      Sorting.title: t.optionTitle,
      Sorting.tag: t.optionTag,
      Sorting.priority: t.optionPriority,
    };
    final picked = await showMenu<Object>(
      context: context,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
      items: [
        PopupMenuItem<Object>(
          enabled: false,
          height: 28,
          child: Text(t.groupByLabel, style: const TextStyle(fontSize: TtText.small)),
        ),
        for (final g in groupings.entries) CheckedPopupMenuItem<Object>(value: g.key, checked: current.grouping == g.key, child: Text(g.value)),
        // "Ordem" of the groups (smart lists, tags, filters).
        if (!inList) ...[
          const PopupMenuDivider(),
          PopupMenuItem<Object>(
            enabled: false,
            height: 28,
            child: Text(t.orderLabel, style: const TextStyle(fontSize: TtText.small)),
          ),
          CheckedPopupMenuItem<Object>(value: false, checked: !current.descending, child: Text(t.orderAscending)),
          CheckedPopupMenuItem<Object>(value: true, checked: current.descending, child: Text(t.orderDescending)),
        ],
        const PopupMenuDivider(),
        PopupMenuItem<Object>(
          enabled: false,
          height: 28,
          child: Text(t.sortByLabel, style: const TextStyle(fontSize: TtText.small)),
        ),
        for (final s in sortings.entries) CheckedPopupMenuItem<Object>(value: s.key, checked: current.sorting == s.key, child: Text(s.value)),
      ],
    );
    switch (picked) {
      case final Grouping g:
        await _setOptions(ref, current.copyWith(grouping: g));
      case final Sorting s:
        await _setOptions(ref, current.copyWith(sorting: s));
      case final bool descending:
        await _setOptions(ref, current.copyWith(descending: descending));
    }
  }

  Future<void> _showMoreMenu(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final current = ref.read(viewOptionsProvider(scope));
    final list = scope is ListScope ? ref.read(snapshotProvider).value?.listById[(scope as ListScope).listId] : null;
    final mode = ref.read(viewModeProvider(scope));
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset(box.size.width - 20, box.size.height));
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
      items: [
        // "Visualização": Lista · Kanban.
        CheckedPopupMenuItem(value: 'view:list', checked: mode == ViewMode.list, child: Text(t.viewList)),
        CheckedPopupMenuItem(value: 'view:kanban', checked: mode == ViewMode.kanban, child: Text(t.viewKanban)),
        // The timeline needs a wide window; phones don't offer it.
        if (supportsTimeline(scope) && MediaQuery.sizeOf(context).width >= TtSizes.narrowBreakpoint)
          CheckedPopupMenuItem(value: 'view:timeline', checked: mode == ViewMode.timeline, child: Text(t.viewTimeline)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'completed', height: 36, child: Text(current.showCompleted ? t.hideCompleted : t.showCompleted)),
        PopupMenuItem(value: 'details', height: 36, child: Text(current.showDetails ? t.hideDetails : t.showDetails)),
        PopupMenuItem(value: 'viewOptions', height: 36, child: Text(t.viewOptions)),
        // The list's "…" ends with Adicionar Seção · Atividades das Listas · Imprimir, then Editar lista ·
        // Deletar lista (the Inbox can't be deleted).
        if (list != null) PopupMenuItem(value: 'section', height: 36, child: Text(t.sectionAdd)),
        if (list != null) PopupMenuItem(value: 'activities', height: 36, child: Text(t.activityListTitleDialog)),
        PopupMenuItem(value: 'print', height: 36, child: Text(t.menuPrint)),
        if (list != null && list.id != inboxListId) ...[
          const PopupMenuDivider(),
          PopupMenuItem(value: 'editList', height: 36, child: Text(t.listEditTitle)),
          PopupMenuItem(
            value: 'deleteList',
            height: 36,
            child: Text(t.listDeleteMenu, style: TextStyle(color: context.tt.overdue)),
          ),
        ],
      ],
    );
    if (!context.mounted) return;
    switch (picked) {
      case 'completed':
        await _setOptions(ref, current.copyWith(showCompleted: !current.showCompleted));
      case 'details':
        await _setOptions(ref, current.copyWith(showDetails: !current.showDetails));
      case 'section':
        final name = await promptText(context, title: t.sectionAdd, hint: t.sectionNew);
        if (name != null) await ref.read(repositoryProvider).createSection(list!.id, name);
      case 'activities':
        await showListActivities(context, list!.id);
      case 'editList':
        final router = GoRouter.of(context);
        await editListWithDialog(context, ref, list!, onDeleted: () => router.go(Routes.of(const ListScope(inboxListId))));
      case 'deleteList':
        final router = GoRouter.of(context);
        if (await deleteListAsking(context, ref, list!)) router.go(Routes.of(const ListScope(inboxListId)));
      case 'viewOptions':
        await _showViewOptions(context, ref);
      case 'print':
        final view = ref.read(viewProvider(scope));
        final snapshot = ref.read(snapshotProvider).value;
        if (view != null && snapshot != null) await printView(ref, t, Labels(t).scopeTitle(snapshot, scope), view);
      case 'view:list':
        await setViewMode(ref, scope, ViewMode.list);
      case 'view:kanban':
        await setViewMode(ref, scope, ViewMode.kanban);
      case 'view:timeline':
        await setViewMode(ref, scope, ViewMode.timeline);
    }
  }

  /// "Visualizar Opções": "Mostrar Data por" the date or a countdown.
  Future<void> _showViewOptions(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final current = ref.read(preferencesProvider).value?.dateDisplay ?? DateDisplay.date;
    final popup = ref.read(preferencesProvider).value?.detailPopup ?? false;
    final picked = await showDialog<Object>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(t.viewOptions, style: const TextStyle(fontSize: 15)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
            child: Text(
              t.showDateBy,
              style: TextStyle(color: context.tt.textTertiary, fontSize: TtText.small),
            ),
          ),
          RadioGroup<DateDisplay>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(context, v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(value: DateDisplay.date, title: Text(t.dateDisplayDate)),
                RadioListTile(value: DateDisplay.countdown, title: Text(t.dateDisplayCountdown)),
              ],
            ),
          ),
          // "Layout de detalhes da tarefa" (computer only; the phone opens tasks full screen).
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: Text(
              t.detailLayout,
              style: TextStyle(color: context.tt.textTertiary, fontSize: TtText.small),
            ),
          ),
          RadioGroup<bool>(
            groupValue: popup,
            onChanged: (v) => Navigator.pop(context, v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(value: false, title: Text(t.detailLayoutPanel)),
                RadioListTile(value: true, title: Text(t.detailLayoutPopup)),
              ],
            ),
          ),
        ],
      ),
    );
    final repo = ref.read(preferencesRepositoryProvider);
    switch (picked) {
      case final DateDisplay display:
        await repo.setDateDisplay(display);
      case final bool enabled:
        await repo.setDetailPopup(enabled: enabled);
    }
  }
}

/// "Adicionar tarefa" field: 40 px, 10 px radius, 3% fill (measured). Enter creates the task, opens
/// it in the detail and keeps the field focused for the next one.
class _AddTaskField extends ConsumerStatefulWidget {
  const _AddTaskField({required this.target, required this.hint});

  final AddTarget target;
  final String hint;

  @override
  ConsumerState<_AddTaskField> createState() => _AddTaskFieldState();
}

class _AddTaskFieldState extends ConsumerState<_AddTaskField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  /// Date chosen with the field's calendar icon, used when the text has no date.
  DateSelection? _schedule;

  /// Chosen in the ▾ menu for the next task: priority, list and section, tags, note.
  Priority? _priority;
  (String, String?)? _destination;
  Set<String> _tags = const {};
  bool _asNote = false;

  /// Files for the next task ("Anexo"): copied to the attachment store and put in its content.
  List<String> _files = const [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    final paths = [for (final f in result?.files ?? const <PlatformFile>[]) ?f.path];
    if (paths.isNotEmpty && mounted) setState(() => _files = [..._files, ...paths]);
  }

  Future<void> _pickPriority(BuildContext at) async {
    final box = at.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset(0, box.size.height));
    final picked = await showMenu<Object>(
      context: context,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
      items: const [_FlagRowEntry()],
    );
    if (picked is Priority && mounted) setState(() => _priority = picked);
  }

  Future<void> _pickDestination() async {
    final target = await pickListTarget(context, ref, currentListId: _destination?.$1 ?? widget.target.listId);
    if (target != null && mounted) setState(() => _destination = target);
  }

  Future<void> _pickTagsForNext() async {
    final tags = await pickTags(context, ref, initial: _tags);
    if (tags != null && mounted) setState(() => _tags = tags);
  }

  Future<void> _addMenu() async {
    final t = AppLocalizations.of(context);
    final detailed = ref.read(preferencesProvider).value?.addFieldDetailed ?? false;
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset(box.size.width - 40, box.size.height));
    final picked = await showMenu<Object>(
      context: context,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
      items: [
        PopupMenuItem<Object>(
          enabled: false,
          height: 28,
          child: Text(t.menuPriority, style: const TextStyle(fontSize: TtText.small)),
        ),
        const _FlagRowEntry(),
        const PopupMenuDivider(),
        PopupMenuItem<Object>(value: 'list', height: 36, child: Text('${t.menuMoveTo} ›')),
        PopupMenuItem<Object>(value: 'tags', height: 36, child: Text(t.menuTags)),
        PopupMenuItem<Object>(value: 'attach', height: 36, child: Text(t.slashAttachment)),
        PopupMenuItem<Object>(value: 'template', height: 36, child: Text(t.templateAddFrom)),
        CheckedPopupMenuItem<Object>(value: 'note', checked: _asNote, child: Text(t.addAsNote)),
        const PopupMenuDivider(),
        // "Estilo da Caixa de Entrada": Simples or Detalhado.
        CheckedPopupMenuItem<Object>(value: 'simple', checked: !detailed, child: Text(t.addFieldSimple)),
        CheckedPopupMenuItem<Object>(value: 'detailed', checked: detailed, child: Text(t.addFieldDetailed)),
      ],
    );
    if (!mounted) return;
    switch (picked) {
      case final Priority p:
        setState(() => _priority = p);
      case 'list':
        await _pickDestination();
      case 'tags':
        await _pickTagsForNext();
      case 'attach':
        await _pickFiles();
      case 'simple' || 'detailed':
        await ref.read(preferencesRepositoryProvider).setAddFieldDetailed(enabled: picked == 'detailed');
      case 'template':
        await _fromTemplate();
      case 'note':
        setState(() => _asNote = !_asNote);
    }
  }

  /// The ▾ choices waiting for the next task, as small chips that clear on a click.
  List<Widget> _pendingChips(TtColors tt) {
    final t = AppLocalizations.of(context);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    Widget chip(Widget child, VoidCallback clear) => Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(onTap: clear, borderRadius: BorderRadius.circular(4), child: child),
    );
    final list = _destination == null ? null : s.listById[_destination!.$1];
    return [
      if (_priority case final p?) chip(Icon(Icons.flag, size: 15, color: tt.priorityColor(p)), () => setState(() => _priority = null)),
      if (list != null)
        chip(
          Text(
            '~${Labels(t).listName(list)}',
            style: TextStyle(fontSize: TtText.small, color: tt.primary),
          ),
          () => setState(() => _destination = null),
        ),
      for (final id in _tags)
        if (s.tagById[id] case final tag?)
          chip(
            Text(
              '#${tag.name}',
              style: TextStyle(fontSize: TtText.small, color: tt.primary),
            ),
            () => setState(() => _tags = {..._tags}..remove(id)),
          ),
      if (_asNote) chip(Icon(Icons.sticky_note_2_outlined, size: 15, color: tt.primary), () => setState(() => _asNote = false)),
      if (_files.isNotEmpty)
        chip(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_file, size: 14, color: tt.primary),
              Text(
                '${_files.length}',
                style: TextStyle(fontSize: TtText.small, color: tt.primary),
              ),
            ],
          ),
          () => setState(() => _files = const []),
        ),
    ];
  }

  String _scheduleLabel(DateSelection schedule) {
    final labels = DateLabels(AppLocalizations.of(context));
    final today = startOfDay(ref.watch(clockProvider).now());
    final start = schedule.startDate;
    final end = schedule.dueDate!;
    return start != null && start.isBefore(end)
        ? labels.detailRange(start, end, isAllDay: schedule.isAllDay, today: today)
        : labels.detailDate(end, isAllDay: schedule.isAllDay, today: today);
  }

  Future<void> _pickSchedule() async {
    final now = ref.read(clockProvider).now();
    final picked = await showTtDatePicker(
      context,
      initial: _schedule ?? DateSelection(dueDate: widget.target.dueDate),
      now: now,
    );
    if (picked == null || !mounted) return;
    setState(() => _schedule = picked.dueDate == null ? null : picked);
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// "Adicionar a partir do modelo": the task gets the template's title, content, checklist and tags,
  /// no date, and opens in the detail.
  Future<void> _fromTemplate() async {
    final template = await pickTemplate(context, notes: widget.target.hint is AddNoteHint);
    if (template == null || !mounted) return;
    final id = await ref.read(repositoryProvider).createTaskFromTemplate(template.id, listId: widget.target.listId);
    if (!mounted) return;
    final router = GoRouter.of(context);
    final base = RegExp(r'^(/[a-z]/[^/]+/tasks)').firstMatch(router.state.uri.path)?.group(1) ?? Routes.of(ListScope(widget.target.listId));
    router.go('$base/$id');
  }

  Future<void> _create(String text) async {
    final id = await createFromQuickAdd(
      ref,
      AppLocalizations.of(context),
      text: text,
      target: widget.target,
      schedule: _schedule,
      priority: _priority,
      listId: _destination?.$1,
      sectionId: _destination?.$2,
      tagIds: _tags,
      kind: _asNote ? TaskKind.note : null,
    );
    if (id == null) return;
    // "Anexo": the files become attachment cards in the new task's content.
    final store = ref.read(attachmentStoreProvider);
    if (_files.isNotEmpty) {
      final references = [for (final path in _files) await store.add(File(path))];
      await ref.read(repositoryProvider).setContent(id, [for (final r in references) '![file]($r)'].join('\n'));
    }
    _controller.clear();
    if (mounted) {
      setState(() {
        _schedule = null;
        _priority = null;
        _destination = null;
        _tags = const {};
        _asNote = false;
        _files = const [];
      });
    }
    _focus.requestFocus();
    if (!mounted) return;
    final router = GoRouter.of(context);
    final path = router.state.uri.path;
    final base = RegExp(r'^(/[a-z]/[^/]+/tasks)').firstMatch(path)?.group(1) ?? Routes.of(ListScope(widget.target.listId));
    router.go('$base/$id');
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    final detailed = ref.watch(preferencesProvider).value?.addFieldDetailed ?? false;
    final field = QuickAddTextField(controller: _controller, focusNode: _focus, hint: widget.hint, onSubmitted: _create);
    final Widget date;
    if (_schedule case final DateSelection schedule) {
      date = InkWell(
        onTap: () => unawaited(_pickSchedule()),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _scheduleLabel(schedule),
                style: TextStyle(fontSize: TtText.small, color: tt.primary),
              ),
              if (schedule.repeatRule != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.repeat, size: 13, color: tt.primary),
                ),
              InkWell(
                onTap: () => setState(() => _schedule = null),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.close, size: 13, color: tt.textTertiary),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      date = IconButton(
        tooltip: t.pickerTabDate,
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.calendar_today_outlined, size: 16, color: tt.textTertiary),
        onPressed: () => unawaited(_pickSchedule()),
      );
    }
    // ▾ extra menu of the field.
    final menu = IconButton(
      tooltip: '',
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.expand_more, size: 16, color: tt.textTertiary),
      onPressed: () => unawaited(_addMenu()),
    );
    Widget icon(IconData data, String tooltip, VoidCallback onPressed) => IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(data, size: 17, color: tt.textTertiary),
      onPressed: onPressed,
    );

    if (detailed) {
      // "Detalhado": a bigger box, the icons below the text and "Adicionar".
      return Padding(
        padding: const EdgeInsets.fromLTRB(21, 0, 20, 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
          decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 32, child: field),
              Row(
                children: [
                  date,
                  Builder(builder: (context) => icon(Icons.outlined_flag, t.menuPriority, () => unawaited(_pickPriority(context)))),
                  icon(Icons.drive_file_move_outline, t.menuMoveTo, () => unawaited(_pickDestination())),
                  icon(Icons.sell_outlined, t.menuTags, () => unawaited(_pickTagsForNext())),
                  icon(Icons.attach_file, t.slashAttachment, () => unawaited(_pickFiles())),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: _pendingChips(tt)),
                    ),
                  ),
                  menu,
                  const SizedBox(width: 4),
                  FilledButton(
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () => unawaited(_create(_controller.text)),
                    child: Text(t.addFieldAdd),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(21, 0, 20, 8),
      child: Container(
        height: TtSizes.addFieldHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(Icons.add, size: 16, color: tt.placeholder),
            const SizedBox(width: 8),
            Expanded(child: field),
            date,
            ..._pendingChips(tt),
            menu,
          ],
        ),
      ),
    );
  }
}

class _Group extends ConsumerWidget {
  const _Group({
    required this.group,
    required this.scope,
    required this.title,
    required this.selectedTaskId,
    required this.now,
    required this.showDetails,
    required this.isNarrow,
  });

  final TaskGroup group;
  final Scope scope;
  final String title;
  final String? selectedTaskId;
  final DateTime now;
  final bool showDetails;
  final bool isNarrow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    final key = '${Routes.of(scope)}|${group.key}';
    final collapsed = ref.watch(collapsedGroupsProvider).contains(key);
    final expanded = ref.watch(expandedClosedGroupsProvider).contains(key);
    final rows = group.isClosed && !expanded ? group.rows.take(5).toList() : group.rows;
    final routeBase = Routes.of(scope);
    final options = ref.watch(viewOptionsProvider(scope));
    final countdown = ref.watch(preferencesProvider).value?.dateDisplay == DateDisplay.countdown;
    // A task drops before another of its own group (any task, with custom or no grouping). Sorted by
    // anything else, the drop switches the view to the custom order (as TickTick does).
    final anyGroup = options.grouping == Grouping.custom || options.grouping == Grouping.none;
    final groupIds = {for (final r in group.rows) r.task.id};
    bool canReorder(String dragged) => !group.isClosed && (anyGroup || groupIds.contains(dragged));
    Future<void> reordered() async {
      if (options.sorting == Sorting.custom) return;
      await setScopeViewOptions(ref, scope, options.copyWith(sorting: Sorting.custom));
      if (context.mounted) showToast(context, t.reorderSortCustom);
    }

    final isSectionGroup = group.header is UnsectionedHeader || group.header is SectionHeader;
    final selection = ref.watch(taskSelectionProvider);
    final multi = selection.isNotEmpty;

    // Ctrl+click adds to the selection, Shift+click selects a range, a plain click opens the task
    // and ends the multi-selection. On a phone, while selecting, a tap adds or removes the task.
    void onRowTap(TaskRow row) {
      final keyboard = HardwareKeyboard.instance;
      final notifier = ref.read(taskSelectionProvider.notifier);
      if (isNarrow && multi) {
        notifier.toggle(row.task.id);
      } else if (!isNarrow && (keyboard.isControlPressed || keyboard.isMetaPressed)) {
        notifier.toggle(row.task.id, current: selectedTaskId);
      } else if (!isNarrow && keyboard.isShiftPressed) {
        final order = [
          for (final g in ref.read(viewProvider(scope))?.groups ?? const <TaskGroup>[])
            for (final r in g.rows) r.task.id,
        ];
        notifier.range(row.task.id, order, current: selectedTaskId);
      } else {
        notifier.clear();
        context.go('$routeBase/${row.task.id}');
      }
    }

    Widget tile(TaskRow row) {
      final tileWidget = TaskRowTile(
        row: row,
        selected: multi ? selection.contains(row.task.id) : row.task.id == selectedTaskId,
        now: now,
        showDetails: showDetails,
        onTap: () => onRowTap(row),
        onToggleComplete: () => fireAndForget(toggleComplete(context, ref, row.task)),
        onToggleCollapse: () => ref.read(collapsedTasksProvider.notifier).toggle(row.task.id),
        onMenu: (p) => fireAndForget(
          showTaskMenu(
            context,
            ref,
            row.task,
            p,
            onAddSubtask: (id) => context.go('$routeBase/$id'),
            // Phones have no Ctrl+click: the long press menu starts the selection.
            onSelect: isNarrow && row.task.deletedAt == null
                ? () {
                    // The add field gets its focus back when the menu closes; selecting needs no keyboard.
                    FocusManager.instance.primaryFocus?.unfocus();
                    ref.read(taskSelectionProvider.notifier).toggle(row.task.id);
                  }
                : null,
          ),
        ),
        countdown: countdown,
        // A phone's long press drags the row; the menu comes from a long press that doesn't move.
        longPressMenu: !isNarrow || multi || row.task.deletedAt != null,
      );
      if (row.task.deletedAt != null || (isNarrow && multi)) return tileWidget;
      final droppable = _DropRow(row: row, sectionId: group.sectionId, canReorder: canReorder, onReordered: reordered, child: tileWidget);
      // Drag a task before another (and, on a computer, onto a list or "Hoje" in the sidebar). On a
      // phone the drag starts with a long press; let go without moving, it opens the menu.
      return _RowDraggable(
        taskId: row.task.id,
        touch: isNarrow,
        onMenu: (p) => fireAndForget(
          showTaskMenu(
            context,
            ref,
            row.task,
            p,
            onAddSubtask: (id) => context.go('$routeBase/$id'),
            onSelect: () {
              FocusManager.instance.primaryFocus?.unfocus();
              ref.read(taskSelectionProvider.notifier).toggle(row.task.id);
            },
          ),
        ),
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
            ),
            child: Text(
              row.task.title.isEmpty ? t.untitled : row.task.title,
              style: TextStyle(color: tt.text, fontSize: TtText.body),
            ),
          ),
        ),
        child: droppable,
      );
    }

    final section = !multi && scope is ListScope && group.header is SectionHeader ? _sectionOf(ref, group.sectionId) : null;
    return SliverMainAxisGroup(
      slivers: [
        if (title.isNotEmpty)
          SliverToBoxAdapter(
            child: _maybeSectionTarget(
              enabled: isSectionGroup && scope is ListScope && !isNarrow,
              onDrop: (taskId) => ref.read(repositoryProvider).moveToSectionTop(taskId, (scope as ListScope).listId, group.sectionId),
              child: InkWell(
                onTap: () => ref.read(collapsedGroupsProvider.notifier).toggle(key),
                child: SizedBox(
                  height: TtSizes.groupHeaderHeight,
                  child: Padding(
                    padding: const EdgeInsets.only(left: ListGrid.left, top: 12),
                    child: Row(
                      children: [
                        ListLeading(child: Icon(collapsed ? Icons.chevron_right : Icons.expand_more, size: 16, color: tt.textTertiary)),
                        const SizedBox(width: ListGrid.gap),
                        if (group.header is PinnedHeader)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin, size: 14, color: tt.palette.priorityMedium),
                          ),
                        Text(
                          title,
                          style: TextStyle(fontSize: TtText.body, fontWeight: FontWeight.w600, color: tt.text),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${group.rows.length}',
                          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                        ),
                        // "…" of a section in the List view.
                        if (section != null) ...[
                          const Spacer(),
                          Builder(
                            builder: (context) => IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: '',
                              icon: Icon(Icons.more_horiz, size: 16, color: tt.textTertiary),
                              onPressed: () {
                                final box = context.findRenderObject()! as RenderBox;
                                final origin = box.localToGlobal(Offset(0, box.size.height));
                                unawaited(
                                  showSectionMenu(
                                    context,
                                    ref,
                                    section,
                                    position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        // While selecting, each group can select or clear all its tasks.
                        if (multi) ...[
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () {
                              final ids = [for (final r in group.rows) r.task.id];
                              final notifier = ref.read(taskSelectionProvider.notifier);
                              ids.every(selection.contains) ? notifier.deselect(ids) : notifier.selectAll(ids);
                            },
                            child: Text(
                              group.rows.every((r) => selection.contains(r.task.id)) ? t.deselectAll : t.selectAll,
                              style: const TextStyle(fontSize: TtText.small),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (!collapsed) ...[
          SliverList.builder(itemCount: rows.length, itemBuilder: (context, i) => tile(rows[i])),
          if (group.isClosed && !expanded && group.rows.length > 5)
            SliverToBoxAdapter(
              child: InkWell(
                onTap: () => ref.read(expandedClosedGroupsProvider.notifier).add(key),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.only(left: ListGrid.title),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.showMore,
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.texts});

  final (String, String) texts;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 96, color: tt.divider),
          const SizedBox(height: 16),
          Text(
            texts.$1,
            style: TextStyle(fontSize: TtText.body, color: tt.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            texts.$2,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
        ],
      ),
    );
  }
}

Widget _maybeSectionTarget({required bool enabled, required Future<void> Function(String taskId) onDrop, required Widget child}) {
  if (!enabled) return child;
  return DragTarget<String>(
    onAcceptWithDetails: (d) => fireAndForget(onDrop(d.data)),
    builder: (context, candidates, _) => DecoratedBox(
      decoration: BoxDecoration(
        color: candidates.isEmpty ? null : context.tt.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    ),
  );
}

enum _DropMode { before, subtask }

/// Saves a view's options: a list in its row, the other views in the preferences.
Future<void> setScopeViewOptions(WidgetRef ref, Scope scope, ViewOptions options) async {
  if (scope is ListScope) {
    await ref
        .read(repositoryProvider)
        .setListViewOptions(
          scope.listId,
          grouping: options.grouping,
          sorting: options.sorting,
          showCompleted: options.showCompleted,
          showDetails: options.showDetails,
        );
  } else {
    ref.read(scopeOptionsProvider.notifier).set(scope, options);
    final saved = ref.read(preferencesProvider).value?.scopeViewOptions ?? const {};
    await ref.read(preferencesRepositoryProvider).setScopeViewOptions({...saved, Routes.of(scope): options});
  }
}

/// A task row that drags: at once with a mouse; after a long press on a phone, where letting go
/// without moving opens [onMenu] instead. Near the top or the bottom of the list, it scrolls.
class _RowDraggable extends StatefulWidget {
  const _RowDraggable({required this.taskId, required this.touch, required this.onMenu, required this.feedback, required this.child});

  final String taskId;
  final bool touch;
  final void Function(Offset at) onMenu;
  final Widget feedback;
  final Widget child;

  @override
  State<_RowDraggable> createState() => _RowDraggableState();
}

class _RowDraggableState extends State<_RowDraggable> {
  Offset? _down;

  /// Scrolls the list a little while the finger (or the mouse) is near one of its edges.
  void _autoScroll(Offset global) {
    final scrollable = Scrollable.maybeOf(context);
    final box = scrollable?.context.findRenderObject();
    if (scrollable == null || box is! RenderBox || !box.hasSize) return;
    final y = box.globalToLocal(global).dy;
    const edge = 56.0;
    final position = scrollable.position;
    final step = y < edge ? -(edge - y) / 3 : (y > box.size.height - edge ? (y - box.size.height + edge) / 3 : 0.0);
    if (step == 0) return;
    position.jumpTo((position.pixels + step).clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.touch) {
      return Draggable<String>(
        data: widget.taskId,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragUpdate: (d) => _autoScroll(d.globalPosition),
        feedback: widget.feedback,
        child: widget.child,
      );
    }
    return Listener(
      onPointerDown: (e) => _down = e.position,
      child: LongPressDraggable<String>(
        data: widget.taskId,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        hapticFeedbackOnStart: true,
        onDragUpdate: (d) => _autoScroll(d.globalPosition),
        // Let go where it began: it was a long press for the menu.
        onDraggableCanceled: (_, offset) {
          final down = _down;
          if (down != null && (offset - down).distance < 16) widget.onMenu(down);
        },
        feedback: widget.feedback,
        child: widget.child,
      ),
    );
  }
}

/// Drop target of a task row: before it (reorder) or, dropped further right, as its subtask.
class _DropRow extends ConsumerStatefulWidget {
  const _DropRow({required this.row, required this.sectionId, required this.canReorder, required this.onReordered, required this.child});

  final TaskRow row;
  final String? sectionId;

  /// Whether the dragged task may drop before this one.
  final bool Function(String dragged) canReorder;

  /// After a drop before this one (the view switches to the custom order).
  final Future<void> Function() onReordered;
  final Widget child;

  @override
  ConsumerState<_DropRow> createState() => _DropRowState();
}

class _DropRowState extends ConsumerState<_DropRow> {
  _DropMode? _mode;

  double get _indent => 16 + TtSizes.subtaskIndent * widget.row.depth;

  _DropMode? _modeAt(Offset global, String dragged) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final x = box.globalToLocal(global).dx;
    if (x > _indent + 60) return _DropMode.subtask;
    return widget.canReorder(dragged) ? _DropMode.before : null;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.row.task;
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != task.id && task.status == TaskStatus.open,
      onMove: (d) {
        final mode = _modeAt(d.offset, d.data);
        if (mode != _mode) setState(() => _mode = mode);
      },
      onLeave: (_) => setState(() => _mode = null),
      onAcceptWithDetails: (d) {
        final mode = _modeAt(d.offset, d.data);
        setState(() => _mode = null);
        final repo = ref.read(repositoryProvider);
        switch (mode) {
          case _DropMode.subtask:
            fireAndForget(guarded(context, () => repo.makeSubtask(d.data, task.id)));
          case _DropMode.before:
            fireAndForget(() async {
              if (await guarded(context, () => repo.moveBefore(d.data, task.id, sectionId: Value(widget.sectionId ?? task.sectionId)))) {
                await widget.onReordered();
              }
            }());
          case null:
            break;
        }
      },
      builder: (context, candidates, _) => Stack(
        children: [
          widget.child,
          if (candidates.isNotEmpty && _mode != null)
            Positioned(
              top: 0,
              left: _mode == _DropMode.subtask ? _indent + TtSizes.subtaskIndent : _indent,
              right: 30,
              child: Container(height: 2, color: context.tt.primary),
            ),
        ],
      ),
    );
  }
}

/// "Contagem Regressiva" at the end of Hoje / Próximos 7 dias: name and "Hoje" / "Em 3 dias"; a click
/// opens the countdowns.
class _CountdownSection extends StatelessWidget {
  const _CountdownSection({required this.countdowns, required this.now});

  final List<Countdown> countdowns;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListSectionTitle(t.navCountdown),
        for (final c in countdowns)
          ListItemRow(
            onTap: () => context.go(Routes.countdown),
            leading: Icon(
              c.type == CountdownType.holiday ? Icons.celebration : Icons.hourglass_bottom,
              size: 16,
              color: parseHexColor(c.color) ?? tt.primary,
            ),
            title: c.name,
            trailing: Text(
              t.countdownDaysAway(daysBetween(startOfDay(now), countdownStatus(c, now).target).clamp(0, 99999)),
              style: TextStyle(fontSize: TtText.small, color: tt.primary),
            ),
          ),
      ],
    );
  }
}

/// "Hábito" in Hoje / Próximos 7 dias: today's habits with the check-in dot.
class _HabitSection extends StatelessWidget {
  const _HabitSection({required this.habits, required this.snapshot, required this.day});

  final List<Habit> habits;
  final Snapshot snapshot;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListSectionTitle(t.navHabit),
        for (final h in habits)
          ListItemRow(
            onTap: () => context.go(Routes.habit),
            leading: HabitIcon(habit: h, size: 20),
            title: h.name,
            trailing: HabitDot(
              habit: h,
              checkin: snapshot.checkinsOf(h.id).where((c) => daysBetween(habitDay(c.day), day) == 0).firstOrNull,
              day: day,
              size: 22,
            ),
          ),
      ],
    );
  }
}

/// The section of a List-view group, if it still exists.
Section? _sectionOf(WidgetRef ref, String? id) =>
    id == null ? null : ref.read(snapshotProvider).value?.sections.where((s) => s.id == id && s.deletedAt == null).firstOrNull;

/// "Todas as datas ▾" and "Todas as listas ▾" of Concluído and Não será feito.
class _ClosedFilterBar extends ConsumerWidget {
  const _ClosedFilterBar({required this.list, required this.snapshot, required this.today});

  final SmartList list;
  final Snapshot snapshot;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final dates = DateLabels(t);
    final filter = ref.watch(closedFiltersProvider)[list] ?? const ClosedFilter();
    void set(ClosedFilter next) => ref.read(closedFiltersProvider.notifier).set(list, next);
    final dateLabel = switch (filter.date) {
      ClosedDate.all => t.closedAllDates,
      ClosedDate.thisWeek => t.filterDateThisWeek,
      ClosedDate.lastWeek => t.searchDateLastWeek,
      ClosedDate.thisMonth => t.filterDateThisMonth,
      ClosedDate.otherMonth => filter.month == null ? t.closedOtherMonth : dates.monthTitle(filter.month!),
    };
    final listName = filter.listId == null ? null : snapshot.listById[filter.listId];
    Widget chip(String label, bool active, List<PopupMenuEntry<Object>> items, void Function(Object) onSelected) => PopupMenuButton<Object>(
      tooltip: '',
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: active ? tt.primary.withValues(alpha: 0.15) : tt.fieldFill, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: TtText.small, color: active ? tt.primary : tt.textSecondary),
            ),
            Icon(Icons.expand_more, size: 14, color: active ? tt.primary : tt.textTertiary),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Wrap(
        spacing: 8,
        children: [
          chip(
            dateLabel,
            filter.date != ClosedDate.all,
            [
              for (final (value, label) in [
                (ClosedDate.all, t.closedAllDates),
                (ClosedDate.thisWeek, t.filterDateThisWeek),
                (ClosedDate.lastWeek, t.searchDateLastWeek),
                (ClosedDate.thisMonth, t.filterDateThisMonth),
                (ClosedDate.otherMonth, t.closedOtherMonth),
              ])
                PopupMenuItem<Object>(value: value, height: 36, child: Text(label)),
            ],
            (v) async {
              if (v != ClosedDate.otherMonth) return set(ClosedFilter(date: v as ClosedDate, listId: filter.listId));
              // "Outro mês": one of the last 24 months.
              final month = await showDialog<DateTime>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text(t.closedOtherMonth, style: const TextStyle(fontSize: 15)),
                  children: [
                    for (var i = 0; i < 24; i++)
                      if (DateTime(today.year, today.month - i) case final m)
                        SimpleDialogOption(onPressed: () => Navigator.pop(context, m), child: Text(dates.monthTitle(m))),
                  ],
                ),
              );
              if (month != null) set(ClosedFilter(date: ClosedDate.otherMonth, month: month, listId: filter.listId));
            },
          ),
          chip(listName == null ? t.closedAllLists : labels.listName(listName), listName != null, [
            PopupMenuItem<Object>(value: '', height: 36, child: Text(t.closedAllLists)),
            for (final l in snapshot.activeLists) PopupMenuItem<Object>(value: l.id, height: 36, child: Text(labels.listName(l))),
          ], (v) => set(ClosedFilter(date: filter.date, month: filter.month, listId: v == '' ? null : v as String))),
        ],
      ),
    );
  }
}

/// The four priority flags as one row of the add field's ▾ menu; pops the [Priority].
class _FlagRowEntry extends PopupMenuEntry<Object> {
  const _FlagRowEntry();

  @override
  double get height => 40;

  @override
  bool represents(Object? value) => false;

  @override
  State<_FlagRowEntry> createState() => _FlagRowEntryState();
}

class _FlagRowEntryState extends State<_FlagRowEntry> {
  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final labels = Labels(AppLocalizations.of(context));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final p in Priority.values.reversed)
            IconButton(
              tooltip: labels.priority(p),
              visualDensity: VisualDensity.compact,
              icon: Icon(p == Priority.none ? Icons.outlined_flag : Icons.flag, color: tt.priorityColor(p), size: 20),
              onPressed: () => Navigator.pop(context, p),
            ),
        ],
      ),
    );
  }
}

/// "Tarefas Sugeridas" for Hoje: overdue, the next days' and undated tasks, each with "+" to bring it
/// to today.
class _SuggestedTasks extends ConsumerWidget {
  const _SuggestedTasks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = DateLabels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final now = ref.watch(clockProvider).now();
    final today = startOfDay(now);
    final suggested = suggestedForToday(s, now);
    final groups = [(t.groupOverdue, suggested.overdue), (t.suggestedUpcoming, suggested.upcoming), (t.groupNoDate, suggested.noDate)];
    Widget row(Task task) => ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.flag, size: 16, color: tt.priorityColor(task.priority)),
      title: Text(task.title.isEmpty ? t.untitled : task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: task.endLocal == null ? null : Text(labels.rowDate(task.endLocal!, isAllDay: task.isAllDay, today: today)),
      trailing: IconButton(
        tooltip: t.suggestedAddToday,
        icon: Icon(Icons.add_circle_outline, color: tt.primary),
        onPressed: () => unawaited(ref.read(repositoryProvider).moveToDay(task.id, today)),
      ),
    );
    final empty = groups.every((g) => g.$2.isEmpty);
    return AlertDialog(
      title: Text(t.suggestedTasks, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 440,
        height: 460,
        child: empty
            ? Center(
                child: Text(t.suggestedEmpty, style: TextStyle(color: tt.textTertiary)),
              )
            : ListView(
                children: [
                  for (final (title, tasks) in groups)
                    if (tasks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 2),
                        child: Text(
                          '$title ${tasks.length}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: tt.textSecondary, fontSize: TtText.small),
                        ),
                      ),
                      for (final task in tasks) row(task),
                    ],
                ],
              ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose))],
    );
  }
}
