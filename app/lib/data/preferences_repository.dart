import 'dart:ui' show Locale;
import 'dart:convert';

import '../core/clock.dart';
import '../domain/calendar.dart';
import '../domain/color_labels.dart';
import '../domain/diet/targets.dart';
import '../domain/focus.dart';
import '../domain/matrix.dart';
import '../domain/reminder_plan.dart';
import '../domain/subscriptions.dart';
import '../domain/summary.dart';
import '../domain/task_defaults.dart';
import '../domain/enums.dart' show Grouping, Sorting;
import '../domain/views.dart';
import 'db/database.dart';

/// Visibility of a smart list in the sidebar (Settings → Smart List).
enum SmartListVisibility {
  show('show'),
  hide('hide'),
  showIfNotEmpty('showIfNotEmpty');

  const SmartListVisibility(this.code);
  final String code;

  static SmartListVisibility? fromCode(Object? code) => values.where((v) => v.code == code).firstOrNull;
}

/// TickTick's defaults.
const defaultSmartListVisibility = {
  SmartList.all: SmartListVisibility.hide,
  SmartList.today: SmartListVisibility.show,
  SmartList.tomorrow: SmartListVisibility.hide,
  SmartList.next7Days: SmartListVisibility.show,
  SmartList.summary: SmartListVisibility.hide,
  SmartList.completed: SmartListVisibility.show,
  SmartList.wontDo: SmartListVisibility.showIfNotEmpty,
  SmartList.trash: SmartListVisibility.show,
};

/// Modules that Settings → Funcionalidades turns on and off.
enum AppFeature {
  calendar('calendar'),
  matrix('matrix'),
  habit('habit'),
  focus('focus'),
  countdown('countdown'),
  finance('finance'),
  diet('diet');

  const AppFeature(this.code);
  final String code;
}

/// "Contagem na barra lateral" (Configurações → Aparência → Exibição).
enum SidebarCount {
  all('all'),
  hideNotes('hideNotes'),
  none('none');

  const SidebarCount(this.code);
  final String code;

  static SidebarCount? fromCode(Object? code) => values.where((v) => v.code == code).firstOrNull;
}

/// "Série de Cores": the primary color of the theme.
enum ColorSeries {
  standard('standard'),
  sky('sky'),
  turquoise('turquoise'),
  teal('teal'),
  reed('reed'),
  yellow('yellow'),
  pinkPear('pinkPear'),
  lilac('lilac'),
  ebony('ebony'),
  navy('navy'),
  grey('grey');

  const ColorSeries(this.code);
  final String code;

  static ColorSeries? fromCode(Object? code) => values.where((v) => v.code == code).firstOrNull;
}

/// The app's language: Portuguese (Brazil) or Latin.
enum AppLanguage {
  portuguese('pt', Locale('pt', 'BR')),
  latin('la', Locale('la'));

  const AppLanguage(this.code, this.locale);
  final String code;
  final Locale locale;

  static AppLanguage? fromCode(Object? code) => values.where((v) => v.code == code).firstOrNull;
}

enum ThemeChoice {
  light('light'),
  dark('dark'),
  system('system');

  const ThemeChoice(this.code);
  final String code;

  static ThemeChoice? fromCode(Object? code) => values.where((v) => v.code == code).firstOrNull;
}

/// "Mostrar Data por" (Visualizar Opções): the date, or a countdown ("em 3 dias").
enum DateDisplay {
  date('date'),
  countdown('countdown');

  const DateDisplay(this.code);
  final String code;

  static DateDisplay? fromCode(Object? code) => values.where((v) => v.code == code).firstOrNull;
}

/// Typed settings over the key/value `preferences` table. Values are JSON; a missing or invalid value
/// falls back to the default, so a bad row can never crash the app.
class Preferences {
  const Preferences({
    required this.smartListVisibility,
    required this.theme,
    required this.inboxVisibility,
    this.dateDisplay = DateDisplay.date,
    this.dailyAlert,
    this.constantReminder = false,
    this.focus = const FocusSettings(),
    this.habitsInToday = true,
    this.habitsSortByStatus = false,
    this.matrixRules = QuadrantRule.defaults,
    this.matrixHideCompleted = true,
    this.calendarMode = CalendarMode.month,
    this.calendarOptions = const CalendarOptions(),
    this.disabledFeatures = const {},
    this.tagsVisibility = SmartListVisibility.show,
    this.filtersVisibility = SmartListVisibility.show,
    this.colorSeries = ColorSeries.standard,
    this.customAccent,
    this.sidebarCount = SidebarCount.all,
    this.strikeCompleted = false,
    this.taskDefaults = const TaskDefaults(),
    this.firstWeekday = DateTime.sunday,
    this.use24h = true,
    this.weekNumbers = false,
    this.timeZonePicker = false,
    this.dateOrder = DateOrder.dayMonthYear,
    this.miniCalendar = false,
    this.sidebarWidth,
    this.detailWidth,
    this.detailPopup = false,
    this.addFieldDetailed = false,
    this.cardStyle = false,
    this.summaryConfig = const SummaryConfig(),
    this.summaryTemplates = const [],
    this.focusTimers = const [],
    this.subscriptions = const [],
    this.colorLabels = const [],
    this.focusRun,
    this.reminderSound = ReminderSound.alarmClock,
    this.closeToTray = true,
    this.launchAtStartup = false,
    this.customShortcuts = const {},
    this.scopeViewOptions = const {},
    this.showListColor = true,
    this.language = AppLanguage.portuguese,
    this.listsWithSublists = const {},
    this.collapsedLists = const {},
    this.dietTargets = const DietTargets(),
  });

  /// Lists whose view shows their sublists' tasks too ("Incluir sublistas").
  final Set<String> listsWithSublists;

  /// Lists whose sublists are folded away in the sidebar.
  final Set<String> collapsedLists;

  final Map<SmartList, SmartListVisibility> smartListVisibility;

  /// The Inbox also has a visibility option in TickTick's settings.
  final SmartListVisibility inboxVisibility;
  final ThemeChoice theme;
  final DateDisplay dateDisplay;

  /// "Notificações diárias": minutes after midnight of the daily alert, null = off.
  final int? dailyAlert;

  /// "Lembrete Constante Global": reminders stay until the user acts.
  final bool constantReminder;

  /// "Configurações de foco".
  final FocusSettings focus;

  /// Habits settings: show them in Hoje / Próximos 7 dias, unchecked ones first.
  final bool habitsInToday;
  final bool habitsSortByStatus;

  /// The four quadrants of the Eisenhower Matrix and "Esconder concluídas".
  final List<QuadrantRule> matrixRules;
  final bool matrixHideCompleted;

  /// Last calendar mode and the calendar's "Opções de visualização".
  final CalendarMode calendarMode;
  final CalendarOptions calendarOptions;

  /// Modules turned off in Settings → Funcionalidades; their icons leave the bar.
  final Set<AppFeature> disabledFeatures;

  bool has(AppFeature f) => !disabledFeatures.contains(f);

  /// The "Etiquetas" and "Filtros" sections of the sidebar (Settings → Lista inteligente).
  final SmartListVisibility tagsVisibility;
  final SmartListVisibility filtersVisibility;

  /// Settings → Aparência.
  final ColorSeries colorSeries;

  /// A color picked in the palette (`#RRGGBB`) instead of a series; null = the series.
  final String? customAccent;
  final SidebarCount sidebarCount;

  /// "Estilo de Tarefa Concluída": Rasurado.
  final bool strikeCompleted;

  /// Settings → Mais configurações.
  final TaskDefaults taskDefaults;

  /// Settings → Data e hora: first day of the week, 24h / 12h, week numbers.
  final int firstWeekday;
  final bool use24h;
  final bool weekNumbers;

  /// "Fuso horário": the date picker offers a fixed zone or "Tempo flutuante".
  final bool timeZonePicker;

  /// "Formato de data".
  final DateOrder dateOrder;

  /// "Mini Calendário": a month at the foot of the sidebar.
  final bool miniCalendar;

  /// Widths the columns were dragged to ("Três colunas redimensionáveis"); null = default.
  final double? sidebarWidth;
  final double? detailWidth;

  /// "Layout de detalhes da tarefa": Janela pop-up instead of the side panel.
  final bool detailPopup;

  /// "Estilo da Caixa de Entrada": Detalhado (a bigger box with icons and "Adicionar") or Simples.
  final bool addFieldDetailed;

  /// "Estilo da Interface": Cartão (the app is a rounded card over the theme's color) or Plano.
  final bool cardStyle;

  /// The "Resumo" last used and its saved "Modelos".
  final SummaryConfig summaryConfig;
  final List<SummaryTemplate> summaryTemplates;

  /// "Timers salvos" of the focus.
  final List<FocusTimer> focusTimers;

  /// "Calendários assinados".
  final List<CalendarSubscription> subscriptions;

  /// Named task colors (Google Calendar's event labels).
  final List<ColorLabel> colorLabels;

  /// The focus session running when the app was closed ([FocusState.toJson]).
  final Map<String, Object?>? focusRun;

  /// "Som do lembrete": the "Despertador" by default.
  final ReminderSound reminderSound;

  /// Windows: closing the window leaves the app in the tray (reminders and focus keep running).
  final bool closeToTray;

  /// Windows: "Iniciar com o Windows", hidden in the tray.
  final bool launchAtStartup;

  /// Shortcuts changed in Settings → Atalhos: action name → its keys (empty = none).
  final Map<String, List<String>> customShortcuts;

  /// Grouping and sorting of the views that aren't lists (Hoje, filters, tags…), by their route; a
  /// list keeps its own in its row.
  final Map<String, ViewOptions> scopeViewOptions;

  /// "Cor da Lista": the list's color as a stripe on task rows outside the list.
  final bool showListColor;

  /// "Idioma".
  final AppLanguage language;

  /// Dieta → ⚙ Metas: the daily calories and macros.
  final DietTargets dietTargets;

  static const defaults = Preferences(
    smartListVisibility: defaultSmartListVisibility,
    theme: ThemeChoice.dark,
    inboxVisibility: SmartListVisibility.show,
  );
}

class PreferencesRepository {
  PreferencesRepository(this._db, {this._clock = const SystemClock()});

  final AppDatabase _db;
  final Clock _clock;

  static String _smartKey(SmartList l) => 'smartList.${l.route}';
  static const _themeKey = 'appearance.theme';
  static const _inboxKey = 'smartList.inbox';
  static const _dateDisplayKey = 'view.dateDisplay';
  static const _dailyAlertKey = 'notifications.dailyAlert';
  static const _constantReminderKey = 'notifications.constantReminder';
  static const _focusKey = 'focus.settings';
  static const _habitsInTodayKey = 'habits.inToday';
  static const _habitsSortKey = 'habits.sortByStatus';
  static const _matrixRulesKey = 'matrix.rules';
  static const _matrixHideCompletedKey = 'matrix.hideCompleted';
  static const _calendarModeKey = 'calendar.mode';
  static const _calendarOptionsKey = 'calendar.options';
  static const _disabledFeaturesKey = 'features.disabled';
  static const _tagsVisibilityKey = 'sidebar.tags';
  static const _filtersVisibilityKey = 'sidebar.filters';
  static const _colorSeriesKey = 'appearance.colorSeries';
  static const _customAccentKey = 'appearance.customAccent';
  static const _sidebarCountKey = 'appearance.sidebarCount';
  static const _strikeCompletedKey = 'appearance.strikeCompleted';
  static const _taskDefaultsKey = 'tasks.defaults';
  static const _firstWeekdayKey = 'datetime.firstWeekday';
  static const _use24hKey = 'datetime.use24h';
  static const _weekNumbersKey = 'datetime.weekNumbers';
  static const _timeZoneKey = 'datetime.timeZone';
  static const _dateOrderKey = 'datetime.dateFormat';
  static const _miniCalendarKey = 'more.miniCalendar';
  static const _sidebarWidthKey = 'layout.sidebarWidth';
  static const _detailWidthKey = 'layout.detailWidth';
  static const _detailPopupKey = 'layout.detailPopup';
  static const _addFieldDetailedKey = 'layout.addFieldDetailed';
  static const _cardStyleKey = 'appearance.cardStyle';
  static const _summaryConfigKey = 'summary.config';
  static const _summaryTemplatesKey = 'summary.templates';
  static const _focusTimersKey = 'focus.timers';
  static const _subscriptionsKey = 'calendars.subscriptions';
  static const _colorLabelsKey = 'calendar.colorLabels';
  static const _focusRunKey = 'focus.run';
  static const _reminderSoundKey = 'notifications.reminderSound';
  static const _closeToTrayKey = 'desktop.closeToTray';
  static const _scopeViewOptionsKey = 'view.scopeOptions';
  static const _launchAtStartupKey = 'desktop.launchAtStartup';
  static const _shortcutsKey = 'shortcuts.custom';
  static const _listColorKey = 'appearance.listColor';
  static const _languageKey = 'appearance.language';
  static const _dietTargetsKey = 'diet.targets';

  Stream<Preferences> watch() => _db.select(_db.preferences).watch().map(_parse);

  Preferences _parse(List<Preference> rows) {
    final raw = {for (final r in rows) r.name: _decode(r.value)};
    return Preferences(
      smartListVisibility: {for (final l in SmartList.values) l: SmartListVisibility.fromCode(raw[_smartKey(l)]) ?? defaultSmartListVisibility[l]!},
      inboxVisibility: SmartListVisibility.fromCode(raw[_inboxKey]) ?? SmartListVisibility.show,
      theme: ThemeChoice.fromCode(raw[_themeKey]) ?? Preferences.defaults.theme,
      language: AppLanguage.fromCode(raw[_languageKey]) ?? AppLanguage.portuguese,
      dateDisplay: DateDisplay.fromCode(raw[_dateDisplayKey]) ?? DateDisplay.date,
      dailyAlert: switch (raw[_dailyAlertKey]) {
        final int minutes when minutes >= 0 && minutes < 24 * 60 => minutes,
        _ => null,
      },
      constantReminder: raw[_constantReminderKey] == true,
      focus: FocusSettings.fromJson(raw[_focusKey]),
      habitsInToday: raw[_habitsInTodayKey] != false,
      habitsSortByStatus: raw[_habitsSortKey] == true,
      matrixRules: [
        for (var i = 0; i < 4; i++)
          QuadrantRule.fromJson(
            raw[_matrixRulesKey] is List<Object?> && (raw[_matrixRulesKey]! as List<Object?>).length == 4
                ? (raw[_matrixRulesKey]! as List<Object?>)[i]
                : null,
            QuadrantRule.defaults[i],
          ),
      ],
      matrixHideCompleted: raw[_matrixHideCompletedKey] != false,
      calendarMode: CalendarMode.fromRoute(raw[_calendarModeKey] is String ? raw[_calendarModeKey]! as String : null),
      calendarOptions: CalendarOptions.fromJson(raw[_calendarOptionsKey]),
      disabledFeatures: {
        if (raw[_disabledFeaturesKey] case final List<Object?> codes)
          for (final c in codes) ?AppFeature.values.where((f) => f.code == c).firstOrNull,
      },
      tagsVisibility: SmartListVisibility.fromCode(raw[_tagsVisibilityKey]) ?? SmartListVisibility.show,
      filtersVisibility: SmartListVisibility.fromCode(raw[_filtersVisibilityKey]) ?? SmartListVisibility.show,
      colorSeries: ColorSeries.fromCode(raw[_colorSeriesKey]) ?? ColorSeries.standard,
      customAccent: raw[_customAccentKey] is String ? raw[_customAccentKey] as String : null,
      sidebarCount: SidebarCount.fromCode(raw[_sidebarCountKey]) ?? SidebarCount.all,
      strikeCompleted: raw[_strikeCompletedKey] == true,
      taskDefaults: TaskDefaults.fromJson(raw[_taskDefaultsKey]),
      // Any day of the week.
      firstWeekday: switch (raw[_firstWeekdayKey]) {
        final int d when d >= DateTime.monday && d <= DateTime.sunday => d,
        _ => DateTime.sunday,
      },
      use24h: raw[_use24hKey] != false,
      weekNumbers: raw[_weekNumbersKey] == true,
      timeZonePicker: raw[_timeZoneKey] == true,
      dateOrder: DateOrder.values.where((o) => o.name == raw[_dateOrderKey]).firstOrNull ?? DateOrder.dayMonthYear,
      miniCalendar: raw[_miniCalendarKey] == true,
      sidebarWidth: raw[_sidebarWidthKey] is num ? (raw[_sidebarWidthKey]! as num).toDouble() : null,
      detailWidth: raw[_detailWidthKey] is num ? (raw[_detailWidthKey]! as num).toDouble() : null,
      detailPopup: raw[_detailPopupKey] == true,
      addFieldDetailed: raw[_addFieldDetailedKey] == true,
      cardStyle: raw[_cardStyleKey] == true,
      summaryConfig: SummaryConfig.fromJson(raw[_summaryConfigKey]),
      summaryTemplates: [
        if (raw[_summaryTemplatesKey] case final List<Object?> items)
          for (final item in items) ?SummaryTemplate.fromJson(item),
      ],
      focusTimers: [
        if (raw[_focusTimersKey] case final List<Object?> items)
          for (final item in items) ?FocusTimer.fromJson(item),
      ],
      subscriptions: [
        if (raw[_subscriptionsKey] case final List<Object?> items)
          for (final item in items) ?CalendarSubscription.fromJson(item),
      ],
      colorLabels: [
        if (raw[_colorLabelsKey] case final List<Object?> items)
          for (final item in items) ?ColorLabel.fromJson(item),
      ],
      focusRun: raw[_focusRunKey] is Map<String, Object?> ? raw[_focusRunKey] as Map<String, Object?> : null,
      reminderSound: ReminderSound.values.where((s) => s.name == raw[_reminderSoundKey]).firstOrNull ?? ReminderSound.alarmClock,
      closeToTray: raw[_closeToTrayKey] != false,
      launchAtStartup: raw[_launchAtStartupKey] == true,
      scopeViewOptions: {
        if (raw[_scopeViewOptionsKey] case final Map<String, Object?> map)
          for (final MapEntry(:key, :value) in map.entries)
            if (value case final Map<String, Object?> o)
              key: ViewOptions(
                grouping: Grouping.values.where((g) => g.name == o['g']).firstOrNull ?? Grouping.date,
                sorting: Sorting.values.where((x) => x.name == o['s']).firstOrNull ?? Sorting.date,
                showCompleted: o['c'] != false,
                descending: o['d'] == true,
                showDetails: o['x'] == true,
              ),
      },
      customShortcuts: {
        if (raw[_shortcutsKey] case final Map<String, Object?> map)
          for (final e in map.entries)
            if (e.value case final List<Object?> keys)
              e.key: [
                for (final k in keys)
                  if (k is String) k,
              ],
      },
      showListColor: raw[_listColorKey] != false,
      listsWithSublists: _idSet(raw[_withSublistsKey]),
      collapsedLists: _idSet(raw[_collapsedListsKey]),
      dietTargets: DietTargets.fromJson(raw[_dietTargetsKey]),
    );
  }

  static const _withSublistsKey = 'view.withSublists';
  static const _collapsedListsKey = 'sidebar.collapsedLists';

  static Set<String> _idSet(Object? raw) => {
    if (raw case final List<Object?> ids)
      for (final id in ids)
        if (id is String) id,
  };

  /// "Incluir sublistas" of a list.
  Future<void> setListWithSublists(Set<String> current, String listId, {required bool enabled}) =>
      _set(_withSublistsKey, [...current.where((id) => id != listId), if (enabled) listId]);

  /// Folds or unfolds a list's sublists in the sidebar.
  Future<void> setListCollapsed(Set<String> current, String listId, {required bool collapsed}) =>
      _set(_collapsedListsKey, [...current.where((id) => id != listId), if (collapsed) listId]);

  static Object? _decode(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }

  Future<void> setSmartListVisibility(SmartList list, SmartListVisibility v) => _set(_smartKey(list), v.code);

  Future<void> setTheme(ThemeChoice theme) => _set(_themeKey, theme.code);

  Future<void> setLanguage(AppLanguage language) => _set(_languageKey, language.code);

  Future<void> setDietTargets(DietTargets targets) => _set(_dietTargetsKey, targets.toJson());

  Future<void> setDateDisplay(DateDisplay display) => _set(_dateDisplayKey, display.code);

  /// [minutes] after midnight, or null to turn the daily alert off.
  Future<void> setDailyAlert(int? minutes) => minutes == null ? _remove(_dailyAlertKey) : _set(_dailyAlertKey, minutes);

  Future<void> setConstantReminder({required bool enabled}) => _set(_constantReminderKey, enabled);

  Future<void> setFocusSettings(FocusSettings settings) => _set(_focusKey, settings.toJson());

  Future<void> setHabitsInToday({required bool enabled}) => _set(_habitsInTodayKey, enabled);

  Future<void> setHabitsSortByStatus({required bool enabled}) => _set(_habitsSortKey, enabled);

  Future<void> setMatrixRules(List<QuadrantRule> rules) => _set(_matrixRulesKey, [for (final r in rules) r.toJson()]);

  Future<void> setMatrixHideCompleted({required bool hide}) => _set(_matrixHideCompletedKey, hide);

  Future<void> setCalendarMode(CalendarMode mode) => _set(_calendarModeKey, mode.route);

  Future<void> setCalendarOptions(CalendarOptions options) => _set(_calendarOptionsKey, options.toJson());

  Future<void> setFeature(Set<AppFeature> disabled, AppFeature f, {required bool enabled}) => _set(_disabledFeaturesKey, [
    for (final d in enabled ? disabled.difference({f}) : {...disabled, f}) d.code,
  ]);

  Future<void> setInboxVisibility(SmartListVisibility v) => _set(_inboxKey, v.code);

  Future<void> setTagsVisibility(SmartListVisibility v) => _set(_tagsVisibilityKey, v.code);

  Future<void> setFiltersVisibility(SmartListVisibility v) => _set(_filtersVisibilityKey, v.code);

  /// A series replaces the custom color.
  Future<void> setColorSeries(ColorSeries c) async {
    await _remove(_customAccentKey);
    await _set(_colorSeriesKey, c.code);
  }

  /// Any color from the palette as the theme's color.
  Future<void> setCustomAccent(String hex) => _set(_customAccentKey, hex);

  Future<void> setSidebarCount(SidebarCount c) => _set(_sidebarCountKey, c.code);

  Future<void> setStrikeCompleted({required bool enabled}) => _set(_strikeCompletedKey, enabled);

  Future<void> setTaskDefaults(TaskDefaults d) => _set(_taskDefaultsKey, d.toJson());

  Future<void> setFirstWeekday(int weekday) => _set(_firstWeekdayKey, weekday);

  Future<void> setUse24h({required bool enabled}) => _set(_use24hKey, enabled);

  Future<void> setWeekNumbers({required bool enabled}) => _set(_weekNumbersKey, enabled);

  Future<void> setTimeZonePicker({required bool enabled}) => _set(_timeZoneKey, enabled);

  Future<void> setDateOrder(DateOrder order) => _set(_dateOrderKey, order.name);

  Future<void> setMiniCalendar({required bool enabled}) => _set(_miniCalendarKey, enabled);

  Future<void> setDetailPopup({required bool enabled}) => _set(_detailPopupKey, enabled);

  Future<void> setAddFieldDetailed({required bool enabled}) => _set(_addFieldDetailedKey, enabled);

  Future<void> setCardStyle({required bool enabled}) => _set(_cardStyleKey, enabled);

  Future<void> setColumnWidths({double? sidebar, double? detail}) async {
    if (sidebar != null) await _set(_sidebarWidthKey, sidebar);
    if (detail != null) await _set(_detailWidthKey, detail);
  }

  Future<void> setSummaryConfig(SummaryConfig c) => _set(_summaryConfigKey, c.toJson());

  Future<void> setCustomShortcuts(Map<String, List<String>> shortcuts) => _set(_shortcutsKey, shortcuts);

  Future<void> setScopeViewOptions(Map<String, ViewOptions> options) => _set(_scopeViewOptionsKey, {
    for (final MapEntry(:key, value: o) in options.entries)
      key: {'g': o.grouping.name, 's': o.sorting.name, 'c': o.showCompleted, 'd': o.descending, 'x': o.showDetails},
  });

  Future<void> setShowListColor({required bool enabled}) => _set(_listColorKey, enabled);

  Future<void> setSubscriptions(List<CalendarSubscription> subs) => _set(_subscriptionsKey, [for (final s in subs) s.toJson()]);

  Future<void> setColorLabels(List<ColorLabel> labels) => _set(_colorLabelsKey, [for (final l in labels) l.toJson()]);

  Future<void> setReminderSound(ReminderSound sound) => _set(_reminderSoundKey, sound.name);

  Future<void> setCloseToTray({required bool enabled}) => _set(_closeToTrayKey, enabled);

  Future<void> setLaunchAtStartup({required bool enabled}) => _set(_launchAtStartupKey, enabled);

  /// The running focus session, or null when none runs.
  Future<void> setFocusRun(Map<String, Object?>? run) => run == null ? _remove(_focusRunKey) : _set(_focusRunKey, run);

  Future<void> setFocusTimers(List<FocusTimer> timers) => _set(_focusTimersKey, [for (final t in timers) t.toJson()]);

  Future<void> setSummaryTemplates(List<SummaryTemplate> templates) => _set(_summaryTemplatesKey, [for (final t in templates) t.toJson()]);

  /// "Redefinir padrão".
  Future<void> resetTaskDefaults() => _remove(_taskDefaultsKey);

  static const _templatesSeededKey = 'templates.builtInSeeded';

  /// Whether the built-in templates were created (they are only created once, even if deleted later).
  Future<bool> builtInTemplatesSeeded() async =>
      (await (_db.select(_db.preferences)..where((p) => p.name.equals(_templatesSeededKey))).getSingleOrNull()) != null;

  Future<void> markBuiltInTemplatesSeeded() => _set(_templatesSeededKey, true);

  static const _noteTemplatesSeededKey = 'templates.noteSeeded';

  /// Whether the built-in note templates were created (added after the task ones, so apart).
  Future<bool> noteTemplatesSeeded() async =>
      (await (_db.select(_db.preferences)..where((p) => p.name.equals(_noteTemplatesSeededKey))).getSingleOrNull()) != null;

  Future<void> markNoteTemplatesSeeded() => _set(_noteTemplatesSeededKey, true);

  static const _countdownsSeededKey = 'countdowns.builtInSeeded';

  /// Whether the default countdowns were created (once, as in a new TickTick account).
  Future<bool> builtInCountdownsSeeded() async =>
      (await (_db.select(_db.preferences)..where((p) => p.name.equals(_countdownsSeededKey))).getSingleOrNull()) != null;

  Future<void> markBuiltInCountdownsSeeded() => _set(_countdownsSeededKey, true);

  static const _financeSeededKey = 'finance.categoriesSeeded';

  /// Whether the default finance categories were created (once: deleting them all keeps them gone).
  Future<bool> financeCategoriesSeeded() async =>
      (await (_db.select(_db.preferences)..where((p) => p.name.equals(_financeSeededKey))).getSingleOrNull()) != null;

  Future<void> markFinanceCategoriesSeeded() => _set(_financeSeededKey, true);

  Future<void> _remove(String name) => (_db.delete(_db.preferences)..where((p) => p.name.equals(name))).go();

  Future<void> _set(String name, Object value) => _db
      .into(_db.preferences)
      .insertOnConflictUpdate(PreferencesCompanion.insert(name: name, value: jsonEncode(value), updatedAt: _clock.now().toUtc()));
}
