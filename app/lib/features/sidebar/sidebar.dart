import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/ids.dart';
import '../../core/sort_order.dart';
import '../../data/db/database.dart';
import '../../data/preferences_repository.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/feedback.dart';
import '../activities/activities_dialog.dart';
import '../common/labels.dart';
import '../filters/filter_dialog.dart';
import '../subscriptions/subscriptions.dart';
import '../lists/list_dialog.dart';
import '../tags/tag_dialog.dart';
import '../date_picker/month_calendar.dart';
import '../calendar/calendar_page.dart' show calendarAnchorProvider;
import '../../domain/calendar.dart' show CalendarMode;
import '../../core/clock.dart';
import '../../app/format/date_labels.dart';
import '../../data/repository.dart' show ListCopyMode, maxListLevels;
import '../lists/folder_dialog.dart';

/// Lists sidebar: smart lists, Lists (folders), Filters, Tags and the closed lists.
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, required this.current, this.onNavigate, this.width});

  /// Width dragged by the user; null = [TtSizes.sidebarWidth].
  final double? width;

  /// The list shown; null in a module (nothing is highlighted).
  final Scope? current;

  /// Called after navigating (the mobile drawer closes itself).
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final labels = Labels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final counts = ref.watch(countsProvider);
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final tt = context.tt;

    void go(Scope scope) {
      context.go(Routes.of(scope));
      onNavigate?.call();
    }

    bool visibleIn(SmartListVisibility v, bool hasItems) => switch (v) {
      SmartListVisibility.show => true,
      SmartListVisibility.hide => false,
      SmartListVisibility.showIfNotEmpty => hasItems,
    };

    bool visible(SmartList l, int count) => switch (prefs.smartListVisibility[l]!) {
      SmartListVisibility.show => true,
      SmartListVisibility.hide => false,
      SmartListVisibility.showIfNotEmpty => count > 0 || _hasAny(s, l),
    };

    Widget smart(SmartList l, Widget icon) {
      final count = counts.bySmartList[l] ?? 0;
      if (!visible(l, count)) return const SizedBox.shrink();
      return _SidebarItem(
        icon: icon,
        label: labels.smartList(l),
        count: l.isReadOnly || l == SmartList.summary ? null : count,
        selected: current == SmartScope(l),
        onTap: () => go(SmartScope(l)),
        onMenu: (position) => _smartListMenu(context, ref, l, position),
        acceptsTaskDrop: l == SmartList.today || l == SmartList.tomorrow,
        onTaskDropped: (taskId) => _dropOnSmartList(context, ref, taskId, l),
      );
    }

    final inbox = s.listById[inboxListId];
    final lists = s.activeLists.where((l) => l.id != inboxListId).toList();
    // Pinned lists, folders, tags and filters sit on top, in the order they were pinned.
    final pinned = <(DateTime, _Pinned)>[
      for (final l in lists)
        if (l.pinnedAt case final at?) (at, _Pinned(ListScope(l.id), _listIcon(l), l.name)),
      for (final f in s.activeFolders)
        if (f.pinnedAt case final at?) (at, _Pinned(FolderScope(f.id), folderIcon(f), f.name)),
      for (final tag in s.activeTags)
        if (tag.pinnedAt case final at?) (at, _Pinned(TagScope(tag.id), const Icon(Icons.sell_outlined), tag.name)),
      for (final f in s.filters)
        if (f.pinnedAt case final at?) (at, _Pinned(FilterScope(f.id), const Icon(Icons.filter_alt_outlined), f.name)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    return Container(
      color: tt.screen,
      width: width ?? TtSizes.sidebarWidth,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        children: [
          if (pinned.isNotEmpty) _PinnedLists(items: [for (final p in pinned) p.$2], current: current, onTap: go),
          smart(SmartList.all, const Icon(Icons.all_inbox_outlined)),
          smart(SmartList.today, _DayIcon(day: ref.watch(nowProvider).value?.day ?? DateTime.now().day)),
          smart(SmartList.tomorrow, const Icon(Icons.wb_twilight_outlined)),
          smart(SmartList.next7Days, const _DayIcon(day: 7)),
          if (inbox != null && visibleIn(prefs.inboxVisibility, (counts.byList[inboxListId] ?? 0) > 0))
            _SidebarItem(
              icon: const Icon(Icons.inbox_outlined),
              label: t.inbox,
              count: counts.byList[inboxListId],
              selected: current == const ListScope(inboxListId),
              onTap: () => go(const ListScope(inboxListId)),
              acceptsTaskDrop: true,
              onTaskDropped: (taskId) => _dropOnList(context, ref, taskId, inbox),
            ),
          smart(SmartList.summary, const Icon(Icons.summarize_outlined)),
          _divider(tt),
          _SectionHeader(label: t.sidebarLists, onAdd: () => _addList(context, ref), onAddFolder: () => createFolderWithDialog(context, ref)),
          ..._listsAndFolders(context, ref, s, lists, counts, go, prefs.collapsedLists),
          if (s.archivedLists.isNotEmpty) ..._archived(context, ref, s, go),
          const SizedBox(height: 4),
          if (visibleIn(prefs.filtersVisibility, s.filters.isNotEmpty)) ...[
            _SectionHeader(label: t.sidebarFilters, onAdd: () => _addFilter(context, ref)),
            if (s.filters.isEmpty) _HelpBox(text: t.sidebarFiltersHelp),
            for (final f in s.filters)
              _SidebarItem(
                icon: const Icon(Icons.filter_alt_outlined),
                label: f.name,
                count: counts.byFilter[f.id],
                selected: current == FilterScope(f.id),
                onTap: () => go(FilterScope(f.id)),
                onMenu: (p) => _filterMenu(context, ref, f, p),
              ),
          ],
          if (visibleIn(prefs.tagsVisibility, s.activeTags.isNotEmpty)) ...[
            _SectionHeader(label: t.sidebarTags, onAdd: () => _addTag(context, ref)),
            if (s.activeTags.isEmpty) _HelpBox(text: t.sidebarTagsHelp),
            ..._tags(context, ref, s, counts, go),
          ],
          // "Calendários assinados": a click opens the calendar.
          if (prefs.subscriptions.isNotEmpty) ...[
            _SectionHeader(label: t.subscriptionsTitle),
            for (final sub in prefs.subscriptions)
              _SidebarItem(
                icon: Icon(sub.visible ? Icons.event_outlined : Icons.visibility_off_outlined),
                label: sub.name,
                color: parseHexColor(sub.color),
                onTap: () {
                  context.go(Routes.calendar);
                  onNavigate?.call();
                },
                onMenu: (p) async {
                  final choice = await _showMenuAt<String>(context, p, [
                    ('toggle', sub.visible ? t.smartListHide : t.smartListShow),
                    ('delete', t.actionDelete),
                  ]);
                  if (choice == 'toggle') await setSubscriptionVisible(ref, sub, visible: !sub.visible);
                  if (choice == 'delete') await removeSubscription(ref, sub);
                },
              ),
          ],
          _divider(tt),
          smart(SmartList.completed, const Icon(Icons.check_box_outlined)),
          smart(SmartList.wontDo, const Icon(Icons.disabled_by_default_outlined)),
          smart(SmartList.trash, const Icon(Icons.delete_outline)),
          // "Mini Calendário" (Settings → Mais configurações): a day opens the Calendar on it.
          if (prefs.miniCalendar) ...[_divider(tt), _MiniCalendar(onNavigate: onNavigate)],
          // In the drawer the modules come last: Hábito · Contagem Regressiva · Foco, plus
          // the Calendário and the Matriz, which the narrow webapp leaves out but TickTick's
          // Android app has.
          if (onNavigate != null) ...[
            _divider(tt),
            for (final (icon, label, route, feature) in [
              (Icons.calendar_month_outlined, t.navCalendar, Routes.calendar, AppFeature.calendar),
              (Icons.grid_view_outlined, t.navMatrix, Routes.matrix, AppFeature.matrix),
              (Icons.track_changes, t.navHabit, Routes.habit, AppFeature.habit),
              (Icons.hourglass_bottom, t.navCountdown, Routes.countdown, AppFeature.countdown),
              (Icons.timer_outlined, t.navFocus, Routes.focus, AppFeature.focus),
              (Icons.account_balance_wallet_outlined, t.navFinance, Routes.finance, AppFeature.finance),
              (Icons.restaurant_outlined, t.navDiet, Routes.diet, AppFeature.diet),
            ])
              if (prefs.has(feature))
                _SidebarItem(
                  icon: Icon(icon),
                  label: label,
                  onTap: () {
                    context.go(route);
                    onNavigate?.call();
                  },
                ),
          ],
        ],
      ),
    );
  }

  static bool _hasAny(Snapshot s, SmartList l) => switch (l) {
    SmartList.wontDo => s.tasks.any((t) => t.deletedAt == null && t.status == TaskStatus.wontDo),
    SmartList.completed => s.tasks.any((t) => t.deletedAt == null && t.status == TaskStatus.completed),
    SmartList.trash => s.tasks.any((t) => t.deletedAt != null),
    _ => false,
  };

  Widget _divider(TtColors tt) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Divider(height: 1, color: tt.divider),
  );

  List<Widget> _listsAndFolders(
    BuildContext context,
    WidgetRef ref,
    Snapshot s,
    List<TaskList> lists,
    Counts counts,
    void Function(Scope) go,
    Set<String> collapsedLists,
  ) {
    final widgets = <Widget>[];
    final folders = s.activeFolders;
    // A list (and its sublists below it, unless folded) with its drag target.
    List<Widget> tree(List<(TaskList, int)> entries, double indent) {
      final rows = <Widget>[];
      int? hiddenBelow;
      for (final (l, depth) in entries) {
        if (hiddenBelow != null && depth > hiddenBelow) continue;
        final hasSublists = s.sublistsOf(l.id).isNotEmpty;
        final folded = hasSublists && collapsedLists.contains(l.id);
        hiddenBelow = folded ? depth : null;
        rows.add(
          _Reorderable(
            item: _SidebarDrag(l.id),
            label: l.name,
            acceptsInside: true,
            onDrop: (dragged, where) => _dropOnListItem(context, ref, s, dragged, l, where),
            child: _listItem(
              context,
              ref,
              l,
              counts,
              go,
              indent: indent + 20.0 * depth,
              expanded: hasSublists ? !folded : null,
              onToggle: () => ref.read(preferencesRepositoryProvider).setListCollapsed(collapsedLists, l.id, collapsed: !folded),
            ),
          ),
        );
      }
      return rows;
    }

    // Folders and loose lists (each with its sublists) share one manual order.
    final loose = s.listTree(lists.where((l) => l.folderId == null || s.folderById[l.folderId]?.deletedAt != null));
    final entries = <(int, Widget Function())>[
      for (final f in folders)
        (
          f.sortOrder,
          () => _Reorderable(
            item: _SidebarDrag(f.id, isFolder: true),
            label: f.name,
            onDrop: (dragged, where) => _dropOnFolder(ref, s, dragged, f, after: where == _Drop.after),
            child: _FolderItem(
              folder: f,
              count: counts.byFolder[f.id],
              current: current,
              onOpen: go,
              onToggle: () => ref.read(repositoryProvider).setFolderCollapsed(f.id, collapsed: !f.isCollapsed),
              onMenu: (p) => _folderMenu(context, ref, f, p),
              lists: tree(s.listTree(lists.where((l) => l.folderId == f.id)), 24),
            ),
          ),
        ),
      for (final (i, (l, depth)) in loose.indexed)
        if (depth == 0) (l.sortOrder, () => Column(children: tree([(l, 0), ...loose.skip(i + 1).takeWhile((e) => e.$2 > 0)], 0))),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final e in entries) {
      widgets.add(e.$2());
    }
    return widgets;
  }

  /// Orders of the siblings a dragged item goes between: the sublists of [parentId], the lists of
  /// [folderId], or the folders and loose lists at the top; [except] (the dragged item) left out.
  static List<int> _siblingOrders(Snapshot s, String? folderId, String except, {String? parentId}) => [
    if (folderId == null && parentId == null)
      for (final f in s.activeFolders)
        if (f.id != except) f.sortOrder,
    for (final l in s.activeLists)
      if (l.id != inboxListId &&
          l.id != except &&
          (parentId != null ? l.parentId == parentId : l.folderId == folderId && s.activeParentOf(l) == null))
        l.sortOrder,
  ]..sort();

  /// The order right before or after [target] among [orders].
  static int _orderBeside(List<int> orders, int target, {required bool after}) {
    final i = orders.indexOf(target);
    if (after) {
      final next = i + 1 < orders.length ? orders[i + 1] : null;
      return next == null ? SortOrder.after(target) : (SortOrder.between(target, next) ?? target + 1);
    }
    final previous = i > 0 ? orders[i - 1] : null;
    return previous == null ? SortOrder.before(target) : (SortOrder.between(previous, target) ?? target - 1);
  }

  /// A list or folder dropped on list [target]: on its middle a list becomes its sublist; on its edges
  /// it goes before or after it, at its level (same parent and folder). A folder dropped on a list goes
  /// beside the folder holding it, or beside its top list.
  Future<void> _dropOnListItem(BuildContext context, WidgetRef ref, Snapshot s, _SidebarDrag dragged, TaskList target, _Drop where) async {
    final repo = ref.read(repositoryProvider);
    if (dragged.isFolder) {
      var top = target;
      for (var p = s.activeParentOf(top); p != null; p = s.activeParentOf(p)) {
        top = p;
      }
      final holder = top.folderId == null ? null : s.folderById[top.folderId];
      final anchor = holder?.sortOrder ?? top.sortOrder;
      await repo.moveFolder(dragged.id, _orderBeside(_siblingOrders(s, null, dragged.id), anchor, after: where == _Drop.after));
      return;
    }
    final t = AppLocalizations.of(context);
    if (where == _Drop.inside) {
      final ok = await guarded(context, () => repo.makeSublist(dragged.id, target.id));
      final name = s.listById[dragged.id]?.name ?? '';
      if (ok && context.mounted) showToast(context, t.toastMadeSublist(name, target.name));
      return;
    }
    final parentId = s.activeParentOf(target)?.id;
    final order = _orderBeside(_siblingOrders(s, target.folderId, dragged.id, parentId: parentId), target.sortOrder, after: where == _Drop.after);
    await guarded(context, () => repo.moveList(dragged.id, folderId: target.folderId, parentId: parentId, sortOrder: order));
  }

  /// Dropped on folder [target]: a list goes into it (at the end, at its top level); a folder goes
  /// before or after it.
  Future<void> _dropOnFolder(WidgetRef ref, Snapshot s, _SidebarDrag dragged, Folder target, {required bool after}) async {
    final repo = ref.read(repositoryProvider);
    if (dragged.isFolder) {
      await repo.moveFolder(dragged.id, _orderBeside(_siblingOrders(s, null, dragged.id), target.sortOrder, after: after));
      return;
    }
    final inside = _siblingOrders(s, target.id, dragged.id);
    await repo.moveList(dragged.id, folderId: target.id, sortOrder: SortOrder.after(inside.isEmpty ? null : inside.last));
  }

  /// [expanded]: null for a list without sublists; otherwise its arrow folds them ([onToggle]).
  Widget _listItem(
    BuildContext context,
    WidgetRef ref,
    TaskList l,
    Counts counts,
    void Function(Scope) go, {
    double indent = 0,
    bool? expanded,
    VoidCallback? onToggle,
  }) => _SidebarItem(
    indent: indent,
    icon: _listIcon(l),
    label: l.name,
    color: parseHexColor(l.color),
    count: counts.byList[l.id],
    selected: current == ListScope(l.id),
    onTap: () => go(ListScope(l.id)),
    onMenu: (p) => _listMenu(context, ref, l, p),
    acceptsTaskDrop: true,
    onTaskDropped: (taskId) => _dropOnList(context, ref, taskId, l),
    expanded: expanded,
    onToggle: onToggle,
  );

  List<Widget> _archived(BuildContext context, WidgetRef ref, Snapshot s, void Function(Scope) go) {
    final t = AppLocalizations.of(context);
    return [
      _SidebarItem(icon: const Icon(Icons.inventory_2_outlined), label: t.archivedLists, onTap: () {}),
      for (final l in s.archivedLists)
        _SidebarItem(
          indent: 24,
          icon: _listIcon(l),
          label: l.name,
          selected: current == ListScope(l.id),
          onTap: () => go(ListScope(l.id)),
          onMenu: (p) => _archivedListMenu(context, ref, l, p),
        ),
    ];
  }

  List<Widget> _tags(BuildContext context, WidgetRef ref, Snapshot s, Counts counts, void Function(Scope) go) {
    final roots = s.activeTags.where((t) => t.parentId == null).toList();
    return [
      for (final tag in roots) ...[
        _tagItem(context, ref, tag, counts, go, 0),
        for (final child in s.activeTags.where((c) => c.parentId == tag.id)) _tagItem(context, ref, child, counts, go, 24),
      ],
    ];
  }

  Widget _tagItem(BuildContext context, WidgetRef ref, Tag tag, Counts counts, void Function(Scope) go, double indent) => _SidebarItem(
    indent: indent,
    icon: const Icon(Icons.sell_outlined),
    label: tag.name,
    color: parseHexColor(tag.color),
    count: counts.byTag[tag.id],
    selected: current == TagScope(tag.id),
    onTap: () => go(TagScope(tag.id)),
    onMenu: (p) => _tagMenu(context, ref, tag, p),
  );

  static Widget _listIcon(TaskList l) => l.emoji != null
      ? Text(l.emoji!, style: const TextStyle(fontSize: 15))
      : Icon(l.kind == ListKind.notes ? Icons.sticky_note_2_outlined : Icons.format_list_bulleted);

  // ---------------------------------------------------------------- actions

  Future<void> _addList(BuildContext context, WidgetRef ref, {String? folderId, String? parentId}) async {
    final id = await addListWithDialog(context, ref, folderId: folderId, parentId: parentId);
    if (id == null || !context.mounted) return;
    context.go(Routes.of(ListScope(id)));
    onNavigate?.call();
    if (ref.read(snapshotProvider).value?.listById[id]?.kind == ListKind.notes) {
      final t = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(t.notesListCreated),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(t.gotIt))],
        ),
      );
    }
  }

  Future<void> _addTag(BuildContext context, WidgetRef ref, {String? parentId}) async {
    final form = await showTagDialog(context, parentId: parentId);
    if (form == null) return;
    await ref.read(repositoryProvider).createTag(form.name, color: form.color, parentId: form.parentId);
  }

  Future<void> _addFilter(BuildContext context, WidgetRef ref) async {
    final form = await showFilterDialog(context);
    if (form == null || !context.mounted) return;
    final id = await ref.read(repositoryProvider).createFilter(form.name, form.rule);
    if (!context.mounted) return;
    context.go(Routes.of(FilterScope(id)));
    onNavigate?.call();
  }

  Future<void> _dropOnList(BuildContext context, WidgetRef ref, String taskId, TaskList list) async {
    final t = AppLocalizations.of(context);
    await ref.read(repositoryProvider).move(taskId, list.id);
    if (context.mounted) showToast(context, t.toastMovedTo(Labels(t).listName(list)));
  }

  Future<void> _dropOnSmartList(BuildContext context, WidgetRef ref, String taskId, SmartList l) async {
    final t = AppLocalizations.of(context);
    final now = ref.read(clockProvider).now();
    final day = DateTime(now.year, now.month, now.day + (l == SmartList.tomorrow ? 1 : 0));
    await ref.read(repositoryProvider).setDueDate(taskId, day);
    if (context.mounted) showToast(context, l == SmartList.today ? t.toastMovedToToday : t.toastMovedTo(Labels(t).smartList(l)));
  }

  Future<void> _smartListMenu(BuildContext context, WidgetRef ref, SmartList l, Offset position) async {
    final t = AppLocalizations.of(context);
    // Todas and Resumo only have Mostrar / Esconder.
    final choice = await _showMenuAt<SmartListVisibility>(context, position, [
      if (l != SmartList.all && l != SmartList.summary) (SmartListVisibility.showIfNotEmpty, t.smartListShowIfNotEmpty),
      (SmartListVisibility.hide, t.smartListHide),
    ]);
    if (choice != null) await ref.read(preferencesRepositoryProvider).setSmartListVisibility(l, choice);
  }

  Future<void> _listMenu(BuildContext context, WidgetRef ref, TaskList l, Offset position) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(repositoryProvider);
    final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
    final choice = await _showMenuAt<String>(context, position, [
      ('edit', t.actionEdit),
      // A sublist inside it, while there is a level left.
      if (s.listDepth(l) + 1 < maxListLevels) ('sublist', t.listAddSublist),
      ('pin', l.pinnedAt == null ? t.menuPin : t.menuUnpin),
      ('duplicate', t.actionDuplicate),
      ('activities', t.activityListTitleDialog),
      ('archive', t.actionArchive),
      ('delete', t.actionDelete),
    ]);
    if (!context.mounted) return;
    switch (choice) {
      case 'edit':
        final router = GoRouter.of(context);
        await editListWithDialog(
          context,
          ref,
          l,
          onDeleted: () {
            if (current == ListScope(l.id)) router.go(Routes.of(const ListScope(inboxListId)));
          },
        );
      case 'sublist':
        await _addList(context, ref, parentId: l.id);
      case 'pin':
        await repo.pinList(l.id, pinned: l.pinnedAt == null);
      case 'duplicate':
        final mode = await _pickCopyMode(context);
        if (mode != null) await repo.duplicateList(l.id, copySuffix: t.copySuffix, mode: mode);
      case 'activities':
        await showListActivities(context, l.id);
      case 'archive':
        if (await archiveListAsking(context, ref, l) && context.mounted) showToast(context, t.toastArchived);
      case 'delete':
        await _deleteList(context, ref, l);
    }
  }

  /// Asks, deletes the list (its tasks go to the trash) and leaves it if it was open.
  Future<void> _deleteList(BuildContext context, WidgetRef ref, TaskList l) async {
    final router = GoRouter.of(context);
    if (await deleteListAsking(context, ref, l) && current == ListScope(l.id)) router.go(Routes.of(const ListScope(inboxListId)));
  }

  Future<bool> _deleteFilter(BuildContext context, WidgetRef ref, TaskFilter f) async {
    final t = AppLocalizations.of(context);
    if (!await confirm(context, message: t.filterDeleteConfirm(f.name), confirmLabel: t.actionDelete) || !context.mounted) return false;
    final router = GoRouter.of(context);
    await ref.read(repositoryProvider).deleteFilter(f.id);
    if (current == FilterScope(f.id)) router.go(Routes.initial);
    return true;
  }

  Future<bool> _deleteTag(BuildContext context, WidgetRef ref, Tag tag) async {
    final t = AppLocalizations.of(context);
    if (!await confirm(context, message: t.tagDeleteConfirm(tag.name), confirmLabel: t.actionDelete) || !context.mounted) return false;
    final router = GoRouter.of(context);
    await ref.read(repositoryProvider).deleteTag(tag.id);
    if (current == TagScope(tag.id)) router.go(Routes.initial);
    return true;
  }

  Future<void> _archivedListMenu(BuildContext context, WidgetRef ref, TaskList l, Offset position) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(repositoryProvider);
    // An archived list's menu: Editar · Desarquivar · Duplicar · Deletar.
    final choice = await _showMenuAt<String>(context, position, [
      ('edit', t.actionEdit),
      ('unarchive', t.actionUnarchive),
      ('duplicate', t.actionDuplicate),
      ('delete', t.actionDelete),
    ]);
    if (!context.mounted) return;
    switch (choice) {
      case 'edit':
        await editListWithDialog(context, ref, l);
      case 'unarchive':
        await repo.archiveList(l.id, archived: false);
      case 'duplicate':
        final mode = await _pickCopyMode(context);
        if (mode != null) await repo.duplicateList(l.id, copySuffix: t.copySuffix, mode: mode);
      case 'delete':
        await deleteListAsking(context, ref, l);
    }
  }

  /// An area's ⋯: Adicionar lista · Editar · Fixar · Deletar (its lists stay, with "Desfazer").
  Future<void> _folderMenu(BuildContext context, WidgetRef ref, Folder f, Offset position) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(repositoryProvider);
    final choice = await _showMenuAt<String>(context, position, [
      ('add', t.actionAddList),
      ('edit', t.actionEdit),
      ('pin', f.pinnedAt == null ? t.menuPin : t.menuUnpin),
      ('delete', t.actionDelete),
    ]);
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    void leave() {
      if (current == FolderScope(f.id)) router.go(Routes.initial);
    }

    switch (choice) {
      case 'add':
        await _addList(context, ref, folderId: f.id);
      case 'edit':
        await editFolderWithDialog(context, ref, f, onDeleted: leave);
      case 'pin':
        await repo.pinFolder(f.id, pinned: f.pinnedAt == null);
      case 'delete':
        if (await deleteFolderWithUndo(context, ref, f)) leave();
    }
  }

  Future<void> _filterMenu(BuildContext context, WidgetRef ref, TaskFilter f, Offset position) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(repositoryProvider);
    final choice = await _showMenuAt<String>(context, position, [
      ('edit', t.actionEdit),
      ('pin', f.pinnedAt == null ? t.menuPin : t.menuUnpin),
      ('delete', t.actionDelete),
    ]);
    if (!context.mounted) return;
    switch (choice) {
      case 'edit':
        final form = await showFilterDialog(context, editing: f, onDelete: () => _deleteFilter(context, ref, f));
        if (form != null) await repo.updateFilter(f.id, name: form.name, rule: form.rule);
      case 'pin':
        await repo.pinFilter(f.id, pinned: f.pinnedAt == null);
      case 'delete':
        await _deleteFilter(context, ref, f);
    }
  }

  Future<void> _tagMenu(BuildContext context, WidgetRef ref, Tag tag, Offset position) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(repositoryProvider);
    final choice = await _showMenuAt<String>(context, position, [
      ('edit', t.actionEdit),
      ('pin', tag.pinnedAt == null ? t.menuPin : t.menuUnpin),
      if (tag.parentId == null) ('subtag', t.tagAddSubtag),
      ('merge', t.tagMerge),
      ('delete', t.actionDelete),
    ]);
    if (!context.mounted) return;
    switch (choice) {
      case 'edit':
        final form = await showTagDialog(context, editing: tag, onDelete: () => _deleteTag(context, ref, tag));
        if (form != null && context.mounted) {
          await guarded(context, () => repo.editTag(tag.id, name: form.name, color: form.color, parentId: form.parentId));
        }
      case 'pin':
        await repo.pinTag(tag.id, pinned: tag.pinnedAt == null);
      case 'subtag':
        await _addTag(context, ref, parentId: tag.id);
      case 'merge':
        final others = (ref.read(snapshotProvider).value?.activeTags ?? const <Tag>[]).where((o) => o.id != tag.id).toList();
        // "Mesclar Tags": the explanation, a tag chooser and "Confirmar".
        final target = await showDialog<String>(
          context: context,
          builder: (context) {
            String? chosen = others.firstOrNull?.id;
            return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: Text(t.tagMergeTitle, style: const TextStyle(fontSize: 15)),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(t.tagMergeExplain(tag.name)),
                      const SizedBox(height: 12),
                      DropdownButton<String>(
                        value: chosen,
                        isExpanded: true,
                        items: [for (final o in others) DropdownMenuItem(value: o.id, child: Text(o.name))],
                        onChanged: (v) => setState(() => chosen = v),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
                  FilledButton(onPressed: chosen == null ? null : () => Navigator.pop(context, chosen), child: Text(t.actionConfirm)),
                ],
              ),
            );
          },
        );
        if (target != null) await repo.mergeTags(tag.id, target);
      case 'delete':
        await _deleteTag(context, ref, tag);
    }
  }
}

Future<T?> _showMenuAt<T>(BuildContext context, Offset position, List<(T, String)> items) => showMenu<T>(
  context: context,
  position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
  items: [for (final i in items) PopupMenuItem<T>(value: i.$1, height: 36, child: Text(i.$2))],
);

/// Calendar-like icon with a number (Today shows the current day, like TickTick).
class _DayIcon extends StatelessWidget {
  const _DayIcon({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? context.tt.textSecondary;
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$day',
        style: TextStyle(fontSize: 8.5, height: 1, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _SectionHeader extends StatefulWidget {
  const _SectionHeader({required this.label, this.onAdd, this.onAddFolder});

  final String label;
  final VoidCallback? onAdd;

  /// "Nova área", beside the "+" of the lists.
  final VoidCallback? onAddFolder;

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: SizedBox(
        height: TtSizes.sidebarHeaderHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w700, color: tt.textFaint),
                ),
              ),
              if (widget.onAddFolder != null && (_hover || Theme.of(context).platform == TargetPlatform.android))
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Tooltip(
                    message: AppLocalizations.of(context).folderNew,
                    child: InkWell(
                      onTap: widget.onAddFolder,
                      child: Icon(Icons.create_new_folder_outlined, size: 16, color: tt.textSecondary),
                    ),
                  ),
                ),
              if (widget.onAdd != null && (_hover || Theme.of(context).platform == TargetPlatform.android))
                InkWell(
                  onTap: widget.onAdd,
                  child: Icon(Icons.add, size: 16, color: tt.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpBox extends StatelessWidget {
  const _HelpBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: tt.hover, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(fontSize: TtText.small, height: 16 / 12, color: tt.textTertiary),
      ),
    );
  }
}

/// One sidebar row: icon, name, optional color dot and count; right click / long press opens [onMenu],
/// and so does its ⋯ (in place of the count under the mouse; always there on a phone).
class _SidebarItem extends ConsumerStatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
    this.color,
    this.selected = false,
    this.indent = 0,
    this.onMenu,
    this.acceptsTaskDrop = false,
    this.onTaskDropped,
    this.expanded,
    this.onToggle,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final int? count;
  final Color? color;
  final bool selected;
  final double indent;
  final void Function(Offset globalPosition)? onMenu;
  final bool acceptsTaskDrop;
  final void Function(String taskId)? onTaskDropped;

  /// A list with sublists: the arrow before the icon shows whether they are unfolded, and [onToggle]
  /// folds them. Null for an item without sublists.
  final bool? expanded;
  final VoidCallback? onToggle;

  @override
  ConsumerState<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends ConsumerState<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final menu = widget.onMenu;
    final showMenuButton = menu != null && (_hover || narrow);
    Widget item(bool highlighted) => GestureDetector(
      onSecondaryTapDown: widget.onMenu == null ? null : (d) => widget.onMenu!(d.globalPosition),
      onLongPressStart: widget.onMenu == null ? null : (d) => widget.onMenu!(d.globalPosition),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: TtSizes.sidebarItemHeight,
            // The arrow takes room from the indent, so the icons stay in line.
            padding: EdgeInsets.only(left: widget.expanded == null ? 12 + widget.indent : (widget.indent - 4).clamp(0, double.infinity), right: 12),
            decoration: BoxDecoration(
              color: highlighted ? tt.primary.withValues(alpha: 0.2) : (widget.selected ? tt.selected : (_hover ? tt.hover : null)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                if (widget.expanded case final expanded?)
                  Tooltip(
                    message: expanded ? AppLocalizations.of(context).sublistsFold : AppLocalizations.of(context).sublistsUnfold,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onToggle,
                      child: SizedBox(
                        width: 16,
                        height: 24,
                        child: Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 16, color: tt.textTertiary),
                      ),
                    ),
                  ),
                SizedBox(
                  width: 18,
                  child: IconTheme.merge(
                    data: IconThemeData(size: 18, color: tt.textSecondary),
                    child: Center(child: widget.icon),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: TtText.body, height: 20 / 14, color: tt.text),
                  ),
                ),
                if (widget.color != null)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                  ),
                if (widget.count != null &&
                    widget.count! > 0 &&
                    !(showMenuButton && !narrow) &&
                    ref.watch(preferencesProvider).value?.sidebarCount != SidebarCount.none)
                  Text(
                    '${widget.count}',
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                if (showMenuButton)
                  Tooltip(
                    message: AppLocalizations.of(context).menuMore,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTapUp: (d) => menu(d.globalPosition),
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 2, 0, 2),
                        child: Icon(Icons.more_horiz, size: 18, color: tt.textTertiary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!widget.acceptsTaskDrop || widget.onTaskDropped == null) return item(false);
    return DragTarget<String>(
      onAcceptWithDetails: (d) => widget.onTaskDropped!(d.data),
      builder: (context, candidates, _) => item(candidates.isNotEmpty),
    );
  }
}

/// An area ("Área"): its emoji or folder icon, its color dot, and its lists (already laid out, with
/// their sublists) when unfolded.
class _FolderItem extends StatelessWidget {
  const _FolderItem({
    required this.folder,
    required this.lists,
    required this.count,
    required this.current,
    required this.onOpen,
    required this.onToggle,
    required this.onMenu,
  });

  final Folder folder;
  final List<Widget> lists;
  final int? count;
  final Scope? current;
  final void Function(Scope) onOpen;
  final VoidCallback onToggle;
  final void Function(Offset) onMenu;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _SidebarItem(
        icon: GestureDetector(
          onTap: () => unawaited(Future.sync(onToggle)),
          child: folderIcon(folder, open: !folder.isCollapsed),
        ),
        label: folder.name,
        color: parseHexColor(folder.color),
        count: count,
        selected: current == FolderScope(folder.id),
        onTap: () {
          onToggle();
          onOpen(FolderScope(folder.id));
        },
        onMenu: onMenu,
      ),
      if (!folder.isCollapsed) ...lists,
    ],
  );
}

/// Where a dragged sidebar item lands on another: before it, after it, or inside it (a list onto the
/// middle of a list becomes its sublist).
enum _Drop { before, inside, after }

/// A list or folder being dragged in the sidebar.
class _SidebarDrag {
  const _SidebarDrag(this.id, {this.isFolder = false});

  final String id;
  final bool isFolder;

  @override
  bool operator ==(Object other) => other is _SidebarDrag && other.id == id && other.isFolder == isFolder;

  @override
  int get hashCode => Object.hash(id, isFolder);
}

/// Lets a sidebar list or folder be dragged to another place (desktop; on touch screens a long press
/// opens the menu). A drop on the upper half puts the item before this one, on the lower half after;
/// with [acceptsInside] (a list), a list dropped on the middle third goes inside it.
class _Reorderable extends StatefulWidget {
  const _Reorderable({required this.item, required this.label, required this.onDrop, required this.child, this.acceptsInside = false});

  final _SidebarDrag item;
  final String label;
  final Future<void> Function(_SidebarDrag dragged, _Drop where) onDrop;
  final Widget child;
  final bool acceptsInside;

  @override
  State<_Reorderable> createState() => _ReorderableState();
}

class _ReorderableState extends State<_Reorderable> {
  /// Where a hovering item would go; null when nothing hovers.
  _Drop? _where;

  _Drop _dropAt(Offset global, _SidebarDrag dragged) {
    final box = context.findRenderObject()! as RenderBox;
    final y = box.globalToLocal(global).dy / box.size.height;
    if (widget.acceptsInside && !dragged.isFolder) return y < 1 / 3 ? _Drop.before : (y > 2 / 3 ? _Drop.after : _Drop.inside);
    return y > 0.5 ? _Drop.after : _Drop.before;
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) return widget.child;
    final tt = context.tt;
    return DragTarget<_SidebarDrag>(
      onWillAcceptWithDetails: (d) => d.data != widget.item,
      onMove: (d) {
        final where = _dropAt(d.offset, d.data);
        if (where != _where) setState(() => _where = where);
      },
      onLeave: (_) => setState(() => _where = null),
      onAcceptWithDetails: (d) {
        final where = _dropAt(d.offset, d.data);
        setState(() => _where = null);
        unawaited(widget.onDrop(d.data, where));
      },
      builder: (context, candidates, _) => Stack(
        children: [
          Draggable<_SidebarDrag>(
            data: widget.item,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
                child: Text(widget.label, style: TextStyle(color: tt.text)),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.4, child: widget.child),
            child: widget.child,
          ),
          // Inside: the whole row outlined; before or after: a line on that edge.
          if (candidates.isNotEmpty && _where == _Drop.inside)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: tt.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else if (candidates.isNotEmpty && _where != null)
            Positioned(
              left: 8,
              right: 8,
              top: _where == _Drop.after ? null : 0,
              bottom: _where == _Drop.after ? 0 : null,
              height: 2,
              child: ColoredBox(color: tt.primary),
            ),
        ],
      ),
    );
  }
}

/// Pinned lists as small blocks above the smart lists.
/// A pinned list, folder, tag or filter.
class _Pinned {
  const _Pinned(this.scope, this.icon, this.name);

  final Scope scope;
  final Widget icon;
  final String name;
}

class _PinnedLists extends StatelessWidget {
  const _PinnedLists({required this.items, required this.current, required this.onTap});

  final List<_Pinned> items;
  final Scope? current;
  final void Function(Scope) onTap;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final l in items)
            InkWell(
              onTap: () => onTap(l.scope),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(color: current == l.scope ? tt.selected : tt.hover, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    IconTheme.merge(
                      data: IconThemeData(size: 18, color: tt.textSecondary),
                      child: l.icon,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: tt.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniCalendar extends ConsumerStatefulWidget {
  const _MiniCalendar({this.onNavigate});

  final VoidCallback? onNavigate;

  @override
  ConsumerState<_MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends ConsumerState<_MiniCalendar> {
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final month = _month ?? DateTime(today.year, today.month);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: MonthCalendar(
        month: month,
        today: today,
        isSelected: (day) => day == today,
        occurrences: const {},
        title: DateLabels(t).monthTitle(month),
        onPrevious: () => setState(() => _month = DateTime(month.year, month.month - 1)),
        onNext: () => setState(() => _month = DateTime(month.year, month.month + 1)),
        onToday: () => setState(() => _month = null),
        onPick: (day) {
          ref.read(calendarAnchorProvider.notifier).set(day);
          context.go(Routes.calendarOf(CalendarMode.day));
          widget.onNavigate?.call();
        },
      ),
    );
  }
}

/// "Duplicar lista" asks what to copy.
Future<ListCopyMode?> _pickCopyMode(BuildContext context) {
  final t = AppLocalizations.of(context);
  return showDialog<ListCopyMode>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(t.actionDuplicate, style: const TextStyle(fontSize: 15)),
      children: [
        for (final (mode, label) in [
          (ListCopyMode.openOnly, t.copyOpenOnly),
          (ListCopyMode.keepStatus, t.copyKeepStatus),
          (ListCopyMode.allReopened, t.copyAllReopened),
        ])
          SimpleDialogOption(onPressed: () => Navigator.pop(context, mode), child: Text(label)),
      ],
    ),
  );
}
