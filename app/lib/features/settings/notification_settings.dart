import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/preferences_repository.dart';
import '../../domain/reminder_plan.dart';
import '../../platform/desktop_shell.dart';
import '../../l10n/app_localizations.dart';
import '../date_picker/date_picker.dart';

/// Settings → Notificações: daily alert of today's tasks and the persistent reminder.
/// The full settings screen is Phase 6; this dialog covers what the reminders already use.
Future<void> showNotificationSettings(BuildContext context) => showDialog<void>(context: context, builder: (_) => const _NotificationSettings());

/// Shows the Windows options outside Windows (tests and screenshots).
@visibleForTesting
bool debugShowDesktopSettings = false;

/// Daily alert time when first turned on (TickTick's "Horário de Alerta Diário" default is not
/// recorded; 09:00 matches the all-day reminders).
const _defaultDailyAlert = 9 * 60;

/// The tiles of Notificações, shared by the dialog and Settings.
class NotificationSettingsPanel extends ConsumerWidget {
  const NotificationSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final repo = ref.read(preferencesRepositoryProvider);
    final daily = prefs.dailyAlert;
    String format(int minutes) => DateLabels.time(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(t.settingsDailyNotifications),
          subtitle: Text(
            t.settingsDailyNotificationsHint,
            style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
          ),
          value: daily != null,
          onChanged: (on) => unawaited(repo.setDailyAlert(on ? _defaultDailyAlert : null)),
        ),
        if (daily != null)
          ListTile(
            title: Text(t.settingsDailyAlertTime),
            trailing: Text(format(daily), style: TextStyle(color: tt.primary)),
            onTap: () async {
              final picked = await showTimeDialog(
                context,
                initial: TimeOfDay(hour: daily ~/ 60, minute: daily % 60),
              );
              if (picked != null) await repo.setDailyAlert(picked.hour * 60 + picked.minute);
            },
          ),
        SwitchListTile(
          title: Text(t.settingsConstantReminder),
          subtitle: Text(
            t.settingsConstantReminderHint,
            style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
          ),
          value: prefs.constantReminder,
          onChanged: (on) => unawaited(repo.setConstantReminder(enabled: on)),
        ),
        ListTile(
          title: Text(t.settingsReminderSound),
          subtitle: Text(
            t.settingsReminderSoundHint,
            style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
          ),
          trailing: DropdownButton<ReminderSound>(
            value: prefs.reminderSound,
            underline: const SizedBox.shrink(),
            onChanged: (v) {
              if (v != null) unawaited(repo.setReminderSound(v));
            },
            items: [
              DropdownMenuItem(value: ReminderSound.alarmClock, child: Text(t.reminderSoundAlarmClock)),
              DropdownMenuItem(value: ReminderSound.standard, child: Text(t.reminderSoundStandard)),
              DropdownMenuItem(value: ReminderSound.silent, child: Text(t.reminderSoundSilent)),
            ],
          ),
        ),
        // Windows: the tray and starting with Windows, so reminders and the despertador reach you.
        if (DesktopShell.available || debugShowDesktopSettings) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t.settingsBackground,
                style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w600, color: tt.textTertiary),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(t.settingsCloseToTray),
            subtitle: Text(
              t.settingsCloseToTrayHint,
              style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
            ),
            value: prefs.closeToTray,
            onChanged: (on) => unawaited(repo.setCloseToTray(enabled: on)),
          ),
          SwitchListTile(
            title: Text(t.settingsLaunchAtStartup),
            subtitle: Text(
              t.settingsLaunchAtStartupHint,
              style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
            ),
            value: prefs.launchAtStartup,
            onChanged: (on) => unawaited(repo.setLaunchAtStartup(enabled: on)),
          ),
          ListTile(
            title: Text(t.settingsDesktopMini),
            subtitle: Text(
              t.settingsDesktopMiniHint,
              style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
            ),
            trailing: OutlinedButton(onPressed: () => unawaited(DesktopShell.openMiniCalendar()), child: Text(t.settingsDesktopMiniOpen)),
          ),
        ],
      ],
    );
  }
}

class _NotificationSettings extends StatelessWidget {
  const _NotificationSettings();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.navNotifications, style: const TextStyle(fontSize: 15)),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      content: const SizedBox(width: 360, child: NotificationSettingsPanel()),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionOk))],
    );
  }
}
