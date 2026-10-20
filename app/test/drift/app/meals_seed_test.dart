import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/data/db/database.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<List<(String, int?)>> meals(AppDatabase db) async => [
    for (final m in await (db.select(db.dietMeals)..orderBy([(m) => OrderingTerm(expression: m.sortOrder)])).get()) (m.id, m.time),
  ];

  const expected = [
    ('breakfast', 420),
    ('morningSnack', 600),
    ('lunch', 750),
    ('afternoonSnack', 960),
    ('dinner', 1170),
    ('supper', 1320),
  ];

  test('a new database has the six meals of before, by their codes, with their times', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await meals(db), expected);
  });

  test('from v19 the six meals come too, so the entries keep their meal', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(19);
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 20);
    expect(await meals(db), expected);
  });
}
