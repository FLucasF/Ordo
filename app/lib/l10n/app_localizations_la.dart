// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latin (`la`).
class AppLocalizationsLa extends AppLocalizations {
  AppLocalizationsLa([String locale = 'la']) : super(locale);

  @override
  String get appTitle => 'Ordo';

  @override
  String get inbox => 'Receptaculum';

  @override
  String get smartAll => 'Omnia';

  @override
  String get smartToday => 'Hodie';

  @override
  String get smartTomorrow => 'Cras';

  @override
  String get smartNext7Days => 'Septem dies proximi';

  @override
  String get smartCompleted => 'Perfecta';

  @override
  String get smartWontDo => 'Non fient';

  @override
  String get smartTrash => 'Quisquiliarium';

  @override
  String get sidebarLists => 'Indices';

  @override
  String get sidebarFilters => 'Filtra';

  @override
  String get sidebarTags => 'Pittacia';

  @override
  String get sidebarFiltersHelp => 'Pensa ostende per indicem, diem, prioritatem, pittacium et alia filtrata.';

  @override
  String get sidebarTagsHelp => 'Pensa tua pittaciis distribue. Scribe # in campo pensi ut novum facias.';

  @override
  String get archivedLists => 'Indices in tabulario';

  @override
  String get navTasks => 'Pensa';

  @override
  String get navSearch => 'Quaerere';

  @override
  String get navSync => 'Synchronizare';

  @override
  String get navNotifications => 'Admonitiones';

  @override
  String get navHelp => 'Auxilium';

  @override
  String get groupPinned => 'Affixa';

  @override
  String get groupUnpinned => 'Non affixa';

  @override
  String get groupUnsectioned => 'Sine sectione';

  @override
  String get groupOverdue => 'Praeterita';

  @override
  String get groupNext7Days => 'Septem dies proximi';

  @override
  String get groupLater => 'Postea';

  @override
  String get groupNoDate => 'Sine die';

  @override
  String get groupNoTag => 'Sine pittaciis';

  @override
  String get groupCompleted => 'Perfecta';

  @override
  String get groupCompletedAndWontDo => 'Perfecta et omissa.';

  @override
  String get groupPriorityHigh => 'Prioritas alta';

  @override
  String get groupPriorityMedium => 'Prioritas media';

  @override
  String get groupPriorityLow => 'Prioritas humilis';

  @override
  String get groupPriorityNone => 'Sine prioritate';

  @override
  String get showMore => 'Plura vide';

  @override
  String get weekdayMonday => 'Dies Lunae';

  @override
  String get weekdayTuesday => 'Dies Martis';

  @override
  String get weekdayWednesday => 'Dies Mercurii';

  @override
  String get weekdayThursday => 'Dies Iovis';

  @override
  String get weekdayFriday => 'Dies Veneris';

  @override
  String get weekdaySaturday => 'Dies Saturni';

  @override
  String get weekdaySunday => 'Dies Solis';

  @override
  String get weekdayShortMonday => 'Lun';

  @override
  String get weekdayShortTuesday => 'Mar';

  @override
  String get weekdayShortWednesday => 'Mer';

  @override
  String get weekdayShortThursday => 'Iov';

  @override
  String get weekdayShortFriday => 'Ven';

  @override
  String get weekdayShortSaturday => 'Sat';

  @override
  String get weekdayShortSunday => 'Sol';

  @override
  String get monthJanuary => 'ianuarius';

  @override
  String get monthFebruary => 'februarius';

  @override
  String get monthMarch => 'martius';

  @override
  String get monthApril => 'aprilis';

  @override
  String get monthMay => 'maius';

  @override
  String get monthJune => 'iunius';

  @override
  String get monthJuly => 'iulius';

  @override
  String get monthAugust => 'augustus';

  @override
  String get monthSeptember => 'september';

  @override
  String get monthOctober => 'october';

  @override
  String get monthNovember => 'november';

  @override
  String get monthDecember => 'december';

  @override
  String get monthShortJanuary => 'ian';

  @override
  String get monthShortFebruary => 'feb';

  @override
  String get monthShortMarch => 'mar';

  @override
  String get monthShortApril => 'apr';

  @override
  String get monthShortMay => 'mai';

  @override
  String get monthShortJune => 'iun';

  @override
  String get monthShortJuly => 'iul';

  @override
  String get monthShortAugust => 'aug';

  @override
  String get monthShortSeptember => 'sep';

  @override
  String get monthShortOctober => 'oct';

  @override
  String get monthShortNovember => 'nov';

  @override
  String get monthShortDecember => 'dec';

  @override
  String get relativeToday => 'Hodie';

  @override
  String get relativeTomorrow => 'Cras';

  @override
  String get relativeYesterday => 'Heri';

  @override
  String get emptyNoTasks => 'Nulla pensa';

  @override
  String get emptyInbox => 'Hic pensa et consilia excipe';

  @override
  String get emptyList => 'Preme receptaculum ut addas';

  @override
  String get emptyNoNotes => 'Nullae notae';

  @override
  String get emptyNotes => 'Hic afflatum et tempus nota';

  @override
  String get emptyTag => 'Paulum quiesce';

  @override
  String get emptySmart => 'Paulum quiesce';

  @override
  String get emptyCompletedTitle => 'Nondum ulla pensa perfecta';

  @override
  String get emptyCompleted => 'Perge sic :)';

  @override
  String get emptyWontDo => 'Pensa quae non facies hic apparent';

  @override
  String get emptyTrashTitle => 'Quisquiliarium purum est';

  @override
  String get emptyTrash => 'Nulla pensa deleta';

  @override
  String get addTask => 'Pensum adde';

  @override
  String get addNote => 'Notam adde';

  @override
  String addTaskTo(String name) {
    return 'Pensum adde ad \'$name\'';
  }

  @override
  String addTaskToTag(String name) {
    return 'Pensum adde ad \'#$name\'';
  }

  @override
  String get addDescriptionHint => 'Shift+Enter descriptionem addit';

  @override
  String get toastTaskCompleted => 'Pensum perfectum';

  @override
  String get toastFirstTaskOfDay => 'Primum pensum diei perfecisti!';

  @override
  String get toastUndo => 'Revoca';

  @override
  String get toastTaskDeleted => 'Pensum deletum';

  @override
  String get toastRestored => 'In indicem pristinum restitutum.';

  @override
  String get toastWontDo => 'Pensum omisisti.';

  @override
  String toastMovedTo(String name) {
    return 'Motum ad $name';
  }

  @override
  String get toastMovedToToday => 'Motum ad \"Hodie\".';

  @override
  String get toastSaved => 'Servatum';

  @override
  String get toastArchived => 'In tabulario conditum';

  @override
  String get toastLinkCopied => 'Nexus exscriptus';

  @override
  String get errorInboxCannotBeArchived => 'Receptaculum in tabulario condi non potest.';

  @override
  String get errorInboxCannotBeDeleted => 'Receptaculum deleri non potest.';

  @override
  String get errorTaskCannotBeItsOwnParent => 'Pensum sui ipsius subpensum esse non potest.';

  @override
  String get errorSubtaskDepthLimit => 'Subpensa usque ad quinque gradus pertinent.';

  @override
  String get errorTaskWithSubtasksCannotBecomeNote => 'Pensa cum subpensis in notas converti non possunt.';

  @override
  String get errorTagNameTaken => 'Pittacium eodem nomine iam est.';

  @override
  String get menuDate => 'Dies';

  @override
  String get menuPriority => 'Prioritas';

  @override
  String get menuAddSubtask => 'Subpensum adde';

  @override
  String get menuLinkParent => 'Pensum parens annecte';

  @override
  String get menuPin => 'Affige';

  @override
  String get menuUnpin => 'Refige';

  @override
  String get menuWontDo => 'Non faciam';

  @override
  String get menuMoveTo => 'Move ad';

  @override
  String get menuTags => 'Pittacia';

  @override
  String get menuDuplicate => 'Duplica';

  @override
  String get menuCopyLink => 'Nexum exscribe';

  @override
  String get menuConvertToNote => 'In notam converte';

  @override
  String get menuConvertToTask => 'In pensum converte';

  @override
  String get menuDelete => 'Dele';

  @override
  String get menuRestore => 'Restitue';

  @override
  String get menuDeleteForever => 'In perpetuum dele';

  @override
  String get menuReopen => 'Rursus aperi';

  @override
  String get menuMore => 'Plura';

  @override
  String get dateToday => 'Hodie';

  @override
  String get dateTomorrow => 'Cras';

  @override
  String get dateNextWeek => 'Hebdomas proxima';

  @override
  String get dateCustom => 'Ad libitum';

  @override
  String get dateClear => 'Purga';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityLow => 'Humilis';

  @override
  String get priorityNone => 'Nulla';

  @override
  String get detailDueDatePlaceholder => 'Dies praestitutus';

  @override
  String get detailTitlePlaceholder => 'Quid facere vis?';

  @override
  String get detailContentPlaceholder => 'Scribe aliquid aut \"/\" ad indicem mandatorum';

  @override
  String get detailNotePlaceholder => 'Scribe aliquid aut exemplar adhibe';

  @override
  String get detailSetReminder => 'Monitum statue';

  @override
  String get detailChecklistTooltip => 'Index inspectionis';

  @override
  String get detailChecklistHint => 'Preme \'Enter\' ut rem in indicem addas';

  @override
  String get detailAddSubtask => 'Subpensum adde';

  @override
  String get detailAddTag => 'Pittacium adde';

  @override
  String get untitled => 'Sine titulo';

  @override
  String get listAddTitle => 'Indicem adde';

  @override
  String get listEditTitle => 'Indicem muta';

  @override
  String get listNameHint => 'Nomen';

  @override
  String get listColor => 'Color indicis';

  @override
  String get listViewType => 'Genus aspectus';

  @override
  String get viewList => 'Index';

  @override
  String get viewKanban => 'Kanban';

  @override
  String get viewTimeline => 'Linea temporis';

  @override
  String get listFolder => 'Fasciculus';

  @override
  String get folderNone => 'Nullus';

  @override
  String get folderNew => 'Novus fasciculus';

  @override
  String get dropAsSubtask => 'Ut subpensum demitte';

  @override
  String get listType => 'Genus indicis';

  @override
  String get listTypeTasks => 'Index pensorum';

  @override
  String get listTypeNotes => 'Index notarum';

  @override
  String get listShowInSmartList => 'In indice sollerti ostende';

  @override
  String get listShowAllTasks => 'Omnia pensa';

  @override
  String get listDontShow => 'Noli ostendere';

  @override
  String get notesListCreated => 'Index notarum feliciter factus est. Hic notas tuas scribere potes.';

  @override
  String get gotIt => 'Intellexi';

  @override
  String get copySuffix => ' exemplar';

  @override
  String get actionCancel => 'Omitte';

  @override
  String get actionAdd => 'Adde';

  @override
  String get actionSave => 'Serva';

  @override
  String get actionClose => 'Claude';

  @override
  String get actionOk => 'Bene';

  @override
  String get actionEdit => 'Muta';

  @override
  String get actionRename => 'Renomina';

  @override
  String get actionDuplicate => 'Duplica';

  @override
  String get actionArchive => 'In tabulario conde';

  @override
  String get actionUnarchive => 'E tabulario educ';

  @override
  String get actionDelete => 'Dele';

  @override
  String get actionAddList => 'Indicem adde';

  @override
  String get actionUngroup => 'Disiunge';

  @override
  String get archiveListConfirm =>
      'Conditus in tabulario, hic index in fasciculo \'Indices in tabulario\' erit. Pensa et notae huius indicis nec monebunt nec in \'Omnia\' aliisque indicibus sollertibus apparebunt.';

  @override
  String get deleteListConfirm => 'Index delebitur et pensa in quisquiliarium ibunt.';

  @override
  String get tagAddTitle => 'Pittacia adde';

  @override
  String get tagEditTitle => 'Pittacium muta';

  @override
  String get tagNameHint => 'Nomen';

  @override
  String get tagColor => 'Color';

  @override
  String get tagParent => 'Pittacium principale';

  @override
  String get tagParentNone => 'Nullum';

  @override
  String get tagAddSubtag => 'Subpittacium adde';

  @override
  String get tagMerge => 'Pittacia confunde';

  @override
  String tagMergeInto(String name) {
    return 'Confunde \'$name\' in:';
  }

  @override
  String get colorNone => 'Nullus';

  @override
  String get sectionAdd => 'Sectionem adde';

  @override
  String get sectionNew => 'Nova sectio';

  @override
  String get sectionAddLeft => 'Sectionem a sinistra adde';

  @override
  String get sectionAddRight => 'Sectionem a dextra adde';

  @override
  String get sortButtonTooltip => 'Ordina et coniunge';

  @override
  String get groupByLabel => 'Coniunge per';

  @override
  String get sortByLabel => 'Ordina per';

  @override
  String get optionCustom => 'Ad libitum';

  @override
  String get optionDate => 'Dies';

  @override
  String get optionModifiedTime => 'Tempus mutationis';

  @override
  String get optionCreatedTime => 'Dies creationis';

  @override
  String get optionTitle => 'Titulus';

  @override
  String get optionTag => 'Pittacium';

  @override
  String get optionPriority => 'Prioritas';

  @override
  String get optionNone => 'Nulla';

  @override
  String get hideCompleted => 'Perfecta cela';

  @override
  String get showCompleted => 'Perfecta ostende';

  @override
  String get showDetails => 'Singula ostende';

  @override
  String get hideDetails => 'Singula cela';

  @override
  String get viewLabel => 'Aspectus';

  @override
  String get smartListShow => 'Ostende';

  @override
  String get smartListHide => 'Cela';

  @override
  String get smartListShowIfNotEmpty => 'Ostende si non vacuum est';

  @override
  String get accountSettings => 'Optiones';

  @override
  String get accountBackup => 'Exemplar tutelae fac';

  @override
  String get accountImportBackup => 'Exemplaria tutelae localia importa';

  @override
  String get backupSaved => 'Exemplar tutelae servatum';

  @override
  String get backupImported => 'Exemplar tutelae importatum. Applicatio data rursus leget.';

  @override
  String get backupImportConfirm => 'Hoc exemplar tutelae importatum omnia data huius instrumenti substituet. Pergere?';

  @override
  String get backupInvalid => 'Plica exemplaris tutelae non valet.';

  @override
  String get emptyTrashTooltip => 'Quisquiliarium exinani';

  @override
  String get emptyTrashConfirm => 'Omnia pensa quisquiliarii in perpetuum delere? Hoc revocari non potest.';

  @override
  String get slashText => 'Textus';

  @override
  String get slashHeading1 => 'Titulus 1';

  @override
  String get slashHeading2 => 'Titulus 2';

  @override
  String get slashHeading3 => 'Titulus 3';

  @override
  String get slashBulletedList => 'Index punctatus';

  @override
  String get slashNumberedList => 'Index numeratus';

  @override
  String get slashChecklistItem => 'Res inspicienda';

  @override
  String get slashQuote => 'Citatio';

  @override
  String get slashDivider => 'Linea transversa';

  @override
  String get pickerTabDate => 'Dies';

  @override
  String get pickerTime => 'Hora';

  @override
  String get pickerReminder => 'Monitum';

  @override
  String get pickerRepeat => 'Repete';

  @override
  String get pickerNone => 'Nulla';

  @override
  String get pickerNextMonth => 'Mensis proximus';

  @override
  String get pickerToday => 'Hodie';

  @override
  String get weekInitialSunday => 'S';

  @override
  String get weekInitialMonday => 'L';

  @override
  String get weekInitialTuesday => 'M';

  @override
  String get weekInitialWednesday => 'M';

  @override
  String get weekInitialThursday => 'I';

  @override
  String get weekInitialFriday => 'V';

  @override
  String get weekInitialSaturday => 'S';

  @override
  String get repeatDaily => 'Cotidie';

  @override
  String repeatWeekly(String weekday) {
    return 'Singulis hebdomadibus ($weekday)';
  }

  @override
  String repeatMonthly(int day) {
    return 'Singulis mensibus ($day.)';
  }

  @override
  String repeatYearly(int day, String month) {
    return 'Quotannis ($day. $month)';
  }

  @override
  String get repeatWeekdays => 'Omnibus diebus negotiosis (Lun-Ven)';

  @override
  String get repeatPickWorkdays => 'Dies negotiosi';

  @override
  String get repeatPickWeekend => 'Finis hebdomadis';

  @override
  String get repeatPickAllDays => 'Omnes';

  @override
  String get repeatCustom => 'Ad libitum';

  @override
  String get repeatEnds => 'Repetitio desinit';

  @override
  String get repeatEndsNever => 'In perpetuum';

  @override
  String get repeatEndsOnDate => 'Die certo desinit';

  @override
  String get repeatEndsAfterCount => 'Post certum numerum desinit';

  @override
  String repeatTimesLeft(int count) {
    return '$count vicibus';
  }

  @override
  String get repeatTimesHint => 'quotiens repetatur';

  @override
  String get repeatFromDue => 'Per dies praestitutos';

  @override
  String get repeatFromCompletion => 'Per diem perfectionis';

  @override
  String get repeatEvery => 'Singulis';

  @override
  String get unitDay => 'Dies';

  @override
  String get unitWeek => 'Hebdomas';

  @override
  String get unitMonth => 'Mensis';

  @override
  String get unitYear => 'Annus';

  @override
  String get unitMinutes => 'Minuta';

  @override
  String get unitHours => 'Horae';

  @override
  String get unitDays => 'Dies';

  @override
  String get reminderOnTime => 'Ipso tempore';

  @override
  String get reminder5m => '5 minutis ante';

  @override
  String get reminder30m => '30 minutis ante';

  @override
  String get reminder1h => 'Una hora ante';

  @override
  String get reminder1d => 'Uno die ante';

  @override
  String get reminderOnTheDay => 'Ipso die (09:00)';

  @override
  String get reminder1dAt9 => 'Uno die ante (09:00)';

  @override
  String get reminder2dAt9 => 'Duobus diebus ante (09:00)';

  @override
  String get reminder3dAt9 => 'Tribus diebus ante (09:00)';

  @override
  String get reminder1wAt9 => 'Una hebdomade ante (09:00)';

  @override
  String get reminderCustom => 'Ad libitum';

  @override
  String reminderCustomValue(int value, String unit) {
    return '$value $unit ante';
  }

  @override
  String reminderPreview(String time) {
    return 'Monebit $time';
  }

  @override
  String get notificationChannelName => 'Monita';

  @override
  String get notificationChannelDescription => 'Monita pensorum';

  @override
  String get notificationActionComplete => 'Perfectum';

  @override
  String get notificationActionSnooze => 'Differ 15 min';

  @override
  String snoozedUntil(String time) {
    return 'dilatum usque ad $time';
  }

  @override
  String get reminderPopupSnooze => 'Differ';

  @override
  String get reminderPopupDone => 'Perfectum';

  @override
  String get reminderPopupDismiss => 'Dimitte';

  @override
  String get snooze15m => '15 minuta';

  @override
  String get snooze30m => '30 minuta';

  @override
  String get snooze1h => 'Una hora';

  @override
  String get snooze3h => 'Tres horae';

  @override
  String get snoozeTonight => 'Hac nocte';

  @override
  String get snoozeTomorrow => 'Cras';

  @override
  String get snoozeCustom => 'Ad libitum';

  @override
  String get repeatSpecificDates => 'Per dies certos';

  @override
  String get repeatMonthEach => 'Singulis';

  @override
  String get repeatMonthOn => 'Die';

  @override
  String get repeatMonthWorkday => 'Dies negotiosus';

  @override
  String get repeatLastDay => 'Dies ultimus';

  @override
  String get ordinalFirst => 'primus';

  @override
  String get ordinalSecond => 'secundus';

  @override
  String get ordinalThird => 'tertius';

  @override
  String get ordinalFourth => 'quartus';

  @override
  String get ordinalLast => 'ultimus';

  @override
  String get workdayFirst => 'Primus dies negotiosus';

  @override
  String get workdayLast => 'Ultimus dies negotiosus';

  @override
  String get repeatPickDates => 'Dies in calendario elige';

  @override
  String quickAddCreateTag(String name) {
    return 'Pittacium \'$name\' crea';
  }

  @override
  String quickAddNextWeekday(String weekday) {
    return '$weekday proximus';
  }

  @override
  String get pickerTabDuration => 'Duratio';

  @override
  String get pickerStart => 'Initium';

  @override
  String get pickerEnd => 'Finis';

  @override
  String get pickerAllDay => 'Totus dies';

  @override
  String get viewOptions => 'Optiones aspectus';

  @override
  String get showDateBy => 'Diem ostende per';

  @override
  String get dateDisplayDate => 'Tempus pensi';

  @override
  String get dateDisplayCountdown => 'Dinumeratio';

  @override
  String countdownInDays(int count) {
    return 'post $count dies';
  }

  @override
  String countdownDaysAgo(int count) {
    return 'ante $count dies';
  }

  @override
  String dailyDigestTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pensa hodie habes', one: 'Unum pensum hodie habes');
    return '$_temp0';
  }

  @override
  String get settingsDailyNotifications => 'Admonitiones cotidianae';

  @override
  String get settingsDailyNotificationsHint => 'Monitum unum in dies cum pensis hodiernis';

  @override
  String get settingsDailyAlertTime => 'Hora moniti cotidiani';

  @override
  String get settingsConstantReminder => 'Monitum perpetuum';

  @override
  String get settingsConstantReminderHint => 'Admonitio manet donec agas';

  @override
  String get checklistItemReminder => 'Monitum rei';

  @override
  String get shortcutsTitle => 'Compendia';

  @override
  String get shortcutsGeneral => 'Generalia';

  @override
  String get shortcutsTask => 'Pensum';

  @override
  String get shortcutsEditTask => 'Pensum muta';

  @override
  String get shortcutsNavigation => 'Navigatio';

  @override
  String get shortcutCancel => 'Omitte';

  @override
  String get shortcutPalette => 'Index mandatorum';

  @override
  String get shortcutList => 'Index compendiorum';

  @override
  String get shortcutAddTask => 'Pensum adde';

  @override
  String get shortcutAddTaskBelow => 'Pensum infra adde';

  @override
  String get shortcutAddSubtask => 'Subpensum adde';

  @override
  String get shortcutToggleSubtasks => 'Subpensa explica/contrahe';

  @override
  String get shortcutComplete => 'Perfice';

  @override
  String get shortcutPin => 'Affige';

  @override
  String get shortcutDelete => 'Dele';

  @override
  String get shortcutSetDate => 'Diem statue';

  @override
  String get shortcutNoDate => 'Sine die';

  @override
  String get shortcutQuickDates => 'Hodie / Cras / Hebd. proxima';

  @override
  String get shortcutPriority => 'Prioritas';

  @override
  String get shortcutSearch => 'Quaere';

  @override
  String get shortcutSettings => 'Ad optiones i';

  @override
  String get shortcutGoSmart => 'Omnia / Hodie / Cras / 7 dies proximi';

  @override
  String get shortcutGoInbox => 'Receptaculum';

  @override
  String get paletteHint => 'Scribe mandatum aut quaere';

  @override
  String get paletteNewTask => 'Novum pensum';

  @override
  String paletteSearchFor(String term) {
    return 'Quaere \'$term\'';
  }

  @override
  String get searchHint => 'Quaere';

  @override
  String get searchTabTask => 'Pensum';

  @override
  String get searchTabTag => 'Pittacium';

  @override
  String get searchTabList => 'Index';

  @override
  String get searchNoResults => 'Nihil inventum';

  @override
  String get searchNotFound => 'Nondum invenisti quod quaeris?';

  @override
  String get searchFullPage => 'Quaestionem plenam tempta.';

  @override
  String get searchLookFor => 'Quaere';

  @override
  String get searchFilterLists => 'Indices';

  @override
  String get searchFilterTag => 'Pittacium';

  @override
  String get searchFilterDate => 'Dies';

  @override
  String get searchFilterPriority => 'Prioritas';

  @override
  String get searchFilterType => 'Genus';

  @override
  String get searchFilterStatus => 'Status';

  @override
  String get searchAll => 'Omnia';

  @override
  String get searchDateAll => 'Omnes';

  @override
  String searchDateThisWeek(String range) {
    return 'Haec hebdomas ($range)';
  }

  @override
  String get searchDateNextWeek => 'Hebdomas proxima';

  @override
  String get searchDateLastWeek => 'Hebdomas superior';

  @override
  String get searchDateThisMonth => 'Hic mensis';

  @override
  String get searchDateLastMonth => 'Mensis superior';

  @override
  String get searchDateCustom => 'Ad libitum';

  @override
  String get searchTypeTask => 'Pensum';

  @override
  String get searchTypeNote => 'Nota';

  @override
  String get searchStatusOpen => 'Imperfectum';

  @override
  String get searchStatusCompleted => 'Perfectum';

  @override
  String get searchStatusWontDo => 'Non fiet';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pensa', one: 'Unum pensum', zero: 'Nullum pensum');
    return '$_temp0';
  }

  @override
  String get quickAddButton => 'Adde';

  @override
  String get menuSelect => 'Selige';

  @override
  String batchSelected(int count) {
    return '$count res selegisti';
  }

  @override
  String get batchDueDate => 'Dies praestitutus';

  @override
  String get batchPostpone => 'Differ';

  @override
  String get postpone1Day => 'Uno die differ';

  @override
  String get postpone1Week => 'Una hebdomade differ';

  @override
  String get postponeCustom => 'Ad libitum';

  @override
  String get postponeDaysPrompt => 'Quot dies differre?';

  @override
  String get batchPriority => 'Prioritas';

  @override
  String get batchList => 'Index';

  @override
  String get batchTags => 'Pittacia';

  @override
  String get batchComplete => 'Perfectum';

  @override
  String get batchPin => 'Affige';

  @override
  String get batchWontDo => 'Non faciam';

  @override
  String get batchLinkParent => 'Pensum parens annecte';

  @override
  String get batchMerge => 'Confunde';

  @override
  String get batchDuplicate => 'Duplica';

  @override
  String get batchConvertNote => 'In notam converte';

  @override
  String get batchCopyText => 'Textum exscribe';

  @override
  String get batchDelete => 'Dele';

  @override
  String mergeConfirm(int count) {
    return 'Haec $count pensa subpensa novi pensi coniuncti fient.';
  }

  @override
  String get mergedTitle => 'Novum pensum coniunctum.';

  @override
  String get selectAll => 'Omnia selige';

  @override
  String get deselectAll => 'Nihil selige';

  @override
  String get toastCopied => 'Exscriptum';

  @override
  String get templateSave => 'Ut exemplar serva';

  @override
  String get templateSaveHint => 'Argumentum et pittacia in exemplari servabuntur.';

  @override
  String get templateNameHint => 'Nomen exemplaris';

  @override
  String get templateAddFrom => 'Ex exemplari adde';

  @override
  String get templatePickerTitle => 'Exemplar pensi';

  @override
  String get templateManage => 'Exemplaria cura';

  @override
  String get templateEmpty => 'Nullum exemplar';

  @override
  String get templateBeforeWorkName => 'Pensa ante laborem';

  @override
  String get templateBeforeWorkItems =>
      'Ordinem diei recognosce\nEpistulas graves inspice\nTres res primas diei statue\nRes conventuum para\nMensam laboris compone\nIndicem pensorum renova\nPoculum aquae bibe';

  @override
  String get templateDailyRecordName => 'Commentarius diurnus';

  @override
  String get templateDailyRecordContent =>
      '**Quid hodie feci?**\n\n**Quid bene cessit?**\n\n**Quid cras melius facere possum?**\n\n**Cuius rei hodie gratus sum?**';

  @override
  String get templateTravelName => 'Res ad iter componendae';

  @override
  String get templateTravelItems =>
      'Documenta et diploma\nCrumena et chartae nummariae\nTelephonum et onerator\nAuscultatoria\nVestimenta\nSubligacula et tibialia\nVestis nocturna\nCalcei\nPeniculus et pasta dentium\nOdoris remedium\nSapo capillorum\nMedicamenta\nUnguentum contra solem\nOcularia\nUmbraculum';

  @override
  String get commentsTitle => 'Commentarii';

  @override
  String get commentHint => 'Commentarium scribe';

  @override
  String get commentAuthor => 'Tu';

  @override
  String get commentJustNow => 'Modo';

  @override
  String commentMinutesAgo(int count) {
    return 'ante $count min';
  }

  @override
  String commentHoursAgo(int count) {
    return 'ante $count h';
  }

  @override
  String get commentEdit => 'Muta';

  @override
  String get commentDelete => 'Dele';

  @override
  String get slashLinkedTask => 'Pensum/nota annexa';

  @override
  String get slashAttachment => 'Adiunctum';

  @override
  String get menuExport => 'Exporta';

  @override
  String get menuPrint => 'Imprime';

  @override
  String get exportMarkdown => 'Markdown';

  @override
  String get exportPlainText => 'Textus purus';

  @override
  String get exportCopy => 'Exscribe';

  @override
  String get attachmentOpenExternal => 'In applicatione systematis aperi';

  @override
  String get exportDownload => 'Deprome';

  @override
  String get navCountdown => 'Dinumeratio';

  @override
  String get countdownActive => 'Activa';

  @override
  String get countdownArchived => 'In tabulario';

  @override
  String get countdownArchivedTitle => 'Dinumerationes in tabulario';

  @override
  String get countdownShowGroup => 'Catervam ostende';

  @override
  String get countdownTypeCountdown => 'Dinumeratio';

  @override
  String get countdownTypeSpecial => 'Dies insignis';

  @override
  String get countdownTypeBirthday => 'Dies natalis';

  @override
  String get countdownTypeHoliday => 'Dies festus';

  @override
  String countdownToday(String date) {
    return 'Hodie $date';
  }

  @override
  String countdownDaysUntil(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Dies usque ad $date', one: 'Dies usque ad $date');
    return '$_temp0';
  }

  @override
  String countdownDaysSince(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Dies ex $date', one: 'Dies ex $date');
    return '$_temp0';
  }

  @override
  String countdownAge(int age) {
    return '$age anni';
  }

  @override
  String countdownDaysAway(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Post $count dies', one: 'Cras', zero: 'Hodie');
    return '$_temp0';
  }

  @override
  String get countdownName => 'Nomen';

  @override
  String get countdownDate => 'Dies';

  @override
  String get countdownType => 'Genus';

  @override
  String get countdownCountMode => 'Modus dierum numerandorum';

  @override
  String get countModeStandard => 'Usitatus';

  @override
  String get countModeStandardHint => 'Dies primus postridie diei electi incipit';

  @override
  String get countModePlusOne => 'Usitatus +1 dies';

  @override
  String get countModePlusOneHint => 'Dies primus ipso die electo incipit';

  @override
  String get countdownVisibility => 'In indice sollerti ostende';

  @override
  String get visibilityOnTheDay => 'Ipso die';

  @override
  String get visibilityThreeDays => 'Tribus diebus ante';

  @override
  String get visibilitySevenDays => 'Septem diebus ante';

  @override
  String get visibilityAlways => 'Semper ostende';

  @override
  String get visibilityNever => 'Noli ostendere';

  @override
  String get countdownIgnoreYear => 'Annum neglege';

  @override
  String get countdownShowAge => 'Aetatem ostende';

  @override
  String get actionNext => 'Proximum';

  @override
  String get actionBack => 'Redi';

  @override
  String get countdownStyle => 'Forma';

  @override
  String get countdownColor => 'Color';

  @override
  String get countdownEdit => 'Muta';

  @override
  String get countdownNotes => 'Notae';

  @override
  String get countdownArchive => 'In tabulario conde';

  @override
  String get countdownRestore => 'Restitue';

  @override
  String get countdownDelete => 'Dele';

  @override
  String get countdownPin => 'Affige';

  @override
  String get countdownUnpin => 'Refige';

  @override
  String get countdownEmpty => 'Nulla dinumeratio';

  @override
  String get countdownSeedUseApp => 'Ordine utere';

  @override
  String get countdownSeedWeekend => 'Finis hebdomadis';

  @override
  String get countdownSeedNewYear => 'Kalendae Ianuariae';

  @override
  String get countdownSpecialSuggestions =>
      'Anniversarium gradus academici\nAnniversarium laboris\nAnniversarium amoris\nDies petitionis nuptiarum\nDies licentiae nuptialis\nAnniversarium nuptiarum\nCentum dies una\nAnniversarium inscriptionis';

  @override
  String get navFocus => 'Attentio';

  @override
  String get focusTitle => 'Pomodoro';

  @override
  String get focusTabPomo => 'Pomo';

  @override
  String get focusTabStopwatch => 'Chronometrum';

  @override
  String get focusLink => 'Attentio';

  @override
  String get focusStart => 'Incipe';

  @override
  String get focusPause => 'Siste';

  @override
  String get focusContinue => 'Perge';

  @override
  String get focusEnd => 'Finis';

  @override
  String get focusPaused => 'Sistitur';

  @override
  String get focusNotes => 'Notae attentionis';

  @override
  String get focusNotesHint => 'Quid in animo habes? Cogitata tua nota…';

  @override
  String get focusDoneTitle => 'Pomum unum habes.';

  @override
  String focusDoneBody(int minutes) {
    return 'Quiesce $minutes minuta.';
  }

  @override
  String get focusRelax => 'Quiesce';

  @override
  String get focusSkip => 'Praeteri';

  @override
  String get focusExit => 'Exi';

  @override
  String get focusBreak => 'Intermissio';

  @override
  String get focusLongBreak => 'Intermissio longa';

  @override
  String get focusOverview => 'Conspectus';

  @override
  String get focusTodayPomos => 'Poma hodierna';

  @override
  String get focusTodayDuration => 'Attentio hodierna';

  @override
  String get focusTotalPomos => 'Poma omnia';

  @override
  String get focusTotalDuration => 'Duratio attentionis tota';

  @override
  String get focusRecords => 'Acta attentionis.';

  @override
  String get focusRecordsEmpty => 'Nondum acta attentionis.';

  @override
  String get focusDeleteAll => 'Omnia dele';

  @override
  String get focusAddRecord => 'Actum adde';

  @override
  String get focusSettings => 'Optiones attentionis';

  @override
  String get focusPomoLength => 'Duratio pomi';

  @override
  String get focusShortBreakLength => 'Duratio intermissionis brevis';

  @override
  String get focusLongBreakLength => 'Duratio intermissionis longae';

  @override
  String get focusLongEvery => 'Poma ante intermissionem longam';

  @override
  String get focusAutoPomo => 'Initium sponte: pomum proximum';

  @override
  String get focusAutoBreak => 'Initium sponte: intermissio';

  @override
  String focusMinutesValue(int count) {
    return '$count min';
  }

  @override
  String focusHours(int count) {
    return '${count}h';
  }

  @override
  String focusMins(int count) {
    return '${count}m';
  }

  @override
  String get focusStartFocus => 'Attentionem incipe';

  @override
  String get focusStartPomo => 'Pomum incipe';

  @override
  String get focusStartStopwatch => 'Chronometrum incipe';

  @override
  String get focusRecordStart => 'Initium';

  @override
  String get focusRecordEnd => 'Finis';

  @override
  String get focusNoTask => 'Sine penso';

  @override
  String get navHabit => 'Consuetudo';

  @override
  String get habitActive => 'Activa';

  @override
  String get habitArchived => 'In tabulario';

  @override
  String get habitEmptyTitle => 'Consuetudinem exerce';

  @override
  String get habitEmptyBody => 'Constantia nos splendere facit';

  @override
  String get habitArchivedEmptyTitle => 'Nulla consuetudo in tabulario';

  @override
  String get habitArchivedEmptyBody => 'Consuetudines in tabulario condere et postea restituere potes.';

  @override
  String get habitNew => 'Consuetudinem crea';

  @override
  String get habitEditTitle => 'Consuetudinem muta';

  @override
  String get habitNameHint => 'Professio cotidiana';

  @override
  String get habitFrequency => 'Frequentia';

  @override
  String get habitDaily => 'Cotidie';

  @override
  String get habitWeekly => 'Singulis hebdomadibus';

  @override
  String get habitInterval => 'Repete';

  @override
  String habitTimesPerWeek(int count) {
    return '$count vicibus in hebdomade';
  }

  @override
  String habitEveryDays(int count) {
    return 'Singulis $count diebus';
  }

  @override
  String get habitGoal => 'Propositum';

  @override
  String get habitGoalAll => 'Omnia perfice';

  @override
  String get habitGoalAmount => 'Certam quantitatem attinge';

  @override
  String get habitUnit => 'Unitas';

  @override
  String get habitUnitDefault => 'Numerus';

  @override
  String get habitPerDay => 'In dies';

  @override
  String get habitStep => 'Actum (numerus)';

  @override
  String get habitCheckMode => 'Cum notas';

  @override
  String get habitCheckAuto => 'Sponte';

  @override
  String get habitCheckManual => 'Manu';

  @override
  String get habitCheckAll => 'Omnia perfice';

  @override
  String get habitStartDate => 'Dies initii';

  @override
  String get habitTargetDays => 'Dies propositi';

  @override
  String get habitForever => 'In perpetuum';

  @override
  String habitDaysValue(int count) {
    return '$count dies';
  }

  @override
  String get habitSection => 'Sectio';

  @override
  String get habitSectionMorning => 'Mane';

  @override
  String get habitSectionAfternoon => 'Post meridiem';

  @override
  String get habitSectionEvening => 'Vesperi';

  @override
  String get habitSectionOthers => 'Alia';

  @override
  String get habitReminder => 'Monitum';

  @override
  String get habitAutoLog => 'Commentarium consuetudinis sponte ostende';

  @override
  String habitSummary(int total, int streak) {
    String _temp0 = intl.Intl.pluralLogic(total, locale: localeName, other: '$total dies', one: '1 dies', zero: '0 dies');
    String _temp1 = intl.Intl.pluralLogic(streak, locale: localeName, other: '$streak dies', one: '1 dies', zero: '0 dies');
    return '$_temp0 · $_temp1';
  }

  @override
  String get habitLog => 'Commentarium consuetudinum';

  @override
  String get habitReset => 'Consuetudinem renova';

  @override
  String get habitSkip => 'Praeteri';

  @override
  String get habitFail => 'Imperfectum';

  @override
  String get habitLogPrompt => 'Notatum est! Quid in animo habes?';

  @override
  String get habitArchive => 'In tabulario conde';

  @override
  String get habitRestore => 'Consuetudinem resume';

  @override
  String get toastRestoredHabit => 'Resumpta';

  @override
  String get habitDelete => 'Dele';

  @override
  String get habitMonthRecords => 'Acta mensis';

  @override
  String get habitTotalCheckins => 'Notationes omnes';

  @override
  String get habitMonthRate => 'Ratio notationum mensis';

  @override
  String get habitStreak => 'Series praesens';

  @override
  String habitMonthLog(String month) {
    return 'Commentarium consuetudinis mense $month';
  }

  @override
  String get habitMonthLogEmpty => 'Hoc mense nondum cogitata notationum communicanda';

  @override
  String get habitIncrease => 'Auge';

  @override
  String get habitSettings => 'Optiones';

  @override
  String get habitShowInToday => 'In \"Hodie\" et \"Septem dies proximi\" ostende';

  @override
  String get habitSortByStatus => 'Per statum notationis ordina';

  @override
  String get habitFreeDay => 'Hic dies pensis vacat';

  @override
  String habitAmount(String value, String goal, String unit) {
    return '$value/$goal $unit';
  }

  @override
  String get habitDetailClose => 'Claude';

  @override
  String get navMatrix => 'Matrix Eisenhoweriana';

  @override
  String get matrixQ1 => 'Urgens et grave';

  @override
  String get matrixQ2 => 'Non urgens sed grave';

  @override
  String get matrixQ3 => 'Urgens sed non grave';

  @override
  String get matrixQ4 => 'Nec urgens nec grave';

  @override
  String get matrixEditTitle => 'Matricem muta';

  @override
  String get matrixRestore => 'Restitue';

  @override
  String get matrixHideCompleted => 'Perfecta cela';

  @override
  String get matrixShowCompleted => 'Perfecta ostende';

  @override
  String get matrixAll => 'Omnia';

  @override
  String get matrixName => 'Nomen';

  @override
  String get filterAddTitle => 'Filtrum adde';

  @override
  String get filterEditTitle => 'Filtrum muta';

  @override
  String get filterName => 'Nomen';

  @override
  String get filterNormal => 'Simplex';

  @override
  String get filterAdvanced => 'Provectum';

  @override
  String get filterFieldList => 'Indices';

  @override
  String get filterFieldTag => 'Pittacia';

  @override
  String get filterFieldDate => 'Dies';

  @override
  String get filterFieldPriority => 'Prioritas';

  @override
  String get filterFieldType => 'Genus';

  @override
  String get filterKeyword => 'Verbum clavis';

  @override
  String get filterKeywordHint => 'Titulus aut descriptio continet';

  @override
  String get filterIs => 'est';

  @override
  String get filterIsNot => 'non est';

  @override
  String get filterAnd => 'ET';

  @override
  String get filterOr => 'AUT';

  @override
  String get filterAddCondition => 'Condicionem adde';

  @override
  String get filterPreview => 'Praevisio';

  @override
  String filterPreviewCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pensa inventa',
      one: 'Unum pensum inventum',
      zero: 'Nullum pensum inventum',
    );
    return '$_temp0';
  }

  @override
  String get filterDateOverdue => 'Praeterita';

  @override
  String get filterDateToday => 'Hodie';

  @override
  String get filterDateTomorrow => 'Cras';

  @override
  String get filterDateThisWeek => 'Haec hebdomas';

  @override
  String get filterDateNextWeek => 'Hebdomas proxima';

  @override
  String get filterDateThisMonth => 'Hic mensis';

  @override
  String get filterDateNextMonth => 'Mensis proximus';

  @override
  String get filterDateNoDate => 'Sine die';

  @override
  String get filterSaveAs => 'Ut filtrum serva';

  @override
  String filterDeleteConfirm(Object name) {
    return 'Filtrum \"$name\" delere? Pensa intacta manebunt.';
  }

  @override
  String filterSaved(Object name) {
    return 'Filtrum \"$name\" factum';
  }

  @override
  String get navCalendar => 'Calendarium';

  @override
  String get calendarModeDay => 'Dies';

  @override
  String get calendarModeWeek => 'Hebdomas';

  @override
  String get calendarModeMonth => 'Mensis';

  @override
  String get calendarModeYear => 'Annus';

  @override
  String get calendarModeAgenda => 'Ordo rerum';

  @override
  String get calendarModeMultiDay => 'Plures dies';

  @override
  String get calendarModeMultiWeek => 'Plures hebdomades';

  @override
  String get calendarToday => 'Hodie';

  @override
  String get calendarAllDay => 'Totus dies';

  @override
  String get calendarNoon => 'Meridies';

  @override
  String get calendarArrange => 'Pensa dispone';

  @override
  String get calendarArrangeHint => 'Pensa sine die in calendarium trahe.';

  @override
  String get calendarArrangeEmpty => 'Nullum pensum sine die';

  @override
  String get calendarViewOptions => 'Optiones aspectus';

  @override
  String get calendarShowCompleted => 'Perfecta ostende';

  @override
  String get calendarShowChecklist => 'Res indicis inspectionis ostende';

  @override
  String get calendarShowRepeats => 'Cyclos futuros ostende';

  @override
  String get calendarShowHabits => 'Consuetudines ostende';

  @override
  String get calendarShowFocus => 'Acta attentionis ostende';

  @override
  String get calendarShowCountdowns => 'Dinumerationes ostende';

  @override
  String get calendarColorBy => 'Color per';

  @override
  String get calendarColorByList => 'Index';

  @override
  String get calendarColorByTag => 'Pittacium';

  @override
  String get calendarColorByPriority => 'Prioritas';

  @override
  String calendarMultiDays(Object count) {
    return '$count dies';
  }

  @override
  String calendarMultiWeeks(Object count) {
    return '$count hebdomades';
  }

  @override
  String get calendarListFilter => 'Filtrum indicum';

  @override
  String get calendarAgendaEmpty => 'Nullum pensum hoc spatio';

  @override
  String get calendarFocusRecord => 'Attentio';

  @override
  String calendarMore(Object count) {
    return '+$count';
  }

  @override
  String get timelineEmpty => 'Nullum pensum cum die.\nPreme regulam ut unum crees aut e tabula \"Pensa dispone\" trahe.';

  @override
  String get timelineArrangeHint => 'Pensa sine die. In regulam trahe.';

  @override
  String get shortcutViews => 'Aspectus Index / Kanban / Linea temporis';

  @override
  String get shortcutCalendarModes => 'Calendarium: Dies / Hebdomas / Mensis / Annus / Ordo rerum';

  @override
  String get activityTaskTitle => 'Acta pensi';

  @override
  String get activityListTitleDialog => 'Acta indicis';

  @override
  String get activityEmpty => 'Nondum ulla acta';

  @override
  String get activityCreated => 'Pensum creavisti';

  @override
  String get activityCompleted => 'Pensum perfecisti';

  @override
  String get activityReopened => 'Pensum rursus aperuisti';

  @override
  String get activityWontDo => 'Pensum ut omissum notavisti';

  @override
  String get activityDeleted => 'Pensum in quisquiliarium movisti';

  @override
  String get activityRestored => 'Pensum restituisti';

  @override
  String activityTitle(Object title) {
    return 'Titulum in \"$title\" mutavisti';
  }

  @override
  String get activityContent => 'Descriptionem mutavisti';

  @override
  String activityDate(Object date) {
    return 'Diem in $date mutavisti';
  }

  @override
  String get activityDateRemoved => 'Diem removisti';

  @override
  String activityPriority(Object priority) {
    return 'Prioritatem in $priority mutavisti';
  }

  @override
  String activityMoved(Object list) {
    return 'Pensum ad $list movisti';
  }

  @override
  String get activityRepeat => 'Repetitionem mutavisti';

  @override
  String get activityRepeatRemoved => 'Repetitionem removisti';

  @override
  String get activityListCreated => 'Indicem creavisti';

  @override
  String activityListTitle(Object name) {
    return 'Indicem \"$name\" nominavisti';
  }

  @override
  String get matrixGroupBy => 'Coniunge per';

  @override
  String get matrixSortBy => 'Ordina per';

  @override
  String get matrixOrder => 'Ordo';

  @override
  String get matrixByTime => 'Tempus';

  @override
  String get matrixByList => 'Index';

  @override
  String get matrixByPriority => 'Prioritas';

  @override
  String get matrixByTag => 'Pittacium';

  @override
  String get matrixByTitle => 'Titulus';

  @override
  String get matrixByNone => 'Nullum';

  @override
  String get matrixAscending => 'Ascendens';

  @override
  String get matrixDescending => 'Descendens';

  @override
  String get statsTitle => 'Statistica';

  @override
  String get statsOverview => 'Conspectus';

  @override
  String get statsTask => 'Pensum';

  @override
  String get statsFocus => 'Attentio';

  @override
  String get statsDone => 'Perfectum';

  @override
  String get statsTasksLabel => 'Pensa';

  @override
  String get statsCompletedLabel => 'Perfecta';

  @override
  String get statsListsLabel => 'Indices';

  @override
  String get statsDaysLabel => 'Dies';

  @override
  String get statsTodayCompletion => 'Perfectio hodierna';

  @override
  String get statsTotalCompletion => 'Perfectio tota';

  @override
  String get statsAchievement => 'Puncta mea meritorum';

  @override
  String statsLevel(Object level) {
    return 'Gradus $level';
  }

  @override
  String statsNextLevel(Object level, Object points) {
    return 'Desunt $points puncta ad gradum $level';
  }

  @override
  String get statsTopLevel => 'Gradus summus';

  @override
  String get statsCompletionCurve => 'Curva perfectionis recens';

  @override
  String get statsRateCurve => 'Curva rationis perfectionis recens';

  @override
  String get statsPomoCurve => 'Curva pomorum recens';

  @override
  String get statsFocusCurve => 'Curva durationis attentionis recens';

  @override
  String get statsHabitsWeek => 'Status consuetudinum hebdomadalis';

  @override
  String get statsNoHabits => 'Nondum ulla consuetudo';

  @override
  String get statsDaily => 'Cotidie';

  @override
  String get statsWeekly => 'Singulis hebdomadibus';

  @override
  String get statsMonthly => 'Singulis mensibus';

  @override
  String get statsTaskCompleted => 'Pensa perfecta';

  @override
  String get statsRate => 'Ratio perfectionis';

  @override
  String get statsVsDay => 'contra heri';

  @override
  String get statsVsWeek => 'contra hebdomadem superiorem';

  @override
  String get statsVsMonth => 'contra mensem superiorem';

  @override
  String get statsDistribution => 'Distributio rationis perfectionis';

  @override
  String get statsOnTime => 'Tempore perfecta';

  @override
  String get statsLate => 'Sero perfecta';

  @override
  String get statsUndone => 'Non perfecta';

  @override
  String get statsByCategory => 'Statistica perfectionis';

  @override
  String get statsByList => 'Index';

  @override
  String get statsByTag => 'Pittacium';

  @override
  String get statsByPriority => 'Prioritas';

  @override
  String get statsByTask => 'Pensum';

  @override
  String get statsFocusDetails => 'Singula';

  @override
  String get statsUnlinked => 'Sine nexu';

  @override
  String get statsTrends => 'Inclinationes';

  @override
  String statsDailyAverage(Object value) {
    return 'Media cotidiana: $value';
  }

  @override
  String get statsWeekTimeline => 'Linea temporis';

  @override
  String get statsMostFocused => 'Tempus attentissimum';

  @override
  String get statsYearGrid => 'Tabula annua';

  @override
  String get statsNoData => 'Nulla data hoc spatio';

  @override
  String get settingsTitle => 'Optiones';

  @override
  String get settingsAccount => 'Ratio';

  @override
  String get settingsFeatures => 'Facultates';

  @override
  String get settingsSmartLists => 'Index sollers';

  @override
  String get settingsAppearance => 'Species';

  @override
  String get settingsAbout => 'De applicatione';

  @override
  String get settingsLocalAccount => 'Ratio localis';

  @override
  String get settingsLocalAccountHint => 'Data tua in hoc solo instrumento manent, sine ratione et sine servitore.';

  @override
  String get settingsBackup => 'Tutela et restitutio';

  @override
  String get settingsBackupGenerate => 'Exemplar tutelae fac';

  @override
  String get settingsBackupImport => 'Exemplaria tutelae localia importa';

  @override
  String get featureHabitSettings => 'Optiones consuetudinum';

  @override
  String get featureCalendarHint => 'Sex aspectus calendarii';

  @override
  String get featureMatrixHint => 'Per gravitatem et urgentiam ordina';

  @override
  String get featureHabitHint => 'Consuetudines crea et sequere';

  @override
  String get featureFocus => 'Pomodoro';

  @override
  String get featureFocusHint => 'Horologium pomi aut chronometrum';

  @override
  String get featureCountdownHint => 'Omnis diei insignis memento';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsTheme => 'Thema';

  @override
  String get themeLight => 'Clarum';

  @override
  String get themeDark => 'Obscurum';

  @override
  String get themeSystem => 'Modum obscurum systematis sequere';

  @override
  String get settingsColorSeries => 'Series colorum';

  @override
  String get colorStandard => 'Usitata';

  @override
  String get colorSky => 'Caelum';

  @override
  String get colorTurquoise => 'Turcicus';

  @override
  String get colorTeal => 'Caeruleo-viridis';

  @override
  String get colorReed => 'Iuncus';

  @override
  String get colorYellow => 'Flavus';

  @override
  String get colorPinkPear => 'Roseum pirum';

  @override
  String get colorLilac => 'Syringa';

  @override
  String get colorEbony => 'Hebenus';

  @override
  String get colorNavy => 'Caeruleus obscurus';

  @override
  String get colorGrey => 'Cinereus';

  @override
  String get appearanceThemePresets => 'Species paratae';

  @override
  String get appearanceThemePresetsHint => 'Color, fundus et anguli simul; singula infra mutari possunt';

  @override
  String get appearanceWallpaper => 'Pictura fundi';

  @override
  String get backgroundTitle => 'Fundus';

  @override
  String get backgroundDefault => 'Usitatus (fasciculi vel Ordinis)';

  @override
  String get backgroundNone => 'Nullus';

  @override
  String get backgroundPicture => 'Imago';

  @override
  String get backgroundPickPicture => 'Imaginem elige';

  @override
  String get backgroundDim => 'Obscura';

  @override
  String get backgroundLighten => 'Clarifica';

  @override
  String get gradientDawn => 'Aurora';

  @override
  String get gradientSunset => 'Occasus';

  @override
  String get gradientOcean => 'Oceanus';

  @override
  String get gradientForest => 'Silva';

  @override
  String get gradientLavender => 'Lavandula';

  @override
  String get gradientNight => 'Nox';

  @override
  String get gradientPeach => 'Persicum';

  @override
  String get gradientMint => 'Mentha';

  @override
  String get presetStandard => 'Usitata';

  @override
  String get presetStudies => 'Studia';

  @override
  String get presetWork => 'Labor';

  @override
  String get presetNight => 'Nox';

  @override
  String get presetNature => 'Natura';

  @override
  String get presetBeach => 'Litus';

  @override
  String get presetCozy => 'Tepor';

  @override
  String get settingsDisplay => 'Ostensio';

  @override
  String get settingsSidebarCount => 'Numerus in tabula laterali';

  @override
  String get sidebarCountAll => 'Ostende (omnia)';

  @override
  String get sidebarCountHideNotes => 'Ostende (notas cela)';

  @override
  String get sidebarCountNone => 'Cela (omnia)';

  @override
  String get settingsCompletedStyle => 'Forma pensi perfecti';

  @override
  String get completedStyleDefault => 'Usitata';

  @override
  String get completedStyleStrike => 'Expuncta';

  @override
  String aboutVersion(Object version) {
    return 'Versio $version';
  }

  @override
  String get aboutText =>
      'Ordo (antea Tarefas appellatus) est applicatio privata modo TickTick, Flutter facta ad Windows et Android. Omnia in hoc instrumento servantur; \"Exemplar tutelae fac\" adhibe ut data tua alio feras.';

  @override
  String get settingsMore => 'Optiones plures';

  @override
  String get settingsSmartRecognition => 'Agnitio sollers';

  @override
  String get settingsRecognizeDates => 'Agnitio dierum';

  @override
  String get settingsRecognizeDatesHint => 'Diem et horam in titulo agnoscit et in penso adhibet';

  @override
  String get settingsRemoveDateText => 'Textus e pensis remove';

  @override
  String get settingsRemoveDateTextHint => 'Diem agnitum e titulo aufert';

  @override
  String get settingsTagRecognition => 'Agnitio pittaciorum';

  @override
  String get tagTextRemove => 'E titulo remove';

  @override
  String get tagTextKeep => 'In titulo serva';

  @override
  String get settingsTaskDefaults => 'Pensa usitata';

  @override
  String get settingsDefaultDate => 'Dies usitatus';

  @override
  String get defaultDateNone => 'Nullus';

  @override
  String get defaultDateDayAfter => 'Perendie';

  @override
  String get settingsDefaultTimedReminder => 'Monitum usitatum, pensum cum hora';

  @override
  String get settingsDefaultAllDayReminder => 'Monitum usitatum, pensum totius diei';

  @override
  String get reminderNoneOption => 'Nullum';

  @override
  String get settingsDefaultPriority => 'Prioritas usitata';

  @override
  String get settingsDefaultList => 'Index usitatus';

  @override
  String get settingsNewTaskPosition => 'Novum pensum adde';

  @override
  String get positionTopOfList => 'In capite indicis';

  @override
  String get positionEndOfList => 'In fine indicis';

  @override
  String get settingsOverduePosition => 'Locus sectionis \"Praeterita\"';

  @override
  String get positionTop => 'Caput';

  @override
  String get positionEnd => 'Finis';

  @override
  String get settingsResetDefaults => 'Usitata restitue';

  @override
  String get settingsTemplates => 'Exemplaria pensorum';

  @override
  String get settingsTemplatesHint => 'Exemplar elige ut pensum in indice usitato crees';

  @override
  String get settingsDateTime => 'Dies et hora';

  @override
  String get settingsTimeFormat => 'Forma horae';

  @override
  String get timeFormat24 => '24 horae (13:00)';

  @override
  String get timeFormat12 => '12 horae (1:00 PM)';

  @override
  String get settingsWeekStart => 'Dies initii hebdomadis';

  @override
  String get settingsWeekNumbers => 'Numeros hebdomadum ostende';

  @override
  String get settingsWeekNumbersHint => 'In mense et pluribus hebdomadibus calendarii';

  @override
  String weekNumber(Object number) {
    return 'H$number';
  }

  @override
  String get settingsShortcuts => 'Compendia';

  @override
  String get shortcutFocusToggle => 'Attentionem incipe/siste';

  @override
  String get smartSummary => 'Summarium';

  @override
  String get summaryEmpty => 'Nullum pensum his filtris inveniri potest.';

  @override
  String get summaryCompleted => 'Perfectum';

  @override
  String get summaryWontDo => 'Non fiet';

  @override
  String get summaryInProgress => 'In cursu';

  @override
  String get summaryUndone => 'Infectum';

  @override
  String get summaryIncomplete => 'Imperfectum';

  @override
  String get summaryNotCompleted => 'Non perfecta';

  @override
  String summaryParent(Object title) {
    return 'in $title';
  }

  @override
  String get summaryTemplates => 'Exemplar';

  @override
  String get summarySaveTemplate => 'Ut exemplar serva';

  @override
  String get summaryTemplateName => 'Nomen exemplaris';

  @override
  String get summaryFilter => 'Filtrum';

  @override
  String get summaryDisplay => 'Optiones ostensionis';

  @override
  String get summaryByStatus => 'Per statum perfectionis';

  @override
  String get summaryByList => 'Per indicem';

  @override
  String get summaryByCompletionDate => 'Per diem perfectionis';

  @override
  String get summaryByTaskDate => 'Per diem pensi';

  @override
  String get summaryByTag => 'Per pittacium';

  @override
  String get summaryByPriority => 'Per prioritatem';

  @override
  String get summaryFieldStatus => 'Status';

  @override
  String get summaryFieldProgress => 'Progressus';

  @override
  String get summaryFieldCompletionTime => 'Tempus perfectionis';

  @override
  String get summaryFieldTaskTime => 'Tempus pensi';

  @override
  String get summaryFieldParent => 'Pensum parens';

  @override
  String get summaryFieldTag => 'Pittacium';

  @override
  String get summaryFieldList => 'Index';

  @override
  String get summaryFieldDetail => 'Singula';

  @override
  String get summaryNextPeriod => 'Pensa spatii proximi';

  @override
  String get summaryCopy => 'Exscribe';

  @override
  String get summarySavePdf => 'Ut PDF serva';

  @override
  String get shortcutGoClosed => 'Perfecta / Non fient / Summarium / Quisquiliarium';

  @override
  String get habitExport => 'Exporta';

  @override
  String get habitExported => 'Consuetudines exportatae';

  @override
  String get habitExportHabit => 'Consuetudo';

  @override
  String get habitExportDate => 'Dies';

  @override
  String get habitExportValue => 'Valor';

  @override
  String get habitExportGoal => 'Propositum';

  @override
  String get habitExportUnit => 'Unitas';

  @override
  String get habitExportStatus => 'Status';

  @override
  String get habitExportMood => 'Animus';

  @override
  String get habitExportNote => 'Nota';

  @override
  String get habitExportDone => 'Perfectum';

  @override
  String get habitExportPartial => 'Ex parte';

  @override
  String get habitExportSkipped => 'Praeteritum';

  @override
  String get habitExportFailed => 'Non attactum';

  @override
  String get focusLinkTask => 'Pensum elige…';

  @override
  String get focusUnlink => 'Nexum remove';

  @override
  String get focusTimers => 'Horologia';

  @override
  String get focusTimersEmpty => 'Compendia attentionis cum nomine, modo et duratione crea.';

  @override
  String get focusTimerAdd => 'Horologium adde';

  @override
  String get focusTimerEdit => 'Horologium muta';

  @override
  String get focusTimerName => 'Nomen horologii';

  @override
  String focusTimerTotal(Object duration) {
    return 'Summa $duration';
  }

  @override
  String get settingsImports => 'Coniunctiones et importatio';

  @override
  String get importSection => 'Importa';

  @override
  String get importTickTick => 'Exemplar tutelae TickTick (.csv)';

  @override
  String get importTickTickHint =>
      'In TickTick: Optiones → Ratio → Tutela et restitutio → Exemplar fac. Fasciculos, indices, sectiones, pittacia, subpensa, indices inspectionis et perfecta affert.';

  @override
  String get importIcal => 'Plica iCal (.ics)';

  @override
  String get importIcalHint => 'Pensa (VTODO) et eventa (VEVENT) pensa fiunt, cum diebus, monitis, repetitione et categoriis ut pittaciis.';

  @override
  String get importIcalList => 'In indicem importa';

  @override
  String importConfirm(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pensa importare?', one: 'Unum pensum importare?');
    return '$_temp0';
  }

  @override
  String get importAction => 'Importa';

  @override
  String importDone(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pensa importata', one: 'Unum pensum importatum');
    return '$_temp0';
  }

  @override
  String get importNothing => 'Nullum pensum in plica inventum';

  @override
  String get importInvalidBackup => 'Haec plica exemplar tutelae TickTick non videtur';

  @override
  String get importInvalidIcal => 'Haec plica calendarium iCal non videtur';

  @override
  String get subscriptionsTitle => 'Calendaria subscripta';

  @override
  String get subscriptionHolidaysName => 'Dies festi Brasiliae';

  @override
  String get subscriptionHolidaysHint => 'Dies festi nationales et liberi, in instrumento computati';

  @override
  String get subscriptionAddHolidays => 'Dies festos Brasiliae adde';

  @override
  String get subscriptionAddUrl => 'Per URL subscribe (.ics)';

  @override
  String get subscriptionUrl => 'Inscriptio calendarii';

  @override
  String get subscriptionName => 'Nomen';

  @override
  String get subscriptionSubscribe => 'Subscribe';

  @override
  String get subscriptionAdded => 'Calendarium subscriptum';

  @override
  String get subscriptionUpdated => 'Calendarium renovatum';

  @override
  String get subscriptionFailed => 'Calendarium deprompi non potuit';

  @override
  String get subscriptionRefresh => 'Renova';

  @override
  String get subscriptionNeverFetched => 'Nondum depromptum';

  @override
  String subscriptionFetched(Object when) {
    return 'Renovatum: $when';
  }

  @override
  String get emojiSearch => 'Emoji quaere';

  @override
  String get emojiPeople => 'Homines et corpus';

  @override
  String get emojiNature => 'Natura';

  @override
  String get emojiFood => 'Cibus';

  @override
  String get emojiActivities => 'Actiones';

  @override
  String get emojiTravel => 'Iter';

  @override
  String get emojiObjects => 'Res';

  @override
  String get emojiSymbols => 'Signa';

  @override
  String get emojiFlags => 'Vexilla';

  @override
  String get emojiResults => 'Eventus';

  @override
  String get emojiRandom => 'Fortuitum';

  @override
  String get emojiReset => 'Restitue';

  @override
  String shortcutGoTo(Object name) {
    return 'I ad $name';
  }

  @override
  String shortcutViewAs(Object name) {
    return 'Aspectus $name';
  }

  @override
  String get shortcutNone => 'Sine compendio';

  @override
  String get shortcutEditHint => 'Preme actionem ut compendium mutes.';

  @override
  String get shortcutRestoreAll => 'Restitue';

  @override
  String shortcutRecordTitle(Object name) {
    return 'Compendium: $name';
  }

  @override
  String get shortcutRecordHint => 'Claves preme (Tab tene pro Tab+clave). Esc omittit.';

  @override
  String get shortcutSequence => 'Duae claves deinceps (ex.: G → T)';

  @override
  String get shortcutRemove => 'Remove';

  @override
  String shortcutConflict(Object name) {
    return 'Compendium a \"$name\" ablatum est';
  }

  @override
  String get searchInArchived => 'In tabulario quaere';

  @override
  String get searchActiveLists => 'Ad indices activos redi';

  @override
  String searchArchivedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in indicibus in tabulario',
      one: 'Unum in indicibus in tabulario',
      zero: 'Nihil in indicibus in tabulario',
    );
    return '$_temp0';
  }

  @override
  String get activityPinned => 'Pensum affixisti';

  @override
  String get activityUnpinned => 'Pensum refixisti';

  @override
  String activityParent(Object title) {
    return 'Pensum intra \"$title\" posuisti';
  }

  @override
  String get activityParentRemoved => 'Pensum e penso parente eduxisti';

  @override
  String activityTags(Object tags) {
    return 'Pittacia in $tags mutavisti';
  }

  @override
  String get activityTagsRemoved => 'Pittacia removisti';

  @override
  String countdownUnitWeeks(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'hebdomades', one: 'hebdomas');
    return '$_temp0';
  }

  @override
  String countdownUnitMonths(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'menses', one: 'mensis');
    return '$_temp0';
  }

  @override
  String countdownUnitYears(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'anni', one: 'annus');
    return '$_temp0';
  }

  @override
  String get countdownIcon => 'Icon';

  @override
  String get countdownImage => 'Imago fundi';

  @override
  String get countdownImagePick => 'Imaginem elige';

  @override
  String get countdownImageRemove => 'Imaginem remove';

  @override
  String get colorCustom => 'Color proprius';

  @override
  String get colorHue => 'Tinctura';

  @override
  String get colorLightness => 'Lux';

  @override
  String get summarySaveImage => 'Ut imaginem serva';

  @override
  String get summaryImageSaved => 'Imago servata';

  @override
  String get reminderAtEnd => 'In fine';

  @override
  String get settingsDefaultDuration => 'Duratio usitata, pensum cum hora';

  @override
  String get settingsListColor => 'Color indicis';

  @override
  String get calendarShowLists => 'Indices a latere ostende';

  @override
  String get statsMedals => 'Numismata';

  @override
  String get medalPerseverance => 'Perseverantia';

  @override
  String get medalGetThingsDone => 'Res perfice';

  @override
  String get medalMindfulness => 'Mens attenta';

  @override
  String get medalSelfDiscipline => 'Disciplina sui';

  @override
  String get medalLocked => 'Clausum';

  @override
  String get medalMinutes => 'min attentionis';

  @override
  String get medalCheckins => 'notationes';

  @override
  String get focusLess5 => '−5 minuta';

  @override
  String get focusMore5 => '+5 minuta';

  @override
  String get focusExtraTime => 'Tempus additum adde';

  @override
  String get focusEditDuration => 'Durationem attentionis muta';

  @override
  String get focusMinutesSuffix => 'minuta';

  @override
  String get calendarStyle => 'Forma';

  @override
  String get calendarStyleModern => 'Recens';

  @override
  String get calendarStyleClassic => 'Classica';

  @override
  String get calendarShowIcons => 'Icones ostende';

  @override
  String get calendarTimeZones => 'Zonae horariae additae';

  @override
  String get calendarAddTimeZone => 'Zonam horariam adde';

  @override
  String get calendarSearchTimeZone => 'Urbem aut zonam quaere';

  @override
  String get summaryFieldFocus => 'Data attentionis';

  @override
  String get summarySendEmail => 'Epistulam electronicam mitte';

  @override
  String get summaryNoMailApp => 'Nulla applicatio epistularum inventa. Textus exscriptus est.';

  @override
  String get settingsTimeZone => 'Zona horaria';

  @override
  String get settingsTimeZoneHint => 'Zonam elige cum horam pensi statuis';

  @override
  String get pickerTimeZone => 'Zona horaria';

  @override
  String get zoneFixed => 'Zona horaria fixa';

  @override
  String get zoneChoose => 'Elige';

  @override
  String get zoneFloating => 'Tempus fluitans';

  @override
  String get zoneFloatingHint => 'Cum zona horaria mutatur, tempus idem manet.';

  @override
  String get focusEstimate => 'Aestimatio';

  @override
  String get estimatePomos => 'Poma aestimata';

  @override
  String get estimateDuration => 'Duratio aestimata';

  @override
  String estimatePomoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count poma', one: 'Unum pomum');
    return '$_temp0';
  }

  @override
  String get estimateFocused => 'Attentio in';

  @override
  String get focusFocusing => 'Attendens';

  @override
  String get focusTimersArchivedEmpty => 'Nullum horologium in tabulario';

  @override
  String get focusSound => 'Sonus pomi';

  @override
  String get focusSoundStandard => 'Usitatus';

  @override
  String get focusSoundAlarm => 'Excitatorium';

  @override
  String get focusSoundReminder => 'Monitum';

  @override
  String get focusSoundMessage => 'Nuntius';

  @override
  String get focusSoundSilent => 'Tacitus';

  @override
  String get notificationSilentChannelName => 'Finis pomi tacitus';

  @override
  String get focusTimeInTitle => 'Tempus currens in titulo fenestrae';

  @override
  String get sectionInsertAbove => 'Sectionem supra insere';

  @override
  String get sectionInsertBelow => 'Sectionem infra insere';

  @override
  String get slashSubtask => 'Subpensum';

  @override
  String get slashTag => 'Pittacium';

  @override
  String get slashTemplate => 'Ex exemplari adde';

  @override
  String get closedAllDates => 'Omnes dies';

  @override
  String get closedOtherMonth => 'Alius mensis';

  @override
  String get closedAllLists => 'Omnes indices';

  @override
  String get orderLabel => 'Ordo';

  @override
  String get orderAscending => 'Ascendens';

  @override
  String get orderDescending => 'Descendens';

  @override
  String get optionList => 'Index';

  @override
  String get matrixExamples => 'Exempla';

  @override
  String get matrixPresetPriority => 'Sola prioritas';

  @override
  String get matrixPresetTime => 'Tempus + prioritas';

  @override
  String get formatBar => 'Forma';

  @override
  String get formatHeading => 'Titulus';

  @override
  String get formatBold => 'Crassum';

  @override
  String get formatItalic => 'Obliquum';

  @override
  String get formatUnderline => 'Sublineatum';

  @override
  String get formatStrikethrough => 'Expunctum';

  @override
  String get formatTime => 'Tempus';

  @override
  String get formatLink => 'Nexus';

  @override
  String get formatCode => 'Codex';

  @override
  String get countdownDirection => 'Modus numerandi';

  @override
  String get countdownDirectionDown => 'Dinumeratio';

  @override
  String get countdownDirectionUp => 'Chronometrum';

  @override
  String get reminderConstant => 'Monitum perpetuum';

  @override
  String get templateNotesTitle => 'Exemplar notae';

  @override
  String get templateWeeklyReviewName => 'Recognitio hebdomadalis';

  @override
  String get templateWeeklyReviewContent =>
      '## Quae hac hebdomade perfeci\n\n## Quae relicta sunt et cur\n\n## Res primae hebdomadis proximae\n\n## Cogitationes';

  @override
  String get templateReadingName => 'Nota lectionis';

  @override
  String get templateReadingContent => '**Titulus libri:** \n\n**Auctor:** \n\n**Summa sententiae:** ';

  @override
  String get templateMeetingName => 'Nota conventus';

  @override
  String get templateMeetingContent => '**Argumentum:** \n\n**Tempus:** \n\n**Participes:** \n\n**Proposita conventus:** ';

  @override
  String get noteInfo => 'Informatio';

  @override
  String get noteWords => 'Verba';

  @override
  String get noteCharacters => 'Litterae';

  @override
  String get noteCreated => 'Creatum';

  @override
  String get noteModified => 'Mutatum';

  @override
  String get habitAddSection => 'Sectionem adde';

  @override
  String get habitYearHeatmap => 'Tabula anni';

  @override
  String get settingsDateFormat => 'Forma diei';

  @override
  String get settingsDefaultTag => 'Pittacium usitatum';

  @override
  String get settingsParseUrls => 'Analysis URL';

  @override
  String get settingsParseUrlsHint => 'Titulus qui solum nexus est titulus paginae fit (paginam in interreti legit)';

  @override
  String get settingsMiniCalendar => 'Calendariolum';

  @override
  String get settingsMiniCalendarHint => 'In tabula laterali ostende';

  @override
  String get copyOpenOnly => 'Sola pensa imperfecta';

  @override
  String get copyKeepStatus => 'Omnia pensa, statu perfectionis servato';

  @override
  String get copyAllReopened => 'Omnia pensa, sine statu perfectionis';

  @override
  String get addAsNote => 'In notam converte';

  @override
  String get detailLayout => 'Dispositio singulorum pensi';

  @override
  String get detailLayoutPanel => 'Tabula lateralis';

  @override
  String get detailLayoutPopup => 'Fenestra emergens';

  @override
  String get focusBatch => 'Administratio catervatim';

  @override
  String get focusExport => 'Exporta';

  @override
  String get focusExported => 'Acta exportata';

  @override
  String get focusExportStart => 'Initium';

  @override
  String get focusExportEnd => 'Finis';

  @override
  String get focusExportMinutes => 'Minuta';

  @override
  String get focusExportMode => 'Modus';

  @override
  String get focusExportLinked => 'Annexum ad';

  @override
  String get focusExportTimer => 'Horologium';

  @override
  String get focusExportNote => 'Nota';

  @override
  String get focusFilterDate => 'Dies';

  @override
  String get focusFilterLength => 'Duratio';

  @override
  String get focusFilterLinked => 'Status nexus';

  @override
  String get focusLengthShort => 'Minus quam 25m';

  @override
  String get focusLengthLong => '25m aut plus';

  @override
  String get focusLinked => 'Annexum';

  @override
  String get focusUnlinked => 'Non annexum';

  @override
  String focusDeleteSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count acta delere?', one: 'Unum actum delere?');
    return '$_temp0';
  }

  @override
  String get focusTimerAddRecord => 'Actum adde';

  @override
  String get timerFocusedDays => 'Dies attenti';

  @override
  String get timerTotal => 'Attentio tota';

  @override
  String timerDailyAverage(String duration) {
    return 'Media cotidiana: $duration';
  }

  @override
  String get suggestedTasks => 'Pensa suggesta tempta';

  @override
  String get suggestedUpcoming => 'Dies proximi';

  @override
  String get suggestedAddToday => 'Ad Hodie adde';

  @override
  String get suggestedEmpty => 'Nulla suggestio interim';

  @override
  String get habitGallery => 'Pinacotheca consuetudinum';

  @override
  String get habitCreateNew => 'Novam crea';

  @override
  String get habitCardView => 'Aspectus chartarum';

  @override
  String get habitListView => 'Aspectus indicis';

  @override
  String get habitGalleryLife => 'Vita';

  @override
  String get habitGalleryHealth => 'Valetudo';

  @override
  String get habitGalleryExercise => 'Exercitatio';

  @override
  String get habitGalleryMind => 'Mens';

  @override
  String get habitGalleryLifeItems =>
      '🌅 Mane surgere\n🛏️ Lectum sternere\n🧹 Domum componere\n🪴 Plantas rigare\n🍳 Domi coquere\n💰 Sumptus notare\n📵 Minus telephono uti\n📞 Familiam vocare\n🧺 Vestes lavare\n🛒 Emptiones parare\n🐶 Canem ambulare\n📬 Receptaculum exinanire\n🌙 Ante horam XXIII dormire\n🗓️ Diem disponere\n🎁 Benigne facere';

  @override
  String get habitGalleryHealthItems =>
      '💧 Aquam bibere\n🥗 Acetaria edere\n🍎 Pomum edere\n💊 Vitamina sumere\n🦷 Filo dentes purgare\n🚭 Non fumare\n🍬 Minus sacchari\n☕ Minus coffeae\n😴 Octo horas dormire\n🧴 Cutem curare\n🥛 Ientare\n🚰 Sine potionibus dulcibus\n🧘 Membra extendere\n👀 Oculos quiescere\n🍷 Sine vino';

  @override
  String get habitGalleryExerciseItems =>
      '🏃 Currere\n🚶 Triginta minuta ambulare\n👟 Decem milia passuum\n🏋️ Pondera tollere\n🚴 Birota vehi\n🏊 Natare\n🧘 Yoga\n🤸 Exercitationes ventris\n💪 Inclinationes bracchiorum\n⛹️ Ludum exercere\n🪜 Scalis uti\n🥊 Exercitatio functionalis\n🕺 Saltare\n🧗 Scandere\n🤾 Fune salire';

  @override
  String get habitGalleryMindItems =>
      '📚 Legere\n🧘 Meditari\n✍️ In commentario scribere\n🙏 Gratias agere\n🗣️ Linguam discere\n🎹 Instrumento canere\n🎨 Delineare\n🧩 Aliquid novi discere\n📝 Diem recognoscere\n🎧 Podcastum audire\n🌳 Tempus in natura\n🤔 Cogitare\n📖 Ante somnum legere\n🧠 Exercitatio memoriae\n😊 Subridere';

  @override
  String get toastUndone => 'Revocatum';

  @override
  String get toastRedone => 'Iteratum';

  @override
  String get shortcutUndo => 'Revoca';

  @override
  String get shortcutRedo => 'Itera';

  @override
  String get addFieldSimple => 'Forma: simplex';

  @override
  String get addFieldDetailed => 'Forma: accurata';

  @override
  String get addFieldAdd => 'Adde';

  @override
  String get formatImmersive => 'Scriptio immersa';

  @override
  String get paletteModules => 'Moduli';

  @override
  String get paletteFolders => 'Fasciculi';

  @override
  String get shortcutCalendarToday => 'Calendarium: ad hodie redi';

  @override
  String get menuAttach => 'Adiunctum onera';

  @override
  String countdownMinutesShort(int count) {
    return '$count M';
  }

  @override
  String countdownHoursShort(int count) {
    return '$count H';
  }

  @override
  String get repeatSkipWeekends => 'Fines hebdomadum praeteri';

  @override
  String get countdownNoteHint => 'Notam adde…';

  @override
  String get settingsInterfaceStyle => 'Forma interfaciei';

  @override
  String get interfaceFlat => 'Plana';

  @override
  String get interfaceCard => 'Charta';

  @override
  String get summaryToNote => 'In notam insere';

  @override
  String get summaryNoteCreated => 'Nota facta';

  @override
  String matrixSwapWith(String name) {
    return 'Locum cum \"$name\" muta';
  }

  @override
  String get habitMottoHint => 'Sententia hortatoria (ad libitum)';

  @override
  String get calendarHideBefore => 'Horas ante (h) cela';

  @override
  String get calendarHideAfter => 'Horas ab (h) cela';

  @override
  String get countdownIconText => 'Textus';

  @override
  String get countdownIconTextHint => 'Unam litteram scribe';

  @override
  String get helpHome => 'Pagina prima';

  @override
  String get helpAbout => 'De Ordine';

  @override
  String get commentImage => 'Imago';

  @override
  String get toastConverted => 'Conversum';

  @override
  String get quickAddModalHint => 'Quid facere vis?';

  @override
  String get summaryAllLists => 'Omnes indices';

  @override
  String get summaryAllStatuses => 'Omnes status';

  @override
  String get summaryAllTags => 'Omnia pittacia';

  @override
  String get summaryAllPriorities => 'Omnes prioritates';

  @override
  String get focusEndBreak => 'Fini';

  @override
  String get habitSortByStatusHint => 'Consuetudines non notatae in capite indicis ostendentur';

  @override
  String get tagMergeTitle => 'Pittacia confunde';

  @override
  String tagMergeExplain(String name) {
    return 'Pensa pittacii \'$name\' cum alio pittacio confundere potes. Post confusionem pittacium \'$name\' delebitur.';
  }

  @override
  String get actionConfirm => 'Confirma';

  @override
  String get kanbanOverdue => 'Praeterita';

  @override
  String get linkPickerHint => 'Quaere';

  @override
  String get linkPickerEmptyTitle => 'Nulla pensa';

  @override
  String get linkPickerEmptyBody => 'Indices muta aut quaere';

  @override
  String get countdownHideGroup => 'Catervam cela';

  @override
  String get countdownAll => 'Omnes';

  @override
  String get summaryFieldTitle => 'Titulus pensi';

  @override
  String get summarySaveTemplateHint => 'Dispositionem praesentem ut exemplar serva, ut postea celeriter eligas.';

  @override
  String get countdownIconEvent => 'Eventus';

  @override
  String get countdownIconPerson => 'Persona';

  @override
  String get countdownIconParty => 'Convivia';

  @override
  String get countdownIconSport => 'Ludus';

  @override
  String get countdownIconAnimal => 'Animal';

  @override
  String get settingsAutoBackup => 'Exemplaria tutelae sponte facta';

  @override
  String get settingsAutoBackupHint =>
      'Exemplar unum in dies pensorum et optionum, in hoc instrumento servatum. Septem recentissima manent. Adiuncta in eo non sunt et ubi sunt manent.';

  @override
  String get autoBackupNone => 'Nondum ullum exemplar tutelae sponte factum.';

  @override
  String get autoBackupRestore => 'Restitue';

  @override
  String get countdownIconBackground => 'Color fundi';

  @override
  String get calendarShowWeekends => 'Fines hebdomadum ostende';

  @override
  String get calendarDimPast => 'Eventa praeterita obscura';

  @override
  String dateFull(String weekday, int day, String month, int year) {
    return '$weekday, $day $month $year';
  }

  @override
  String calendarDayOfTotal(int day, int total) {
    return '(Dies $day/$total)';
  }

  @override
  String get calendarCreate => 'Crea';

  @override
  String get calendarMyCalendars => 'Calendaria mea';

  @override
  String get calendarOtherCalendars => 'Alia calendaria';

  @override
  String get calendarShowOnly => 'Hoc solum ostende';

  @override
  String get calendarAddOther => 'Alia calendaria adde';

  @override
  String get calendarTogglePanel => 'Tabulam ostende aut cela';

  @override
  String get calendarAddTitle => 'Titulum adde';

  @override
  String get calendarKindTask => 'Pensum';

  @override
  String get calendarKindNote => 'Nota';

  @override
  String get calendarAddDescription => 'Descriptionem adde';

  @override
  String get calendarNoRepeat => 'Non repetitur';

  @override
  String get calendarMoreOptions => 'Optiones plures';

  @override
  String get calendarNoDate => 'Sine die';

  @override
  String get calendarNoReminder => 'Sine monito';

  @override
  String get ordinalsFeminine => 'primo,secundo,tertio,quarto';

  @override
  String get ordinalsMasculine => 'primo,secundo,tertio,quarto';

  @override
  String get lastFeminine => 'ultimo';

  @override
  String get lastMasculine => 'ultimo';

  @override
  String repeatMonthlyOn(String when) {
    return 'Singulis mensibus $when';
  }

  @override
  String get calendarDetails => 'Singula';

  @override
  String get calendarAddReminder => 'Monitum adde';

  @override
  String get insightsTitle => 'Perspectus temporis';

  @override
  String get insightsMore => 'Plures perspectus';

  @override
  String get insightsBreakdown => 'Partitio temporis';

  @override
  String get insightsByList => 'Index';

  @override
  String get insightsByTag => 'Pittacium';

  @override
  String get insightsByKind => 'Genus';

  @override
  String get insightsPerDay => 'Horae in dies';

  @override
  String get insightsNoTag => 'Sine pittacio';

  @override
  String get insightsTasks => 'Pensa';

  @override
  String get insightsTotal => 'in summa';

  @override
  String get insightsEmpty => 'Nihil hora statuta hoc spatio.';

  @override
  String insightsScheduled(String hours) {
    return '$hours hora statuta';
  }

  @override
  String get eventColorNames =>
      'Flos cerasi,Lycopersicum,Malum aureum,Cucurbita,Mangifera,Musa,Citrus,Persea,Pistacium,Ocimum,Salvia,Eucalyptus,Pavo,Vaccinium,Lavandula,Wisteria,Amethystus,Uva,Cacao,Betula,Graphites';

  @override
  String get colorLabelsEdit => 'Titulos colorum muta';

  @override
  String get colorLabelsHint => 'Coloribus nomina da: in perspectu temporis, pensa cuiusque coloris hoc nomine apparent.';

  @override
  String get colorLabelsColor => 'Color';

  @override
  String get colorLabelsName => 'Nomen tituli';

  @override
  String get colorLabelsAdd => 'Titulum adde';

  @override
  String get colorDefault => 'Usitatus';

  @override
  String get colorOfTask => 'Color pensi';

  @override
  String get insightsByLabel => 'Titulus';

  @override
  String get insightsNoLabel => 'Sine titulo';

  @override
  String get recurrenceTitle => 'Repetitio ad libitum';

  @override
  String get recurrenceEvery => 'Repete singulis';

  @override
  String get recurrenceOn => 'Repete die';

  @override
  String get recurrenceEnds => 'Desinit';

  @override
  String get recurrenceNever => 'Numquam';

  @override
  String get recurrenceOnDate => 'Die';

  @override
  String get recurrenceAfter => 'Post';

  @override
  String get recurrenceDone => 'Perfectum';

  @override
  String recurrenceOccurrences(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'vices', one: 'vicem');
    return '$_temp0';
  }

  @override
  String recurrenceDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'dies', one: 'diem');
    return '$_temp0';
  }

  @override
  String recurrenceWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'hebdomades', one: 'hebdomadem');
    return '$_temp0';
  }

  @override
  String recurrenceMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'menses', one: 'mensem');
    return '$_temp0';
  }

  @override
  String recurrenceYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'annos', one: 'annum');
    return '$_temp0';
  }

  @override
  String recurrenceEveryN(int count, String unit) {
    return 'Singulis $count $unit';
  }

  @override
  String recurrenceWeeklyOn(String days) {
    return 'Singulis hebdomadibus: $days';
  }

  @override
  String recurrenceTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count vicibus', one: 'semel');
    return '$_temp0';
  }

  @override
  String recurrenceUntil(String date) {
    return 'usque ad $date';
  }

  @override
  String get colorCode => 'Codex';

  @override
  String get colorSeriesCustom => 'Alius color';

  @override
  String get calendarEditTask => 'Pensum muta';

  @override
  String get calendarDeleteTask => 'Pensum dele';

  @override
  String get calendarOptions => 'Optiones';

  @override
  String get calendarOpenDetail => 'Singula pensi aperi';

  @override
  String get calendarMarkDone => 'Ut perfectum nota';

  @override
  String get calendarMarkUndone => 'Ut imperfectum nota';

  @override
  String get calendarOpen => 'Aperi';

  @override
  String get calendarShortAs30 => 'Eventa brevia magnitudine triginta minutorum';

  @override
  String get recurringDeleteTitle => 'Pensum repetitum dele';

  @override
  String get recurringEditTitle => 'Pensum repetitum muta';

  @override
  String get recurringOne => 'Hoc solum';

  @override
  String get recurringFollowing => 'Hoc et sequentia';

  @override
  String get recurringAll => 'Omnia';

  @override
  String get notificationAlarmChannelName => 'Excitatorium attentionis';

  @override
  String get notificationFocusChannelName => 'Attentio in cursu';

  @override
  String get notificationActionStop => 'Siste';

  @override
  String get focusBreakDoneTitle => 'Intermissio finita est.';

  @override
  String get focusBreakDoneBody => 'Tempus est ad attentionem redire.';

  @override
  String get focusRunningTitle => 'Attendens';

  @override
  String get focusPausedTitle => 'Attentio sistitur';

  @override
  String get focusBreakTitle => 'Intermissio';

  @override
  String get notificationAlarmClockChannelName => 'Monita (excitatorium)';

  @override
  String get trayOpen => 'Ordinem aperi';

  @override
  String get trayQuit => 'Exi';

  @override
  String get trayMiniCalendar => 'Calendariolum';

  @override
  String get settingsReminderSound => 'Sonus moniti';

  @override
  String get settingsReminderSoundHint => 'Excitatorium paucis secundis sonat; sonus pomi est in Attentio → Optiones attentionis.';

  @override
  String get reminderSoundAlarmClock => 'Excitatorium';

  @override
  String get reminderSoundStandard => 'Usitatus';

  @override
  String get reminderSoundSilent => 'Tacitus';

  @override
  String get settingsBackground => 'Post scaenam';

  @override
  String get settingsCloseToTray => 'Cum clauditur, in area notificationum mane';

  @override
  String get settingsCloseToTrayHint => 'Monita, pomum et sonus excitatorii pergunt. Ut omnino exeas, \"Exi\" in icone prope horologium adhibe.';

  @override
  String get settingsLaunchAtStartup => 'Cum Windows incipe';

  @override
  String get settingsLaunchAtStartupHint => 'Occultum in area notificationum aperitur cum in Windows intras.';

  @override
  String get settingsDesktopMini => 'Calendariolum';

  @override
  String get settingsDesktopMiniHint =>
      'Fenestella cum calendario in mensa operaria, sicut instrumentum telephoni. Etiam ex icone prope horologium aperitur.';

  @override
  String get settingsDesktopMiniOpen => 'Aperi';

  @override
  String get inFeminine => 'in';

  @override
  String get inMasculine => 'in';

  @override
  String recurrenceYearlyOn(String date) {
    return 'Quotannis die $date';
  }

  @override
  String get navFinance => 'Res pecuniaria';

  @override
  String get featureFinanceHint => 'Reditus, impensae, chartae creditae, rationes fixae et mutua.';

  @override
  String get finTabEntries => 'Inscriptiones';

  @override
  String get finTabCategories => 'Categoriae';

  @override
  String get finNewEntry => 'Nova inscriptio';

  @override
  String get finEditEntry => 'Inscriptionem muta';

  @override
  String get finIncome => 'Reditus';

  @override
  String get finExpense => 'Impensa';

  @override
  String get finIncomes => 'Reditus';

  @override
  String get finExpenses => 'Impensae';

  @override
  String get finBalance => 'Reliquum';

  @override
  String get finAmount => 'Summa';

  @override
  String get finDescription => 'Descriptio';

  @override
  String get finDate => 'Dies';

  @override
  String get finCategory => 'Categoria';

  @override
  String get finNoCategory => 'Sine categoria';

  @override
  String get finCard => 'Charta';

  @override
  String get finNoCard => 'Non charta solutum';

  @override
  String get finInstallments => 'Pensiones';

  @override
  String finInstallmentsValue(int count, String amount) {
    return '${count}x $amount';
  }

  @override
  String get finNote => 'Adnotatio';

  @override
  String get finInvalidAmount => 'Summam maiorem quam nihil scribe.';

  @override
  String get finEntriesEmpty => 'Nulla inscriptio hoc spatio.';

  @override
  String finInvoiceOf(String card, String day) {
    return 'Ratio $card · solvenda $day';
  }

  @override
  String get finEntryDeleted => 'Inscriptio deleta';

  @override
  String get finDeleteInstallments => 'Emptionem per pensiones dele';

  @override
  String get finDeleteOneInstallment => 'Hanc solam pensionem';

  @override
  String finDeleteAllInstallments(int count) {
    return 'Omnes $count pensiones';
  }

  @override
  String get finDuplicate => 'Duplica';

  @override
  String finLimitNear(String category, String percent, String spent, String limit) {
    return '$category: $percent finis mensis ($spent ex $limit).';
  }

  @override
  String finLimitOver(String category, String spent, String limit) {
    return '$category finem mensis excessit: $spent ex $limit.';
  }

  @override
  String get finNewCategory => 'Nova categoria';

  @override
  String get finEditCategory => 'Categoriam muta';

  @override
  String get finCategoryName => 'Nomen';

  @override
  String get finMonthlyLimit => 'Finis in mensem';

  @override
  String get finLimitHint => 'Vacuum, sine fine. Monitum ab octoginta centesimis finis venit.';

  @override
  String finLimitProgress(String spent, String limit) {
    return '$spent ex $limit';
  }

  @override
  String finSpentThisMonth(String spent) {
    return '$spent hoc mense';
  }

  @override
  String finDeleteCategory(String name) {
    return 'Categoriam \"$name\" delere? Inscriptiones eius sine categoria manebunt.';
  }

  @override
  String get finIcon => 'Icon';

  @override
  String get finPeriodMonth => 'Mensis';

  @override
  String get finPeriodYear => 'Annus';

  @override
  String get finAllCategories => 'Omnes categoriae';

  @override
  String get finAllKinds => 'Reditus et impensae';

  @override
  String get finSearchHint => 'In descriptione quaere';

  @override
  String get finCatFood => 'Victus';

  @override
  String get finCatMarket => 'Macellum';

  @override
  String get finCatTransport => 'Vectura';

  @override
  String get finCatHome => 'Habitatio';

  @override
  String get finCatBills => 'Rationes domus';

  @override
  String get finCatHealth => 'Valetudo';

  @override
  String get finCatEducation => 'Educatio';

  @override
  String get finCatLeisure => 'Otium';

  @override
  String get finCatShopping => 'Emptiones';

  @override
  String get finCatSubscriptions => 'Subscriptiones';

  @override
  String get finCatOther => 'Alia';

  @override
  String get finCatSalary => 'Merces';

  @override
  String get finCatExtra => 'Reditus additus';

  @override
  String get finTabCards => 'Chartae';

  @override
  String get finTabRecurring => 'Rationes fixae';

  @override
  String get finTabLoans => 'Mutua';

  @override
  String get finTabReports => 'Relationes';

  @override
  String get finNewCard => 'Nova charta';

  @override
  String get finEditCard => 'Chartam muta';

  @override
  String get finCardName => 'Nomen chartae';

  @override
  String get finClosingDay => 'Dies clausurae';

  @override
  String get finDueDay => 'Dies solutionis';

  @override
  String get finCreditLimit => 'Finis chartae (ad libitum)';

  @override
  String finCardDays(int closing, int due) {
    return 'Clauditur die $closing · solvenda die $due';
  }

  @override
  String finCardUsed(String used, String limit) {
    return '$used adhibita ex $limit';
  }

  @override
  String finInvoiceTitle(String month) {
    return 'Ratio mensis $month';
  }

  @override
  String get finInvoiceOpen => 'Aperta';

  @override
  String get finInvoiceClosed => 'Clausa';

  @override
  String get finInvoicePaid => 'Soluta';

  @override
  String get finInvoiceOverdue => 'Praeterita';

  @override
  String get finInvoiceEmpty => 'Sine emptionibus';

  @override
  String finInvoiceDates(String closing, String due) {
    return 'Clauditur $closing · solvenda $due';
  }

  @override
  String get finInvoiceTotal => 'Summa';

  @override
  String get finInvoicePaidAmount => 'Solutum';

  @override
  String get finInvoiceRemaining => 'Solvendum restat';

  @override
  String get finPayInvoice => 'Rationem solve';

  @override
  String get finPaymentAmount => 'Summa soluta';

  @override
  String get finPaymentDate => 'Dies solutionis';

  @override
  String get finPayments => 'Solutiones';

  @override
  String get finPurchases => 'Emptiones';

  @override
  String get finNoCards => 'Nondum ulla charta. Unam inscribe ut emptiones charta factas notes et rationes sequaris.';

  @override
  String get finArchive => 'In tabulario conde';

  @override
  String get finUnarchive => 'E tabulario educ';

  @override
  String get finArchivedCards => 'In tabulario';

  @override
  String get finCardDeleteBlocked => 'Haec charta emptiones aut solutiones habet. In tabulario conde ut celes.';

  @override
  String finDeleteCard(String name) {
    return 'Chartam \"$name\" delere?';
  }

  @override
  String get finPaymentDeleted => 'Solutio deleta';

  @override
  String get finNewRecurring => 'Nova ratio fixa';

  @override
  String get finEditRecurring => 'Rationem fixam muta';

  @override
  String get finNoRecurring => 'Nondum ulla ratio fixa. Pensionem, subscriptiones, mercedem inscribe…';

  @override
  String get finRecurringHint => 'Pensio domus, interrete, merces…';

  @override
  String get finRecurringInvalid => 'Descriptionem et summam maiorem quam nihil scribe.';

  @override
  String get finOverdueBills => 'Praeteritae';

  @override
  String get finDueThisMonth => 'Solutiones mensis';

  @override
  String get finRecurringBills => 'Rationes inscriptae';

  @override
  String finEveryMonthOn(int day) {
    return 'Quoque die $day';
  }

  @override
  String finEveryYearOn(String date) {
    return 'Quotannis die $date';
  }

  @override
  String finDueOn(String date) {
    return 'solvenda $date';
  }

  @override
  String finPaidOn(String date) {
    return 'soluta $date';
  }

  @override
  String get finConfirmPaid => 'Solve';

  @override
  String get finConfirmReceived => 'Accipe';

  @override
  String get finUndoPayment => 'Solutionem revoca';

  @override
  String get finPaymentUndone => 'Solutio revocata';

  @override
  String finDeleteRecurring(String name) {
    return 'Rationem fixam \"$name\" delere? Inscriptiones iam factae manent.';
  }

  @override
  String get finMonthly => 'Singulis mensibus';

  @override
  String get finYearly => 'Quotannis';

  @override
  String get finReminder => 'Monitum';

  @override
  String get finNoReminder => 'Sine monito';

  @override
  String get finRemindOnDay => 'Ipso die solutionis';

  @override
  String finRemindDaysBefore(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days diebus ante', one: 'Uno die ante');
    return '$_temp0';
  }

  @override
  String get finStartsOn => 'Incipit';

  @override
  String get finEndsOn => 'Desinit';

  @override
  String get finNoEnd => 'Sine fine';

  @override
  String get finNewLoan => 'Novum mutuum';

  @override
  String get finEditLoan => 'Mutuum muta';

  @override
  String get finNoLoans => 'Nondum ullum mutuum.';

  @override
  String get finNoLoansHere => 'Nullum mutuum hic.';

  @override
  String get finLoansOpen => 'Aperta';

  @override
  String get finLoansOverdue => 'Praeterita';

  @override
  String get finLoansPaid => 'Soluta';

  @override
  String get finLoansAll => 'Omnia';

  @override
  String get finLentOpen => 'Mutuo datum';

  @override
  String get finToReceive => 'Accipiendum';

  @override
  String get finInterestReceived => 'Usurae acceptae';

  @override
  String get finOverdueAmount => 'Praeteritum';

  @override
  String finLoansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count mutua', one: 'unum mutuum', zero: 'nullum');
    return '$_temp0';
  }

  @override
  String finInterestToCome(String amount) {
    return '$amount usurarum accipiendarum';
  }

  @override
  String get finLoanInterest => 'Usurae mutuorum';

  @override
  String get finChartGeneral => 'Generale';

  @override
  String get finChartDetailed => 'Accuratum';

  @override
  String finLentTotal(String amount) {
    return '$amount mutuo data in summa';
  }

  @override
  String get finLoanOnTime => 'Tempore';

  @override
  String finLoanLate(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Praeteritum a $days diebus',
      one: 'Praeteritum ab uno die',
      zero: 'Praeteritum',
    );
    return '$_temp0';
  }

  @override
  String get finLoanPaid => 'Solutum';

  @override
  String finLoanLeft(String amount) {
    return 'Restat $amount';
  }

  @override
  String finProfit(String amount, String rate) {
    return 'lucrum $amount ($rate)';
  }

  @override
  String finDeleteLoan(String name) {
    return 'Mutuum $name et solutiones eius delere?';
  }

  @override
  String get finLoanDeleted => 'Mutuum deletum';

  @override
  String get finLent => 'Summa mutuo data';

  @override
  String get finLoanTotal => 'Summa accipienda';

  @override
  String get finProfitLabel => 'Lucrum';

  @override
  String get finReceived => 'Acceptum';

  @override
  String get finLoanBalance => 'Accipiendum restat';

  @override
  String get finLentOn => 'Dies mutui';

  @override
  String get finDueDate => 'Dies solutionis';

  @override
  String get finAddLoanPayment => 'Solutionem inscribe';

  @override
  String get finBorrower => 'Qui mutuum accepit';

  @override
  String get finInterestRate => 'Usurae';

  @override
  String finProfitPreview(String amount) {
    return 'Lucrum: $amount';
  }

  @override
  String get finLoanInvalid => 'Scribe quis accepit, summam mutuo datam et summam accipiendam non minorem.';

  @override
  String get finLoanRemind => 'Monere die solutionis et si praeteritur';

  @override
  String get finByCategory => 'Impensae per categorias';

  @override
  String get finNoExpenses => 'Nulla impensa hoc mense.';

  @override
  String get finIncomeVsExpenses => 'Reditus × impensae';

  @override
  String get finCompareMonths => 'Comparatio mensium';

  @override
  String get finVersus => 'cum';

  @override
  String get finChange => 'Mutatio';

  @override
  String get finTotal => 'Summa';

  @override
  String get finLoansSummary => 'Mutua';

  @override
  String finReminderBillTitle(String name) {
    return '$name hodie solvenda';
  }

  @override
  String finReminderBillSoon(String name, String date) {
    return '$name solvenda $date';
  }

  @override
  String finReminderLoanDue(String name) {
    return 'Hodie mutuum $name solvendum';
  }

  @override
  String finReminderLoanLate(String name) {
    return 'Mutuum $name praeteritum';
  }

  @override
  String finReminderLoanBody(String amount) {
    return 'Accipiendum restat $amount';
  }

  @override
  String get finByDueMonth => 'Per mensem solutionis';

  @override
  String get finByLentMonth => 'Per mensem mutui';

  @override
  String finMonthLoanTotals(String amount, String profit) {
    return 'accipiendum $amount · lucrum $profit';
  }

  @override
  String get calendarShowFinance => 'Res pecuniarias ostende (rationes, chartas, exactiones)';

  @override
  String finCalendarInvoice(String card) {
    return 'Ratio $card';
  }

  @override
  String finCalendarLoan(String name) {
    return 'Exige $name';
  }

  @override
  String get finThisMonth => 'Hic mensis';

  @override
  String get finCurrentInvoice => 'Ratio praesens';

  @override
  String get finMonthSpending => 'Impensae mensis';

  @override
  String get finMoreReports => 'Plures relationes';

  @override
  String get finCategoriesFilter => 'Categoriae…';

  @override
  String get finSituation => 'Status';

  @override
  String get finGroupBy => 'Coniunge';

  @override
  String get finCreditAvailable => 'Finis disponibilis';

  @override
  String get habitPanelDone => 'Facta';

  @override
  String get habitPanelLeft => 'Restant';

  @override
  String get habitPanelNone => 'Nulla consuetudo hodie.';

  @override
  String get habitPanelShow => 'Ostende';

  @override
  String get countdownTypes => 'Genera';

  @override
  String get countdownCreateWhich => 'Crea';

  @override
  String get matrixQuadrants => 'Quadrantes';

  @override
  String get focusShortcuts => 'Compendia';

  @override
  String get habitColor => 'Color consuetudinis';

  @override
  String get habitColorMenu => 'Color';

  @override
  String get finNewPurchase => 'Nova emptio';

  @override
  String get habitNewButton => 'Nova consuetudo';

  @override
  String get countdownNew => 'Nova dinumeratio';

  @override
  String get focusTimerNew => 'Novum horologium';

  @override
  String get finEditPayment => 'Solutionem muta';

  @override
  String habitDeleteConfirm(String name) {
    return 'Consuetudinem \"$name\" et omnes eius notationes delere? Hoc revocari non potest.';
  }

  @override
  String get habitLogDelete => 'Actum dele';

  @override
  String countdownDeleteConfirm(String name) {
    return '\"$name\" delere? Hoc revocari non potest.';
  }

  @override
  String focusTimerDeleteConfirm(String name) {
    return 'Horologium \"$name\" delere? Acta attentionis manent.';
  }

  @override
  String get focusRecordDeleteConfirm => 'Hoc actum attentionis delere? Hoc revocari non potest.';

  @override
  String tagDeleteConfirm(String name) {
    return 'Pittacium \"$name\" delere? Pensa sine eo manent.';
  }

  @override
  String get listDeleteMenu => 'Indicem dele';

  @override
  String get syncTitle => 'Cum alio instrumento synchroniza';

  @override
  String get syncMenu => 'Instrumenta synchroniza';

  @override
  String get syncIntro =>
      'Telephonum et computatrum per Wi-Fi paria redde, sine interreti et sine ratione: unum instrumentum omnia quae habet mittit, et alterum ei par fit.';

  @override
  String get syncSend => 'Ex hoc instrumento mitte';

  @override
  String get syncSendHint => 'Alterum instrumentum huic par fit.';

  @override
  String get syncReceive => 'In hoc instrumento accipe';

  @override
  String get syncReceiveHint =>
      'Hoc instrumentum alteri par fit. Prius exemplar tutelae datorum hic fit (in Optiones → Ratio → Exemplaria tutelae sponte facta).';

  @override
  String get syncSameWifi => 'Ambo in eodem Wi-Fi esse debent, Ordine aperto et eadem versione.';

  @override
  String syncWaiting(String name) {
    return 'In altero instrumento aperi Synchronizare → Ex hoc instrumento mitte, elige \"$name\" et hunc codicem scribe:';
  }

  @override
  String syncAddress(String name, String address) {
    return 'Si \"$name\" ibi non apparet, preme Inscriptionem scribe et adhibe: $address';
  }

  @override
  String get syncFirewall => 'In Windows, si murus ignifer interrogat, preme Aditum permitte.';

  @override
  String get syncReceiving => 'Data accipiuntur…';

  @override
  String syncReceived(String name) {
    return 'Factum! Hoc instrumentum \"$name\" par factum est.';
  }

  @override
  String get syncReceiveFailed => 'Data accepta adhiberi non potuerunt (versiones applicationis differunt?). Hic nihil mutatum est.';

  @override
  String get syncSearching => 'Instrumenta in Wi-Fi quaeruntur…';

  @override
  String get syncTypeAddress => 'Inscriptionem scribe';

  @override
  String get syncAddressLabel => 'Inscriptio (ex.: 192.168.0.10:50000)';

  @override
  String syncEnterCode(String name) {
    return 'Codicem scribe qui in \"$name\" apparet';
  }

  @override
  String get syncSendButton => 'Mitte';

  @override
  String get syncSending => 'Mittitur… alterum instrumentum huic par fit.';

  @override
  String syncDone(String name) {
    return 'Factum! \"$name\" huic instrumento par factum est.';
  }

  @override
  String get syncWrongCode => 'Codex falsus. Codicem in altero instrumento inspice.';

  @override
  String get syncRefused => 'Alterum instrumentum post multa conata accipere desiit. Ibi \"Accipe\" claude et rursus aperi.';

  @override
  String get syncFailed => 'Non successit. Inspice num ambo in eodem Wi-Fi sint, Ordine aperto et eadem versione.';

  @override
  String get syncCodeLabel => 'Codex';

  @override
  String get syncWaitingOther => 'Alterum instrumentum mittere exspectatur…';

  @override
  String get widgetDay => 'Dies';

  @override
  String get widgetWeek => 'Hebdomas';

  @override
  String get widgetMonth => 'Mensis';

  @override
  String get widgetEmpty => 'Nihil hoc die';

  @override
  String get widgetAllDay => 'Totus dies';

  @override
  String get miniLayerTop => 'Super fenestras';

  @override
  String get miniLayerNormal => 'Usitate';

  @override
  String get miniLayerDesktop => 'In mensa operaria';

  @override
  String get miniClose => 'Claude';

  @override
  String get reorderSortCustom => 'Nunc ordo huius indicis tuus est (Ordina per: ad libitum).';

  @override
  String get navDiet => 'Victus';

  @override
  String get featureDietHint => 'Commentarius ciborum cum tabula TACO: calores et macronutrientia diei';

  @override
  String get dietTabDiary => 'Commentarius';

  @override
  String get dietTabFoods => 'Cibi';

  @override
  String get dietAddFood => 'Cibum adde';

  @override
  String dietAddTo(String meal) {
    return 'Adde in $meal';
  }

  @override
  String get dietNewFood => 'Novus cibus';

  @override
  String get dietEditFood => 'Cibum muta';

  @override
  String get dietEditEntry => 'Cibum diei muta';

  @override
  String get dietMealBreakfast => 'Ientaculum';

  @override
  String get dietMealMorningSnack => 'Gustatio matutina';

  @override
  String get dietMealLunch => 'Prandium';

  @override
  String get dietMealAfternoonSnack => 'Gustatio pomeridiana';

  @override
  String get dietMealDinner => 'Cena';

  @override
  String get dietMealSupper => 'Comissatio';

  @override
  String get dietMeal => 'Cibatio';

  @override
  String get dietKcal => 'Calores';

  @override
  String get dietProtein => 'Proteina';

  @override
  String get dietCarbs => 'Carbohydrata';

  @override
  String get dietFat => 'Adipes';

  @override
  String get dietFiber => 'Fibrae';

  @override
  String get dietSearchHint => 'Cibum quaere (ex.: oryza, musa, pullus)';

  @override
  String get dietQuantity => 'Quantitas';

  @override
  String get dietGrams => 'grammata';

  @override
  String get dietNotFound => 'Non inveni: cibum inscribe';

  @override
  String get dietKcalFromMacros => 'Per macronutrientia: P×4 + C×4 + A×9';

  @override
  String get dietPer100 => 'Valores per 100 g (vacua relinque quae nescis)';

  @override
  String get dietName => 'Nomen';

  @override
  String get dietNameRequired => 'Cibo nomen da.';

  @override
  String get dietMeasureName => 'Mensura domestica (ad libitum, ex.: cochlear)';

  @override
  String get dietMeasureGrams => 'Grammata huius mensurae';

  @override
  String get dietDayEmpty => 'Nihil hoc die inscriptum.';

  @override
  String get dietMyFoods => 'Cibi mei';

  @override
  String get dietMyFoodsEmpty => 'Nondum cibos inscripsisti. Adhibe + Novus cibus aut \"Non inveni\" cum inscribis.';

  @override
  String get dietMine => 'Cibus meus';

  @override
  String get dietSource => 'Tabula TACO: NEPA/Unicamp, editio quarta. Valores per 100 g partis edulis.';

  @override
  String get dietEntryDeleted => 'Cibus e die remotus';

  @override
  String get dietFoodDeleted => 'Cibus deletus';

  @override
  String get dietIncomplete => 'Quidam cibi non omnes valores in tabula habent: summa minimum est.';

  @override
  String get dietChangeFood => 'Muta';

  @override
  String dietPerHundred(String kcal) {
    return '$kcal kcal/100 g';
  }

  @override
  String dietPortionResult(String grams, String kcal) {
    return '= $grams g · $kcal kcal';
  }

  @override
  String get dietQuantityRequired => 'Cibum et quantitatem maiorem quam nihil elige.';

  @override
  String get dietSaveAndUse => 'Inscribe et adhibe';

  @override
  String get dietAddToDay => 'Diei adde';

  @override
  String get dietDayTotals => 'Summae diei';

  @override
  String get dietEnergy => 'Vis';

  @override
  String dietLegendProtein(String pct) {
    return 'Prot. $pct';
  }

  @override
  String dietLegendCarbs(String pct) {
    return 'Carb. $pct';
  }

  @override
  String dietLegendFat(String pct) {
    return 'Adip. $pct';
  }
}
