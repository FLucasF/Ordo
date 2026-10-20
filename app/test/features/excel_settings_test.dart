import 'dart:io';

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/attachment_store.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/data/subscription_store.dart';
import 'package:task_manager/data/xlsx/xlsx.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/features/backup/auto_backup.dart';
import 'package:task_manager/features/countdown/countdown_card.dart' show countdownImagesProvider;
import 'package:task_manager/features/settings/settings_dialog.dart';
import 'package:task_manager/features/subscriptions/subscriptions.dart' show subscriptionStoreProvider;
import 'package:task_manager/l10n/app_localizations.dart';

/// The system's file dialogs: "Salvar como" answers [savePath], "Abrir" answers [picked].
class FakePicker extends FilePicker {
  String? savePath;
  String? savedName;
  Uint8List? picked;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    savedName = fileName;
    return savePath;
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    final bytes = picked;
    if (bytes == null) return null;
    return FilePickerResult([PlatformFile(name: 'planilha.xlsx', size: bytes.length, bytes: bytes)]);
  }
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late FakePicker picker;
  final clock = FixedClock(DateTime(2026, 9, 24, 12));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    picker = FakePicker();
    FilePicker.platform = picker;
  });
  tearDown(() => db.close());

  /// Lets the real file and database work run; with [until], as long as that is not on screen (the
  /// safety copy takes a while).
  Future<void> settle(WidgetTester tester, {Finder? until}) async {
    for (var i = 0; i < (until == null ? 10 : 100) && (until == null || until.evaluate().isEmpty); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> openSettings(WidgetTester tester, {Size size = const Size(1400, 900)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    dir = (await tester.runAsync(() => Directory.systemTemp.createTemp('excel_test')))!;
    addTearDown(() => dir.deleteSync(recursive: true));
    Directory sub(String name) => Directory(p.join(dir.path, name))..createSync(recursive: true);
    // The backup's scratch folder (path_provider has no plugin in tests).
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (_) async => dir.path);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
          autoBackupProvider.overrideWithValue(AutoBackup(sub('backups'))),
          attachmentStoreProvider.overrideWithValue(AttachmentStore(sub('attachments'))),
          countdownImagesProvider.overrideWithValue(sub('images')),
          subscriptionStoreProvider.overrideWithValue(SubscriptionStore(sub('calendars'))),
        ],
        child: MaterialApp(
          theme: buildTheme(dark: false),
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSettings(context, tab: SettingsTab.account),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  }

  testWidgets('Conta → "Exportar para Excel" saves a workbook of every module where the user picks', (tester) async {
    await tester.runAsync(() async {
      await Repository(db, clock: clock).createTask(listId: inboxListId, title: 'Pagar luz');
      final fin = FinanceRepository(db, clock: clock);
      await fin.addEntry(kind: FinKind.expense, amount: 9990, date: DateTime(2026, 9, 20), description: 'Conta de luz');
    });
    await openSettings(tester);
    expect(find.text('Exportar para Excel'), findsOneWidget);
    expect(find.text('Importar do Excel'), findsOneWidget);

    picker.savePath = p.join(dir.path, 'saida.xlsx');
    await tester.tap(find.text('Exportar para Excel'));
    await settle(tester);
    expect(picker.savedName, 'ordo_20260924_1200.xlsx');
    expect(find.text('Planilha salva'), findsOneWidget);
    // The desktop picker only gives the path; the app writes the file.
    final tables = decodeXlsx(File(picker.savePath!).readAsBytesSync());
    expect(tables.map((t) => t.name), containsAll(['Tarefas', 'Lançamentos', 'Caixinhas', 'Dieta', 'Diário']));
    expect(tables.first.rows[1].cells, contains('Pagar luz'));
    expect(tables[2].rows[1].cells, containsAll(['Conta de luz', 99.9]));
    await dispose(tester);
  });

  testWidgets('Conta → "Importar do Excel" shows the preview with the errors, keeps a safety copy and appends', (tester) async {
    await tester.runAsync(() => Repository(db, clock: clock).createTask(listId: inboxListId, title: 'Já existia'));
    picker.picked = encodeXlsx([
      XlsxSheet(
        'Tarefas',
        const [XlsxColumn('Lista'), XlsxColumn('Título'), XlsxColumn('Prazo')],
        [
          ['Trabalho', 'Relatório', XlsxDate(DateTime(2026, 10, 2))],
          ['Trabalho', null, '01/10/2026'],
          [null, 'Ligar para o banco'],
        ],
      ),
      XlsxSheet(
        'Lançamentos',
        const [XlsxColumn('Data'), XlsxColumn('Tipo'), XlsxColumn('Categoria'), XlsxColumn('Valor')],
        [
          [XlsxDate(DateTime(2026, 9, 30)), 'Despesa', 'Mercado', const XlsxMoney(4550)],
        ],
      ),
      const XlsxSheet(
        'Hábitos',
        [XlsxColumn('Hábito')],
        [
          ['Ler'],
        ],
      ),
    ]);
    await openSettings(tester);
    await tester.tap(find.text('Importar do Excel'));
    await settle(tester);
    expect(find.text('2 tarefas, 1 lançamento; 1 linha com erro'), findsOneWidget);
    expect(find.text('Tarefas, linha 3: sem título'), findsOneWidget);
    expect(find.text('Abas não importadas (só Tarefas e Lançamentos entram): Hábitos'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Importar'));
    await settle(tester, until: find.textContaining('Importado'));
    expect(find.text('Importado: 2 tarefas e 1 lançamento'), findsOneWidget);
    final s = (await tester.runAsync(() => Repository(db).loadSnapshot()))!;
    expect(s.tasks.map((t) => t.title).toSet(), {'Já existia', 'Relatório', 'Ligar para o banco'});
    expect(s.lists.where((l) => l.name == 'Trabalho'), hasLength(1), reason: 'the missing list is created');
    final f = (await tester.runAsync(() => FinanceRepository(db).load()))!;
    expect((f.entries.single.amount, f.categories.single.name), (4550, 'Mercado'));
    // The safety copy, listed in "Backups automáticos".
    expect(AutoBackup(Directory(p.join(dir.path, 'backups'))).list(), hasLength(1));
    await dispose(tester);
  });

  testWidgets('on a phone, the two Excel entries fit and "Cancelar" in the preview writes nothing', (tester) async {
    picker.picked = encodeXlsx([
      XlsxSheet(
        'Tarefas',
        const [XlsxColumn('Título')],
        [
          ['Uma tarefa com um título bem comprido para ver se a linha cabe na tela do celular'],
        ],
      ),
    ]);
    await openSettings(tester, size: const Size(360, 740));
    await tester.scrollUntilVisible(find.text('Importar do Excel'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Exportar para Excel'), findsOneWidget);
    await tester.tap(find.text('Importar do Excel'));
    await settle(tester);
    expect(find.text('1 tarefa, nenhum lançamento; nenhuma linha com erro'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await settle(tester);
    final s = (await tester.runAsync(() => Repository(db).loadSnapshot()))!;
    expect(s.tasks, isEmpty);
    expect(AutoBackup(Directory(p.join(dir.path, 'backups'))).list(), isEmpty);
    await dispose(tester);
  });

  testWidgets('a file that is not a workbook says so', (tester) async {
    picker.picked = Uint8List.fromList('Título;Prazo\nx;y'.codeUnits);
    await openSettings(tester);
    await tester.tap(find.text('Importar do Excel'));
    await settle(tester);
    expect(find.text('Este arquivo não parece uma planilha do Excel (.xlsx)'), findsOneWidget);
    await dispose(tester);
  });
}
