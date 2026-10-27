import 'package:drift/drift.dart';

// The devices' sync (schema v22). These tables belong to this device only: they never travel to the
// other one, nor are they part of what is merged.

/// What changed on this device, for the devices it syncs with: one line per row (the last change),
/// written by triggers on every synced table ([syncTriggerStatements]) so no write is missed, hard
/// deletes included. [seq] grows with every change: a device asks for those after the last it got.
/// A line whose row is gone is a deletion ("tombstone").
@DataClassName('SyncChange')
class SyncChanges extends Table {
  TextColumn get tbl => text()();
  TextColumn get rowId => text()();
  IntColumn get seq => integer()();

  /// When the change was made here (UTC ISO text, as drift stores dates): for a deletion, the moment
  /// to compare with the other device's edits.
  TextColumn get changedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {tbl, rowId};
}

/// A device this one is linked to.
@DataClassName('LinkedDevice')
class SyncPeers extends Table {
  /// The other device's id ([SyncState.deviceId] over there).
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// The secret both devices agreed on when linked (base64): it proves who is talking and keys the
  /// encryption.
  TextColumn get secret => text()();

  /// Where it was last reached, to try first.
  TextColumn get address => text().nullable()();
  IntColumn get port => integer().nullable()();

  /// The last of this device's changes ([SyncChanges.seq]) the other one confirmed.
  IntColumn get sentSeq => integer().withDefault(const Constant(0))();
  DateTimeColumn get pairedAt => dateTime()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// This device's own sync state, one row (id 1).
@DataClassName('SyncStateRow')
class SyncState extends Table {
  IntColumn get id => integer()();

  /// This device's id, made once.
  TextColumn get deviceId => text()();

  /// 1 while changes from the other device are written: the triggers then leave them out of
  /// [SyncChanges], so they don't travel back.
  IntColumn get applying => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
