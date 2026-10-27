import 'package:drift/drift.dart';

/// The tables that travel between linked devices, parents before children, with their key column.
/// Every one has `updated_at`, the time a merge compares.
const syncedTables = <(String, String)>[
  ('folders', 'id'),
  ('lists', 'id'),
  ('sections', 'id'),
  ('tags', 'id'),
  ('tasks', 'id'),
  ('checklist_items', 'id'),
  ('comments', 'id'),
  ('activities', 'id'),
  ('templates', 'id'),
  ('filters', 'id'),
  ('countdowns', 'id'),
  ('focus_records', 'id'),
  ('habits', 'id'),
  ('habit_checkins', 'id'),
  ('fin_categories', 'id'),
  ('fin_cards', 'id'),
  ('fin_recurrings', 'id'),
  ('fin_entries', 'id'),
  ('fin_card_payments', 'id'),
  ('loans', 'id'),
  ('loan_payments', 'id'),
  ('fin_goals', 'id'),
  ('fin_goal_moves', 'id'),
  ('diet_foods', 'id'),
  ('diet_meals', 'id'),
  ('diet_food_measures', 'id'),
  ('diet_plan_items', 'id'),
  ('diet_entries', 'id'),
  ('journal_entries', 'id'),
  ('preferences', 'name'),
];

/// A task's tags and reminders have no id of their own: they travel with the task, and changing one
/// counts as changing the task.
const taskChildTables = ['task_tags', 'task_reminders'];

/// Preferences that belong to the device, not to the person: the window and panels' sizes, the
/// Windows-only switches, the background picture (a file of this device), the running focus timer,
/// the subscribed calendars (their files are kept here), shortcuts, backups and the sync itself.
bool isDevicePreference(String name) =>
    const ['layout.', 'desktop.', 'shortcuts.', 'backup.', 'sync.'].any(name.startsWith) ||
    const {'focus.run', 'more.miniCalendar', 'appearance.background', 'appearance.backgroundDim', 'calendars.subscriptions'}.contains(name);

const _now = "strftime('%Y-%m-%dT%H:%M:%fZ', 'now')";
const _live = '(SELECT applying FROM sync_state WHERE id = 1) = 0';

String _log(String table, String key) =>
    "INSERT INTO sync_changes (tbl, row_id, seq, changed_at) VALUES ('$table', $key, (SELECT COALESCE(MAX(seq), 0) + 1 FROM sync_changes), $_now) "
    'ON CONFLICT (tbl, row_id) DO UPDATE SET seq = excluded.seq, changed_at = excluded.changed_at;';

/// The triggers that note every change of this device in `sync_changes` (not while the other
/// device's changes are being written), make sure an edit always moves `updated_at` forward, and
/// count a change of a task's tags or reminders as a change of the task. Each is dropped and made
/// again, so running them on every start keeps them right after any table is rebuilt.
List<String> syncTriggerStatements() => [
  for (final (table, key) in syncedTables) ...[
    'DROP TRIGGER IF EXISTS sync_${table}_ins;',
    'CREATE TRIGGER sync_${table}_ins AFTER INSERT ON $table WHEN $_live BEGIN ${_log(table, 'NEW.$key')} END;',
    'DROP TRIGGER IF EXISTS sync_${table}_upd;',
    'CREATE TRIGGER sync_${table}_upd AFTER UPDATE ON $table WHEN $_live BEGIN ${_log(table, 'NEW.$key')} END;',
    'DROP TRIGGER IF EXISTS sync_${table}_del;',
    'CREATE TRIGGER sync_${table}_del AFTER DELETE ON $table WHEN $_live BEGIN ${_log(table, 'OLD.$key')} END;',
    // An edit that left `updated_at` as it was still has to win over an older one elsewhere.
    'DROP TRIGGER IF EXISTS sync_${table}_touch;',
    'CREATE TRIGGER sync_${table}_touch AFTER UPDATE ON $table WHEN NEW.updated_at IS OLD.updated_at AND $_live '
        'BEGIN UPDATE $table SET updated_at = $_now WHERE $key = NEW.$key; END;',
  ],
  for (final table in taskChildTables) ...[
    'DROP TRIGGER IF EXISTS sync_${table}_ins;',
    'CREATE TRIGGER sync_${table}_ins AFTER INSERT ON $table WHEN $_live BEGIN UPDATE tasks SET updated_at = $_now WHERE id = NEW.task_id; END;',
    'DROP TRIGGER IF EXISTS sync_${table}_del;',
    'CREATE TRIGGER sync_${table}_del AFTER DELETE ON $table WHEN $_live BEGIN UPDATE tasks SET updated_at = $_now WHERE id = OLD.task_id; END;',
  ],
];

/// Makes the sync's own row (with a new [deviceId]) when missing, and the triggers.
Future<void> installSync(DatabaseConnectionUser db, String deviceId) async {
  await db.customStatement('INSERT OR IGNORE INTO sync_state (id, device_id, applying) VALUES (1, ?, 0)', [deviceId]);
  // A start after a crash in the middle of a merge.
  await db.customStatement('UPDATE sync_state SET applying = 0 WHERE id = 1');
  // Every write asks for the last number: without the index, each would read the whole log.
  await db.customStatement('CREATE INDEX IF NOT EXISTS sync_changes_seq ON sync_changes (seq)');
  for (final statement in syncTriggerStatements()) {
    await db.customStatement(statement);
  }
}

/// Notes every row already there as changed, so the first sync with a device sends them all.
Future<void> logExistingRows(DatabaseConnectionUser db) async {
  for (final (table, key) in syncedTables) {
    await db.customStatement(
      'INSERT OR IGNORE INTO sync_changes (tbl, row_id, seq, changed_at) '
      "SELECT '$table', $key, (SELECT COALESCE(MAX(seq), 0) FROM sync_changes) + ROW_NUMBER() OVER (), $_now FROM $table",
    );
  }
}
