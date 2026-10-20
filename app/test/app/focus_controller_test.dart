import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/focus_controller.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/app/window_title.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/focus.dart';

/// A clock the test moves forward.
class _Clock implements Clock {
  DateTime value = DateTime(2026, 9, 25, 10);

  @override
  DateTime now() => value;
}

void main() {
  late AppDatabase db;
  late _Clock clock;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = _Clock();
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<FocusRecord>> records() => container.read(repositoryProvider).watchFocusRecords().first;

  test('"Tempo de execução" in the window title, only when the option is on', () async {
    final sub = container.listen(preferencesProvider, (_, _) {});
    addTearDown(sub.close);
    final focus = container.read(focusProvider.notifier)..start(mode: FocusMode.pomo);
    await pumpEventQueue();
    expect(container.read(windowTitleProvider), 'Ordo', reason: 'off by default');

    await container.read(preferencesRepositoryProvider).setFocusSettings(const FocusSettings(timeInTitle: true));
    await pumpEventQueue();
    clock.value = clock.value.add(const Duration(minutes: 1, seconds: 9));
    container.invalidate(windowTitleProvider);
    expect(container.read(windowTitleProvider), '23:51 · Ordo');
    focus.pause();
    expect(container.read(windowTitleProvider), 'Pausado 23:51 · Ordo');
    await focus.finish();
    expect(container.read(windowTitleProvider), 'Ordo');
  });

  test('extra time and a new duration change the record of the Pomo that just ended', () async {
    final focus = container.read(focusProvider.notifier)..start(mode: FocusMode.pomo);
    clock.value = clock.value.add(const Duration(minutes: 26));
    focus.tick();
    await pumpEventQueue();
    final id = container.read(focusProvider).recordId;
    expect(id, isNotNull, reason: 'the ended Pomo keeps its record');
    expect((await records()).single.seconds, 25 * 60);

    focus.extend(5);
    expect(container.read(focusProvider).phase, FocusPhase.focusing);
    clock.value = clock.value.add(const Duration(minutes: 6));
    focus.tick();
    await pumpEventQueue();
    final grown = (await records()).single;
    expect((grown.id, grown.seconds), (id, 30 * 60), reason: 'the same record, not a second one');

    await focus.editDuration(20);
    expect((await records()).single.seconds, 20 * 60);

    focus.exit();
    expect(container.read(focusProvider).recordId, isNull, reason: 'the next Pomo starts clean');
  });

  test('a Pomo running when the app closed goes on when it opens; one that ended meanwhile is recorded at its time', () async {
    // Started at 10:00 and saved; the app "reopens" at 10:10 with a new container.
    container.read(focusProvider.notifier).start(mode: FocusMode.pomo);
    await pumpEventQueue();
    container.dispose();
    clock.value = DateTime(2026, 9, 25, 10, 10);
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)]);
    container.read(focusProvider);
    await pumpEventQueue();
    final running = container.read(focusProvider);
    expect((running.phase, running.shown(clock.value)), (FocusPhase.focusing, const Duration(minutes: 15)));

    // Closed again; reopened at 11:00: the Pomo ended at 10:25 while closed.
    container.dispose();
    clock.value = DateTime(2026, 9, 25, 11);
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)]);
    container.read(focusProvider);
    await pumpEventQueue();
    expect(container.read(focusProvider).phase, FocusPhase.pomoDone);
    final record = (await records()).single;
    expect((record.seconds, record.endedAt.toLocal()), (25 * 60, DateTime(2026, 9, 25, 10, 25)));
  });

  test('the session as JSON', () {
    final s = FocusState(
      phase: FocusPhase.breaking,
      mode: FocusMode.pomo,
      target: const Duration(minutes: 25),
      startedAt: DateTime(2026, 9, 25, 10),
      accumulated: const Duration(minutes: 25),
      taskId: 't1',
      note: 'nota',
      pomosInCycle: 2,
      breakEndsAt: DateTime(2026, 9, 25, 10, 30),
      breakLength: const Duration(minutes: 5),
      recordId: 'r1',
    );
    final back = FocusState.fromJson(s.toJson())!;
    expect(back.toJson(), s.toJson());
    expect(FocusState.fromJson({'phase': 'nope'}), isNull);
  });
}
