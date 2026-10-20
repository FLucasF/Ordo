import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/clock.dart';
import '../data/attachment_store.dart';
import '../data/db/database.dart';
import '../data/finance_repository.dart';
import '../data/preferences_repository.dart';
import '../data/repository.dart';
import '../domain/enums.dart';
import '../domain/finance/finance.dart';
import '../domain/snapshot.dart';
import '../domain/views.dart';
import 'routes.dart';
import '../data/diet_repository.dart';
import '../domain/diet/diet.dart';
import '../data/journal_repository.dart';

/// Overridden in `main` with the opened database (and in tests with an in-memory one).
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('databaseProvider must be overridden'));

final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Attachment files; the app points it at its data folder (main.dart), tests at a temporary one.
final attachmentStoreProvider = Provider<AttachmentStore>(
  (ref) => AttachmentStore(Directory(p.join(Directory.systemTemp.path, 'tarefas_attachments'))),
);

final repositoryProvider = Provider<Repository>((ref) => Repository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)));

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final snapshotProvider = StreamProvider<Snapshot>((ref) => ref.watch(repositoryProvider).watchSnapshot());

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

/// Finanças, apart from the tasks' snapshot.
final financeProvider = StreamProvider<FinanceSnapshot>((ref) => ref.watch(financeRepositoryProvider).watch());

final dietRepositoryProvider = Provider<DietRepository>((ref) => DietRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)));

/// The user's foods and the diary (Dieta).
final dietProvider = StreamProvider<DietSnapshot>((ref) => ref.watch(dietRepositoryProvider).watch());

/// The TACO table bundled with the app (assets/taco.json), read once.
// Read as bytes: loadString's shared cache (and its isolate) isn't needed for 84 KB read once.
final tacoProvider = FutureProvider<List<Food>>(
  (ref) async => parseTaco(utf8.decode((await rootBundle.load('assets/taco.json')).buffer.asUint8List())),
);

final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => JournalRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

/// The journal's entries (Diário).
final journalProvider = StreamProvider<JournalSnapshot>((ref) => ref.watch(journalRepositoryProvider).watch());

/// Dieta's daily calorie target as Diário reads it (null = none set).
final journalCalorieTargetProvider = StreamProvider<double?>((ref) => ref.watch(journalRepositoryProvider).watchCalorieTarget());

final preferencesProvider = StreamProvider<Preferences>((ref) => ref.watch(preferencesRepositoryProvider).watch());

/// Current time, refreshed every minute so "today" rolls over at midnight.
final nowProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<DateTime>();
  controller.add(clock.now());
  final timer = Timer.periodic(const Duration(minutes: 1), (_) => controller.add(clock.now()));
  ref.onDispose(() {
    timer.cancel();
    unawaited(controller.close());
  });
  return controller.stream;
});

DateTime _now(Ref ref) => ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();

final countsProvider = Provider<Counts>((ref) {
  final snapshot = ref.watch(snapshotProvider).value ?? Snapshot.empty();
  final prefs = ref.watch(preferencesProvider).value;
  return Counts(snapshot, _now(ref), includeNotes: prefs?.sidebarCount != SidebarCount.hideNotes);
});

/// A set of ids toggled by the UI (collapsed subtasks, groups, expanded "Ver mais").
class IdSet extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) => state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  void add(String id) => state = {...state, id};
}

/// Parent tasks whose subtasks are collapsed.
final collapsedTasksProvider = NotifierProvider<IdSet, Set<String>>(IdSet.new);

/// Multi-selection of tasks (Ctrl+click and Shift+click).
class TaskSelection extends Notifier<Set<String>> {
  String? _anchor;

  @override
  Set<String> build() => const {};

  /// Ctrl+click: adds or removes [id]; the task open in the detail ([current]) joins the selection.
  void toggle(String id, {String? current}) {
    final next = {...state, if (state.isEmpty && current != null && current != id) current};
    state = next.contains(id) ? (next..remove(id)) : {...next, id};
    _anchor = id;
  }

  /// Shift+click: everything between the anchor (or [current]) and [id], in the visible [order].
  void range(String id, List<String> order, {String? current}) {
    final anchor = _anchor ?? current ?? id;
    final a = order.indexOf(anchor), b = order.indexOf(id);
    if (a < 0 || b < 0) return toggle(id, current: current);
    state = {...state, ...order.sublist(a < b ? a : b, (a < b ? b : a) + 1)};
  }

  void selectAll(Iterable<String> ids) => state = {...state, ...ids};

  void deselect(Iterable<String> ids) => state = {...state}..removeAll(ids);

  void clear() {
    _anchor = null;
    if (state.isNotEmpty) state = const {};
  }
}

final taskSelectionProvider = NotifierProvider<TaskSelection, Set<String>>(TaskSelection.new);

/// Collapsed group headers, keyed by `scope|groupKey`.
final collapsedGroupsProvider = NotifierProvider<IdSet, Set<String>>(IdSet.new);

/// Closed groups expanded past 5 rows ("Ver mais"), keyed by `scope|groupKey`.
final expandedClosedGroupsProvider = NotifierProvider<IdSet, Set<String>>(IdSet.new);

/// Grouping/sorting of smart lists, tags and folders (lists keep theirs in the database).
class ScopeOptions extends Notifier<Map<Scope, ViewOptions>> {
  @override
  Map<Scope, ViewOptions> build() => const {};

  void set(Scope scope, ViewOptions options) => state = {...state, scope: options};
}

final scopeOptionsProvider = NotifierProvider<ScopeOptions, Map<Scope, ViewOptions>>(ScopeOptions.new);

ViewOptions optionsFor(Ref ref, Snapshot snapshot, Scope scope) {
  if (scope is ListScope) {
    final list = snapshot.listById[scope.listId];
    if (list != null) {
      return ViewOptions(grouping: list.groupBy, sorting: list.sortBy, showCompleted: list.showCompleted, showDetails: list.showDetails);
    }
  }
  // Changed in this run, or saved before (Hoje, filters, tags keep theirs between runs).
  return ref.watch(scopeOptionsProvider)[scope] ??
      ref.watch(preferencesProvider).value?.scopeViewOptions[Routes.of(scope)] ??
      (scope is ListScope || scope is FolderScope ? const ViewOptions() : smartListDefaultOptions);
}

/// Date and list filters of Concluído and Não será feito, per smart list.
class ClosedFilters extends Notifier<Map<SmartList, ClosedFilter>> {
  @override
  Map<SmartList, ClosedFilter> build() => const {};

  void set(SmartList list, ClosedFilter filter) => state = {...state, list: filter};
}

final closedFiltersProvider = NotifierProvider<ClosedFilters, Map<SmartList, ClosedFilter>>(ClosedFilters.new);

final viewProvider = Provider.family<ViewContent?, Scope>((ref, scope) {
  final snapshot = ref.watch(snapshotProvider).value;
  if (snapshot == null) return null;
  final overdueLast = !(ref.watch(preferencesProvider).value?.taskDefaults.overdueAtTop ?? true);
  return buildView(
    snapshot,
    scope,
    _now(ref),
    options: optionsFor(ref, snapshot, scope),
    collapsed: ref.watch(collapsedTasksProvider),
    overdueLast: overdueLast,
    closedFilter: scope is SmartScope ? ref.watch(closedFiltersProvider)[scope.smartList] ?? const ClosedFilter() : const ClosedFilter(),
    withSublists: scope is ListScope && (ref.watch(preferencesProvider).value?.listsWithSublists.contains(scope.listId) ?? false),
  );
});

/// Current view options of a scope (for the sort/group menu).
/// Lista or Kanban for scopes that are not lists (lists keep it in the database).
class ScopeViewModes extends Notifier<Map<Scope, ViewMode>> {
  @override
  Map<Scope, ViewMode> build() => const {};

  void set(Scope scope, ViewMode mode) => state = {...state, scope: mode};
}

final scopeViewModesProvider = NotifierProvider<ScopeViewModes, Map<Scope, ViewMode>>(ScopeViewModes.new);

/// "Visualização" of a scope: Lista or Kanban.
final viewModeProvider = Provider.family<ViewMode, Scope>((ref, scope) {
  if (scope is ListScope) return ref.watch(snapshotProvider).value?.listById[scope.listId]?.viewMode ?? ViewMode.list;
  return ref.watch(scopeViewModesProvider)[scope] ?? ViewMode.list;
});

Future<void> setViewMode(WidgetRef ref, Scope scope, ViewMode mode) async {
  if (scope is ListScope) {
    await ref.read(repositoryProvider).setListViewOptions(scope.listId, viewMode: mode);
  } else {
    ref.read(scopeViewModesProvider.notifier).set(scope, mode);
  }
}

final viewOptionsProvider = Provider.family<ViewOptions, Scope>((ref, scope) {
  final snapshot = ref.watch(snapshotProvider).value ?? Snapshot.empty();
  return optionsFor(ref, snapshot, scope);
});
