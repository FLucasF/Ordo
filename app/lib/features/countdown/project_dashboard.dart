import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/repository.dart';
import '../../domain/countdown.dart';
import '../../domain/enums.dart';
import '../../domain/project.dart';
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/feedback.dart';
import '../common/labels.dart';
import '../common/shell_widgets.dart';
import '../statistics/charts.dart';
import 'countdown_card.dart';

/// "2,3": one decimal with a comma, none when whole.
String _decimal(double v) => (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)).replaceAll('.', ',');

String _percent(double ratio) => '${(ratio * 100).round()}%';

/// Freezes the project's final report and closes it. A project closing by itself ([byItself]) ends on
/// its day; one closed by hand ends today.
Future<void> closeProjectNow(Repository repo, Snapshot s, Countdown c, DateTime now, {bool byItself = false}) {
  final tasks = projectTasks(s, c);
  final end = byItself ? countdownDate(c) : startOfDay(now);
  final report = buildProjectReport(tasks, start: projectStart(c, tasks), end: end);
  return repo.closeProject(c.id, report.encode());
}

/// Closes the linked countdowns whose day is over ([closesByItself]), once each.
Future<void> closeFinishedProjects(Repository repo, Snapshot s, DateTime now) async {
  for (final c in s.countdowns.where((c) => closesByItself(c, now))) {
    await closeProjectNow(repo, s, c, now, byItself: true);
  }
}

/// The project's dashboard (a linked countdown): a full screen on a phone, a large dialog otherwise.
Future<void> showProjectDashboard(BuildContext context, String countdownId) {
  final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
  return showDialog<void>(
    context: context,
    builder: (_) => narrow
        ? Dialog.fullscreen(child: ProjectDashboard(countdownId: countdownId))
        : Dialog(
            insetPadding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920, maxHeight: 860),
              child: ProjectDashboard(countdownId: countdownId),
            ),
          ),
  );
}

/// "Painel do projeto": days left, progress, pace, accuracy, tasks by section, the next deadlines, the
/// evolution and the late tasks; a closed project shows its final report on top.
class ProjectDashboard extends ConsumerWidget {
  const ProjectDashboard({super.key, required this.countdownId});

  final String countdownId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = startOfDay(now);
    final c = s.countdowns.where((c) => c.id == countdownId).firstOrNull;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    if (c == null) return const SizedBox.shrink();
    final accent = parseHexColor(c.color) ?? tt.primary;
    final lists = projectLists(s, c);
    final tasks = projectTasks(s, c);
    final progress = ProjectProgress.of(tasks);
    final status = countdownStatus(c, now, countUp: false);
    final deadline = status.target;
    final pace = c.closedAt == null ? projectPace(tasks, deadline, now) : null;
    final accuracy = Accuracy.of(tasks, now);
    final report = c.closedAt == null ? null : ProjectReport.decode(c.report);
    final projectName = switch (c) {
      Countdown(listId: final id?) => s.listById[id] == null ? null : labels.listName(s.listById[id]!),
      Countdown(folderId: final id?) => s.folderById[id]?.name,
      _ => null,
    };

    void openTask(Task task) {
      Navigator.pop(context);
      context.go(Routes.of(ListScope(task.listId), taskId: task.id));
    }

    Widget taskLine(Task task, {String? note, Color? noteColor}) => InkWell(
      onTap: () => openTask(task),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(task.title.isEmpty ? t.untitled : task.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            if (note != null)
              Flexible(
                child: Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: TtText.small, color: noteColor ?? tt.textTertiary),
                ),
              ),
          ],
        ),
      ),
    );

    final daysValue = switch (status.phase) {
      CountdownPhase.future => t.projectDaysLeft(status.days),
      CountdownPhase.today => t.projectDaysLeft(0),
      CountdownPhase.past => t.projectDayPassed,
    };
    final paceColor = switch (pace?.level) {
      PaceLevel.onTrack => tt.palette.green,
      PaceLevel.close => tt.palette.priorityMedium,
      PaceLevel.behind => tt.overdue,
      null => null,
    };

    // Evolution: the last 14 days (up to the report's end when closed), at least since the start.
    final chartEnd = c.closedAt == null ? today : startOfDay(c.closedAt!.toLocal());
    final chartStart = DateTime(chartEnd.year, chartEnd.month, chartEnd.day - 13);
    final perDay = completionsPerDay(tasks, chartStart, chartEnd);

    final sections = progressBySection(s, lists, tasks);
    final upcoming = upcomingWithDeadline(tasks);

    final body = ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 24, 8, narrow ? 16 : 24, 24),
      children: [
        if (projectName == null && isProject(c))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(t.projectGone, style: TextStyle(color: tt.textTertiary)),
          ),
        if (c.closedAt != null && report != null) ProjectReportCard(report: report, accent: accent, closedAt: c.closedAt!.toLocal()),
        const SizedBox(height: 12),
        FigureStrip(
          figures: [
            (label: t.projectDays, value: daysValue, color: accent, hint: DateLabels.numeric(deadline)),
            (label: t.projectProgress, value: _percent(progress.ratio), color: null, hint: t.projectTasksDone(progress.done, progress.total)),
            (
              label: t.projectAccuracy,
              value: accuracy.rate == null ? '—' : _percent(accuracy.rate!),
              color: null,
              hint: accuracy.rate == null ? t.projectAccuracyNone : t.projectAccuracyDetail(accuracy.onTime, accuracy.late, accuracy.missed),
            ),
            if (pace != null)
              (
                label: t.projectPace,
                value: pace.remaining == 0 ? t.projectPaceDone : t.projectPacePerDay(_decimal(pace.perDay)),
                color: paceColor,
                hint: t.projectPaceRecent(_decimal(pace.recent)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress.ratio, minHeight: 8, color: accent, backgroundColor: accent.withValues(alpha: 0.18)),
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(t.projectEmpty, style: TextStyle(color: tt.textTertiary)),
          ),
        if (sections.isNotEmpty) ...[
          BodyHeading(t.projectBySection),
          for (final part in sections)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      [
                        if (lists.length > 1) labels.listName(s.listById[part.listId]!),
                        part.sectionId == null ? t.groupUnsectioned : s.sections.firstWhere((x) => x.id == part.sectionId).name,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: part.progress.ratio, minHeight: 5, color: accent, backgroundColor: tt.divider),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${part.progress.done}/${part.progress.total}',
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                ],
              ),
            ),
        ],
        BodyHeading(t.projectUpcoming),
        if (upcoming.isEmpty)
          Text(t.projectNoUpcoming, style: TextStyle(color: tt.textTertiary))
        else
          for (final task in upcoming)
            taskLine(task, note: DateLabels.numeric(task.dueDate!.toLocal()), noteColor: (taskAccuracy(task, now) == 0) ? tt.overdue : null),
        BodyHeading(t.projectEvolution),
        BarChart(
          values: [for (final n in perDay) n.toDouble()],
          labels: [for (var i = 0; i < perDay.length; i++) '${DateTime(chartStart.year, chartStart.month, chartStart.day + i).day}'],
          format: (v) => v == 0 ? '' : v.round().toString(),
          highlight: perDay.length - 1,
        ),
        if (accuracy.lateTasks.isNotEmpty) ...[
          BodyHeading(t.projectLate, color: tt.overdue),
          for (final task in accuracy.lateTasks)
            taskLine(
              task,
              note: '${DateLabels.numeric(task.dueDate!.toLocal())} · ${task.status == TaskStatus.completed ? t.projectLateDone : t.projectLateOpen}',
              noteColor: task.status == TaskStatus.completed ? tt.palette.priorityMedium : tt.overdue,
            ),
        ],
      ],
    );

    final repo = ref.read(repositoryProvider);
    return Material(
      color: Theme.of(context).dialogTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
      borderRadius: narrow ? null : BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(narrow ? 8 : 24, 12, 12, 0),
            child: Row(
              children: [
                if (c.icon case final icon? when icon.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CountdownIcon(icon: icon, color: c.iconColor, size: 18),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${t.projectDashboard}${projectName == null ? '' : ' · $projectName'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                      ),
                    ],
                  ),
                ),
                // "Encerrar projeto" / "Reabrir projeto" (an icon with its tooltip on a phone).
                for (final (icon, label, action) in [
                  if (c.closedAt == null)
                    (
                      Icons.flag_outlined,
                      t.projectClose,
                      () async {
                        if (!await confirm(context, message: t.projectCloseConfirm, confirmLabel: t.projectClose)) return;
                        await closeProjectNow(repo, s, c, ref.read(clockProvider).now());
                        if (context.mounted) showToast(context, t.projectClosedToast);
                      },
                    )
                  else
                    (Icons.replay, t.projectReopen, () => repo.reopenProject(c.id)),
                ])
                  narrow
                      ? IconButton(tooltip: label, icon: Icon(icon), onPressed: () => unawaited(action()))
                      : TextButton.icon(icon: Icon(icon, size: 18), label: Text(label), onPressed: () => unawaited(action())),
                IconButton(tooltip: t.actionClose, icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// The closing card: the trophies, the deadlines, the accuracy, the evolution and the best day, as
/// frozen when the project closed.
class ProjectReportCard extends StatelessWidget {
  const ProjectReportCard({super.key, required this.report, required this.accent, required this.closedAt});

  final ProjectReport report;
  final Color accent;
  final DateTime closedAt;

  static String trophyLabel(AppLocalizations t, Trophy trophy) => switch (trophy) {
    Trophy.allDone => t.trophyAllDone,
    Trophy.allOnTime => t.trophyAllOnTime,
    Trophy.strongFinish => t.trophyStrongFinish,
    Trophy.noLate7 => t.trophyNoLate7,
  };

  static String trophyHint(AppLocalizations t, Trophy trophy) => switch (trophy) {
    Trophy.allDone => t.trophyAllDoneHint,
    Trophy.allOnTime => t.trophyAllOnTimeHint,
    Trophy.strongFinish => t.trophyStrongFinishHint,
    Trophy.noLate7 => t.trophyNoLate7Hint,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final start = report.evolutionStart;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.projectReport, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Flexible(
                child: Text(
                  t.projectClosedOn(DateLabels.numeric(closedAt)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t.projectReportPeriod(DateLabels.numeric(report.start), DateLabels.numeric(report.end)),
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          const SizedBox(height: 12),
          if (report.trophies.isEmpty)
            Text(t.projectNoTrophies, style: TextStyle(color: tt.textTertiary))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final trophy in Trophy.values.where(report.trophies.contains))
                  Tooltip(
                    message: trophyHint(t, trophy),
                    child: Chip(
                      avatar: Icon(Icons.emoji_events, size: 16, color: tt.palette.priorityMedium),
                      label: Text(trophyLabel(t, trophy)),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          FigureStrip(
            figures: [
              (label: t.projectProgress, value: t.projectTasksDone(report.done, report.total), color: null, hint: null),
              (label: t.projectDeadlines, value: t.projectAccuracyDetail(report.onTime, report.late, report.missed), color: null, hint: null),
              (label: t.projectAccuracy, value: report.accuracy == null ? '—' : _percent(report.accuracy!), color: null, hint: null),
              if (report.bestDay case final best?)
                (label: t.projectBestDay, value: DateLabels.numeric(best), color: null, hint: t.projectBestDayCount(report.bestDayCount)),
            ],
          ),
          if (report.evolution.isNotEmpty) ...[
            const SizedBox(height: 12),
            BarChart(
              height: 120,
              values: [for (final n in report.evolution) n.toDouble()],
              labels: [
                for (var i = 0; i < report.evolution.length; i++)
                  // Every day's number while they fit; then one a week.
                  report.evolution.length <= 16 || i % 7 == 0 ? '${DateTime(start.year, start.month, start.day + i).day}' : '',
              ],
              format: report.evolution.length <= 16 ? (v) => v == 0 ? '' : v.round().toString() : null,
            ),
          ],
        ],
      ),
    );
  }
}
