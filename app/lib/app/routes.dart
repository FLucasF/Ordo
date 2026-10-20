import '../core/ids.dart';
import '../domain/calendar.dart';
import '../domain/views.dart';

/// Routes mirror the TickTick webapp's hash routes:
/// `/p/{listId}/tasks/{taskId}`, `/q/{smart}/tasks`, `/t/{tagId}/tasks`, `/g/{folderId}/tasks`.
abstract final class Routes {
  static const initial = '/q/today/tasks';

  /// Search page (`#s` in TickTick): `/s?q=term&task=id`.
  static const search = '/s';

  /// The last place outside the search page: Esc and ✕ go back there.
  static String backFromSearch = initial;

  /// Whether [location] is the search page (not "/statistics", which also starts with "/s").
  static bool isSearch(String location) => location == search || location.startsWith('$search?') || location.startsWith('$search/');

  /// Countdown module (`#countdown`).
  static const countdown = '/countdown';

  /// Focus module (`#focus`).
  static const focus = '/focus';

  /// Habits module (`#q/all/habit`).
  static const habit = '/habit';

  /// Calendar (`#c/all/calendar/{mode}`); without a mode, the last one used.
  static const calendar = '/calendar';

  static String calendarOf(CalendarMode mode) => '$calendar/${mode.route}';

  /// Statistics (`#statistics/{tab}`): overview, task, pomo.
  static const statistics = '/statistics';

  static String statisticsOf(String tab) => '$statistics/$tab';

  /// Finanças (`/finance/{tab}`): entries, categories…; without a tab, the entries.
  static const finance = '/finance';

  static String financeOf(String tab) => '$finance/$tab';

  /// Dieta (`/diet/{tab}`): the diary of the day's meals, or the foods.
  static const diet = '/diet';

  static String dietOf(String tab) => '$diet/$tab';

  /// Diário (`/journal/{tab}`): the day's entry, the timeline or the calendar of moods.
  static const journal = '/journal';

  static String journalOf(String tab) => '$journal/$tab';

  /// Eisenhower Matrix (`#m/all/matrix`).
  static const matrix = '/matrix';

  static String of(Scope scope, {String? taskId}) {
    final base = switch (scope) {
      ListScope(:final listId) => '/p/$listId/tasks',
      FolderScope(:final folderId) => '/g/$folderId/tasks',
      TagScope(:final tagId) => '/t/$tagId/tasks',
      SmartScope(:final smartList) => '/q/${smartList.route}/tasks',
      FilterScope(:final filterId) => '/f/$filterId/tasks',
    };
    return taskId == null ? base : '$base/$taskId';
  }

  /// Scope of a route's `kind` and `id` path parameters; falls back to the Inbox.
  static Scope scopeOf(String kind, String id) => switch (kind) {
    'p' => ListScope(id),
    'g' => FolderScope(id),
    't' => TagScope(id),
    'q' => SmartScope(SmartList.fromRoute(id) ?? SmartList.today),
    'f' => FilterScope(id),
    _ => const ListScope(inboxListId),
  };
}
