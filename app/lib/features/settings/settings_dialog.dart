import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/palette_generated.dart';
import '../../data/preferences_repository.dart';
import '../../core/ids.dart';
import '../../data/importer.dart';
import '../../domain/enums.dart';
import '../../domain/import/ical.dart';
import '../../domain/import/imported_task.dart';
import '../../domain/import/ticktick_csv.dart';
import '../../domain/reminders.dart';
import '../../domain/snapshot.dart';
import '../../domain/task_defaults.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../appearance/backdrop.dart';
import '../appearance/backgrounds.dart';
import '../backup/backup_actions.dart';
import '../backup/excel_actions.dart';
import '../common/feedback.dart';
import '../common/labels.dart';
import '../date_picker/date_picker.dart' show reminderLabel;
import '../templates/templates.dart' show pickTemplate;
import '../focus/focus_page.dart' show showFocusSettings;
import '../habits/habit_page.dart' show showHabitSettings;
import '../shell/shortcut_help.dart' show ShortcutList;
import '../subscriptions/subscriptions.dart';
import 'notification_settings.dart';
import '../../core/clock.dart';
import '../common/color_choice.dart';
import '../sync/sync_dialog.dart';

/// Tabs of the settings that apply to a local app.
enum SettingsTab { account, features, smartLists, notifications, dateTime, appearance, more, imports, shortcuts, about }

/// "Configurações": a modal with the tabs on the left; phones open one tab at a time.
Future<void> showSettings(BuildContext context, {SettingsTab? tab}) => showDialog<void>(
  context: context,
  builder: (_) => _SettingsDialog(initial: tab),
);

String _tabLabel(AppLocalizations t, SettingsTab tab) => switch (tab) {
  SettingsTab.account => t.settingsAccount,
  SettingsTab.features => t.settingsFeatures,
  SettingsTab.smartLists => t.settingsSmartLists,
  SettingsTab.notifications => t.navNotifications,
  SettingsTab.dateTime => t.settingsDateTime,
  SettingsTab.appearance => t.settingsAppearance,
  SettingsTab.more => t.settingsMore,
  SettingsTab.imports => t.settingsImports,
  SettingsTab.shortcuts => t.settingsShortcuts,
  SettingsTab.about => t.settingsAbout,
};

IconData _tabIcon(SettingsTab tab) => switch (tab) {
  SettingsTab.account => Icons.person_outline,
  SettingsTab.features => Icons.apps,
  SettingsTab.smartLists => Icons.list_alt,
  SettingsTab.notifications => Icons.notifications_none,
  SettingsTab.dateTime => Icons.schedule,
  SettingsTab.appearance => Icons.palette_outlined,
  SettingsTab.more => Icons.tune,
  SettingsTab.imports => Icons.move_to_inbox_outlined,
  SettingsTab.shortcuts => Icons.keyboard_outlined,
  SettingsTab.about => Icons.info_outline,
};

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({this.initial});

  final SettingsTab? initial;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late SettingsTab? _tab = widget.initial;

  Widget _content(SettingsTab tab) => switch (tab) {
    SettingsTab.account => const _AccountTab(),
    SettingsTab.features => const _FeaturesTab(),
    SettingsTab.smartLists => const _SmartListsTab(),
    SettingsTab.notifications => const NotificationSettingsPanel(),
    SettingsTab.dateTime => const _DateTimeTab(),
    SettingsTab.appearance => const _AppearanceTab(),
    SettingsTab.more => const _MoreTab(),
    SettingsTab.imports => const _ImportTab(),
    SettingsTab.shortcuts => const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: ShortcutList(editable: true)),
    SettingsTab.about => const _AboutTab(),
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < 700;

    Widget nav({required bool fill}) => ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Keyboard shortcuts belong to the computer; phones don't show them.
        for (final tab in SettingsTab.values)
          if (tab != SettingsTab.shortcuts || defaultTargetPlatform != TargetPlatform.android)
            ListTile(
              dense: true,
              selected: !fill && tab == (_tab ?? SettingsTab.account),
              selectedColor: tt.primary,
              selectedTileColor: tt.selected,
              leading: Icon(_tabIcon(tab), size: 18),
              title: Text(_tabLabel(t, tab)),
              trailing: fill ? const Icon(Icons.chevron_right, size: 18) : null,
              onTap: () => setState(() => _tab = tab),
            ),
      ],
    );

    Widget page(SettingsTab tab, {Widget? leading}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
          child: Row(
            children: [
              ?leading,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    _tabLabel(t, tab),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tt.text),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: tt.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 20), child: _content(tab)),
        ),
      ],
    );

    if (narrow) {
      final tab = _tab;
      return Dialog.fullscreen(
        backgroundColor: tt.screen,
        child: SafeArea(
          child: tab == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 8, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.settingsTitle,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tt.text),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: tt.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: nav(fill: true)),
                  ],
                )
              : page(
                  tab,
                  leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _tab = null)),
                ),
        ),
      );
    }
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 820,
        height: 600,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A Material of its own, so the tiles' highlight shows over the panel's color.
            Material(
              color: tt.hover,
              child: SizedBox(
                width: 210,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
                      child: Text(
                        t.settingsTitle,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tt.text),
                      ),
                    ),
                    Expanded(child: nav(fill: false)),
                  ],
                ),
              ),
            ),
            Expanded(child: page(_tab ?? SettingsTab.account)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ shared

/// A section title inside a tab.
class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
    child: Text(
      text,
      style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w700, color: context.tt.textTertiary),
    ),
  );
}

/// A row with a label and a dropdown on the right.
class _Choice<T> extends StatelessWidget {
  const _Choice({required this.label, required this.value, required this.options, required this.onChanged, this.subtitle});

  final String label;
  final String? subtitle;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: subtitle == null
        ? null
        : Text(
            subtitle!,
            style: TextStyle(fontSize: TtText.small, color: context.tt.textTertiary),
          ),
    trailing: DropdownButton<T>(
      value: value,
      underline: const SizedBox.shrink(),
      // The button is as wide as its longest option; the chosen one sits by the arrow, so every value
      // in the tab ends on the same line.
      alignment: AlignmentDirectional.centerEnd,
      items: [for (final o in options.entries) DropdownMenuItem(value: o.key, child: Text(o.value))],
      onChanged: (v) => v == null ? null : onChanged(v),
    ),
  );
}

// ------------------------------------------------------------------ Conta

class _AccountTab extends ConsumerWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF7B2FBE),
            child: Text(t.appTitle.substring(0, 1), style: const TextStyle(color: Colors.white)),
          ),
          title: Text(t.settingsLocalAccount),
          subtitle: Text(
            t.settingsLocalAccountHint,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
        ),
        _Section(t.settingsBackup),
        ListTile(
          leading: const Icon(Icons.sync),
          title: Text(t.syncTitle),
          subtitle: Text(
            t.syncSameWifi,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          onTap: () => unawaited(showDeviceSync(context)),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(t.settingsBackupGenerate),
          onTap: () => unawaited(exportBackup(context, ref)),
        ),
        ListTile(leading: const Icon(Icons.upload_outlined), title: Text(t.settingsBackupImport), onTap: () => unawaited(importBackup(context, ref))),
        ListTile(
          leading: const Icon(Icons.history),
          title: Text(t.settingsAutoBackup),
          subtitle: Text(
            t.settingsAutoBackupHint,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          onTap: () => unawaited(showAutoBackups(context, ref)),
        ),
        ListTile(
          leading: const Icon(Icons.table_view_outlined),
          title: Text(t.xlsxExport),
          subtitle: Text(
            t.xlsxExportHint,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          onTap: () => unawaited(exportExcel(context, ref)),
        ),
        ListTile(
          leading: const Icon(Icons.post_add_outlined),
          title: Text(t.xlsxImport),
          subtitle: Text(
            t.xlsxImportHint,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          onTap: () => unawaited(importExcel(context, ref)),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Funcionalidades

class _FeaturesTab extends ConsumerWidget {
  const _FeaturesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final repo = ref.read(preferencesRepositoryProvider);
    Widget feature(AppFeature f, IconData icon, String name, String hint, {VoidCallback? settings, String? settingsLabel}) => Column(
      children: [
        SwitchListTile(
          secondary: Icon(icon, color: tt.textSecondary),
          title: Text(name),
          subtitle: Text(
            hint,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          value: prefs.has(f),
          onChanged: (on) => unawaited(repo.setFeature(prefs.disabledFeatures, f, enabled: on)),
        ),
        if (settings != null && prefs.has(f))
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 64, bottom: 4),
              child: TextButton(onPressed: settings, child: Text(settingsLabel ?? '')),
            ),
          ),
      ],
    );
    return Column(
      children: [
        feature(AppFeature.calendar, Icons.calendar_month_outlined, t.navCalendar, t.featureCalendarHint),
        feature(AppFeature.matrix, Icons.grid_view_rounded, t.navMatrix, t.featureMatrixHint),
        feature(
          AppFeature.habit,
          Icons.track_changes,
          t.navHabit,
          t.featureHabitHint,
          settings: () => unawaited(showHabitSettings(context)),
          settingsLabel: t.featureHabitSettings,
        ),
        feature(
          AppFeature.focus,
          Icons.timer_outlined,
          t.featureFocus,
          t.featureFocusHint,
          settings: () => unawaited(showFocusSettings(context, ref)),
          settingsLabel: t.focusSettings,
        ),
        feature(AppFeature.countdown, Icons.hourglass_bottom, t.navCountdown, t.featureCountdownHint),
        feature(AppFeature.finance, Icons.account_balance_wallet_outlined, t.navFinance, t.featureFinanceHint),
        feature(AppFeature.diet, Icons.restaurant_outlined, t.navDiet, t.featureDietHint),
        feature(AppFeature.journal, Icons.auto_stories_outlined, t.navJournal, t.featureJournalHint),
      ],
    );
  }
}

// ------------------------------------------------------------------ Lista inteligente

class _SmartListsTab extends ConsumerWidget {
  const _SmartListsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final labels = Labels(t);
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final repo = ref.read(preferencesRepositoryProvider);
    final options = {
      SmartListVisibility.show: t.smartListShow,
      SmartListVisibility.hide: t.smartListHide,
      SmartListVisibility.showIfNotEmpty: t.smartListShowIfNotEmpty,
    };
    Widget row(String label, SmartListVisibility value, void Function(SmartListVisibility) set) =>
        _Choice<SmartListVisibility>(label: label, value: value, options: options, onChanged: (v) => unawaited(Future.sync(() => set(v))));
    return Column(
      children: [
        for (final l in [SmartList.all, SmartList.today, SmartList.tomorrow, SmartList.next7Days])
          row(labels.smartList(l), prefs.smartListVisibility[l]!, (v) => repo.setSmartListVisibility(l, v)),
        row(t.inbox, prefs.inboxVisibility, repo.setInboxVisibility),
        row(
          labels.smartList(SmartList.summary),
          prefs.smartListVisibility[SmartList.summary]!,
          (v) => repo.setSmartListVisibility(SmartList.summary, v),
        ),
        row(t.sidebarTags, prefs.tagsVisibility, repo.setTagsVisibility),
        row(t.sidebarFilters, prefs.filtersVisibility, repo.setFiltersVisibility),
        for (final l in [SmartList.completed, SmartList.wontDo, SmartList.trash])
          row(labels.smartList(l), prefs.smartListVisibility[l]!, (v) => repo.setSmartListVisibility(l, v)),
      ],
    );
  }
}

// ------------------------------------------------------------------ Data e hora

class _DateTimeTab extends ConsumerWidget {
  const _DateTimeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final repo = ref.read(preferencesRepositoryProvider);
    // 2026-09-20 is a Sunday: day + weekday % 7 names each weekday.
    String name(int weekday) => dates.weekday(DateTime(2026, 9, 20 + weekday % 7));
    return Column(
      children: [
        _Choice<DateOrder>(
          label: t.settingsDateFormat,
          value: prefs.dateOrder,
          options: {DateOrder.dayMonthYear: '31/12/2026', DateOrder.monthDayYear: '12/31/2026', DateOrder.yearMonthDay: '2026/12/31'},
          onChanged: (v) => unawaited(repo.setDateOrder(v)),
        ),
        _Choice<bool>(
          label: t.settingsTimeFormat,
          value: prefs.use24h,
          options: {true: t.timeFormat24, false: t.timeFormat12},
          onChanged: (v) => unawaited(repo.setUse24h(enabled: v)),
        ),
        _Choice<int>(
          label: t.settingsWeekStart,
          value: prefs.firstWeekday,
          options: {
            for (final wd in [
              DateTime.sunday,
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
              DateTime.saturday,
            ])
              wd: name(wd),
          },
          onChanged: (v) => unawaited(repo.setFirstWeekday(v)),
        ),
        SwitchListTile(
          title: Text(t.settingsWeekNumbers),
          subtitle: Text(
            t.settingsWeekNumbersHint,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          value: prefs.weekNumbers,
          onChanged: (v) => unawaited(repo.setWeekNumbers(enabled: v)),
        ),
        SwitchListTile(
          title: Text(t.settingsTimeZone),
          subtitle: Text(
            t.settingsTimeZoneHint,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          value: prefs.timeZonePicker,
          onChanged: (v) => unawaited(repo.setTimeZonePicker(enabled: v)),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Aparência

class _AppearanceTab extends ConsumerWidget {
  const _AppearanceTab();

  static String seriesName(AppLocalizations t, ColorSeries s) => switch (s) {
    ColorSeries.standard => t.colorStandard,
    ColorSeries.sky => t.colorSky,
    ColorSeries.turquoise => t.colorTurquoise,
    ColorSeries.teal => t.colorTeal,
    ColorSeries.reed => t.colorReed,
    ColorSeries.yellow => t.colorYellow,
    ColorSeries.pinkPear => t.colorPinkPear,
    ColorSeries.lilac => t.colorLilac,
    ColorSeries.ebony => t.colorEbony,
    ColorSeries.navy => t.colorNavy,
    ColorSeries.grey => t.colorGrey,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final repo = ref.read(preferencesRepositoryProvider);
    final standard = Theme.of(context).brightness == Brightness.dark ? darkPalette.primary : lightPalette.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Choice<AppLanguage>(
          label: t.settingsLanguage,
          value: prefs.language,
          options: const {AppLanguage.portuguese: 'Português', AppLanguage.latin: 'Latina'},
          onChanged: (v) => unawaited(repo.setLanguage(v)),
        ),
        // "Estilo da Interface".
        _Choice<bool>(
          label: t.settingsInterfaceStyle,
          value: prefs.cardStyle,
          options: {false: t.interfaceFlat, true: t.interfaceCard},
          onChanged: (v) => unawaited(repo.setCardStyle(enabled: v)),
        ),
        _Section(t.settingsTheme),
        // Claro | Escuro, and apart from them the switch that follows the system.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeChoice>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ThemeChoice.light, label: Text(t.themeLight)),
                ButtonSegment(value: ThemeChoice.dark, label: Text(t.themeDark)),
              ],
              selected: {
                prefs.theme == ThemeChoice.system
                    ? (MediaQuery.platformBrightnessOf(context) == Brightness.dark ? ThemeChoice.dark : ThemeChoice.light)
                    : prefs.theme,
              },
              onSelectionChanged: (v) => unawaited(repo.setTheme(v.first)),
            ),
          ),
        ),
        SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(t.themeSystem, style: const TextStyle(fontSize: TtText.body)),
          value: prefs.theme == ThemeChoice.system,
          onChanged: (on) => unawaited(
            repo.setTheme(on ? ThemeChoice.system : (Theme.of(context).brightness == Brightness.dark ? ThemeChoice.dark : ThemeChoice.light)),
          ),
        ),
        _Section(t.settingsColorSeries),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // Cells of one width, so the swatches line up in columns whatever the name's length.
          child: Wrap(
            spacing: 4,
            runSpacing: 10,
            children: [
              for (final series in ColorSeries.values)
                Tooltip(
                  message: seriesName(t, series),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => unawaited(repo.setColorSeries(series)),
                    child: SizedBox(
                      width: 64,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: seriesPrimary(series) ?? standard,
                              shape: BoxShape.circle,
                              border: prefs.customAccent == null && prefs.colorSeries == series ? Border.all(color: tt.text, width: 2) : null,
                            ),
                            child: prefs.customAccent == null && prefs.colorSeries == series
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            seriesName(t, series),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: tt.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Any color, from the palette: the rainbow, or the color picked.
              Tooltip(
                message: t.colorCustom,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final picked = await showColorPicker(context, initial: prefs.customAccent);
                    if (picked != null) await repo.setCustomAccent(picked);
                  },
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: parseHexColor(prefs.customAccent),
                            gradient: prefs.customAccent == null
                                ? const SweepGradient(
                                    colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red],
                                  )
                                : null,
                            border: prefs.customAccent != null ? Border.all(color: tt.text, width: 2) : null,
                          ),
                          child: Icon(prefs.customAccent != null ? Icons.check : Icons.add, size: 16, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.colorSeriesCustom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: tt.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // "Temas prontos": color, background and corners at once.
        _Section(t.appearanceThemePresets),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            t.appearanceThemePresetsHint,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final preset in ThemePreset.values)
                _PresetTile(preset: preset, standard: standard, selected: preset.matches(prefs), onTap: () => unawaited(preset.apply(repo))),
            ],
          ),
        ),
        _Section(t.appearanceWallpaper),
        _WallpaperSection(prefs: prefs),
        _Section(t.settingsDisplay),
        _Choice<SidebarCount>(
          label: t.settingsSidebarCount,
          value: prefs.sidebarCount,
          options: {SidebarCount.all: t.sidebarCountAll, SidebarCount.hideNotes: t.sidebarCountHideNotes, SidebarCount.none: t.sidebarCountNone},
          onChanged: (v) => unawaited(repo.setSidebarCount(v)),
        ),
        _Choice<bool>(
          label: t.settingsListColor,
          value: prefs.showListColor,
          options: {true: t.smartListShow, false: t.smartListHide},
          onChanged: (v) => unawaited(repo.setShowListColor(enabled: v)),
        ),
        _Choice<bool>(
          label: t.settingsCompletedStyle,
          value: prefs.strikeCompleted,
          options: {false: t.completedStyleDefault, true: t.completedStyleStrike},
          onChanged: (v) => unawaited(repo.setStrikeCompleted(enabled: v)),
        ),
      ],
    );
  }
}

/// A "Temas prontos" card: the preset's background with its color and corners, and its name.
class _PresetTile extends StatelessWidget {
  const _PresetTile({required this.preset, required this.standard, required this.selected, required this.onTap});

  final ThemePreset preset;
  final Color standard;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    // "Noite" shows how it will look: dark.
    final dark = preset.theme == ThemeChoice.dark || tt.isDark;
    final accent = seriesPrimary(preset.series) ?? standard;
    final radius = BorderRadius.circular(preset.card ? 10 : 3);
    return Tooltip(
      message: presetName(t, preset),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 84,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1C1C1C) : Colors.white,
                  gradient: preset.gradient?.gradient(dark: dark),
                  borderRadius: radius,
                  border: Border.all(color: selected ? tt.primary : tt.divider, width: selected ? 2 : 1),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                presetName(t, preset),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: tt.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Papel de parede": the live preview, the choices and "Escurecer", which the preview follows while
/// it's dragged (saved when let go).
class _WallpaperSection extends ConsumerStatefulWidget {
  const _WallpaperSection({required this.prefs});

  final Preferences prefs;

  @override
  ConsumerState<_WallpaperSection> createState() => _WallpaperSectionState();
}

class _WallpaperSectionState extends ConsumerState<_WallpaperSection> {
  double? _dragging;

  @override
  void didUpdateWidget(_WallpaperSection old) {
    super.didUpdateWidget(old);
    // The saved value arrived: the slider follows the settings again.
    if (old.prefs.backgroundDim != widget.prefs.backgroundDim) _dragging = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final prefs = widget.prefs;
    final repo = ref.read(preferencesRepositoryProvider);
    final dim = _dragging ?? prefs.backgroundDim;
    final shown = hasBackground(prefs.background) ? prefs.background : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, box) {
              final preview = SizedBox(
                width: 210,
                height: 120,
                child: AppearancePreview(background: shown, dim: dim, card: prefs.cardStyle),
              );
              final choices = BackgroundChoices(value: prefs.background, onChanged: (c) => unawaited(repo.setBackground(c)));
              return box.maxWidth >= 520
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        preview,
                        const SizedBox(width: 16),
                        Expanded(child: choices),
                      ],
                    )
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [preview, const SizedBox(height: 12), choices]);
            },
          ),
        ),
        // "Escurecer" in the dark theme, "Clarear" in the light one: the veil is the theme's own color.
        if (shown != null)
          ListTile(
            title: Text(tt.isDark ? t.backgroundDim : t.backgroundLighten),
            trailing: SizedBox(
              width: 220,
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: dim.clamp(0.0, maxBackgroundDim),
                      max: maxBackgroundDim,
                      divisions: 18,
                      onChanged: (v) => setState(() => _dragging = v),
                      onChangeEnd: (v) => unawaited(repo.setBackgroundDim(v)),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(dim * 100).round()}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Mais configurações

class _MoreTab extends ConsumerWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final repo = ref.read(preferencesRepositoryProvider);
    final lists = (ref.watch(snapshotProvider).value ?? Snapshot.empty()).activeLists;
    final tags = (ref.watch(snapshotProvider).value ?? Snapshot.empty()).activeTags;
    final d = prefs.taskDefaults;
    void set(TaskDefaults next) => unawaited(repo.setTaskDefaults(next));
    TextStyle hint() => TextStyle(fontSize: TtText.small, color: tt.textTertiary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(t.settingsSmartRecognition),
        SwitchListTile(
          title: Text(t.settingsRecognizeDates),
          subtitle: Text(t.settingsRecognizeDatesHint, style: hint()),
          value: d.recognizeDates,
          onChanged: (v) => set(d.copyWith(recognizeDates: v)),
        ),
        SwitchListTile(
          title: Text(t.settingsRemoveDateText),
          subtitle: Text(t.settingsRemoveDateTextHint, style: hint()),
          value: d.removeDateText,
          onChanged: d.recognizeDates ? (v) => set(d.copyWith(removeDateText: v)) : null,
        ),
        _Choice<bool>(
          label: t.settingsTagRecognition,
          value: d.removeTagText,
          options: {true: t.tagTextRemove, false: t.tagTextKeep},
          onChanged: (v) => set(d.copyWith(removeTagText: v)),
        ),
        SwitchListTile(
          title: Text(t.settingsParseUrls),
          subtitle: Text(t.settingsParseUrlsHint, style: hint()),
          value: d.parseUrls,
          onChanged: (v) => set(d.copyWith(parseUrls: v)),
        ),
        _Section(t.settingsTaskDefaults),
        _Choice<DefaultDate>(
          label: t.settingsDefaultDate,
          value: d.date,
          options: {
            DefaultDate.none: t.defaultDateNone,
            DefaultDate.today: t.dateToday,
            DefaultDate.tomorrow: t.dateTomorrow,
            DefaultDate.dayAfterTomorrow: t.defaultDateDayAfter,
            DefaultDate.nextWeek: t.dateNextWeek,
          },
          onChanged: (v) => set(d.copyWith(date: v)),
        ),
        _Choice<String?>(
          label: t.settingsDefaultTimedReminder,
          value: d.timedReminder,
          options: {null: t.reminderNoneOption, for (final p in ReminderPresets.timed) p: reminderLabel(t, p)},
          onChanged: (v) => set(d.copyWith(timedReminder: () => v)),
        ),
        _Choice<String?>(
          label: t.settingsDefaultAllDayReminder,
          value: d.allDayReminder,
          options: {null: t.reminderNoneOption, for (final p in ReminderPresets.allDay) p: reminderLabel(t, p)},
          onChanged: (v) => set(d.copyWith(allDayReminder: () => v)),
        ),
        _Choice<int?>(
          label: t.settingsDefaultDuration,
          value: d.durationMinutes,
          options: {
            null: t.defaultDateNone,
            for (final m in const [15, 30, 45, 60, 90, 120])
              m: m < 60 ? t.focusMinutesValue(m) : (m % 60 == 0 ? t.focusHours(m ~/ 60) : '${t.focusHours(m ~/ 60)} ${t.focusMins(m % 60)}'),
          },
          onChanged: (v) => set(d.copyWith(durationMinutes: () => v)),
        ),
        _Choice<Priority>(
          label: t.settingsDefaultPriority,
          value: d.priority,
          options: {for (final p in Priority.values.reversed) p: labels.priority(p)},
          onChanged: (v) => set(d.copyWith(priority: v)),
        ),
        _Choice<String?>(
          label: t.settingsDefaultTag,
          value: tags.any((tag) => tag.id == d.tagId) ? d.tagId : null,
          options: {null: t.defaultDateNone, for (final tag in tags) tag.id: tag.name},
          onChanged: (v) => set(d.copyWith(tagId: () => v)),
        ),
        _Choice<String>(
          label: t.settingsDefaultList,
          value: lists.any((l) => l.id == d.listId) ? d.listId : inboxListId,
          options: {for (final l in lists) l.id: labels.listName(l)},
          onChanged: (v) => set(d.copyWith(listId: v)),
        ),
        _Choice<bool>(
          label: t.settingsNewTaskPosition,
          value: d.addAtTop,
          options: {true: t.positionTopOfList, false: t.positionEndOfList},
          onChanged: (v) => set(d.copyWith(addAtTop: v)),
        ),
        _Choice<bool>(
          label: t.settingsOverduePosition,
          value: d.overdueAtTop,
          options: {true: t.positionTop, false: t.positionEnd},
          onChanged: (v) => set(d.copyWith(overdueAtTop: v)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton(onPressed: () => unawaited(repo.resetTaskDefaults()), child: Text(t.settingsResetDefaults)),
          ),
        ),
        SwitchListTile(
          title: Text(t.settingsMiniCalendar),
          subtitle: Text(t.settingsMiniCalendarHint, style: hint()),
          value: prefs.miniCalendar,
          onChanged: (v) => unawaited(repo.setMiniCalendar(enabled: v)),
        ),
        _Section(t.settingsTemplates),
        ListTile(
          leading: const Icon(Icons.dashboard_customize_outlined),
          title: Text(t.settingsTemplates),
          subtitle: Text(t.settingsTemplatesHint, style: hint()),
          onTap: () async {
            final template = await pickTemplate(context);
            if (template == null) return;
            await ref.read(repositoryProvider).createTaskFromTemplate(template.id, listId: d.listId);
          },
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Integrações e Importação

class _ImportTab extends ConsumerStatefulWidget {
  const _ImportTab();

  @override
  ConsumerState<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends ConsumerState<_ImportTab> {
  /// "Importar para Lista" of the iCal import.
  String _icalList = inboxListId;
  bool _busy = false;

  Future<void> _import({required bool ical}) async {
    final t = AppLocalizations.of(context);
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: [if (ical) 'ics' else 'csv'], withData: true);
    final bytes = picked?.files.single.bytes;
    if (bytes == null || !mounted) return;
    final text = utf8.decode(bytes, allowMalformed: true);
    final List<ImportedTask> tasks;
    try {
      tasks = ical ? parseICal(text) : parseTickTickBackup(text);
    } on FormatException {
      showToast(context, ical ? t.importInvalidIcal : t.importInvalidBackup);
      return;
    }
    if (tasks.isEmpty) {
      showToast(context, t.importNothing);
      return;
    }
    if (!await confirm(context, message: t.importConfirm(tasks.length), confirmLabel: t.importAction) || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await importTasks(ref.read(repositoryProvider), tasks, defaultListId: ical ? _icalList : inboxListId);
      if (mounted) showToast(context, t.importDone(result.tasks));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final lists = (ref.watch(snapshotProvider).value ?? Snapshot.empty()).activeLists;
    TextStyle hint() => TextStyle(fontSize: TtText.small, color: tt.textTertiary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(t.importSection),
        if (_busy) const LinearProgressIndicator(),
        ListTile(
          leading: const Icon(Icons.check_box_outlined),
          title: Text(t.importTickTick),
          subtitle: Text(t.importTickTickHint, style: hint()),
          onTap: _busy ? null : () => unawaited(_import(ical: false)),
        ),
        ListTile(
          leading: const Icon(Icons.event_note_outlined),
          title: Text(t.importIcal),
          subtitle: Text(t.importIcalHint, style: hint()),
          onTap: _busy ? null : () => unawaited(_import(ical: true)),
        ),
        _Choice<String>(
          label: t.importIcalList,
          value: lists.any((l) => l.id == _icalList) ? _icalList : inboxListId,
          options: {for (final l in lists) l.id: labels.listName(l)},
          onChanged: (v) => setState(() => _icalList = v),
        ),
        _Section(t.subscriptionsTitle),
        const SubscriptionsSettings(),
      ],
    );
  }
}

// ------------------------------------------------------------------ Sobre

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: tt.primary,
                child: const Icon(Icons.check, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.appTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tt.text),
                  ),
                  Text(
                    t.aboutVersion(appVersion),
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(t.aboutText, style: TextStyle(color: tt.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

/// The app's version (pubspec.yaml).
const appVersion = '1.6.2';
