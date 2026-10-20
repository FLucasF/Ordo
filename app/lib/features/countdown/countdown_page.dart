import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/format/date_labels.dart';
import '../../domain/countdown.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/preferences_repository.dart';
import '../../data/repository.dart';
import '../../domain/enums.dart';
import '../../domain/project.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/feedback.dart';
import '../common/shell_widgets.dart';
import '../shell/app_shell.dart';
import 'countdown_card.dart';
import 'countdown_form.dart';
import 'project_dashboard.dart';

/// The countdowns of a new TickTick account, created once on the first run: "Use o
/// Tarefas" (since today), "Fim de semana" (every Saturday) and "Dia de Ano Novo".
Future<void> seedBuiltInCountdowns(Repository repo, PreferencesRepository prefs, AppLocalizations t, DateTime now) async {
  if (await prefs.builtInCountdownsSeeded()) return;
  final today = startOfDay(now);
  await repo.createCountdown(name: t.countdownSeedUseApp, date: today, countMode: CountMode.plusOne);
  final saturday = today.add(Duration(days: (DateTime.saturday - today.weekday) % 7));
  await repo.createCountdown(name: t.countdownSeedWeekend, date: saturday, repeatRule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=SA');
  await repo.createCountdown(
    name: t.countdownSeedNewYear,
    date: DateTime(today.year + 1),
    type: CountdownType.holiday,
    repeatRule: 'FREQ=YEARLY;INTERVAL=1;BYMONTH=1;BYMONTHDAY=1',
  );
  await prefs.markBuiltInCountdownsSeeded();
}

/// Countdown module (`#countdown`).
class CountdownPage extends ConsumerStatefulWidget {
  const CountdownPage({super.key});

  @override
  ConsumerState<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends ConsumerState<CountdownPage> {
  bool _archived = false;

  /// Types unchecked in the left panel ("Tipos").
  Set<CountdownType> _hidden = {};
  bool _panel = true;

  /// Projects being closed by themselves now (their day is over), so each closes once.
  final Set<String> _closing = {};

  void _closeFinished(Snapshot s, DateTime now) {
    final due = s.countdowns.where((c) => closesByItself(c, now) && !_closing.contains(c.id)).toList();
    if (due.isEmpty) return;
    _closing.addAll(due.map((c) => c.id));
    final repo = ref.read(repositoryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final c in due) {
        await closeProjectNow(repo, s, c, now, byItself: true);
      }
    });
  }

  /// "+ Criar": which kind, then the form.
  Future<void> _create() async {
    final t = AppLocalizations.of(context);
    final type = await showDialog<CountdownType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(t.countdownCreateWhich),
        children: [
          for (final type in CountdownType.values)
            SimpleDialogOption(onPressed: () => Navigator.pop(context, type), child: Text(countdownTypeLabel(t, type))),
        ],
      ),
    );
    if (type != null && mounted) await showCountdownForm(context, type: type);
  }

  Color _typeColor(CountdownType type) {
    final tt = context.tt;
    return switch (type) {
      CountdownType.countdown => tt.primary,
      CountdownType.specialDay => tt.palette.priorityMedium,
      CountdownType.birthday => tt.palette.priorityHigh,
      CountdownType.holiday => tt.palette.green,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final countdowns = sortCountdowns(s.countdowns.where((c) => (c.archivedAt != null) == _archived && !_hidden.contains(c.type)), now);
    _closeFinished(s, now);

    // A fixed card height: on a phone the two columns are narrow, and a width-based height cut the
    // legend off.
    Widget grid(List<Countdown> items) => GridView(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 170,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [for (final c in items) _CountdownTile(countdown: c)],
    );

    void toggleType(CountdownType type, {required bool shown}) => setState(() => _hidden = shown ? ({..._hidden}..remove(type)) : {..._hidden, type});

    final header = ShellTopBar(
      title: _archived ? t.countdownArchivedTitle : t.navCountdown,
      onTogglePanel: () => setState(() => _panel = !_panel),
      onCreate: () => unawaited(_create()),
      createLabel: t.countdownNew,
      actions: [
        PopupMenuButton<Object>(
          tooltip: '',
          icon: Icon(Icons.more_horiz, color: tt.textSecondary),
          onSelected: (v) => switch (v) {
            final CountdownType type => toggleType(type, shown: _hidden.contains(type)),
            _ => setState(() => _archived = !_archived),
          },
          itemBuilder: (_) => [
            CheckedPopupMenuItem<Object>(value: 'archived', checked: _archived, child: Text(t.countdownArchived)),
            if (narrow) ...[
              const PopupMenuDivider(),
              for (final type in CountdownType.values)
                CheckedPopupMenuItem<Object>(value: type, checked: !_hidden.contains(type), child: Text(countdownTypeLabel(t, type))),
            ],
          ],
        ),
      ],
    );

    final panel = ShellPanel(
      children: [
        PanelSection(
          title: t.countdownTypes,
          children: [
            for (final type in CountdownType.values)
              PanelCheckRow(
                color: _typeColor(type),
                label: countdownTypeLabel(t, type),
                shown: !_hidden.contains(type),
                trailing: '${s.countdowns.where((c) => c.type == type && (c.archivedAt != null) == _archived).length}',
                onChanged: (on) => toggleType(type, shown: on),
                onOnly: () => setState(() => _hidden = {...CountdownType.values}..remove(type)),
              ),
          ],
        ),
        PanelSection(
          title: t.habitPanelShow,
          children: [
            PanelNavRow(
              icon: Icons.hourglass_bottom,
              label: t.countdownActive,
              selected: !_archived,
              trailing: '${s.countdowns.where((c) => c.archivedAt == null).length}',
              onTap: () => setState(() => _archived = false),
            ),
            PanelNavRow(
              icon: Icons.inventory_2_outlined,
              label: t.countdownArchived,
              selected: _archived,
              trailing: '${s.countdowns.where((c) => c.archivedAt != null).length}',
              onTap: () => setState(() => _archived = true),
            ),
          ],
        ),
      ],
    );

    // One block per kind, each under its heading (as the Calendar's sections).
    final types = [
      for (final type in CountdownType.values)
        if (countdowns.any((c) => c.type == type)) type,
    ];
    final body = countdowns.isEmpty
        ? Center(
            child: Text(t.countdownEmpty, style: TextStyle(color: tt.textTertiary)),
          )
        : ListView(
            padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 0, narrow ? 12 : 20, 24),
            children: [
              for (final (i, type) in types.indexed) ...[
                if (i > 0) ...[const SizedBox(height: 8), Divider(height: 1, color: tt.divider)],
                BodyHeading(countdownTypeLabel(t, type)),
                grid([
                  for (final c in countdowns)
                    if (c.type == type) c,
                ]),
              ],
            ],
          );

    final page = ShellLayout(panel: panel, panelOpen: _panel, topBar: header, body: body, onCreate: () => unawaited(_create()));
    return ModuleScaffold(module: AppModule.countdown, child: page);
  }
}

class _CountdownTile extends ConsumerWidget {
  const _CountdownTile({required this.countdown});

  final Countdown countdown;

  Future<void> _menu(BuildContext context, WidgetRef ref, Offset at) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(repositoryProvider);
    final c = countdown;
    final archived = c.archivedAt != null;
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        // A project: its dashboard, and closing or reopening it.
        if (isProject(c)) ...[
          PopupMenuItem(value: 'dashboard', height: 36, child: Text(c.closedAt == null ? t.projectDashboard : t.projectReport)),
          if (c.closedAt == null)
            PopupMenuItem(value: 'close', height: 36, child: Text(t.projectClose))
          else
            PopupMenuItem(value: 'reopen', height: 36, child: Text(t.projectReopen)),
        ],
        if (archived)
          PopupMenuItem(value: 'restore', height: 36, child: Text(t.countdownRestore))
        else ...[
          PopupMenuItem(value: 'edit', height: 36, child: Text(t.countdownEdit)),
          PopupMenuItem(value: 'style', height: 36, child: Text(t.countdownStyle)),
          PopupMenuItem(value: 'notes', height: 36, child: Text(t.countdownNotes)),
          PopupMenuItem(value: 'pin', height: 36, child: Text(c.pinnedAt == null ? t.countdownPin : t.countdownUnpin)),
          PopupMenuItem(value: 'archive', height: 36, child: Text(t.countdownArchive)),
        ],
        PopupMenuItem(value: 'delete', height: 36, child: Text(t.countdownDelete)),
      ],
    );
    if (!context.mounted || picked == null) return;
    switch (picked) {
      case 'dashboard':
        await showProjectDashboard(context, c.id);
      case 'close':
        if (await confirm(context, message: t.projectCloseConfirm, confirmLabel: t.projectClose)) {
          final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
          await closeProjectNow(repo, s, c, ref.read(clockProvider).now());
          if (context.mounted) await showProjectDashboard(context, c.id);
        }
      case 'reopen':
        await repo.reopenProject(c.id);
      case 'edit':
        await showCountdownForm(context, type: c.type, editing: c);
      case 'style':
        await _pickStyle(context, ref);
      case 'notes':
        await _editNotes(context, ref);
      case 'pin':
        await repo.pinCountdown(c.id, pinned: c.pinnedAt == null);
      case 'archive':
        await repo.archiveCountdown(c.id, archived: true);
        if (context.mounted) showToast(context, t.toastArchived);
      case 'restore':
        await repo.archiveCountdown(c.id, archived: false);
      case 'delete':
        await deleteCountdownAsking(context, repo, c);
    }
  }

  Future<void> _pickStyle(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    var style = countdown.style;
    var color = countdown.color;
    var icon = countdown.icon;
    var iconColor = countdown.iconColor;
    var image = countdown.image;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final tt = context.tt;
          return AlertDialog(
            title: Text(t.countdownStyle, style: const TextStyle(fontSize: 15)),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < countdownStyles; i++)
                        GestureDetector(
                          onTap: () => setState(() => style = i),
                          child: Container(
                            width: 128,
                            height: 84,
                            decoration: BoxDecoration(
                              border: Border.all(color: style == i ? tt.primary : Colors.transparent, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CountdownCardBody(
                              countdown: countdown.copyWith(icon: Value(icon), iconColor: Value(iconColor), image: Value(image)),
                              style: i,
                              color: parseHexColor(color) ?? tt.primary,
                              compact: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CountdownLookFields(
                    icon: icon,
                    iconColor: iconColor,
                    image: image,
                    onIcon: (v, c) => setState(() {
                      icon = v;
                      iconColor = c;
                    }),
                    onImage: (v) => setState(() => image = v),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in presetColors)
                        GestureDetector(
                          onTap: () => setState(() => color = c),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: parseHexColor(c),
                              shape: BoxShape.circle,
                              border: Border.all(color: color == c ? tt.text : Colors.transparent, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.actionCancel)),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.actionOk)),
            ],
          );
        },
      ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).setCountdownStyle(countdown.id, style: style, color: color, icon: icon, iconColor: iconColor, image: image);
    }
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController(text: countdown.note);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.countdownNotes, style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 8,
            minLines: 4,
            decoration: InputDecoration(hintText: t.countdownNoteHint),
          ),
        ),
        actions: [
          // Inserts the date and time where the cursor is.
          IconButton(
            tooltip: t.formatTime,
            icon: const Icon(Icons.schedule, size: 18),
            onPressed: () {
              final now = ref.read(clockProvider).now();
              final stamp = '${DateLabels.numeric(now)} ${DateLabels.time(now)}';
              final at = controller.selection.isValid ? controller.selection.start : controller.text.length;
              final end = controller.selection.isValid ? controller.selection.end : at;
              controller.value = TextEditingValue(
                text: controller.text.replaceRange(at, end, stamp),
                selection: TextSelection.collapsed(offset: at + stamp.length),
              );
            },
          ),
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.actionClose)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.actionSave)),
        ],
      ),
    );
    final text = controller.text;
    controller.dispose();
    if (ok == true) await ref.read(repositoryProvider).setCountdownNote(countdown.id, text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = context.tt;
    final project = isProject(countdown);
    final progress = project ? ProjectProgress.of(projectTasks(ref.watch(snapshotProvider).value ?? Snapshot.empty(), countdown)) : null;
    return GestureDetector(
      // A project opens its dashboard; another countdown, its form.
      onTapUp: (d) => unawaited(
        countdown.archivedAt != null
            ? _menu(context, ref, d.globalPosition)
            : project
            ? showProjectDashboard(context, countdown.id)
            : showCountdownForm(context, type: countdown.type, editing: countdown),
      ),
      onSecondaryTapUp: (d) => unawaited(_menu(context, ref, d.globalPosition)),
      onLongPressStart: (d) => unawaited(_menu(context, ref, d.globalPosition)),
      child: Stack(
        children: [
          Opacity(
            opacity: countdown.archivedAt == null ? 1 : 0.6,
            child: CountdownCardBody(
              countdown: countdown,
              style: countdown.style,
              color: parseHexColor(countdown.color) ?? tt.primary,
              progress: progress,
            ),
          ),
          // A closed project shows its trophy.
          if (countdown.closedAt != null)
            Positioned(
              top: 8,
              right: 40,
              child: Tooltip(
                message: AppLocalizations.of(context).projectReport,
                child: Icon(Icons.emoji_events, size: 18, color: tt.palette.priorityMedium),
              ),
            ),
          // ⋯ on a dark round, readable over any style or picture.
          Positioned(
            top: 6,
            right: 6,
            child: Tooltip(
              message: AppLocalizations.of(context).menuMore,
              child: Material(
                color: Colors.black.withValues(alpha: 0.28),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTapUp: (d) => unawaited(_menu(context, ref, d.globalPosition)),
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.more_horiz, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
