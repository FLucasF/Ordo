import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_la.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('la'), Locale('pt')];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ordo'**
  String get appTitle;

  /// No description provided for @inbox.
  ///
  /// In pt, this message translates to:
  /// **'Caixa de Entrada'**
  String get inbox;

  /// No description provided for @smartAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get smartAll;

  /// No description provided for @smartToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get smartToday;

  /// No description provided for @smartTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get smartTomorrow;

  /// No description provided for @smartNext7Days.
  ///
  /// In pt, this message translates to:
  /// **'Próximos 7 dias'**
  String get smartNext7Days;

  /// No description provided for @smartCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get smartCompleted;

  /// No description provided for @smartWontDo.
  ///
  /// In pt, this message translates to:
  /// **'Não será feito'**
  String get smartWontDo;

  /// No description provided for @smartTrash.
  ///
  /// In pt, this message translates to:
  /// **'Lixeira'**
  String get smartTrash;

  /// No description provided for @sidebarLists.
  ///
  /// In pt, this message translates to:
  /// **'Listas'**
  String get sidebarLists;

  /// No description provided for @sidebarFilters.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get sidebarFilters;

  /// No description provided for @sidebarTags.
  ///
  /// In pt, this message translates to:
  /// **'Etiquetas'**
  String get sidebarTags;

  /// No description provided for @sidebarFiltersHelp.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar tarefas filtradas por lista, data, prioridade, etiqueta e mais.'**
  String get sidebarFiltersHelp;

  /// No description provided for @sidebarTagsHelp.
  ///
  /// In pt, this message translates to:
  /// **'Categorize suas tarefas com etiquetas. Digite # no campo de tarefa para criar.'**
  String get sidebarTagsHelp;

  /// No description provided for @archivedLists.
  ///
  /// In pt, this message translates to:
  /// **'Listas Arquivadas'**
  String get archivedLists;

  /// No description provided for @navTasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get navTasks;

  /// No description provided for @navSearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get navSearch;

  /// No description provided for @navSync.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar'**
  String get navSync;

  /// No description provided for @navNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get navNotifications;

  /// No description provided for @navHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda'**
  String get navHelp;

  /// No description provided for @groupPinned.
  ///
  /// In pt, this message translates to:
  /// **'Fixado'**
  String get groupPinned;

  /// No description provided for @groupUnpinned.
  ///
  /// In pt, this message translates to:
  /// **'Não fixado'**
  String get groupUnpinned;

  /// No description provided for @groupUnsectioned.
  ///
  /// In pt, this message translates to:
  /// **'Não Classificado'**
  String get groupUnsectioned;

  /// No description provided for @groupOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasadas'**
  String get groupOverdue;

  /// No description provided for @groupNext7Days.
  ///
  /// In pt, this message translates to:
  /// **'Próximos 7 dias'**
  String get groupNext7Days;

  /// No description provided for @groupLater.
  ///
  /// In pt, this message translates to:
  /// **'Mais tarde'**
  String get groupLater;

  /// No description provided for @groupNoDate.
  ///
  /// In pt, this message translates to:
  /// **'Sem Data'**
  String get groupNoDate;

  /// No description provided for @groupNoTag.
  ///
  /// In pt, this message translates to:
  /// **'Sem etiquetas'**
  String get groupNoTag;

  /// No description provided for @groupCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get groupCompleted;

  /// No description provided for @groupCompletedAndWontDo.
  ///
  /// In pt, this message translates to:
  /// **'Concluído e Não Farei.'**
  String get groupCompletedAndWontDo;

  /// No description provided for @groupPriorityHigh.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade alta'**
  String get groupPriorityHigh;

  /// No description provided for @groupPriorityMedium.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade média'**
  String get groupPriorityMedium;

  /// No description provided for @groupPriorityLow.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade baixa'**
  String get groupPriorityLow;

  /// No description provided for @groupPriorityNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem prioridade'**
  String get groupPriorityNone;

  /// No description provided for @showMore.
  ///
  /// In pt, this message translates to:
  /// **'Ver mais'**
  String get showMore;

  /// No description provided for @weekdayMonday.
  ///
  /// In pt, this message translates to:
  /// **'Segunda-feira'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In pt, this message translates to:
  /// **'Terça-feira'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In pt, this message translates to:
  /// **'Quarta-feira'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In pt, this message translates to:
  /// **'Quinta-feira'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In pt, this message translates to:
  /// **'Sexta-feira'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In pt, this message translates to:
  /// **'Sábado'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In pt, this message translates to:
  /// **'Domingo'**
  String get weekdaySunday;

  /// No description provided for @weekdayShortMonday.
  ///
  /// In pt, this message translates to:
  /// **'Seg'**
  String get weekdayShortMonday;

  /// No description provided for @weekdayShortTuesday.
  ///
  /// In pt, this message translates to:
  /// **'Ter'**
  String get weekdayShortTuesday;

  /// No description provided for @weekdayShortWednesday.
  ///
  /// In pt, this message translates to:
  /// **'Qua'**
  String get weekdayShortWednesday;

  /// No description provided for @weekdayShortThursday.
  ///
  /// In pt, this message translates to:
  /// **'Qui'**
  String get weekdayShortThursday;

  /// No description provided for @weekdayShortFriday.
  ///
  /// In pt, this message translates to:
  /// **'Sex'**
  String get weekdayShortFriday;

  /// No description provided for @weekdayShortSaturday.
  ///
  /// In pt, this message translates to:
  /// **'Sáb'**
  String get weekdayShortSaturday;

  /// No description provided for @weekdayShortSunday.
  ///
  /// In pt, this message translates to:
  /// **'Dom'**
  String get weekdayShortSunday;

  /// No description provided for @monthJanuary.
  ///
  /// In pt, this message translates to:
  /// **'janeiro'**
  String get monthJanuary;

  /// No description provided for @monthFebruary.
  ///
  /// In pt, this message translates to:
  /// **'fevereiro'**
  String get monthFebruary;

  /// No description provided for @monthMarch.
  ///
  /// In pt, this message translates to:
  /// **'março'**
  String get monthMarch;

  /// No description provided for @monthApril.
  ///
  /// In pt, this message translates to:
  /// **'abril'**
  String get monthApril;

  /// No description provided for @monthMay.
  ///
  /// In pt, this message translates to:
  /// **'maio'**
  String get monthMay;

  /// No description provided for @monthJune.
  ///
  /// In pt, this message translates to:
  /// **'junho'**
  String get monthJune;

  /// No description provided for @monthJuly.
  ///
  /// In pt, this message translates to:
  /// **'julho'**
  String get monthJuly;

  /// No description provided for @monthAugust.
  ///
  /// In pt, this message translates to:
  /// **'agosto'**
  String get monthAugust;

  /// No description provided for @monthSeptember.
  ///
  /// In pt, this message translates to:
  /// **'setembro'**
  String get monthSeptember;

  /// No description provided for @monthOctober.
  ///
  /// In pt, this message translates to:
  /// **'outubro'**
  String get monthOctober;

  /// No description provided for @monthNovember.
  ///
  /// In pt, this message translates to:
  /// **'novembro'**
  String get monthNovember;

  /// No description provided for @monthDecember.
  ///
  /// In pt, this message translates to:
  /// **'dezembro'**
  String get monthDecember;

  /// No description provided for @monthShortJanuary.
  ///
  /// In pt, this message translates to:
  /// **'jan'**
  String get monthShortJanuary;

  /// No description provided for @monthShortFebruary.
  ///
  /// In pt, this message translates to:
  /// **'fev'**
  String get monthShortFebruary;

  /// No description provided for @monthShortMarch.
  ///
  /// In pt, this message translates to:
  /// **'mar'**
  String get monthShortMarch;

  /// No description provided for @monthShortApril.
  ///
  /// In pt, this message translates to:
  /// **'abr'**
  String get monthShortApril;

  /// No description provided for @monthShortMay.
  ///
  /// In pt, this message translates to:
  /// **'mai'**
  String get monthShortMay;

  /// No description provided for @monthShortJune.
  ///
  /// In pt, this message translates to:
  /// **'jun'**
  String get monthShortJune;

  /// No description provided for @monthShortJuly.
  ///
  /// In pt, this message translates to:
  /// **'jul'**
  String get monthShortJuly;

  /// No description provided for @monthShortAugust.
  ///
  /// In pt, this message translates to:
  /// **'ago'**
  String get monthShortAugust;

  /// No description provided for @monthShortSeptember.
  ///
  /// In pt, this message translates to:
  /// **'set'**
  String get monthShortSeptember;

  /// No description provided for @monthShortOctober.
  ///
  /// In pt, this message translates to:
  /// **'out'**
  String get monthShortOctober;

  /// No description provided for @monthShortNovember.
  ///
  /// In pt, this message translates to:
  /// **'nov'**
  String get monthShortNovember;

  /// No description provided for @monthShortDecember.
  ///
  /// In pt, this message translates to:
  /// **'dez'**
  String get monthShortDecember;

  /// No description provided for @relativeToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get relativeToday;

  /// No description provided for @relativeTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get relativeTomorrow;

  /// No description provided for @relativeYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get relativeYesterday;

  /// No description provided for @emptyNoTasks.
  ///
  /// In pt, this message translates to:
  /// **'Sem tarefas'**
  String get emptyNoTasks;

  /// No description provided for @emptyInbox.
  ///
  /// In pt, this message translates to:
  /// **'Capture aqui as tarefas e ideias'**
  String get emptyInbox;

  /// No description provided for @emptyList.
  ///
  /// In pt, this message translates to:
  /// **'Clique na caixa de entrada para adicionar'**
  String get emptyList;

  /// No description provided for @emptyNoNotes.
  ///
  /// In pt, this message translates to:
  /// **'Sem notas'**
  String get emptyNoNotes;

  /// No description provided for @emptyNotes.
  ///
  /// In pt, this message translates to:
  /// **'Registre inspiração e tempo aqui'**
  String get emptyNotes;

  /// No description provided for @emptyTag.
  ///
  /// In pt, this message translates to:
  /// **'Relaxe um pouco'**
  String get emptyTag;

  /// No description provided for @emptySmart.
  ///
  /// In pt, this message translates to:
  /// **'Relaxe um pouco'**
  String get emptySmart;

  /// No description provided for @emptyCompletedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há tarefas concluídas'**
  String get emptyCompletedTitle;

  /// No description provided for @emptyCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Continue assim :)'**
  String get emptyCompleted;

  /// No description provided for @emptyWontDo.
  ///
  /// In pt, this message translates to:
  /// **'As tarefas que você não fará aparecem aqui'**
  String get emptyWontDo;

  /// No description provided for @emptyTrashTitle.
  ///
  /// In pt, this message translates to:
  /// **'A lixeira está limpa'**
  String get emptyTrashTitle;

  /// No description provided for @emptyTrash.
  ///
  /// In pt, this message translates to:
  /// **'Não há tarefas excluídas'**
  String get emptyTrash;

  /// No description provided for @addTask.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar tarefa'**
  String get addTask;

  /// No description provided for @addNote.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar nota'**
  String get addNote;

  /// No description provided for @addTaskTo.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar tarefa a \'{name}\''**
  String addTaskTo(String name);

  /// No description provided for @addTaskToTag.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar tarefa a \'#{name}\''**
  String addTaskToTag(String name);

  /// No description provided for @addDescriptionHint.
  ///
  /// In pt, this message translates to:
  /// **'Shift+Enter adicionar descrição'**
  String get addDescriptionHint;

  /// No description provided for @toastTaskCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa concluída'**
  String get toastTaskCompleted;

  /// No description provided for @toastFirstTaskOfDay.
  ///
  /// In pt, this message translates to:
  /// **'Completou a primeira tarefa do dia!'**
  String get toastFirstTaskOfDay;

  /// No description provided for @toastUndo.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer'**
  String get toastUndo;

  /// No description provided for @toastTaskDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa excluída'**
  String get toastTaskDeleted;

  /// No description provided for @toastRestored.
  ///
  /// In pt, this message translates to:
  /// **'Restaurado para a lista original.'**
  String get toastRestored;

  /// No description provided for @toastWontDo.
  ///
  /// In pt, this message translates to:
  /// **'Você desistiu da tarefa.'**
  String get toastWontDo;

  /// No description provided for @toastMovedTo.
  ///
  /// In pt, this message translates to:
  /// **'Movido para {name}'**
  String toastMovedTo(String name);

  /// No description provided for @toastMovedToToday.
  ///
  /// In pt, this message translates to:
  /// **'Movido para \"Hoje\".'**
  String get toastMovedToToday;

  /// No description provided for @toastSaved.
  ///
  /// In pt, this message translates to:
  /// **'Salvo'**
  String get toastSaved;

  /// No description provided for @toastArchived.
  ///
  /// In pt, this message translates to:
  /// **'Arquivado'**
  String get toastArchived;

  /// No description provided for @toastLinkCopied.
  ///
  /// In pt, this message translates to:
  /// **'Link copiado'**
  String get toastLinkCopied;

  /// No description provided for @errorInboxCannotBeArchived.
  ///
  /// In pt, this message translates to:
  /// **'A Caixa de Entrada não pode ser arquivada.'**
  String get errorInboxCannotBeArchived;

  /// No description provided for @errorInboxCannotBeDeleted.
  ///
  /// In pt, this message translates to:
  /// **'A Caixa de Entrada não pode ser excluída.'**
  String get errorInboxCannotBeDeleted;

  /// No description provided for @errorTaskCannotBeItsOwnParent.
  ///
  /// In pt, this message translates to:
  /// **'Uma tarefa não pode ser subtarefa dela mesma.'**
  String get errorTaskCannotBeItsOwnParent;

  /// No description provided for @errorSubtaskDepthLimit.
  ///
  /// In pt, this message translates to:
  /// **'As subtarefas vão até 5 níveis.'**
  String get errorSubtaskDepthLimit;

  /// No description provided for @errorTaskWithSubtasksCannotBecomeNote.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas com sub-tarefas não podem ser convertidas em notas.'**
  String get errorTaskWithSubtasksCannotBecomeNote;

  /// No description provided for @errorTagNameTaken.
  ///
  /// In pt, this message translates to:
  /// **'Já existe uma etiqueta com esse nome.'**
  String get errorTagNameTaken;

  /// No description provided for @menuDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get menuDate;

  /// No description provided for @menuPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get menuPriority;

  /// No description provided for @menuAddSubtask.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar subtarefa'**
  String get menuAddSubtask;

  /// No description provided for @menuLinkParent.
  ///
  /// In pt, this message translates to:
  /// **'Vincular Tarefa Pai'**
  String get menuLinkParent;

  /// No description provided for @menuPin.
  ///
  /// In pt, this message translates to:
  /// **'Fixar'**
  String get menuPin;

  /// No description provided for @menuUnpin.
  ///
  /// In pt, this message translates to:
  /// **'Desafixar'**
  String get menuUnpin;

  /// No description provided for @menuWontDo.
  ///
  /// In pt, this message translates to:
  /// **'Não farei'**
  String get menuWontDo;

  /// No description provided for @menuMoveTo.
  ///
  /// In pt, this message translates to:
  /// **'Mover para'**
  String get menuMoveTo;

  /// No description provided for @menuTags.
  ///
  /// In pt, this message translates to:
  /// **'Etiquetas'**
  String get menuTags;

  /// No description provided for @menuDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar'**
  String get menuDuplicate;

  /// No description provided for @menuCopyLink.
  ///
  /// In pt, this message translates to:
  /// **'Copiar link'**
  String get menuCopyLink;

  /// No description provided for @menuConvertToNote.
  ///
  /// In pt, this message translates to:
  /// **'Converter para nota'**
  String get menuConvertToNote;

  /// No description provided for @menuConvertToTask.
  ///
  /// In pt, this message translates to:
  /// **'Converter para tarefa'**
  String get menuConvertToTask;

  /// No description provided for @menuDelete.
  ///
  /// In pt, this message translates to:
  /// **'Deletar'**
  String get menuDelete;

  /// No description provided for @menuRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get menuRestore;

  /// No description provided for @menuDeleteForever.
  ///
  /// In pt, this message translates to:
  /// **'Excluir definitivamente'**
  String get menuDeleteForever;

  /// No description provided for @menuReopen.
  ///
  /// In pt, this message translates to:
  /// **'Reabrir'**
  String get menuReopen;

  /// No description provided for @menuMore.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get menuMore;

  /// No description provided for @dateToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get dateToday;

  /// No description provided for @dateTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get dateTomorrow;

  /// No description provided for @dateNextWeek.
  ///
  /// In pt, this message translates to:
  /// **'Próxima Semana'**
  String get dateNextWeek;

  /// No description provided for @dateCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get dateCustom;

  /// No description provided for @dateClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get dateClear;

  /// No description provided for @priorityHigh.
  ///
  /// In pt, this message translates to:
  /// **'Alta'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In pt, this message translates to:
  /// **'Média'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In pt, this message translates to:
  /// **'Baixa'**
  String get priorityLow;

  /// No description provided for @priorityNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma'**
  String get priorityNone;

  /// No description provided for @detailDueDatePlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Dia do vencimento'**
  String get detailDueDatePlaceholder;

  /// No description provided for @detailTitlePlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'O que você gostaria de fazer?'**
  String get detailTitlePlaceholder;

  /// No description provided for @detailContentPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Digite o conteúdo ou use \"/\" para o menu'**
  String get detailContentPlaceholder;

  /// No description provided for @detailNotePlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Escreva algo ou use um modelo'**
  String get detailNotePlaceholder;

  /// No description provided for @detailSetReminder.
  ///
  /// In pt, this message translates to:
  /// **'Definir lembrete'**
  String get detailSetReminder;

  /// No description provided for @detailChecklistTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Lista de verificação'**
  String get detailChecklistTooltip;

  /// No description provided for @detailChecklistHint.
  ///
  /// In pt, this message translates to:
  /// **'Pressione \'Entrar\' para adicionar item na lista'**
  String get detailChecklistHint;

  /// No description provided for @detailAddSubtask.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar subtarefa'**
  String get detailAddSubtask;

  /// No description provided for @detailAddTag.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar etiqueta'**
  String get detailAddTag;

  /// No description provided for @untitled.
  ///
  /// In pt, this message translates to:
  /// **'Sem título'**
  String get untitled;

  /// No description provided for @listAddTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar lista'**
  String get listAddTitle;

  /// No description provided for @listEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar lista'**
  String get listEditTitle;

  /// No description provided for @listNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get listNameHint;

  /// No description provided for @listColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor da Lista'**
  String get listColor;

  /// No description provided for @listViewType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Visualização'**
  String get listViewType;

  /// No description provided for @viewList.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get viewList;

  /// No description provided for @viewKanban.
  ///
  /// In pt, this message translates to:
  /// **'Kanban'**
  String get viewKanban;

  /// No description provided for @viewTimeline.
  ///
  /// In pt, this message translates to:
  /// **'Linha do tempo'**
  String get viewTimeline;

  /// No description provided for @listFolder.
  ///
  /// In pt, this message translates to:
  /// **'Área'**
  String get listFolder;

  /// No description provided for @folderNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma'**
  String get folderNone;

  /// No description provided for @folderNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova área'**
  String get folderNew;

  /// No description provided for @dropAsSubtask.
  ///
  /// In pt, this message translates to:
  /// **'Soltar como subtarefa'**
  String get dropAsSubtask;

  /// No description provided for @listType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de lista'**
  String get listType;

  /// No description provided for @folderEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar área'**
  String get folderEditTitle;

  /// No description provided for @folderNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome da área (ex.: Saúde, Faculdade)'**
  String get folderNameHint;

  /// No description provided for @folderIcon.
  ///
  /// In pt, this message translates to:
  /// **'Ícone'**
  String get folderIcon;

  /// No description provided for @folderColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor'**
  String get folderColor;

  /// No description provided for @folderDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Área \"{name}\" deletada; as listas ficaram'**
  String folderDeleted(String name);

  /// No description provided for @listParent.
  ///
  /// In pt, this message translates to:
  /// **'Dentro de'**
  String get listParent;

  /// No description provided for @listParentNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma (no topo)'**
  String get listParentNone;

  /// No description provided for @listAddSublist.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar sublista'**
  String get listAddSublist;

  /// No description provided for @listIncludeSublists.
  ///
  /// In pt, this message translates to:
  /// **'Incluir sublistas'**
  String get listIncludeSublists;

  /// No description provided for @sublistsFold.
  ///
  /// In pt, this message translates to:
  /// **'Recolher sublistas'**
  String get sublistsFold;

  /// No description provided for @sublistsUnfold.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar sublistas'**
  String get sublistsUnfold;

  /// No description provided for @sublistsWhatTitle.
  ///
  /// In pt, this message translates to:
  /// **'E as sublistas?'**
  String get sublistsWhatTitle;

  /// No description provided for @sublistsMoveUp.
  ///
  /// In pt, this message translates to:
  /// **'Mover as sublistas um nível acima'**
  String get sublistsMoveUp;

  /// No description provided for @sublistsDeleteToo.
  ///
  /// In pt, this message translates to:
  /// **'Deletar as sublistas também'**
  String get sublistsDeleteToo;

  /// No description provided for @sublistsArchiveToo.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar as sublistas também'**
  String get sublistsArchiveToo;

  /// No description provided for @toastMadeSublist.
  ///
  /// In pt, this message translates to:
  /// **'\"{name}\" agora está dentro de \"{parent}\"'**
  String toastMadeSublist(String name, String parent);

  /// No description provided for @errorListCannotBeItsOwnParent.
  ///
  /// In pt, this message translates to:
  /// **'Uma lista não pode ficar dentro dela mesma nem de uma sublista sua'**
  String get errorListCannotBeItsOwnParent;

  /// No description provided for @errorSublistDepthLimit.
  ///
  /// In pt, this message translates to:
  /// **'As sublistas vão até 3 níveis'**
  String get errorSublistDepthLimit;

  /// No description provided for @errorInboxCannotNest.
  ///
  /// In pt, this message translates to:
  /// **'A Caixa de Entrada não entra em sublistas'**
  String get errorInboxCannotNest;

  /// No description provided for @countdownLink.
  ///
  /// In pt, this message translates to:
  /// **'Vincular a uma lista ou área'**
  String get countdownLink;

  /// No description provided for @countdownLinkNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma'**
  String get countdownLinkNone;

  /// No description provided for @countdownLinkArea.
  ///
  /// In pt, this message translates to:
  /// **'Área: {name}'**
  String countdownLinkArea(String name);

  /// No description provided for @projectDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Painel do projeto'**
  String get projectDashboard;

  /// No description provided for @projectDays.
  ///
  /// In pt, this message translates to:
  /// **'Prazo'**
  String get projectDays;

  /// No description provided for @projectDaysLeft.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{É hoje} =1{Falta 1 dia} other{Faltam {count} dias}}'**
  String projectDaysLeft(int count);

  /// No description provided for @projectDayPassed.
  ///
  /// In pt, this message translates to:
  /// **'O dia já passou'**
  String get projectDayPassed;

  /// No description provided for @projectGone.
  ///
  /// In pt, this message translates to:
  /// **'A lista ou área deste projeto não existe mais.'**
  String get projectGone;

  /// No description provided for @projectEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa no projeto ainda.'**
  String get projectEmpty;

  /// No description provided for @projectProgress.
  ///
  /// In pt, this message translates to:
  /// **'Progresso'**
  String get projectProgress;

  /// No description provided for @projectTasksDone.
  ///
  /// In pt, this message translates to:
  /// **'{done} de {total} tarefas'**
  String projectTasksDone(int done, int total);

  /// No description provided for @projectAccuracy.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de exatidão'**
  String get projectAccuracy;

  /// No description provided for @projectAccuracyNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum prazo vencido ou cumprido ainda'**
  String get projectAccuracyNone;

  /// No description provided for @projectAccuracyDetail.
  ///
  /// In pt, this message translates to:
  /// **'{onTime} no prazo · {late} depois · {missed} vencidas'**
  String projectAccuracyDetail(int onTime, int late, int missed);

  /// No description provided for @projectPace.
  ///
  /// In pt, this message translates to:
  /// **'Ritmo'**
  String get projectPace;

  /// No description provided for @projectPacePerDay.
  ///
  /// In pt, this message translates to:
  /// **'Faça {count} tarefas por dia'**
  String projectPacePerDay(String count);

  /// No description provided for @projectPaceRecent.
  ///
  /// In pt, this message translates to:
  /// **'Média dos últimos 7 dias: {count} por dia'**
  String projectPaceRecent(String count);

  /// No description provided for @projectPaceDone.
  ///
  /// In pt, this message translates to:
  /// **'Tudo feito'**
  String get projectPaceDone;

  /// No description provided for @projectBySection.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas por seção'**
  String get projectBySection;

  /// No description provided for @projectUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Próximas com prazo'**
  String get projectUpcoming;

  /// No description provided for @projectNoUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa com prazo pela frente.'**
  String get projectNoUpcoming;

  /// No description provided for @projectEvolution.
  ///
  /// In pt, this message translates to:
  /// **'Evolução (concluídas por dia)'**
  String get projectEvolution;

  /// No description provided for @projectLate.
  ///
  /// In pt, this message translates to:
  /// **'Atrasadas'**
  String get projectLate;

  /// No description provided for @projectLateDone.
  ///
  /// In pt, this message translates to:
  /// **'concluída depois do prazo'**
  String get projectLateDone;

  /// No description provided for @projectLateOpen.
  ///
  /// In pt, this message translates to:
  /// **'prazo vencido'**
  String get projectLateOpen;

  /// No description provided for @projectClose.
  ///
  /// In pt, this message translates to:
  /// **'Encerrar projeto'**
  String get projectClose;

  /// No description provided for @projectCloseConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Encerrar o projeto agora? O relatório final fica guardado e o projeto pode ser reaberto depois.'**
  String get projectCloseConfirm;

  /// No description provided for @projectClosedToast.
  ///
  /// In pt, this message translates to:
  /// **'Projeto encerrado'**
  String get projectClosedToast;

  /// No description provided for @projectReopen.
  ///
  /// In pt, this message translates to:
  /// **'Reabrir projeto'**
  String get projectReopen;

  /// No description provided for @projectReport.
  ///
  /// In pt, this message translates to:
  /// **'Relatório final'**
  String get projectReport;

  /// No description provided for @projectClosedOn.
  ///
  /// In pt, this message translates to:
  /// **'Encerrado em {date}'**
  String projectClosedOn(String date);

  /// No description provided for @projectReportPeriod.
  ///
  /// In pt, this message translates to:
  /// **'De {start} a {end}'**
  String projectReportPeriod(String start, String end);

  /// No description provided for @projectDeadlines.
  ///
  /// In pt, this message translates to:
  /// **'Prazos'**
  String get projectDeadlines;

  /// No description provided for @projectBestDay.
  ///
  /// In pt, this message translates to:
  /// **'Melhor dia'**
  String get projectBestDay;

  /// No description provided for @projectBestDayCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 concluída} other{{count} concluídas}}'**
  String projectBestDayCount(int count);

  /// No description provided for @projectNoTrophies.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum troféu desta vez.'**
  String get projectNoTrophies;

  /// No description provided for @trophyAllDone.
  ///
  /// In pt, this message translates to:
  /// **'Tudo concluído'**
  String get trophyAllDone;

  /// No description provided for @trophyAllDoneHint.
  ///
  /// In pt, this message translates to:
  /// **'Todas as tarefas do projeto foram concluídas'**
  String get trophyAllDoneHint;

  /// No description provided for @trophyAllOnTime.
  ///
  /// In pt, this message translates to:
  /// **'Tudo no prazo'**
  String get trophyAllOnTime;

  /// No description provided for @trophyAllOnTimeHint.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa com prazo atrasou'**
  String get trophyAllOnTimeHint;

  /// No description provided for @trophyStrongFinish.
  ///
  /// In pt, this message translates to:
  /// **'Reta final forte'**
  String get trophyStrongFinish;

  /// No description provided for @trophyStrongFinishHint.
  ///
  /// In pt, this message translates to:
  /// **'Os últimos 7 dias renderam acima da média do projeto (3 tarefas ou mais)'**
  String get trophyStrongFinishHint;

  /// No description provided for @trophyNoLate7.
  ///
  /// In pt, this message translates to:
  /// **'Sem atrasos 7 dias'**
  String get trophyNoLate7;

  /// No description provided for @trophyNoLate7Hint.
  ///
  /// In pt, this message translates to:
  /// **'Tudo o que vencia na última semana saiu no prazo'**
  String get trophyNoLate7Hint;

  /// No description provided for @listTypeTasks.
  ///
  /// In pt, this message translates to:
  /// **'Lista de tarefas'**
  String get listTypeTasks;

  /// No description provided for @listTypeNotes.
  ///
  /// In pt, this message translates to:
  /// **'Lista de notas'**
  String get listTypeNotes;

  /// No description provided for @listShowInSmartList.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar na Lista Inteligente'**
  String get listShowInSmartList;

  /// No description provided for @listShowAllTasks.
  ///
  /// In pt, this message translates to:
  /// **'Todas as tarefas'**
  String get listShowAllTasks;

  /// No description provided for @listDontShow.
  ///
  /// In pt, this message translates to:
  /// **'Não mostrar'**
  String get listDontShow;

  /// No description provided for @notesListCreated.
  ///
  /// In pt, this message translates to:
  /// **'Uma lista de notas foi criada com sucesso. Você pode escrever suas notas aqui.'**
  String get notesListCreated;

  /// No description provided for @gotIt.
  ///
  /// In pt, this message translates to:
  /// **'Eu sei'**
  String get gotIt;

  /// No description provided for @copySuffix.
  ///
  /// In pt, this message translates to:
  /// **' copiar'**
  String get copySuffix;

  /// No description provided for @actionCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// No description provided for @actionAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get actionAdd;

  /// No description provided for @actionSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get actionSave;

  /// No description provided for @actionClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get actionClose;

  /// No description provided for @actionOk.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get actionEdit;

  /// No description provided for @actionRename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get actionRename;

  /// No description provided for @actionDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar'**
  String get actionDuplicate;

  /// No description provided for @actionArchive.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar'**
  String get actionArchive;

  /// No description provided for @actionUnarchive.
  ///
  /// In pt, this message translates to:
  /// **'Lista de desarquivamento'**
  String get actionUnarchive;

  /// No description provided for @actionDelete.
  ///
  /// In pt, this message translates to:
  /// **'Deletar'**
  String get actionDelete;

  /// No description provided for @actionAddList.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar lista'**
  String get actionAddList;

  /// No description provided for @actionUngroup.
  ///
  /// In pt, this message translates to:
  /// **'Desagrupar'**
  String get actionUngroup;

  /// No description provided for @archiveListConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Se arquivada, esta lista será agrupada na pasta \'Listas Arquivadas\'. As tarefas e notas dentro desta lista não serão lembradas ou exibidas em \'Todas\' e outras Listas Inteligentes.'**
  String get archiveListConfirm;

  /// No description provided for @deleteListConfirm.
  ///
  /// In pt, this message translates to:
  /// **'A lista será excluída e as tarefas irão para a Lixeira.'**
  String get deleteListConfirm;

  /// No description provided for @tagAddTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Tags'**
  String get tagAddTitle;

  /// No description provided for @tagEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar tag'**
  String get tagEditTitle;

  /// No description provided for @tagNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get tagNameHint;

  /// No description provided for @tagColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor'**
  String get tagColor;

  /// No description provided for @tagParent.
  ///
  /// In pt, this message translates to:
  /// **'Tag principal'**
  String get tagParent;

  /// No description provided for @tagParentNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma'**
  String get tagParentNone;

  /// No description provided for @tagAddSubtag.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Sub-tag'**
  String get tagAddSubtag;

  /// No description provided for @tagMerge.
  ///
  /// In pt, this message translates to:
  /// **'Mesclar Tags'**
  String get tagMerge;

  /// No description provided for @tagMergeInto.
  ///
  /// In pt, this message translates to:
  /// **'Mesclar \'{name}\' em:'**
  String tagMergeInto(String name);

  /// No description provided for @colorNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma'**
  String get colorNone;

  /// No description provided for @sectionAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Seção'**
  String get sectionAdd;

  /// No description provided for @sectionNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova seção'**
  String get sectionNew;

  /// No description provided for @sectionAddLeft.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Seção à Esquerda'**
  String get sectionAddLeft;

  /// No description provided for @sectionAddRight.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Seção à Direita'**
  String get sectionAddRight;

  /// No description provided for @sortButtonTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar e agrupar'**
  String get sortButtonTooltip;

  /// No description provided for @groupByLabel.
  ///
  /// In pt, this message translates to:
  /// **'Agrupar por'**
  String get groupByLabel;

  /// No description provided for @sortByLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por'**
  String get sortByLabel;

  /// No description provided for @optionCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get optionCustom;

  /// No description provided for @optionDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get optionDate;

  /// No description provided for @optionModifiedTime.
  ///
  /// In pt, this message translates to:
  /// **'Hora de modificação'**
  String get optionModifiedTime;

  /// No description provided for @optionCreatedTime.
  ///
  /// In pt, this message translates to:
  /// **'Data de criação'**
  String get optionCreatedTime;

  /// No description provided for @optionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get optionTitle;

  /// No description provided for @optionTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get optionTag;

  /// No description provided for @optionPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get optionPriority;

  /// No description provided for @optionNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma'**
  String get optionNone;

  /// No description provided for @hideCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Esconder concluídas'**
  String get hideCompleted;

  /// No description provided for @showCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar concluídas'**
  String get showCompleted;

  /// No description provided for @showDetails.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar detalhes'**
  String get showDetails;

  /// No description provided for @hideDetails.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar Detalhes'**
  String get hideDetails;

  /// No description provided for @viewLabel.
  ///
  /// In pt, this message translates to:
  /// **'Visualização'**
  String get viewLabel;

  /// No description provided for @smartListShow.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar'**
  String get smartListShow;

  /// No description provided for @smartListHide.
  ///
  /// In pt, this message translates to:
  /// **'Esconder'**
  String get smartListHide;

  /// No description provided for @smartListShowIfNotEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar se não estiver vazio'**
  String get smartListShowIfNotEmpty;

  /// No description provided for @accountSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get accountSettings;

  /// No description provided for @accountBackup.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Backup'**
  String get accountBackup;

  /// No description provided for @accountImportBackup.
  ///
  /// In pt, this message translates to:
  /// **'Importar backups locais'**
  String get accountImportBackup;

  /// No description provided for @backupSaved.
  ///
  /// In pt, this message translates to:
  /// **'Backup salvo'**
  String get backupSaved;

  /// No description provided for @backupImported.
  ///
  /// In pt, this message translates to:
  /// **'Backup importado. O app vai recarregar os dados.'**
  String get backupImported;

  /// No description provided for @backupImportConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Importar este backup substitui todos os dados atuais deste aparelho. Continuar?'**
  String get backupImportConfirm;

  /// No description provided for @backupInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo de backup inválido.'**
  String get backupInvalid;

  /// No description provided for @emptyTrashTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Esvaziar lixeira'**
  String get emptyTrashTooltip;

  /// No description provided for @emptyTrashConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir definitivamente todas as tarefas da lixeira? Isso não pode ser desfeito.'**
  String get emptyTrashConfirm;

  /// No description provided for @slashText.
  ///
  /// In pt, this message translates to:
  /// **'Texto'**
  String get slashText;

  /// No description provided for @slashHeading1.
  ///
  /// In pt, this message translates to:
  /// **'Título 1'**
  String get slashHeading1;

  /// No description provided for @slashHeading2.
  ///
  /// In pt, this message translates to:
  /// **'Título 2'**
  String get slashHeading2;

  /// No description provided for @slashHeading3.
  ///
  /// In pt, this message translates to:
  /// **'Título 3'**
  String get slashHeading3;

  /// No description provided for @slashBulletedList.
  ///
  /// In pt, this message translates to:
  /// **'Lista com marcadores'**
  String get slashBulletedList;

  /// No description provided for @slashNumberedList.
  ///
  /// In pt, this message translates to:
  /// **'Lista numerada'**
  String get slashNumberedList;

  /// No description provided for @slashChecklistItem.
  ///
  /// In pt, this message translates to:
  /// **'Item de verificação'**
  String get slashChecklistItem;

  /// No description provided for @slashQuote.
  ///
  /// In pt, this message translates to:
  /// **'Citação'**
  String get slashQuote;

  /// No description provided for @slashDivider.
  ///
  /// In pt, this message translates to:
  /// **'Linha horizontal'**
  String get slashDivider;

  /// No description provided for @pickerTabDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get pickerTabDate;

  /// No description provided for @pickerTime.
  ///
  /// In pt, this message translates to:
  /// **'Hora'**
  String get pickerTime;

  /// No description provided for @pickerReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete'**
  String get pickerReminder;

  /// No description provided for @pickerRepeat.
  ///
  /// In pt, this message translates to:
  /// **'Repetir'**
  String get pickerRepeat;

  /// No description provided for @pickerNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma'**
  String get pickerNone;

  /// No description provided for @pickerNextMonth.
  ///
  /// In pt, this message translates to:
  /// **'Próximo mês'**
  String get pickerNextMonth;

  /// No description provided for @pickerToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get pickerToday;

  /// No description provided for @weekInitialSunday.
  ///
  /// In pt, this message translates to:
  /// **'D'**
  String get weekInitialSunday;

  /// No description provided for @weekInitialMonday.
  ///
  /// In pt, this message translates to:
  /// **'S'**
  String get weekInitialMonday;

  /// No description provided for @weekInitialTuesday.
  ///
  /// In pt, this message translates to:
  /// **'T'**
  String get weekInitialTuesday;

  /// No description provided for @weekInitialWednesday.
  ///
  /// In pt, this message translates to:
  /// **'Q'**
  String get weekInitialWednesday;

  /// No description provided for @weekInitialThursday.
  ///
  /// In pt, this message translates to:
  /// **'Q'**
  String get weekInitialThursday;

  /// No description provided for @weekInitialFriday.
  ///
  /// In pt, this message translates to:
  /// **'S'**
  String get weekInitialFriday;

  /// No description provided for @weekInitialSaturday.
  ///
  /// In pt, this message translates to:
  /// **'S'**
  String get weekInitialSaturday;

  /// No description provided for @repeatDaily.
  ///
  /// In pt, this message translates to:
  /// **'Diariamente'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal ({weekday})'**
  String repeatWeekly(String weekday);

  /// No description provided for @repeatMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal ({day}º)'**
  String repeatMonthly(int day);

  /// No description provided for @repeatYearly.
  ///
  /// In pt, this message translates to:
  /// **'Anualmente ({day}º {month})'**
  String repeatYearly(int day, String month);

  /// No description provided for @repeatWeekdays.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dias úteis (Seg-Sex)'**
  String get repeatWeekdays;

  /// No description provided for @repeatPickWorkdays.
  ///
  /// In pt, this message translates to:
  /// **'Dias úteis'**
  String get repeatPickWorkdays;

  /// No description provided for @repeatPickWeekend.
  ///
  /// In pt, this message translates to:
  /// **'Fim de semana'**
  String get repeatPickWeekend;

  /// No description provided for @repeatPickAllDays.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get repeatPickAllDays;

  /// No description provided for @repeatCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get repeatCustom;

  /// No description provided for @repeatEnds.
  ///
  /// In pt, this message translates to:
  /// **'A repetição termina'**
  String get repeatEnds;

  /// No description provided for @repeatEndsNever.
  ///
  /// In pt, this message translates to:
  /// **'Para sempre'**
  String get repeatEndsNever;

  /// No description provided for @repeatEndsOnDate.
  ///
  /// In pt, this message translates to:
  /// **'Termina na data'**
  String get repeatEndsOnDate;

  /// No description provided for @repeatEndsAfterCount.
  ///
  /// In pt, this message translates to:
  /// **'Terminar por uma contagem repetida'**
  String get repeatEndsAfterCount;

  /// No description provided for @repeatTimesLeft.
  ///
  /// In pt, this message translates to:
  /// **'Em {count} tempos'**
  String repeatTimesLeft(int count);

  /// No description provided for @repeatTimesHint.
  ///
  /// In pt, this message translates to:
  /// **'repetir vezes'**
  String get repeatTimesHint;

  /// No description provided for @repeatFromDue.
  ///
  /// In pt, this message translates to:
  /// **'Por datas de vencimento'**
  String get repeatFromDue;

  /// No description provided for @repeatFromCompletion.
  ///
  /// In pt, this message translates to:
  /// **'Por Data de Conclusão'**
  String get repeatFromCompletion;

  /// No description provided for @repeatEvery.
  ///
  /// In pt, this message translates to:
  /// **'A cada'**
  String get repeatEvery;

  /// No description provided for @unitDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get unitDay;

  /// No description provided for @unitWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana'**
  String get unitWeek;

  /// No description provided for @unitMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get unitMonth;

  /// No description provided for @unitYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get unitYear;

  /// No description provided for @unitMinutes.
  ///
  /// In pt, this message translates to:
  /// **'Minutos'**
  String get unitMinutes;

  /// No description provided for @unitHours.
  ///
  /// In pt, this message translates to:
  /// **'Horas'**
  String get unitHours;

  /// No description provided for @unitDays.
  ///
  /// In pt, this message translates to:
  /// **'Dias'**
  String get unitDays;

  /// No description provided for @reminderOnTime.
  ///
  /// In pt, this message translates to:
  /// **'Na hora'**
  String get reminderOnTime;

  /// No description provided for @reminder5m.
  ///
  /// In pt, this message translates to:
  /// **'5 minutos antes'**
  String get reminder5m;

  /// No description provided for @reminder30m.
  ///
  /// In pt, this message translates to:
  /// **'30 minutos antes'**
  String get reminder30m;

  /// No description provided for @reminder1h.
  ///
  /// In pt, this message translates to:
  /// **'1 hora antes'**
  String get reminder1h;

  /// No description provided for @reminder1d.
  ///
  /// In pt, this message translates to:
  /// **'1 dia antes'**
  String get reminder1d;

  /// No description provided for @reminderOnTheDay.
  ///
  /// In pt, this message translates to:
  /// **'No dia (09:00)'**
  String get reminderOnTheDay;

  /// No description provided for @reminder1dAt9.
  ///
  /// In pt, this message translates to:
  /// **'1 dia antes (09:00)'**
  String get reminder1dAt9;

  /// No description provided for @reminder2dAt9.
  ///
  /// In pt, this message translates to:
  /// **'2 dias antes (09:00)'**
  String get reminder2dAt9;

  /// No description provided for @reminder3dAt9.
  ///
  /// In pt, this message translates to:
  /// **'3 dias antes (09:00)'**
  String get reminder3dAt9;

  /// No description provided for @reminder1wAt9.
  ///
  /// In pt, this message translates to:
  /// **'1 semana antes (09:00)'**
  String get reminder1wAt9;

  /// No description provided for @reminderCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get reminderCustom;

  /// No description provided for @reminderCustomValue.
  ///
  /// In pt, this message translates to:
  /// **'{value} {unit} antes'**
  String reminderCustomValue(int value, String unit);

  /// No description provided for @reminderPreview.
  ///
  /// In pt, this message translates to:
  /// **'Lembre-se em {time}'**
  String reminderPreview(String time);

  /// No description provided for @notificationChannelName.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes das tarefas'**
  String get notificationChannelDescription;

  /// No description provided for @notificationActionComplete.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get notificationActionComplete;

  /// No description provided for @notificationActionSnooze.
  ///
  /// In pt, this message translates to:
  /// **'Adiar 15 min'**
  String get notificationActionSnooze;

  /// No description provided for @snoozedUntil.
  ///
  /// In pt, this message translates to:
  /// **'adiar até {time}'**
  String snoozedUntil(String time);

  /// No description provided for @reminderPopupSnooze.
  ///
  /// In pt, this message translates to:
  /// **'Adiar'**
  String get reminderPopupSnooze;

  /// No description provided for @reminderPopupDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get reminderPopupDone;

  /// No description provided for @reminderPopupDismiss.
  ///
  /// In pt, this message translates to:
  /// **'Dispensar'**
  String get reminderPopupDismiss;

  /// No description provided for @snooze15m.
  ///
  /// In pt, this message translates to:
  /// **'15 minutos'**
  String get snooze15m;

  /// No description provided for @snooze30m.
  ///
  /// In pt, this message translates to:
  /// **'30 minutos'**
  String get snooze30m;

  /// No description provided for @snooze1h.
  ///
  /// In pt, this message translates to:
  /// **'1 hora'**
  String get snooze1h;

  /// No description provided for @snooze3h.
  ///
  /// In pt, this message translates to:
  /// **'3 horas'**
  String get snooze3h;

  /// No description provided for @snoozeTonight.
  ///
  /// In pt, this message translates to:
  /// **'Hoje à noite'**
  String get snoozeTonight;

  /// No description provided for @snoozeTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get snoozeTomorrow;

  /// No description provided for @snoozeCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get snoozeCustom;

  /// No description provided for @repeatSpecificDates.
  ///
  /// In pt, this message translates to:
  /// **'Por datas específicas'**
  String get repeatSpecificDates;

  /// No description provided for @repeatMonthEach.
  ///
  /// In pt, this message translates to:
  /// **'Cada'**
  String get repeatMonthEach;

  /// No description provided for @repeatMonthOn.
  ///
  /// In pt, this message translates to:
  /// **'No'**
  String get repeatMonthOn;

  /// No description provided for @repeatMonthWorkday.
  ///
  /// In pt, this message translates to:
  /// **'Dia útil'**
  String get repeatMonthWorkday;

  /// No description provided for @repeatLastDay.
  ///
  /// In pt, this message translates to:
  /// **'Último dia'**
  String get repeatLastDay;

  /// No description provided for @ordinalFirst.
  ///
  /// In pt, this message translates to:
  /// **'primeiro'**
  String get ordinalFirst;

  /// No description provided for @ordinalSecond.
  ///
  /// In pt, this message translates to:
  /// **'segundo'**
  String get ordinalSecond;

  /// No description provided for @ordinalThird.
  ///
  /// In pt, this message translates to:
  /// **'terceiro'**
  String get ordinalThird;

  /// No description provided for @ordinalFourth.
  ///
  /// In pt, this message translates to:
  /// **'quarto'**
  String get ordinalFourth;

  /// No description provided for @ordinalLast.
  ///
  /// In pt, this message translates to:
  /// **'último'**
  String get ordinalLast;

  /// No description provided for @workdayFirst.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro dia útil'**
  String get workdayFirst;

  /// No description provided for @workdayLast.
  ///
  /// In pt, this message translates to:
  /// **'Último dia útil'**
  String get workdayLast;

  /// No description provided for @repeatPickDates.
  ///
  /// In pt, this message translates to:
  /// **'Escolha os dias no calendário'**
  String get repeatPickDates;

  /// No description provided for @quickAddCreateTag.
  ///
  /// In pt, this message translates to:
  /// **'Criar Tag \'{name}\''**
  String quickAddCreateTag(String name);

  /// No description provided for @quickAddNextWeekday.
  ///
  /// In pt, this message translates to:
  /// **'Próxima {weekday}'**
  String quickAddNextWeekday(String weekday);

  /// No description provided for @pickerTabDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get pickerTabDuration;

  /// No description provided for @pickerStart.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get pickerStart;

  /// No description provided for @pickerEnd.
  ///
  /// In pt, this message translates to:
  /// **'Fim'**
  String get pickerEnd;

  /// No description provided for @pickerAllDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia inteiro'**
  String get pickerAllDay;

  /// No description provided for @viewOptions.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar Opções'**
  String get viewOptions;

  /// No description provided for @showDateBy.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar Data por'**
  String get showDateBy;

  /// No description provided for @dateDisplayDate.
  ///
  /// In pt, this message translates to:
  /// **'Tempo da tarefa'**
  String get dateDisplayDate;

  /// No description provided for @dateDisplayCountdown.
  ///
  /// In pt, this message translates to:
  /// **'Contagem regressiva'**
  String get dateDisplayCountdown;

  /// No description provided for @countdownInDays.
  ///
  /// In pt, this message translates to:
  /// **'em {count} dias'**
  String countdownInDays(int count);

  /// No description provided for @countdownDaysAgo.
  ///
  /// In pt, this message translates to:
  /// **'há {count} dias'**
  String countdownDaysAgo(int count);

  /// No description provided for @dailyDigestTitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Você tem 1 tarefa para hoje} other{Você tem {count} tarefas para hoje}}'**
  String dailyDigestTitle(int count);

  /// No description provided for @settingsDailyNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações diárias'**
  String get settingsDailyNotifications;

  /// No description provided for @settingsDailyNotificationsHint.
  ///
  /// In pt, this message translates to:
  /// **'Um lembrete por dia com as tarefas de hoje'**
  String get settingsDailyNotificationsHint;

  /// No description provided for @settingsDailyAlertTime.
  ///
  /// In pt, this message translates to:
  /// **'Horário de Alerta Diário'**
  String get settingsDailyAlertTime;

  /// No description provided for @settingsConstantReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete Constante Global'**
  String get settingsConstantReminder;

  /// No description provided for @settingsConstantReminderHint.
  ///
  /// In pt, this message translates to:
  /// **'A notificação persiste até você agir'**
  String get settingsConstantReminderHint;

  /// No description provided for @checklistItemReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete do item'**
  String get checklistItemReminder;

  /// No description provided for @shortcutsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atalhos'**
  String get shortcutsTitle;

  /// No description provided for @shortcutsGeneral.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get shortcutsGeneral;

  /// No description provided for @shortcutsTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa'**
  String get shortcutsTask;

  /// No description provided for @shortcutsEditTask.
  ///
  /// In pt, this message translates to:
  /// **'Editar tarefa'**
  String get shortcutsEditTask;

  /// No description provided for @shortcutsNavigation.
  ///
  /// In pt, this message translates to:
  /// **'Navegação'**
  String get shortcutsNavigation;

  /// No description provided for @shortcutCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get shortcutCancel;

  /// No description provided for @shortcutPalette.
  ///
  /// In pt, this message translates to:
  /// **'Menu de comandos'**
  String get shortcutPalette;

  /// No description provided for @shortcutList.
  ///
  /// In pt, this message translates to:
  /// **'Lista de atalhos'**
  String get shortcutList;

  /// No description provided for @shortcutAddTask.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar tarefa'**
  String get shortcutAddTask;

  /// No description provided for @shortcutAddTaskBelow.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar tarefa abaixo'**
  String get shortcutAddTaskBelow;

  /// No description provided for @shortcutAddSubtask.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar subtarefa'**
  String get shortcutAddSubtask;

  /// No description provided for @shortcutToggleSubtasks.
  ///
  /// In pt, this message translates to:
  /// **'Expandir/Recolher subtarefas'**
  String get shortcutToggleSubtasks;

  /// No description provided for @shortcutComplete.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get shortcutComplete;

  /// No description provided for @shortcutPin.
  ///
  /// In pt, this message translates to:
  /// **'Fixar'**
  String get shortcutPin;

  /// No description provided for @shortcutDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get shortcutDelete;

  /// No description provided for @shortcutSetDate.
  ///
  /// In pt, this message translates to:
  /// **'Definir data'**
  String get shortcutSetDate;

  /// No description provided for @shortcutNoDate.
  ///
  /// In pt, this message translates to:
  /// **'Sem data'**
  String get shortcutNoDate;

  /// No description provided for @shortcutQuickDates.
  ///
  /// In pt, this message translates to:
  /// **'Hoje / Amanhã / Próx. semana'**
  String get shortcutQuickDates;

  /// No description provided for @shortcutPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get shortcutPriority;

  /// No description provided for @shortcutSearch.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar'**
  String get shortcutSearch;

  /// No description provided for @shortcutSettings.
  ///
  /// In pt, this message translates to:
  /// **'Ir para Configurações'**
  String get shortcutSettings;

  /// No description provided for @shortcutGoSmart.
  ///
  /// In pt, this message translates to:
  /// **'Todas / Hoje / Amanhã / Próx. 7 dias'**
  String get shortcutGoSmart;

  /// No description provided for @shortcutGoInbox.
  ///
  /// In pt, this message translates to:
  /// **'Caixa de entrada'**
  String get shortcutGoInbox;

  /// No description provided for @paletteHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite um comando ou pesquise'**
  String get paletteHint;

  /// No description provided for @paletteNewTask.
  ///
  /// In pt, this message translates to:
  /// **'Nova tarefa'**
  String get paletteNewTask;

  /// No description provided for @paletteSearchFor.
  ///
  /// In pt, this message translates to:
  /// **'Buscar \'{term}\''**
  String paletteSearchFor(String term);

  /// No description provided for @searchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar'**
  String get searchHint;

  /// No description provided for @searchTabTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa'**
  String get searchTabTask;

  /// No description provided for @searchTabTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get searchTabTag;

  /// No description provided for @searchTabList.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get searchTabList;

  /// No description provided for @searchNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado'**
  String get searchNoResults;

  /// No description provided for @searchNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não encontrou o que procura?'**
  String get searchNotFound;

  /// No description provided for @searchFullPage.
  ///
  /// In pt, this message translates to:
  /// **'Experimente a pesquisa completa.'**
  String get searchFullPage;

  /// No description provided for @searchLookFor.
  ///
  /// In pt, this message translates to:
  /// **'Procurar por'**
  String get searchLookFor;

  /// No description provided for @searchFilterLists.
  ///
  /// In pt, this message translates to:
  /// **'Listas'**
  String get searchFilterLists;

  /// No description provided for @searchFilterTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get searchFilterTag;

  /// No description provided for @searchFilterDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get searchFilterDate;

  /// No description provided for @searchFilterPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get searchFilterPriority;

  /// No description provided for @searchFilterType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get searchFilterType;

  /// No description provided for @searchFilterStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get searchFilterStatus;

  /// No description provided for @searchAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get searchAll;

  /// No description provided for @searchDateAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get searchDateAll;

  /// No description provided for @searchDateThisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana ({range})'**
  String searchDateThisWeek(String range);

  /// No description provided for @searchDateNextWeek.
  ///
  /// In pt, this message translates to:
  /// **'Próxima Semana'**
  String get searchDateNextWeek;

  /// No description provided for @searchDateLastWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana passada'**
  String get searchDateLastWeek;

  /// No description provided for @searchDateThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get searchDateThisMonth;

  /// No description provided for @searchDateLastMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês passado'**
  String get searchDateLastMonth;

  /// No description provided for @searchDateCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get searchDateCustom;

  /// No description provided for @searchTypeTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa'**
  String get searchTypeTask;

  /// No description provided for @searchTypeNote.
  ///
  /// In pt, this message translates to:
  /// **'Nota'**
  String get searchTypeNote;

  /// No description provided for @searchStatusOpen.
  ///
  /// In pt, this message translates to:
  /// **'Incompleta'**
  String get searchStatusOpen;

  /// No description provided for @searchStatusCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get searchStatusCompleted;

  /// No description provided for @searchStatusWontDo.
  ///
  /// In pt, this message translates to:
  /// **'Não será feito'**
  String get searchStatusWontDo;

  /// No description provided for @searchResultCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhuma tarefa} =1{1 tarefa} other{{count} tarefas}}'**
  String searchResultCount(int count);

  /// No description provided for @quickAddButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get quickAddButton;

  /// No description provided for @menuSelect.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar'**
  String get menuSelect;

  /// No description provided for @batchSelected.
  ///
  /// In pt, this message translates to:
  /// **'Você escolheu {count} itens'**
  String batchSelected(int count);

  /// No description provided for @batchDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Dia do vencimento'**
  String get batchDueDate;

  /// No description provided for @batchPostpone.
  ///
  /// In pt, this message translates to:
  /// **'Atrasar'**
  String get batchPostpone;

  /// No description provided for @postpone1Day.
  ///
  /// In pt, this message translates to:
  /// **'Adiar por 1 dia'**
  String get postpone1Day;

  /// No description provided for @postpone1Week.
  ///
  /// In pt, this message translates to:
  /// **'Adiar por 1 semana'**
  String get postpone1Week;

  /// No description provided for @postponeCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get postponeCustom;

  /// No description provided for @postponeDaysPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Adiar por quantos dias?'**
  String get postponeDaysPrompt;

  /// No description provided for @batchPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get batchPriority;

  /// No description provided for @batchList.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get batchList;

  /// No description provided for @batchTags.
  ///
  /// In pt, this message translates to:
  /// **'Etiquetas'**
  String get batchTags;

  /// No description provided for @batchComplete.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get batchComplete;

  /// No description provided for @batchPin.
  ///
  /// In pt, this message translates to:
  /// **'Fixar'**
  String get batchPin;

  /// No description provided for @batchWontDo.
  ///
  /// In pt, this message translates to:
  /// **'Não farei'**
  String get batchWontDo;

  /// No description provided for @batchLinkParent.
  ///
  /// In pt, this message translates to:
  /// **'Vincular Tarefa Pai'**
  String get batchLinkParent;

  /// No description provided for @batchMerge.
  ///
  /// In pt, this message translates to:
  /// **'Mesclar'**
  String get batchMerge;

  /// No description provided for @batchDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar'**
  String get batchDuplicate;

  /// No description provided for @batchConvertNote.
  ///
  /// In pt, this message translates to:
  /// **'Converter para nota'**
  String get batchConvertNote;

  /// No description provided for @batchCopyText.
  ///
  /// In pt, this message translates to:
  /// **'Copiar Texto'**
  String get batchCopyText;

  /// No description provided for @batchDelete.
  ///
  /// In pt, this message translates to:
  /// **'Deletar'**
  String get batchDelete;

  /// No description provided for @mergeConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Estas {count} tarefas serão convertidas em sub-tarefas do novo trabalho combinado.'**
  String mergeConfirm(int count);

  /// No description provided for @mergedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova tarefa mesclada.'**
  String get mergedTitle;

  /// No description provided for @selectAll.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Tudo'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In pt, this message translates to:
  /// **'Desmarcar Todos'**
  String get deselectAll;

  /// No description provided for @toastCopied.
  ///
  /// In pt, this message translates to:
  /// **'Copiado'**
  String get toastCopied;

  /// No description provided for @templateSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar como modelo'**
  String get templateSave;

  /// No description provided for @templateSaveHint.
  ///
  /// In pt, this message translates to:
  /// **'O conteúdo e as tags serão salvos no modelo.'**
  String get templateSaveHint;

  /// No description provided for @templateNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome do modelo'**
  String get templateNameHint;

  /// No description provided for @templateAddFrom.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar a partir do modelo'**
  String get templateAddFrom;

  /// No description provided for @templatePickerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modelo de tarefa'**
  String get templatePickerTitle;

  /// No description provided for @templateManage.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar modelo'**
  String get templateManage;

  /// No description provided for @templateEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum modelo'**
  String get templateEmpty;

  /// No description provided for @templateBeforeWorkName.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas antes do trabalho'**
  String get templateBeforeWorkName;

  /// No description provided for @templateBeforeWorkItems.
  ///
  /// In pt, this message translates to:
  /// **'Revisar a agenda do dia\nConferir os e-mails importantes\nDefinir as 3 prioridades do dia\nPreparar os materiais das reuniões\nOrganizar a mesa de trabalho\nAtualizar a lista de tarefas\nBeber um copo de água'**
  String get templateBeforeWorkItems;

  /// No description provided for @templateDailyRecordName.
  ///
  /// In pt, this message translates to:
  /// **'Daily record'**
  String get templateDailyRecordName;

  /// No description provided for @templateDailyRecordContent.
  ///
  /// In pt, this message translates to:
  /// **'**O que eu fiz hoje?**\n\n**O que deu certo?**\n\n**O que posso melhorar amanhã?**\n\n**Pelo que sou grato hoje?**'**
  String get templateDailyRecordContent;

  /// No description provided for @templateTravelName.
  ///
  /// In pt, this message translates to:
  /// **'Coisas para embalar para viajar'**
  String get templateTravelName;

  /// No description provided for @templateTravelItems.
  ///
  /// In pt, this message translates to:
  /// **'Documentos e passaporte\nCarteira e cartões\nCelular e carregador\nFones de ouvido\nRoupas\nRoupas íntimas e meias\nPijama\nSapatos\nEscova e pasta de dente\nDesodorante\nXampu e condicionador\nRemédios\nProtetor solar\nÓculos\nGuarda-chuva'**
  String get templateTravelItems;

  /// No description provided for @commentsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Comentários'**
  String get commentsTitle;

  /// No description provided for @commentHint.
  ///
  /// In pt, this message translates to:
  /// **'Escrever um comentário'**
  String get commentHint;

  /// No description provided for @commentAuthor.
  ///
  /// In pt, this message translates to:
  /// **'Você'**
  String get commentAuthor;

  /// No description provided for @commentJustNow.
  ///
  /// In pt, this message translates to:
  /// **'Agora mesmo'**
  String get commentJustNow;

  /// No description provided for @commentMinutesAgo.
  ///
  /// In pt, this message translates to:
  /// **'há {count} min'**
  String commentMinutesAgo(int count);

  /// No description provided for @commentHoursAgo.
  ///
  /// In pt, this message translates to:
  /// **'há {count} h'**
  String commentHoursAgo(int count);

  /// No description provided for @commentEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get commentEdit;

  /// No description provided for @commentDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get commentDelete;

  /// No description provided for @slashLinkedTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa/nota vinculada'**
  String get slashLinkedTask;

  /// No description provided for @slashAttachment.
  ///
  /// In pt, this message translates to:
  /// **'Anexo'**
  String get slashAttachment;

  /// No description provided for @menuExport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar'**
  String get menuExport;

  /// No description provided for @menuPrint.
  ///
  /// In pt, this message translates to:
  /// **'Imprimir'**
  String get menuPrint;

  /// No description provided for @exportMarkdown.
  ///
  /// In pt, this message translates to:
  /// **'Markdown'**
  String get exportMarkdown;

  /// No description provided for @exportPlainText.
  ///
  /// In pt, this message translates to:
  /// **'Plain Text'**
  String get exportPlainText;

  /// No description provided for @exportCopy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get exportCopy;

  /// No description provided for @attachmentOpenExternal.
  ///
  /// In pt, this message translates to:
  /// **'Abrir no app do sistema'**
  String get attachmentOpenExternal;

  /// No description provided for @exportDownload.
  ///
  /// In pt, this message translates to:
  /// **'Baixar'**
  String get exportDownload;

  /// No description provided for @navCountdown.
  ///
  /// In pt, this message translates to:
  /// **'Contagem Regressiva'**
  String get navCountdown;

  /// No description provided for @countdownActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get countdownActive;

  /// No description provided for @countdownArchived.
  ///
  /// In pt, this message translates to:
  /// **'Arquivado'**
  String get countdownArchived;

  /// No description provided for @countdownArchivedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contagens Regressivas Arquivadas'**
  String get countdownArchivedTitle;

  /// No description provided for @countdownShowGroup.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar Grupo'**
  String get countdownShowGroup;

  /// No description provided for @countdownTypeCountdown.
  ///
  /// In pt, this message translates to:
  /// **'Contagem Regressiva'**
  String get countdownTypeCountdown;

  /// No description provided for @countdownTypeSpecial.
  ///
  /// In pt, this message translates to:
  /// **'Data Especial'**
  String get countdownTypeSpecial;

  /// No description provided for @countdownTypeBirthday.
  ///
  /// In pt, this message translates to:
  /// **'Aniversário'**
  String get countdownTypeBirthday;

  /// No description provided for @countdownTypeHoliday.
  ///
  /// In pt, this message translates to:
  /// **'Feriado'**
  String get countdownTypeHoliday;

  /// No description provided for @countdownToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje {date}'**
  String countdownToday(String date);

  /// No description provided for @countdownDaysUntil.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Dia até {date}} other{Dias até {date}}}'**
  String countdownDaysUntil(int count, String date);

  /// No description provided for @countdownDaysSince.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Dia desde {date}} other{Dias desde {date}}}'**
  String countdownDaysSince(int count, String date);

  /// No description provided for @countdownAge.
  ///
  /// In pt, this message translates to:
  /// **'{age} anos'**
  String countdownAge(int age);

  /// No description provided for @countdownDaysAway.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Hoje} =1{Amanhã} other{Em {count} dias}}'**
  String countdownDaysAway(int count);

  /// No description provided for @countdownName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get countdownName;

  /// No description provided for @countdownDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get countdownDate;

  /// No description provided for @countdownType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get countdownType;

  /// No description provided for @countdownCountMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo de Cálculo de Dias'**
  String get countdownCountMode;

  /// No description provided for @countModeStandard.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get countModeStandard;

  /// No description provided for @countModeStandardHint.
  ///
  /// In pt, this message translates to:
  /// **'O Dia 1 começa no dia seguinte à data selecionada'**
  String get countModeStandardHint;

  /// No description provided for @countModePlusOne.
  ///
  /// In pt, this message translates to:
  /// **'Padrão +1 dia'**
  String get countModePlusOne;

  /// No description provided for @countModePlusOneHint.
  ///
  /// In pt, this message translates to:
  /// **'O Dia 1 começa na data selecionada'**
  String get countModePlusOneHint;

  /// No description provided for @countdownVisibility.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar na Lista Inteligente'**
  String get countdownVisibility;

  /// No description provided for @visibilityOnTheDay.
  ///
  /// In pt, this message translates to:
  /// **'No dia'**
  String get visibilityOnTheDay;

  /// No description provided for @visibilityThreeDays.
  ///
  /// In pt, this message translates to:
  /// **'3 dias de antecedência'**
  String get visibilityThreeDays;

  /// No description provided for @visibilitySevenDays.
  ///
  /// In pt, this message translates to:
  /// **'7 dias de antecedência'**
  String get visibilitySevenDays;

  /// No description provided for @visibilityAlways.
  ///
  /// In pt, this message translates to:
  /// **'Sempre mostrar'**
  String get visibilityAlways;

  /// No description provided for @visibilityNever.
  ///
  /// In pt, this message translates to:
  /// **'Não mostrar'**
  String get visibilityNever;

  /// No description provided for @countdownIgnoreYear.
  ///
  /// In pt, this message translates to:
  /// **'Ignorar ano'**
  String get countdownIgnoreYear;

  /// No description provided for @countdownShowAge.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar idade'**
  String get countdownShowAge;

  /// No description provided for @actionNext.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get actionBack;

  /// No description provided for @countdownStyle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo'**
  String get countdownStyle;

  /// No description provided for @countdownColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor'**
  String get countdownColor;

  /// No description provided for @countdownEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get countdownEdit;

  /// No description provided for @countdownNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get countdownNotes;

  /// No description provided for @countdownArchive.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar'**
  String get countdownArchive;

  /// No description provided for @countdownRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get countdownRestore;

  /// No description provided for @countdownDelete.
  ///
  /// In pt, this message translates to:
  /// **'Deletar'**
  String get countdownDelete;

  /// No description provided for @countdownPin.
  ///
  /// In pt, this message translates to:
  /// **'Fixar'**
  String get countdownPin;

  /// No description provided for @countdownUnpin.
  ///
  /// In pt, this message translates to:
  /// **'Desafixar'**
  String get countdownUnpin;

  /// No description provided for @countdownEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma contagem regressiva'**
  String get countdownEmpty;

  /// No description provided for @countdownSeedUseApp.
  ///
  /// In pt, this message translates to:
  /// **'Use o Ordo'**
  String get countdownSeedUseApp;

  /// No description provided for @countdownSeedWeekend.
  ///
  /// In pt, this message translates to:
  /// **'Fim de semana'**
  String get countdownSeedWeekend;

  /// No description provided for @countdownSeedNewYear.
  ///
  /// In pt, this message translates to:
  /// **'Dia de Ano Novo'**
  String get countdownSeedNewYear;

  /// No description provided for @countdownSpecialSuggestions.
  ///
  /// In pt, this message translates to:
  /// **'Aniversário de Graduação\nAniversário de Trabalho\nAniversário de Namoro\nDia do Pedido de Casamento\nDia da Licença de Casamento\nAniversário de Casamento\n100 Dias Juntos\nAniversário de Matrícula'**
  String get countdownSpecialSuggestions;

  /// No description provided for @navFocus.
  ///
  /// In pt, this message translates to:
  /// **'Foco'**
  String get navFocus;

  /// No description provided for @focusTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pomodoro'**
  String get focusTitle;

  /// No description provided for @focusTabPomo.
  ///
  /// In pt, this message translates to:
  /// **'Pomo'**
  String get focusTabPomo;

  /// No description provided for @focusTabStopwatch.
  ///
  /// In pt, this message translates to:
  /// **'Cronômetro'**
  String get focusTabStopwatch;

  /// No description provided for @focusLink.
  ///
  /// In pt, this message translates to:
  /// **'Foco'**
  String get focusLink;

  /// No description provided for @focusStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get focusStart;

  /// No description provided for @focusPause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar'**
  String get focusPause;

  /// No description provided for @focusContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get focusContinue;

  /// No description provided for @focusEnd.
  ///
  /// In pt, this message translates to:
  /// **'Fim'**
  String get focusEnd;

  /// No description provided for @focusPaused.
  ///
  /// In pt, this message translates to:
  /// **'Pausado'**
  String get focusPaused;

  /// No description provided for @focusNotes.
  ///
  /// In pt, this message translates to:
  /// **'Foco em Notas'**
  String get focusNotes;

  /// No description provided for @focusNotesHint.
  ///
  /// In pt, this message translates to:
  /// **'O que você tem em mente? Registre suas ideias…'**
  String get focusNotesHint;

  /// No description provided for @focusDoneTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você tem um Pomo.'**
  String get focusDoneTitle;

  /// No description provided for @focusDoneBody.
  ///
  /// In pt, this message translates to:
  /// **'Descanse por {minutes} minutos.'**
  String focusDoneBody(int minutes);

  /// No description provided for @focusRelax.
  ///
  /// In pt, this message translates to:
  /// **'Relaxar'**
  String get focusRelax;

  /// No description provided for @focusSkip.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get focusSkip;

  /// No description provided for @focusExit.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get focusExit;

  /// No description provided for @focusBreak.
  ///
  /// In pt, this message translates to:
  /// **'Pausa'**
  String get focusBreak;

  /// No description provided for @focusLongBreak.
  ///
  /// In pt, this message translates to:
  /// **'Pausa longa'**
  String get focusLongBreak;

  /// No description provided for @focusOverview.
  ///
  /// In pt, this message translates to:
  /// **'Visão geral'**
  String get focusOverview;

  /// No description provided for @focusTodayPomos.
  ///
  /// In pt, this message translates to:
  /// **'Pomo de hoje'**
  String get focusTodayPomos;

  /// No description provided for @focusTodayDuration.
  ///
  /// In pt, this message translates to:
  /// **'Foco de hoje'**
  String get focusTodayDuration;

  /// No description provided for @focusTotalPomos.
  ///
  /// In pt, this message translates to:
  /// **'Pomo Total'**
  String get focusTotalPomos;

  /// No description provided for @focusTotalDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração Total Focada'**
  String get focusTotalDuration;

  /// No description provided for @focusRecords.
  ///
  /// In pt, this message translates to:
  /// **'Foco em registro.'**
  String get focusRecords;

  /// No description provided for @focusRecordsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há registro de foco.'**
  String get focusRecordsEmpty;

  /// No description provided for @focusDeleteAll.
  ///
  /// In pt, this message translates to:
  /// **'Excluir tudo'**
  String get focusDeleteAll;

  /// No description provided for @focusAddRecord.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar registro'**
  String get focusAddRecord;

  /// No description provided for @focusSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações de foco'**
  String get focusSettings;

  /// No description provided for @focusPomoLength.
  ///
  /// In pt, this message translates to:
  /// **'Duração do Pomo'**
  String get focusPomoLength;

  /// No description provided for @focusShortBreakLength.
  ///
  /// In pt, this message translates to:
  /// **'Duração da Pausa Curta'**
  String get focusShortBreakLength;

  /// No description provided for @focusLongBreakLength.
  ///
  /// In pt, this message translates to:
  /// **'Duração da Pausa Longa'**
  String get focusLongBreakLength;

  /// No description provided for @focusLongEvery.
  ///
  /// In pt, this message translates to:
  /// **'Pomos para intervalo longo'**
  String get focusLongEvery;

  /// No description provided for @focusAutoPomo.
  ///
  /// In pt, this message translates to:
  /// **'Início automático: Próximo Pomo'**
  String get focusAutoPomo;

  /// No description provided for @focusAutoBreak.
  ///
  /// In pt, this message translates to:
  /// **'Início automático: Pausa'**
  String get focusAutoBreak;

  /// No description provided for @focusMinutesValue.
  ///
  /// In pt, this message translates to:
  /// **'{count} min'**
  String focusMinutesValue(int count);

  /// No description provided for @focusHours.
  ///
  /// In pt, this message translates to:
  /// **'{count}h'**
  String focusHours(int count);

  /// No description provided for @focusMins.
  ///
  /// In pt, this message translates to:
  /// **'{count}m'**
  String focusMins(int count);

  /// No description provided for @focusStartFocus.
  ///
  /// In pt, this message translates to:
  /// **'Começar o foco'**
  String get focusStartFocus;

  /// No description provided for @focusStartPomo.
  ///
  /// In pt, this message translates to:
  /// **'Comece Pomo'**
  String get focusStartPomo;

  /// No description provided for @focusStartStopwatch.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar cronômetro'**
  String get focusStartStopwatch;

  /// No description provided for @focusRecordStart.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get focusRecordStart;

  /// No description provided for @focusRecordEnd.
  ///
  /// In pt, this message translates to:
  /// **'Fim'**
  String get focusRecordEnd;

  /// No description provided for @focusNoTask.
  ///
  /// In pt, this message translates to:
  /// **'Sem tarefa'**
  String get focusNoTask;

  /// No description provided for @navHabit.
  ///
  /// In pt, this message translates to:
  /// **'Hábito'**
  String get navHabit;

  /// No description provided for @habitActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get habitActive;

  /// No description provided for @habitArchived.
  ///
  /// In pt, this message translates to:
  /// **'Arquivado'**
  String get habitArchived;

  /// No description provided for @habitEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desenvolver um hábito'**
  String get habitEmptyTitle;

  /// No description provided for @habitEmptyBody.
  ///
  /// In pt, this message translates to:
  /// **'A perseverança nos faz brilhar'**
  String get habitEmptyBody;

  /// No description provided for @habitArchivedEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum hábito arquivado'**
  String get habitArchivedEmptyTitle;

  /// No description provided for @habitArchivedEmptyBody.
  ///
  /// In pt, this message translates to:
  /// **'Você pode arquivar os hábitos e restaurá-los posteriormente.'**
  String get habitArchivedEmptyBody;

  /// No description provided for @habitNew.
  ///
  /// In pt, this message translates to:
  /// **'Criar Hábito'**
  String get habitNew;

  /// No description provided for @habitEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar hábito'**
  String get habitEditTitle;

  /// No description provided for @habitNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Check-in diário'**
  String get habitNameHint;

  /// No description provided for @habitFrequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência'**
  String get habitFrequency;

  /// No description provided for @habitDaily.
  ///
  /// In pt, this message translates to:
  /// **'Diariamente'**
  String get habitDaily;

  /// No description provided for @habitWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get habitWeekly;

  /// No description provided for @habitInterval.
  ///
  /// In pt, this message translates to:
  /// **'Repetir'**
  String get habitInterval;

  /// No description provided for @habitTimesPerWeek.
  ///
  /// In pt, this message translates to:
  /// **'{count} vezes por semana'**
  String habitTimesPerWeek(int count);

  /// No description provided for @habitEveryDays.
  ///
  /// In pt, this message translates to:
  /// **'A cada {count} dias'**
  String habitEveryDays(int count);

  /// No description provided for @habitGoal.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo'**
  String get habitGoal;

  /// No description provided for @habitGoalAll.
  ///
  /// In pt, this message translates to:
  /// **'Conquiste tudo'**
  String get habitGoalAll;

  /// No description provided for @habitGoalAmount.
  ///
  /// In pt, this message translates to:
  /// **'Atingir uma certa quantia'**
  String get habitGoalAmount;

  /// No description provided for @habitUnit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get habitUnit;

  /// No description provided for @habitUnitDefault.
  ///
  /// In pt, this message translates to:
  /// **'Contagem'**
  String get habitUnitDefault;

  /// No description provided for @habitPerDay.
  ///
  /// In pt, this message translates to:
  /// **'Por dia'**
  String get habitPerDay;

  /// No description provided for @habitStep.
  ///
  /// In pt, this message translates to:
  /// **'Recorde (Contagem)'**
  String get habitStep;

  /// No description provided for @habitCheckMode.
  ///
  /// In pt, this message translates to:
  /// **'Ao verificar'**
  String get habitCheckMode;

  /// No description provided for @habitCheckAuto.
  ///
  /// In pt, this message translates to:
  /// **'Automático'**
  String get habitCheckAuto;

  /// No description provided for @habitCheckManual.
  ///
  /// In pt, this message translates to:
  /// **'Manual'**
  String get habitCheckManual;

  /// No description provided for @habitCheckAll.
  ///
  /// In pt, this message translates to:
  /// **'Complete todos'**
  String get habitCheckAll;

  /// No description provided for @habitStartDate.
  ///
  /// In pt, this message translates to:
  /// **'Data de início'**
  String get habitStartDate;

  /// No description provided for @habitTargetDays.
  ///
  /// In pt, this message translates to:
  /// **'Dias de meta'**
  String get habitTargetDays;

  /// No description provided for @habitForever.
  ///
  /// In pt, this message translates to:
  /// **'Para sempre'**
  String get habitForever;

  /// No description provided for @habitDaysValue.
  ///
  /// In pt, this message translates to:
  /// **'{count} dias'**
  String habitDaysValue(int count);

  /// No description provided for @habitSection.
  ///
  /// In pt, this message translates to:
  /// **'Seção'**
  String get habitSection;

  /// No description provided for @habitSectionMorning.
  ///
  /// In pt, this message translates to:
  /// **'Manhã'**
  String get habitSectionMorning;

  /// No description provided for @habitSectionAfternoon.
  ///
  /// In pt, this message translates to:
  /// **'Tarde'**
  String get habitSectionAfternoon;

  /// No description provided for @habitSectionEvening.
  ///
  /// In pt, this message translates to:
  /// **'Noite'**
  String get habitSectionEvening;

  /// No description provided for @habitSectionOthers.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get habitSectionOthers;

  /// No description provided for @habitReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete'**
  String get habitReminder;

  /// No description provided for @habitAutoLog.
  ///
  /// In pt, this message translates to:
  /// **'Auto exibição do registro de hábito'**
  String get habitAutoLog;

  /// No description provided for @habitSummary.
  ///
  /// In pt, this message translates to:
  /// **'{total, plural, =0{0 dia} =1{1 dia} other{{total} dias}} · {streak, plural, =0{0 dia} =1{1 dia} other{{streak} dias}}'**
  String habitSummary(int total, int streak);

  /// No description provided for @habitLog.
  ///
  /// In pt, this message translates to:
  /// **'Registro de hábitos'**
  String get habitLog;

  /// No description provided for @habitReset.
  ///
  /// In pt, this message translates to:
  /// **'Reiniciar hábito'**
  String get habitReset;

  /// No description provided for @habitSkip.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get habitSkip;

  /// No description provided for @habitFail.
  ///
  /// In pt, this message translates to:
  /// **'Incompleta'**
  String get habitFail;

  /// No description provided for @habitLogPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Check-in realizado! O que você tem em mente?'**
  String get habitLogPrompt;

  /// No description provided for @habitArchive.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar'**
  String get habitArchive;

  /// No description provided for @habitRestore.
  ///
  /// In pt, this message translates to:
  /// **'Adquira o hábito'**
  String get habitRestore;

  /// No description provided for @toastRestoredHabit.
  ///
  /// In pt, this message translates to:
  /// **'Pegou'**
  String get toastRestoredHabit;

  /// No description provided for @habitDelete.
  ///
  /// In pt, this message translates to:
  /// **'Deletar'**
  String get habitDelete;

  /// No description provided for @habitMonthRecords.
  ///
  /// In pt, this message translates to:
  /// **'Registros mensais'**
  String get habitMonthRecords;

  /// No description provided for @habitTotalCheckins.
  ///
  /// In pt, this message translates to:
  /// **'Total de check-ins'**
  String get habitTotalCheckins;

  /// No description provided for @habitMonthRate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de check-in mensal'**
  String get habitMonthRate;

  /// No description provided for @habitStreak.
  ///
  /// In pt, this message translates to:
  /// **'Sequência atual'**
  String get habitStreak;

  /// No description provided for @habitMonthLog.
  ///
  /// In pt, this message translates to:
  /// **'Log de hábito em {month}'**
  String habitMonthLog(String month);

  /// No description provided for @habitMonthLogEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há pensamentos de check-in para compartilhar este mês'**
  String get habitMonthLogEmpty;

  /// No description provided for @habitIncrease.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar'**
  String get habitIncrease;

  /// No description provided for @habitSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get habitSettings;

  /// No description provided for @habitShowInToday.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar em \"Hoje\" e \"Próximos 7 dias\"'**
  String get habitShowInToday;

  /// No description provided for @habitSortByStatus.
  ///
  /// In pt, this message translates to:
  /// **'Classificar por status de check-in'**
  String get habitSortByStatus;

  /// No description provided for @habitFreeDay.
  ///
  /// In pt, this message translates to:
  /// **'Essa data está livre de tarefas'**
  String get habitFreeDay;

  /// No description provided for @habitAmount.
  ///
  /// In pt, this message translates to:
  /// **'{value}/{goal} {unit}'**
  String habitAmount(String value, String goal, String unit);

  /// No description provided for @habitDetailClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get habitDetailClose;

  /// No description provided for @navMatrix.
  ///
  /// In pt, this message translates to:
  /// **'Matriz de Eisenhower'**
  String get navMatrix;

  /// No description provided for @matrixQ1.
  ///
  /// In pt, this message translates to:
  /// **'Urgente e Importante'**
  String get matrixQ1;

  /// No description provided for @matrixQ2.
  ///
  /// In pt, this message translates to:
  /// **'Não Urgente e Importante'**
  String get matrixQ2;

  /// No description provided for @matrixQ3.
  ///
  /// In pt, this message translates to:
  /// **'Urgente e não importante'**
  String get matrixQ3;

  /// No description provided for @matrixQ4.
  ///
  /// In pt, this message translates to:
  /// **'Não urgente e não importante'**
  String get matrixQ4;

  /// No description provided for @matrixEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Matriz'**
  String get matrixEditTitle;

  /// No description provided for @matrixRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get matrixRestore;

  /// No description provided for @matrixHideCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Esconder concluídas'**
  String get matrixHideCompleted;

  /// No description provided for @matrixShowCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar concluídas'**
  String get matrixShowCompleted;

  /// No description provided for @matrixAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get matrixAll;

  /// No description provided for @matrixName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get matrixName;

  /// No description provided for @filterAddTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Filtro'**
  String get filterAddTitle;

  /// No description provided for @filterEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Filtro'**
  String get filterEditTitle;

  /// No description provided for @filterName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get filterName;

  /// No description provided for @filterNormal.
  ///
  /// In pt, this message translates to:
  /// **'Normal'**
  String get filterNormal;

  /// No description provided for @filterAdvanced.
  ///
  /// In pt, this message translates to:
  /// **'Avançado'**
  String get filterAdvanced;

  /// No description provided for @filterFieldList.
  ///
  /// In pt, this message translates to:
  /// **'Listas'**
  String get filterFieldList;

  /// No description provided for @filterFieldTag.
  ///
  /// In pt, this message translates to:
  /// **'Tags'**
  String get filterFieldTag;

  /// No description provided for @filterFieldDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get filterFieldDate;

  /// No description provided for @filterFieldPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get filterFieldPriority;

  /// No description provided for @filterFieldType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get filterFieldType;

  /// No description provided for @filterKeyword.
  ///
  /// In pt, this message translates to:
  /// **'Palavra-chave'**
  String get filterKeyword;

  /// No description provided for @filterKeywordHint.
  ///
  /// In pt, this message translates to:
  /// **'Título ou descrição contém'**
  String get filterKeywordHint;

  /// No description provided for @filterIs.
  ///
  /// In pt, this message translates to:
  /// **'é'**
  String get filterIs;

  /// No description provided for @filterIsNot.
  ///
  /// In pt, this message translates to:
  /// **'não é'**
  String get filterIsNot;

  /// No description provided for @filterAnd.
  ///
  /// In pt, this message translates to:
  /// **'E'**
  String get filterAnd;

  /// No description provided for @filterOr.
  ///
  /// In pt, this message translates to:
  /// **'OU'**
  String get filterOr;

  /// No description provided for @filterAddCondition.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar condição'**
  String get filterAddCondition;

  /// No description provided for @filterPreview.
  ///
  /// In pt, this message translates to:
  /// **'Prévia'**
  String get filterPreview;

  /// No description provided for @filterPreviewCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhuma tarefa encontrada} =1{1 tarefa encontrada} other{{count} tarefas encontradas}}'**
  String filterPreviewCount(num count);

  /// No description provided for @filterDateOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasadas'**
  String get filterDateOverdue;

  /// No description provided for @filterDateToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get filterDateToday;

  /// No description provided for @filterDateTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get filterDateTomorrow;

  /// No description provided for @filterDateThisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get filterDateThisWeek;

  /// No description provided for @filterDateNextWeek.
  ///
  /// In pt, this message translates to:
  /// **'Próxima semana'**
  String get filterDateNextWeek;

  /// No description provided for @filterDateThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get filterDateThisMonth;

  /// No description provided for @filterDateNextMonth.
  ///
  /// In pt, this message translates to:
  /// **'Próximo mês'**
  String get filterDateNextMonth;

  /// No description provided for @filterDateNoDate.
  ///
  /// In pt, this message translates to:
  /// **'Sem data'**
  String get filterDateNoDate;

  /// No description provided for @filterSaveAs.
  ///
  /// In pt, this message translates to:
  /// **'Salvar como filtro'**
  String get filterSaveAs;

  /// No description provided for @filterDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir o filtro \"{name}\"? As tarefas não serão afetadas.'**
  String filterDeleteConfirm(Object name);

  /// No description provided for @filterSaved.
  ///
  /// In pt, this message translates to:
  /// **'Filtro \"{name}\" criado'**
  String filterSaved(Object name);

  /// No description provided for @navCalendar.
  ///
  /// In pt, this message translates to:
  /// **'Calendário'**
  String get navCalendar;

  /// No description provided for @calendarModeDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get calendarModeDay;

  /// No description provided for @calendarModeWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana'**
  String get calendarModeWeek;

  /// No description provided for @calendarModeMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get calendarModeMonth;

  /// No description provided for @calendarModeYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get calendarModeYear;

  /// No description provided for @calendarModeAgenda.
  ///
  /// In pt, this message translates to:
  /// **'Agenda'**
  String get calendarModeAgenda;

  /// No description provided for @calendarModeMultiDay.
  ///
  /// In pt, this message translates to:
  /// **'Multi-Dia'**
  String get calendarModeMultiDay;

  /// No description provided for @calendarModeMultiWeek.
  ///
  /// In pt, this message translates to:
  /// **'Multi-Semana'**
  String get calendarModeMultiWeek;

  /// No description provided for @calendarToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get calendarToday;

  /// No description provided for @calendarAllDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia inteiro'**
  String get calendarAllDay;

  /// No description provided for @calendarNoon.
  ///
  /// In pt, this message translates to:
  /// **'Meio-dia'**
  String get calendarNoon;

  /// No description provided for @calendarArrange.
  ///
  /// In pt, this message translates to:
  /// **'Organizar tarefas'**
  String get calendarArrange;

  /// No description provided for @calendarArrangeHint.
  ///
  /// In pt, this message translates to:
  /// **'Arraste as tarefas sem data para o calendário.'**
  String get calendarArrangeHint;

  /// No description provided for @calendarArrangeEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa sem data'**
  String get calendarArrangeEmpty;

  /// No description provided for @calendarViewOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções de visualização'**
  String get calendarViewOptions;

  /// No description provided for @calendarShowCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar concluídas'**
  String get calendarShowCompleted;

  /// No description provided for @calendarShowChecklist.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar itens de checklist'**
  String get calendarShowChecklist;

  /// No description provided for @calendarShowRepeats.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar ciclos futuros'**
  String get calendarShowRepeats;

  /// No description provided for @calendarShowHabits.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar hábitos'**
  String get calendarShowHabits;

  /// No description provided for @calendarShowFocus.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar registros de foco'**
  String get calendarShowFocus;

  /// No description provided for @calendarShowCountdowns.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar contagem regressiva'**
  String get calendarShowCountdowns;

  /// No description provided for @calendarColorBy.
  ///
  /// In pt, this message translates to:
  /// **'Cor por'**
  String get calendarColorBy;

  /// No description provided for @calendarColorByList.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get calendarColorByList;

  /// No description provided for @calendarColorByTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get calendarColorByTag;

  /// No description provided for @calendarColorByPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get calendarColorByPriority;

  /// No description provided for @calendarMultiDays.
  ///
  /// In pt, this message translates to:
  /// **'{count} dias'**
  String calendarMultiDays(Object count);

  /// No description provided for @calendarMultiWeeks.
  ///
  /// In pt, this message translates to:
  /// **'{count} Semanas'**
  String calendarMultiWeeks(Object count);

  /// No description provided for @calendarListFilter.
  ///
  /// In pt, this message translates to:
  /// **'Filtro de listas'**
  String get calendarListFilter;

  /// No description provided for @calendarAgendaEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa neste período'**
  String get calendarAgendaEmpty;

  /// No description provided for @calendarFocusRecord.
  ///
  /// In pt, this message translates to:
  /// **'Foco'**
  String get calendarFocusRecord;

  /// No description provided for @calendarMore.
  ///
  /// In pt, this message translates to:
  /// **'+{count}'**
  String calendarMore(Object count);

  /// No description provided for @timelineEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa com data.\nClique na régua para criar uma ou arraste do painel \"Organizar tarefas\".'**
  String get timelineEmpty;

  /// No description provided for @timelineArrangeHint.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas sem data. Arraste para a régua.'**
  String get timelineArrangeHint;

  /// No description provided for @shortcutViews.
  ///
  /// In pt, this message translates to:
  /// **'Visualização Lista / Kanban / Linha do tempo'**
  String get shortcutViews;

  /// No description provided for @shortcutCalendarModes.
  ///
  /// In pt, this message translates to:
  /// **'Calendário: Dia / Semana / Mês / Ano / Agenda'**
  String get shortcutCalendarModes;

  /// No description provided for @activityTaskTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atividades da tarefa'**
  String get activityTaskTitle;

  /// No description provided for @activityListTitleDialog.
  ///
  /// In pt, this message translates to:
  /// **'Atividades da lista'**
  String get activityListTitleDialog;

  /// No description provided for @activityEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma atividade ainda'**
  String get activityEmpty;

  /// No description provided for @activityCreated.
  ///
  /// In pt, this message translates to:
  /// **'Você criou a tarefa'**
  String get activityCreated;

  /// No description provided for @activityCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Você concluiu a tarefa'**
  String get activityCompleted;

  /// No description provided for @activityReopened.
  ///
  /// In pt, this message translates to:
  /// **'Você reabriu a tarefa'**
  String get activityReopened;

  /// No description provided for @activityWontDo.
  ///
  /// In pt, this message translates to:
  /// **'Você marcou a tarefa como Não farei'**
  String get activityWontDo;

  /// No description provided for @activityDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Você moveu a tarefa para a Lixeira'**
  String get activityDeleted;

  /// No description provided for @activityRestored.
  ///
  /// In pt, this message translates to:
  /// **'Você restaurou a tarefa'**
  String get activityRestored;

  /// No description provided for @activityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você mudou o título para \"{title}\"'**
  String activityTitle(Object title);

  /// No description provided for @activityContent.
  ///
  /// In pt, this message translates to:
  /// **'Você editou a descrição'**
  String get activityContent;

  /// No description provided for @activityDate.
  ///
  /// In pt, this message translates to:
  /// **'Você mudou a data para {date}'**
  String activityDate(Object date);

  /// No description provided for @activityDateRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Você removeu a data'**
  String get activityDateRemoved;

  /// No description provided for @activityPriority.
  ///
  /// In pt, this message translates to:
  /// **'Você mudou a prioridade para {priority}'**
  String activityPriority(Object priority);

  /// No description provided for @activityMoved.
  ///
  /// In pt, this message translates to:
  /// **'Você moveu a tarefa para {list}'**
  String activityMoved(Object list);

  /// No description provided for @activityRepeat.
  ///
  /// In pt, this message translates to:
  /// **'Você mudou a repetição'**
  String get activityRepeat;

  /// No description provided for @activityRepeatRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Você removeu a repetição'**
  String get activityRepeatRemoved;

  /// No description provided for @activityListCreated.
  ///
  /// In pt, this message translates to:
  /// **'Você criou a lista'**
  String get activityListCreated;

  /// No description provided for @activityListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você renomeou a lista para \"{name}\"'**
  String activityListTitle(Object name);

  /// No description provided for @matrixGroupBy.
  ///
  /// In pt, this message translates to:
  /// **'Agrupar por'**
  String get matrixGroupBy;

  /// No description provided for @matrixSortBy.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por'**
  String get matrixSortBy;

  /// No description provided for @matrixOrder.
  ///
  /// In pt, this message translates to:
  /// **'Ordem'**
  String get matrixOrder;

  /// No description provided for @matrixByTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo'**
  String get matrixByTime;

  /// No description provided for @matrixByList.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get matrixByList;

  /// No description provided for @matrixByPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get matrixByPriority;

  /// No description provided for @matrixByTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get matrixByTag;

  /// No description provided for @matrixByTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get matrixByTitle;

  /// No description provided for @matrixByNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum'**
  String get matrixByNone;

  /// No description provided for @matrixAscending.
  ///
  /// In pt, this message translates to:
  /// **'Crescente'**
  String get matrixAscending;

  /// No description provided for @matrixDescending.
  ///
  /// In pt, this message translates to:
  /// **'Decrescente'**
  String get matrixDescending;

  /// No description provided for @statsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get statsTitle;

  /// No description provided for @statsOverview.
  ///
  /// In pt, this message translates to:
  /// **'Visão geral'**
  String get statsOverview;

  /// No description provided for @statsTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa'**
  String get statsTask;

  /// No description provided for @statsFocus.
  ///
  /// In pt, this message translates to:
  /// **'Foco'**
  String get statsFocus;

  /// No description provided for @statsDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get statsDone;

  /// No description provided for @statsTasksLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get statsTasksLabel;

  /// No description provided for @statsCompletedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get statsCompletedLabel;

  /// No description provided for @statsListsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Listas'**
  String get statsListsLabel;

  /// No description provided for @statsDaysLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dias'**
  String get statsDaysLabel;

  /// No description provided for @statsTodayCompletion.
  ///
  /// In pt, this message translates to:
  /// **'Conclusão de Hoje'**
  String get statsTodayCompletion;

  /// No description provided for @statsTotalCompletion.
  ///
  /// In pt, this message translates to:
  /// **'Conclusão Total'**
  String get statsTotalCompletion;

  /// No description provided for @statsAchievement.
  ///
  /// In pt, this message translates to:
  /// **'Minha pontuação de conquista'**
  String get statsAchievement;

  /// No description provided for @statsLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level}'**
  String statsLevel(Object level);

  /// No description provided for @statsNextLevel.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {points} pontos para o Nível {level}'**
  String statsNextLevel(Object level, Object points);

  /// No description provided for @statsTopLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível máximo'**
  String get statsTopLevel;

  /// No description provided for @statsCompletionCurve.
  ///
  /// In pt, this message translates to:
  /// **'Curva de conclusão recente'**
  String get statsCompletionCurve;

  /// No description provided for @statsRateCurve.
  ///
  /// In pt, this message translates to:
  /// **'Curva de taxa de conclusão recente'**
  String get statsRateCurve;

  /// No description provided for @statsPomoCurve.
  ///
  /// In pt, this message translates to:
  /// **'Curva Pomo recente'**
  String get statsPomoCurve;

  /// No description provided for @statsFocusCurve.
  ///
  /// In pt, this message translates to:
  /// **'Curva de duração de foco recente'**
  String get statsFocusCurve;

  /// No description provided for @statsHabitsWeek.
  ///
  /// In pt, this message translates to:
  /// **'Status semanal dos hábitos'**
  String get statsHabitsWeek;

  /// No description provided for @statsNoHabits.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum hábito ainda'**
  String get statsNoHabits;

  /// No description provided for @statsDaily.
  ///
  /// In pt, this message translates to:
  /// **'Diariamente'**
  String get statsDaily;

  /// No description provided for @statsWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanalmente'**
  String get statsWeekly;

  /// No description provided for @statsMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensalmente'**
  String get statsMonthly;

  /// No description provided for @statsTaskCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa Concluída'**
  String get statsTaskCompleted;

  /// No description provided for @statsRate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de Realização'**
  String get statsRate;

  /// No description provided for @statsVsDay.
  ///
  /// In pt, this message translates to:
  /// **'vs ontem'**
  String get statsVsDay;

  /// No description provided for @statsVsWeek.
  ///
  /// In pt, this message translates to:
  /// **'vs semana passada'**
  String get statsVsWeek;

  /// No description provided for @statsVsMonth.
  ///
  /// In pt, this message translates to:
  /// **'vs mês passado'**
  String get statsVsMonth;

  /// No description provided for @statsDistribution.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição da taxa de conclusão'**
  String get statsDistribution;

  /// No description provided for @statsOnTime.
  ///
  /// In pt, this message translates to:
  /// **'Concluídas no prazo'**
  String get statsOnTime;

  /// No description provided for @statsLate.
  ///
  /// In pt, this message translates to:
  /// **'Concluídas com atraso'**
  String get statsLate;

  /// No description provided for @statsUndone.
  ///
  /// In pt, this message translates to:
  /// **'Não concluídas'**
  String get statsUndone;

  /// No description provided for @statsByCategory.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas de conclusão'**
  String get statsByCategory;

  /// No description provided for @statsByList.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get statsByList;

  /// No description provided for @statsByTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get statsByTag;

  /// No description provided for @statsByPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get statsByPriority;

  /// No description provided for @statsByTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa'**
  String get statsByTask;

  /// No description provided for @statsFocusDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get statsFocusDetails;

  /// No description provided for @statsUnlinked.
  ///
  /// In pt, this message translates to:
  /// **'Sem vínculo'**
  String get statsUnlinked;

  /// No description provided for @statsTrends.
  ///
  /// In pt, this message translates to:
  /// **'Tendências'**
  String get statsTrends;

  /// No description provided for @statsDailyAverage.
  ///
  /// In pt, this message translates to:
  /// **'Média diária: {value}'**
  String statsDailyAverage(Object value);

  /// No description provided for @statsWeekTimeline.
  ///
  /// In pt, this message translates to:
  /// **'Linha do Tempo'**
  String get statsWeekTimeline;

  /// No description provided for @statsMostFocused.
  ///
  /// In pt, this message translates to:
  /// **'Tempo mais concentrado'**
  String get statsMostFocused;

  /// No description provided for @statsYearGrid.
  ///
  /// In pt, this message translates to:
  /// **'Grade anual'**
  String get statsYearGrid;

  /// No description provided for @statsNoData.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados neste período'**
  String get statsNoData;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get settingsAccount;

  /// No description provided for @settingsFeatures.
  ///
  /// In pt, this message translates to:
  /// **'Funcionalidades'**
  String get settingsFeatures;

  /// No description provided for @settingsSmartLists.
  ///
  /// In pt, this message translates to:
  /// **'Lista inteligente'**
  String get settingsSmartLists;

  /// No description provided for @settingsAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get settingsAppearance;

  /// No description provided for @settingsAbout.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get settingsAbout;

  /// No description provided for @settingsLocalAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta local'**
  String get settingsLocalAccount;

  /// No description provided for @settingsLocalAccountHint.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados ficam só neste aparelho, sem conta nem servidor.'**
  String get settingsLocalAccountHint;

  /// No description provided for @settingsBackup.
  ///
  /// In pt, this message translates to:
  /// **'Backup & Recuperação'**
  String get settingsBackup;

  /// No description provided for @settingsBackupGenerate.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Backup'**
  String get settingsBackupGenerate;

  /// No description provided for @settingsBackupImport.
  ///
  /// In pt, this message translates to:
  /// **'Importar backups locais'**
  String get settingsBackupImport;

  /// No description provided for @featureHabitSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações de hábitos'**
  String get featureHabitSettings;

  /// No description provided for @featureCalendarHint.
  ///
  /// In pt, this message translates to:
  /// **'Seis visualizações de calendário'**
  String get featureCalendarHint;

  /// No description provided for @featureMatrixHint.
  ///
  /// In pt, this message translates to:
  /// **'Organize por importante e urgente'**
  String get featureMatrixHint;

  /// No description provided for @featureHabitHint.
  ///
  /// In pt, this message translates to:
  /// **'Crie e acompanhe hábitos'**
  String get featureHabitHint;

  /// No description provided for @featureFocus.
  ///
  /// In pt, this message translates to:
  /// **'Pomodoro'**
  String get featureFocus;

  /// No description provided for @featureFocusHint.
  ///
  /// In pt, this message translates to:
  /// **'Temporizador Pomo ou cronômetro'**
  String get featureFocusHint;

  /// No description provided for @featureCountdownHint.
  ///
  /// In pt, this message translates to:
  /// **'Lembre-se de cada dia especial'**
  String get featureCountdownHint;

  /// No description provided for @settingsLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Seguir o modo escuro do sistema'**
  String get themeSystem;

  /// No description provided for @settingsColorSeries.
  ///
  /// In pt, this message translates to:
  /// **'Série de Cores'**
  String get settingsColorSeries;

  /// No description provided for @colorStandard.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get colorStandard;

  /// No description provided for @colorSky.
  ///
  /// In pt, this message translates to:
  /// **'Céu'**
  String get colorSky;

  /// No description provided for @colorTurquoise.
  ///
  /// In pt, this message translates to:
  /// **'Turquesa'**
  String get colorTurquoise;

  /// No description provided for @colorTeal.
  ///
  /// In pt, this message translates to:
  /// **'Azul teal'**
  String get colorTeal;

  /// No description provided for @colorReed.
  ///
  /// In pt, this message translates to:
  /// **'Junco'**
  String get colorReed;

  /// No description provided for @colorYellow.
  ///
  /// In pt, this message translates to:
  /// **'Amarelo'**
  String get colorYellow;

  /// No description provided for @colorPinkPear.
  ///
  /// In pt, this message translates to:
  /// **'Rosa Pêra'**
  String get colorPinkPear;

  /// No description provided for @colorLilac.
  ///
  /// In pt, this message translates to:
  /// **'Lilás'**
  String get colorLilac;

  /// No description provided for @colorEbony.
  ///
  /// In pt, this message translates to:
  /// **'Ébano'**
  String get colorEbony;

  /// No description provided for @colorNavy.
  ///
  /// In pt, this message translates to:
  /// **'Azul Escuro'**
  String get colorNavy;

  /// No description provided for @colorGrey.
  ///
  /// In pt, this message translates to:
  /// **'Cinza'**
  String get colorGrey;

  /// No description provided for @appearanceThemePresets.
  ///
  /// In pt, this message translates to:
  /// **'Temas prontos'**
  String get appearanceThemePresets;

  /// No description provided for @appearanceThemePresetsHint.
  ///
  /// In pt, this message translates to:
  /// **'Cor, fundo e cantos de uma vez; cada um continua editável abaixo'**
  String get appearanceThemePresetsHint;

  /// No description provided for @appearanceWallpaper.
  ///
  /// In pt, this message translates to:
  /// **'Papel de parede'**
  String get appearanceWallpaper;

  /// No description provided for @backgroundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fundo'**
  String get backgroundTitle;

  /// No description provided for @backgroundDefault.
  ///
  /// In pt, this message translates to:
  /// **'Padrão (o da pasta ou do app)'**
  String get backgroundDefault;

  /// No description provided for @backgroundNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum'**
  String get backgroundNone;

  /// No description provided for @backgroundPicture.
  ///
  /// In pt, this message translates to:
  /// **'Imagem'**
  String get backgroundPicture;

  /// No description provided for @backgroundPickPicture.
  ///
  /// In pt, this message translates to:
  /// **'Escolher imagem'**
  String get backgroundPickPicture;

  /// No description provided for @backgroundDim.
  ///
  /// In pt, this message translates to:
  /// **'Escurecer'**
  String get backgroundDim;

  /// No description provided for @backgroundLighten.
  ///
  /// In pt, this message translates to:
  /// **'Clarear'**
  String get backgroundLighten;

  /// No description provided for @gradientDawn.
  ///
  /// In pt, this message translates to:
  /// **'Amanhecer'**
  String get gradientDawn;

  /// No description provided for @gradientSunset.
  ///
  /// In pt, this message translates to:
  /// **'Pôr do sol'**
  String get gradientSunset;

  /// No description provided for @gradientOcean.
  ///
  /// In pt, this message translates to:
  /// **'Oceano'**
  String get gradientOcean;

  /// No description provided for @gradientForest.
  ///
  /// In pt, this message translates to:
  /// **'Floresta'**
  String get gradientForest;

  /// No description provided for @gradientLavender.
  ///
  /// In pt, this message translates to:
  /// **'Lavanda'**
  String get gradientLavender;

  /// No description provided for @gradientNight.
  ///
  /// In pt, this message translates to:
  /// **'Noite'**
  String get gradientNight;

  /// No description provided for @gradientPeach.
  ///
  /// In pt, this message translates to:
  /// **'Pêssego'**
  String get gradientPeach;

  /// No description provided for @gradientMint.
  ///
  /// In pt, this message translates to:
  /// **'Menta'**
  String get gradientMint;

  /// No description provided for @presetStandard.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get presetStandard;

  /// No description provided for @presetStudies.
  ///
  /// In pt, this message translates to:
  /// **'Estudos'**
  String get presetStudies;

  /// No description provided for @presetWork.
  ///
  /// In pt, this message translates to:
  /// **'Trabalho'**
  String get presetWork;

  /// No description provided for @presetNight.
  ///
  /// In pt, this message translates to:
  /// **'Noite'**
  String get presetNight;

  /// No description provided for @presetNature.
  ///
  /// In pt, this message translates to:
  /// **'Natureza'**
  String get presetNature;

  /// No description provided for @presetBeach.
  ///
  /// In pt, this message translates to:
  /// **'Praia'**
  String get presetBeach;

  /// No description provided for @presetCozy.
  ///
  /// In pt, this message translates to:
  /// **'Aconchego'**
  String get presetCozy;

  /// No description provided for @settingsDisplay.
  ///
  /// In pt, this message translates to:
  /// **'Exibição'**
  String get settingsDisplay;

  /// No description provided for @settingsSidebarCount.
  ///
  /// In pt, this message translates to:
  /// **'Contagem na barra lateral'**
  String get settingsSidebarCount;

  /// No description provided for @sidebarCountAll.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar (Tudo)'**
  String get sidebarCountAll;

  /// No description provided for @sidebarCountHideNotes.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar (Ocultar Nota)'**
  String get sidebarCountHideNotes;

  /// No description provided for @sidebarCountNone.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar (Tudo)'**
  String get sidebarCountNone;

  /// No description provided for @settingsCompletedStyle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo de Tarefa Concluída'**
  String get settingsCompletedStyle;

  /// No description provided for @completedStyleDefault.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get completedStyleDefault;

  /// No description provided for @completedStyleStrike.
  ///
  /// In pt, this message translates to:
  /// **'Rasurado'**
  String get completedStyleStrike;

  /// No description provided for @aboutVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão {version}'**
  String aboutVersion(Object version);

  /// No description provided for @aboutText.
  ///
  /// In pt, this message translates to:
  /// **'Ordo (antes chamado Tarefas) é um app pessoal no estilo do TickTick, feito em Flutter para Windows e Android. Tudo fica salvo neste aparelho; use Gerar Backup para levar seus dados para outro lugar.'**
  String get aboutText;

  /// No description provided for @settingsMore.
  ///
  /// In pt, this message translates to:
  /// **'Mais configurações'**
  String get settingsMore;

  /// No description provided for @settingsSmartRecognition.
  ///
  /// In pt, this message translates to:
  /// **'Reconhecimento Inteligente'**
  String get settingsSmartRecognition;

  /// No description provided for @settingsRecognizeDates.
  ///
  /// In pt, this message translates to:
  /// **'Reconhecimento de Data'**
  String get settingsRecognizeDates;

  /// No description provided for @settingsRecognizeDatesHint.
  ///
  /// In pt, this message translates to:
  /// **'Detecta a data e a hora no título e as usa na tarefa'**
  String get settingsRecognizeDatesHint;

  /// No description provided for @settingsRemoveDateText.
  ///
  /// In pt, this message translates to:
  /// **'Remover textos nas tarefas'**
  String get settingsRemoveDateText;

  /// No description provided for @settingsRemoveDateTextHint.
  ///
  /// In pt, this message translates to:
  /// **'Tira do título a data reconhecida'**
  String get settingsRemoveDateTextHint;

  /// No description provided for @settingsTagRecognition.
  ///
  /// In pt, this message translates to:
  /// **'Reconhecimento de tag'**
  String get settingsTagRecognition;

  /// No description provided for @tagTextRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover do título'**
  String get tagTextRemove;

  /// No description provided for @tagTextKeep.
  ///
  /// In pt, this message translates to:
  /// **'Manter no título'**
  String get tagTextKeep;

  /// No description provided for @settingsTaskDefaults.
  ///
  /// In pt, this message translates to:
  /// **'Padrão de Tarefas'**
  String get settingsTaskDefaults;

  /// No description provided for @settingsDefaultDate.
  ///
  /// In pt, this message translates to:
  /// **'Data padrão'**
  String get settingsDefaultDate;

  /// No description provided for @defaultDateNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma'**
  String get defaultDateNone;

  /// No description provided for @defaultDateDayAfter.
  ///
  /// In pt, this message translates to:
  /// **'Depois de amanhã'**
  String get defaultDateDayAfter;

  /// No description provided for @settingsDefaultTimedReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete padrão, tarefa com hora'**
  String get settingsDefaultTimedReminder;

  /// No description provided for @settingsDefaultAllDayReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete padrão, tarefa de dia inteiro'**
  String get settingsDefaultAllDayReminder;

  /// No description provided for @reminderNoneOption.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum'**
  String get reminderNoneOption;

  /// No description provided for @settingsDefaultPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade padrão'**
  String get settingsDefaultPriority;

  /// No description provided for @settingsDefaultList.
  ///
  /// In pt, this message translates to:
  /// **'Lista padrão'**
  String get settingsDefaultList;

  /// No description provided for @settingsNewTaskPosition.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar nova tarefa'**
  String get settingsNewTaskPosition;

  /// No description provided for @positionTopOfList.
  ///
  /// In pt, this message translates to:
  /// **'Topo da lista'**
  String get positionTopOfList;

  /// No description provided for @positionEndOfList.
  ///
  /// In pt, this message translates to:
  /// **'Fim da lista'**
  String get positionEndOfList;

  /// No description provided for @settingsOverduePosition.
  ///
  /// In pt, this message translates to:
  /// **'Posição da seção \"Atrasadas\"'**
  String get settingsOverduePosition;

  /// No description provided for @positionTop.
  ///
  /// In pt, this message translates to:
  /// **'Topo'**
  String get positionTop;

  /// No description provided for @positionEnd.
  ///
  /// In pt, this message translates to:
  /// **'Fim'**
  String get positionEnd;

  /// No description provided for @settingsResetDefaults.
  ///
  /// In pt, this message translates to:
  /// **'Redefinir padrão'**
  String get settingsResetDefaults;

  /// No description provided for @settingsTemplates.
  ///
  /// In pt, this message translates to:
  /// **'Modelos de tarefa'**
  String get settingsTemplates;

  /// No description provided for @settingsTemplatesHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um modelo para criar uma tarefa na lista padrão'**
  String get settingsTemplatesHint;

  /// No description provided for @settingsDateTime.
  ///
  /// In pt, this message translates to:
  /// **'Data e hora'**
  String get settingsDateTime;

  /// No description provided for @settingsTimeFormat.
  ///
  /// In pt, this message translates to:
  /// **'Formato da hora'**
  String get settingsTimeFormat;

  /// No description provided for @timeFormat24.
  ///
  /// In pt, this message translates to:
  /// **'24 horas (13:00)'**
  String get timeFormat24;

  /// No description provided for @timeFormat12.
  ///
  /// In pt, this message translates to:
  /// **'12 horas (1:00 PM)'**
  String get timeFormat12;

  /// No description provided for @settingsWeekStart.
  ///
  /// In pt, this message translates to:
  /// **'Dia de início da semana'**
  String get settingsWeekStart;

  /// No description provided for @settingsWeekNumbers.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar números da semana'**
  String get settingsWeekNumbers;

  /// No description provided for @settingsWeekNumbersHint.
  ///
  /// In pt, this message translates to:
  /// **'No Mês e na Multi-Semana do Calendário'**
  String get settingsWeekNumbersHint;

  /// No description provided for @weekNumber.
  ///
  /// In pt, this message translates to:
  /// **'S{number}'**
  String weekNumber(Object number);

  /// No description provided for @settingsShortcuts.
  ///
  /// In pt, this message translates to:
  /// **'Atalhos'**
  String get settingsShortcuts;

  /// No description provided for @shortcutFocusToggle.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar/Pausar foco'**
  String get shortcutFocusToggle;

  /// No description provided for @smartSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get smartSummary;

  /// No description provided for @summaryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa pode ser encontrada com os filtros atuais.'**
  String get summaryEmpty;

  /// No description provided for @summaryCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get summaryCompleted;

  /// No description provided for @summaryWontDo.
  ///
  /// In pt, this message translates to:
  /// **'Não será feito'**
  String get summaryWontDo;

  /// No description provided for @summaryInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Em andamento'**
  String get summaryInProgress;

  /// No description provided for @summaryUndone.
  ///
  /// In pt, this message translates to:
  /// **'Desfeito'**
  String get summaryUndone;

  /// No description provided for @summaryIncomplete.
  ///
  /// In pt, this message translates to:
  /// **'Incompleta'**
  String get summaryIncomplete;

  /// No description provided for @summaryNotCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Não concluídas'**
  String get summaryNotCompleted;

  /// No description provided for @summaryParent.
  ///
  /// In pt, this message translates to:
  /// **'em {title}'**
  String summaryParent(Object title);

  /// No description provided for @summaryTemplates.
  ///
  /// In pt, this message translates to:
  /// **'Modelo'**
  String get summaryTemplates;

  /// No description provided for @summarySaveTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Salvar como modelo'**
  String get summarySaveTemplate;

  /// No description provided for @summaryTemplateName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do modelo'**
  String get summaryTemplateName;

  /// No description provided for @summaryFilter.
  ///
  /// In pt, this message translates to:
  /// **'Filtro'**
  String get summaryFilter;

  /// No description provided for @summaryDisplay.
  ///
  /// In pt, this message translates to:
  /// **'Opções de Exibição'**
  String get summaryDisplay;

  /// No description provided for @summaryByStatus.
  ///
  /// In pt, this message translates to:
  /// **'Por Status de Conclusão'**
  String get summaryByStatus;

  /// No description provided for @summaryByList.
  ///
  /// In pt, this message translates to:
  /// **'Por lista'**
  String get summaryByList;

  /// No description provided for @summaryByCompletionDate.
  ///
  /// In pt, this message translates to:
  /// **'Por Data de Conclusão'**
  String get summaryByCompletionDate;

  /// No description provided for @summaryByTaskDate.
  ///
  /// In pt, this message translates to:
  /// **'Por Data da Tarefa'**
  String get summaryByTaskDate;

  /// No description provided for @summaryByTag.
  ///
  /// In pt, this message translates to:
  /// **'Por Tag'**
  String get summaryByTag;

  /// No description provided for @summaryByPriority.
  ///
  /// In pt, this message translates to:
  /// **'Por Prioridade'**
  String get summaryByPriority;

  /// No description provided for @summaryFieldStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get summaryFieldStatus;

  /// No description provided for @summaryFieldProgress.
  ///
  /// In pt, this message translates to:
  /// **'Progresso'**
  String get summaryFieldProgress;

  /// No description provided for @summaryFieldCompletionTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo de conclusão'**
  String get summaryFieldCompletionTime;

  /// No description provided for @summaryFieldTaskTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo da tarefa'**
  String get summaryFieldTaskTime;

  /// No description provided for @summaryFieldParent.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa Pai'**
  String get summaryFieldParent;

  /// No description provided for @summaryFieldTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get summaryFieldTag;

  /// No description provided for @summaryFieldList.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get summaryFieldList;

  /// No description provided for @summaryFieldDetail.
  ///
  /// In pt, this message translates to:
  /// **'Detalhe'**
  String get summaryFieldDetail;

  /// No description provided for @summaryNextPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas do Próximo Período'**
  String get summaryNextPeriod;

  /// No description provided for @summaryCopy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get summaryCopy;

  /// No description provided for @summarySavePdf.
  ///
  /// In pt, this message translates to:
  /// **'Salvar como PDF'**
  String get summarySavePdf;

  /// No description provided for @shortcutGoClosed.
  ///
  /// In pt, this message translates to:
  /// **'Concluído / Não será feito / Resumo / Lixeira'**
  String get shortcutGoClosed;

  /// No description provided for @habitExport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar'**
  String get habitExport;

  /// No description provided for @habitExported.
  ///
  /// In pt, this message translates to:
  /// **'Hábitos exportados'**
  String get habitExported;

  /// No description provided for @habitExportHabit.
  ///
  /// In pt, this message translates to:
  /// **'Hábito'**
  String get habitExportHabit;

  /// No description provided for @habitExportDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get habitExportDate;

  /// No description provided for @habitExportValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get habitExportValue;

  /// No description provided for @habitExportGoal.
  ///
  /// In pt, this message translates to:
  /// **'Meta'**
  String get habitExportGoal;

  /// No description provided for @habitExportUnit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get habitExportUnit;

  /// No description provided for @habitExportStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get habitExportStatus;

  /// No description provided for @habitExportMood.
  ///
  /// In pt, this message translates to:
  /// **'Humor'**
  String get habitExportMood;

  /// No description provided for @habitExportNote.
  ///
  /// In pt, this message translates to:
  /// **'Nota'**
  String get habitExportNote;

  /// No description provided for @habitExportDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get habitExportDone;

  /// No description provided for @habitExportPartial.
  ///
  /// In pt, this message translates to:
  /// **'Parcial'**
  String get habitExportPartial;

  /// No description provided for @habitExportSkipped.
  ///
  /// In pt, this message translates to:
  /// **'Pulado'**
  String get habitExportSkipped;

  /// No description provided for @habitExportFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não alcançado'**
  String get habitExportFailed;

  /// No description provided for @focusLinkTask.
  ///
  /// In pt, this message translates to:
  /// **'Escolher tarefa…'**
  String get focusLinkTask;

  /// No description provided for @focusUnlink.
  ///
  /// In pt, this message translates to:
  /// **'Remover vínculo'**
  String get focusUnlink;

  /// No description provided for @focusTimers.
  ///
  /// In pt, this message translates to:
  /// **'Timers'**
  String get focusTimers;

  /// No description provided for @focusTimersEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Crie atalhos de foco com nome, modo e duração.'**
  String get focusTimersEmpty;

  /// No description provided for @focusTimerAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar temporizador'**
  String get focusTimerAdd;

  /// No description provided for @focusTimerEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar timer'**
  String get focusTimerEdit;

  /// No description provided for @focusTimerName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do timer'**
  String get focusTimerName;

  /// No description provided for @focusTimerTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total {duration}'**
  String focusTimerTotal(Object duration);

  /// No description provided for @settingsImports.
  ///
  /// In pt, this message translates to:
  /// **'Integrações e Importação'**
  String get settingsImports;

  /// No description provided for @importSection.
  ///
  /// In pt, this message translates to:
  /// **'Importar'**
  String get importSection;

  /// No description provided for @importTickTick.
  ///
  /// In pt, this message translates to:
  /// **'Backup do TickTick (.csv)'**
  String get importTickTick;

  /// No description provided for @importTickTickHint.
  ///
  /// In pt, this message translates to:
  /// **'No TickTick: Configurações → Conta → Backup & Recuperação → Gerar Backup. Traz pastas, listas, seções, tags, subtarefas, checklists e concluídas.'**
  String get importTickTickHint;

  /// No description provided for @importIcal.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo iCal (.ics)'**
  String get importIcal;

  /// No description provided for @importIcalHint.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas (VTODO) e eventos (VEVENT) viram tarefas, com datas, alarmes, repetição e categorias como tags.'**
  String get importIcalHint;

  /// No description provided for @importIcalList.
  ///
  /// In pt, this message translates to:
  /// **'Importar para Lista'**
  String get importIcalList;

  /// No description provided for @importConfirm.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Importar 1 tarefa?} other{Importar {count} tarefas?}}'**
  String importConfirm(num count);

  /// No description provided for @importAction.
  ///
  /// In pt, this message translates to:
  /// **'Importar'**
  String get importAction;

  /// No description provided for @importDone.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 tarefa importada} other{{count} tarefas importadas}}'**
  String importDone(num count);

  /// No description provided for @importNothing.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa encontrada no arquivo'**
  String get importNothing;

  /// No description provided for @importInvalidBackup.
  ///
  /// In pt, this message translates to:
  /// **'Este arquivo não parece um backup do TickTick'**
  String get importInvalidBackup;

  /// No description provided for @importInvalidIcal.
  ///
  /// In pt, this message translates to:
  /// **'Este arquivo não parece um calendário iCal'**
  String get importInvalidIcal;

  /// No description provided for @subscriptionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Calendários assinados'**
  String get subscriptionsTitle;

  /// No description provided for @subscriptionHolidaysName.
  ///
  /// In pt, this message translates to:
  /// **'Feriados do Brasil'**
  String get subscriptionHolidaysName;

  /// No description provided for @subscriptionHolidaysHint.
  ///
  /// In pt, this message translates to:
  /// **'Feriados nacionais e pontos facultativos, calculados no aparelho'**
  String get subscriptionHolidaysHint;

  /// No description provided for @subscriptionAddHolidays.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar feriados do Brasil'**
  String get subscriptionAddHolidays;

  /// No description provided for @subscriptionAddUrl.
  ///
  /// In pt, this message translates to:
  /// **'Assinar por URL (.ics)'**
  String get subscriptionAddUrl;

  /// No description provided for @subscriptionUrl.
  ///
  /// In pt, this message translates to:
  /// **'Endereço do calendário'**
  String get subscriptionUrl;

  /// No description provided for @subscriptionName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get subscriptionName;

  /// No description provided for @subscriptionSubscribe.
  ///
  /// In pt, this message translates to:
  /// **'Assinar'**
  String get subscriptionSubscribe;

  /// No description provided for @subscriptionAdded.
  ///
  /// In pt, this message translates to:
  /// **'Calendário assinado'**
  String get subscriptionAdded;

  /// No description provided for @subscriptionUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Calendário atualizado'**
  String get subscriptionUpdated;

  /// No description provided for @subscriptionFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível baixar o calendário'**
  String get subscriptionFailed;

  /// No description provided for @subscriptionRefresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get subscriptionRefresh;

  /// No description provided for @subscriptionNeverFetched.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não baixado'**
  String get subscriptionNeverFetched;

  /// No description provided for @subscriptionFetched.
  ///
  /// In pt, this message translates to:
  /// **'Atualizado: {when}'**
  String subscriptionFetched(Object when);

  /// No description provided for @emojiSearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar emoji'**
  String get emojiSearch;

  /// No description provided for @emojiPeople.
  ///
  /// In pt, this message translates to:
  /// **'Pessoas e Corpo'**
  String get emojiPeople;

  /// No description provided for @emojiNature.
  ///
  /// In pt, this message translates to:
  /// **'Natureza'**
  String get emojiNature;

  /// No description provided for @emojiFood.
  ///
  /// In pt, this message translates to:
  /// **'Comida'**
  String get emojiFood;

  /// No description provided for @emojiActivities.
  ///
  /// In pt, this message translates to:
  /// **'Atividades'**
  String get emojiActivities;

  /// No description provided for @emojiTravel.
  ///
  /// In pt, this message translates to:
  /// **'Viagem'**
  String get emojiTravel;

  /// No description provided for @emojiObjects.
  ///
  /// In pt, this message translates to:
  /// **'Objetos'**
  String get emojiObjects;

  /// No description provided for @emojiSymbols.
  ///
  /// In pt, this message translates to:
  /// **'Símbolos'**
  String get emojiSymbols;

  /// No description provided for @emojiFlags.
  ///
  /// In pt, this message translates to:
  /// **'Bandeiras'**
  String get emojiFlags;

  /// No description provided for @emojiResults.
  ///
  /// In pt, this message translates to:
  /// **'Resultados'**
  String get emojiResults;

  /// No description provided for @emojiRandom.
  ///
  /// In pt, this message translates to:
  /// **'Aleatório'**
  String get emojiRandom;

  /// No description provided for @emojiReset.
  ///
  /// In pt, this message translates to:
  /// **'Redefinir'**
  String get emojiReset;

  /// No description provided for @shortcutGoTo.
  ///
  /// In pt, this message translates to:
  /// **'Ir para {name}'**
  String shortcutGoTo(Object name);

  /// No description provided for @shortcutViewAs.
  ///
  /// In pt, this message translates to:
  /// **'Visualização {name}'**
  String shortcutViewAs(Object name);

  /// No description provided for @shortcutNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem atalho'**
  String get shortcutNone;

  /// No description provided for @shortcutEditHint.
  ///
  /// In pt, this message translates to:
  /// **'Clique numa ação para trocar o atalho.'**
  String get shortcutEditHint;

  /// No description provided for @shortcutRestoreAll.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get shortcutRestoreAll;

  /// No description provided for @shortcutRecordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atalho: {name}'**
  String shortcutRecordTitle(Object name);

  /// No description provided for @shortcutRecordHint.
  ///
  /// In pt, this message translates to:
  /// **'Pressione as teclas (segure Tab para Tab+tecla). Esc cancela.'**
  String get shortcutRecordHint;

  /// No description provided for @shortcutSequence.
  ///
  /// In pt, this message translates to:
  /// **'Duas teclas em sequência (ex.: G → T)'**
  String get shortcutSequence;

  /// No description provided for @shortcutRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get shortcutRemove;

  /// No description provided for @shortcutConflict.
  ///
  /// In pt, this message translates to:
  /// **'O atalho saiu de \"{name}\"'**
  String shortcutConflict(Object name);

  /// No description provided for @searchInArchived.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar em Arquivados'**
  String get searchInArchived;

  /// No description provided for @searchActiveLists.
  ///
  /// In pt, this message translates to:
  /// **'Voltar às listas ativas'**
  String get searchActiveLists;

  /// No description provided for @searchArchivedCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhum resultado nas listas arquivadas} =1{1 resultado nas listas arquivadas} other{{count} resultados nas listas arquivadas}}'**
  String searchArchivedCount(num count);

  /// No description provided for @activityPinned.
  ///
  /// In pt, this message translates to:
  /// **'Você fixou a tarefa'**
  String get activityPinned;

  /// No description provided for @activityUnpinned.
  ///
  /// In pt, this message translates to:
  /// **'Você desafixou a tarefa'**
  String get activityUnpinned;

  /// No description provided for @activityParent.
  ///
  /// In pt, this message translates to:
  /// **'Você colocou a tarefa dentro de \"{title}\"'**
  String activityParent(Object title);

  /// No description provided for @activityParentRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Você tirou a tarefa de dentro da tarefa-pai'**
  String get activityParentRemoved;

  /// No description provided for @activityTags.
  ///
  /// In pt, this message translates to:
  /// **'Você mudou as tags para {tags}'**
  String activityTags(Object tags);

  /// No description provided for @activityTagsRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Você tirou as tags'**
  String get activityTagsRemoved;

  /// No description provided for @countdownUnitWeeks.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{semana} other{semanas}}'**
  String countdownUnitWeeks(num count);

  /// No description provided for @countdownUnitMonths.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{mês} other{meses}}'**
  String countdownUnitMonths(num count);

  /// No description provided for @countdownUnitYears.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{ano} other{anos}}'**
  String countdownUnitYears(num count);

  /// No description provided for @countdownIcon.
  ///
  /// In pt, this message translates to:
  /// **'Ícone'**
  String get countdownIcon;

  /// No description provided for @countdownImage.
  ///
  /// In pt, this message translates to:
  /// **'Imagem de fundo'**
  String get countdownImage;

  /// No description provided for @countdownImagePick.
  ///
  /// In pt, this message translates to:
  /// **'Escolher imagem'**
  String get countdownImagePick;

  /// No description provided for @countdownImageRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover imagem'**
  String get countdownImageRemove;

  /// No description provided for @colorCustom.
  ///
  /// In pt, this message translates to:
  /// **'Cor personalizada'**
  String get colorCustom;

  /// No description provided for @colorHue.
  ///
  /// In pt, this message translates to:
  /// **'Tom'**
  String get colorHue;

  /// No description provided for @colorLightness.
  ///
  /// In pt, this message translates to:
  /// **'Luz'**
  String get colorLightness;

  /// No description provided for @summarySaveImage.
  ///
  /// In pt, this message translates to:
  /// **'Salvar como Imagem'**
  String get summarySaveImage;

  /// No description provided for @summaryImageSaved.
  ///
  /// In pt, this message translates to:
  /// **'Imagem salva'**
  String get summaryImageSaved;

  /// No description provided for @reminderAtEnd.
  ///
  /// In pt, this message translates to:
  /// **'No fim'**
  String get reminderAtEnd;

  /// No description provided for @settingsDefaultDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração padrão, tarefa com hora'**
  String get settingsDefaultDuration;

  /// No description provided for @settingsListColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor da Lista'**
  String get settingsListColor;

  /// No description provided for @calendarShowLists.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar listas ao lado'**
  String get calendarShowLists;

  /// No description provided for @statsMedals.
  ///
  /// In pt, this message translates to:
  /// **'Medalhas'**
  String get statsMedals;

  /// No description provided for @medalPerseverance.
  ///
  /// In pt, this message translates to:
  /// **'Perseverança'**
  String get medalPerseverance;

  /// No description provided for @medalGetThingsDone.
  ///
  /// In pt, this message translates to:
  /// **'Get Things Done'**
  String get medalGetThingsDone;

  /// No description provided for @medalMindfulness.
  ///
  /// In pt, this message translates to:
  /// **'Mindfulness'**
  String get medalMindfulness;

  /// No description provided for @medalSelfDiscipline.
  ///
  /// In pt, this message translates to:
  /// **'Autodisciplina'**
  String get medalSelfDiscipline;

  /// No description provided for @medalLocked.
  ///
  /// In pt, this message translates to:
  /// **'Bloqueada'**
  String get medalLocked;

  /// No description provided for @medalMinutes.
  ///
  /// In pt, this message translates to:
  /// **'min de foco'**
  String get medalMinutes;

  /// No description provided for @medalCheckins.
  ///
  /// In pt, this message translates to:
  /// **'check-ins'**
  String get medalCheckins;

  /// No description provided for @focusLess5.
  ///
  /// In pt, this message translates to:
  /// **'−5 minutos'**
  String get focusLess5;

  /// No description provided for @focusMore5.
  ///
  /// In pt, this message translates to:
  /// **'+5 minutos'**
  String get focusMore5;

  /// No description provided for @focusExtraTime.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar tempo extra'**
  String get focusExtraTime;

  /// No description provided for @focusEditDuration.
  ///
  /// In pt, this message translates to:
  /// **'Editar duração do foco'**
  String get focusEditDuration;

  /// No description provided for @focusMinutesSuffix.
  ///
  /// In pt, this message translates to:
  /// **'minutos'**
  String get focusMinutesSuffix;

  /// No description provided for @calendarStyle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo'**
  String get calendarStyle;

  /// No description provided for @calendarStyleModern.
  ///
  /// In pt, this message translates to:
  /// **'Moderno'**
  String get calendarStyleModern;

  /// No description provided for @calendarStyleClassic.
  ///
  /// In pt, this message translates to:
  /// **'Clássico'**
  String get calendarStyleClassic;

  /// No description provided for @calendarShowIcons.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar ícones'**
  String get calendarShowIcons;

  /// No description provided for @calendarTimeZones.
  ///
  /// In pt, this message translates to:
  /// **'Fusos adicionais'**
  String get calendarTimeZones;

  /// No description provided for @calendarAddTimeZone.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar fuso horário'**
  String get calendarAddTimeZone;

  /// No description provided for @calendarSearchTimeZone.
  ///
  /// In pt, this message translates to:
  /// **'Buscar cidade ou fuso'**
  String get calendarSearchTimeZone;

  /// No description provided for @summaryFieldFocus.
  ///
  /// In pt, this message translates to:
  /// **'Dados de foco'**
  String get summaryFieldFocus;

  /// No description provided for @summarySendEmail.
  ///
  /// In pt, this message translates to:
  /// **'Enviar email'**
  String get summarySendEmail;

  /// No description provided for @summaryNoMailApp.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum app de email encontrado. O texto foi copiado.'**
  String get summaryNoMailApp;

  /// No description provided for @settingsTimeZone.
  ///
  /// In pt, this message translates to:
  /// **'Fuso horário'**
  String get settingsTimeZone;

  /// No description provided for @settingsTimeZoneHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolher o fuso ao definir a hora da tarefa'**
  String get settingsTimeZoneHint;

  /// No description provided for @pickerTimeZone.
  ///
  /// In pt, this message translates to:
  /// **'Fuso horário'**
  String get pickerTimeZone;

  /// No description provided for @zoneFixed.
  ///
  /// In pt, this message translates to:
  /// **'Fuso horário fixo'**
  String get zoneFixed;

  /// No description provided for @zoneChoose.
  ///
  /// In pt, this message translates to:
  /// **'Escolher'**
  String get zoneChoose;

  /// No description provided for @zoneFloating.
  ///
  /// In pt, this message translates to:
  /// **'Tempo flutuante'**
  String get zoneFloating;

  /// No description provided for @zoneFloatingHint.
  ///
  /// In pt, this message translates to:
  /// **'Quando o fuso horário muda, o tempo permanece o mesmo.'**
  String get zoneFloatingHint;

  /// No description provided for @focusEstimate.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa'**
  String get focusEstimate;

  /// No description provided for @estimatePomos.
  ///
  /// In pt, this message translates to:
  /// **'Pomo Estimado'**
  String get estimatePomos;

  /// No description provided for @estimateDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração estimada'**
  String get estimateDuration;

  /// No description provided for @estimatePomoCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 Pomo} other{{count} Pomos}}'**
  String estimatePomoCount(int count);

  /// No description provided for @estimateFocused.
  ///
  /// In pt, this message translates to:
  /// **'Focado em'**
  String get estimateFocused;

  /// No description provided for @focusFocusing.
  ///
  /// In pt, this message translates to:
  /// **'Focando'**
  String get focusFocusing;

  /// No description provided for @focusTimersArchivedEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum timer arquivado'**
  String get focusTimersArchivedEmpty;

  /// No description provided for @focusSound.
  ///
  /// In pt, this message translates to:
  /// **'Som do Pomo'**
  String get focusSound;

  /// No description provided for @focusSoundStandard.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get focusSoundStandard;

  /// No description provided for @focusSoundAlarm.
  ///
  /// In pt, this message translates to:
  /// **'Despertador'**
  String get focusSoundAlarm;

  /// No description provided for @focusSoundReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete'**
  String get focusSoundReminder;

  /// No description provided for @focusSoundMessage.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem'**
  String get focusSoundMessage;

  /// No description provided for @focusSoundSilent.
  ///
  /// In pt, this message translates to:
  /// **'Silencioso'**
  String get focusSoundSilent;

  /// No description provided for @notificationSilentChannelName.
  ///
  /// In pt, this message translates to:
  /// **'Fim do Pomo silencioso'**
  String get notificationSilentChannelName;

  /// No description provided for @focusTimeInTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tempo de execução no título da janela'**
  String get focusTimeInTitle;

  /// No description provided for @sectionInsertAbove.
  ///
  /// In pt, this message translates to:
  /// **'Inserir seção acima'**
  String get sectionInsertAbove;

  /// No description provided for @sectionInsertBelow.
  ///
  /// In pt, this message translates to:
  /// **'Inserir seção abaixo'**
  String get sectionInsertBelow;

  /// No description provided for @slashSubtask.
  ///
  /// In pt, this message translates to:
  /// **'Subtarefa'**
  String get slashSubtask;

  /// No description provided for @slashTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get slashTag;

  /// No description provided for @slashTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar a partir do modelo'**
  String get slashTemplate;

  /// No description provided for @closedAllDates.
  ///
  /// In pt, this message translates to:
  /// **'Todas as datas'**
  String get closedAllDates;

  /// No description provided for @closedOtherMonth.
  ///
  /// In pt, this message translates to:
  /// **'Outro mês'**
  String get closedOtherMonth;

  /// No description provided for @closedAllLists.
  ///
  /// In pt, this message translates to:
  /// **'Todas as listas'**
  String get closedAllLists;

  /// No description provided for @orderLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ordem'**
  String get orderLabel;

  /// No description provided for @orderAscending.
  ///
  /// In pt, this message translates to:
  /// **'Crescente'**
  String get orderAscending;

  /// No description provided for @orderDescending.
  ///
  /// In pt, this message translates to:
  /// **'Decrescente'**
  String get orderDescending;

  /// No description provided for @optionList.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get optionList;

  /// No description provided for @matrixExamples.
  ///
  /// In pt, this message translates to:
  /// **'Exemplos'**
  String get matrixExamples;

  /// No description provided for @matrixPresetPriority.
  ///
  /// In pt, this message translates to:
  /// **'Só prioridade'**
  String get matrixPresetPriority;

  /// No description provided for @matrixPresetTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo + prioridade'**
  String get matrixPresetTime;

  /// No description provided for @formatBar.
  ///
  /// In pt, this message translates to:
  /// **'Formatar'**
  String get formatBar;

  /// No description provided for @formatHeading.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get formatHeading;

  /// No description provided for @formatBold.
  ///
  /// In pt, this message translates to:
  /// **'Negrito'**
  String get formatBold;

  /// No description provided for @formatItalic.
  ///
  /// In pt, this message translates to:
  /// **'Itálico'**
  String get formatItalic;

  /// No description provided for @formatUnderline.
  ///
  /// In pt, this message translates to:
  /// **'Sublinhado'**
  String get formatUnderline;

  /// No description provided for @formatStrikethrough.
  ///
  /// In pt, this message translates to:
  /// **'Tachado'**
  String get formatStrikethrough;

  /// No description provided for @formatTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo'**
  String get formatTime;

  /// No description provided for @formatLink.
  ///
  /// In pt, this message translates to:
  /// **'Link'**
  String get formatLink;

  /// No description provided for @formatCode.
  ///
  /// In pt, this message translates to:
  /// **'Código'**
  String get formatCode;

  /// No description provided for @countdownDirection.
  ///
  /// In pt, this message translates to:
  /// **'Modo de Contagem'**
  String get countdownDirection;

  /// No description provided for @countdownDirectionDown.
  ///
  /// In pt, this message translates to:
  /// **'Contagem regressiva'**
  String get countdownDirectionDown;

  /// No description provided for @countdownDirectionUp.
  ///
  /// In pt, this message translates to:
  /// **'Cronômetro'**
  String get countdownDirectionUp;

  /// No description provided for @reminderConstant.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete constante'**
  String get reminderConstant;

  /// No description provided for @templateNotesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modelo de nota'**
  String get templateNotesTitle;

  /// No description provided for @templateWeeklyReviewName.
  ///
  /// In pt, this message translates to:
  /// **'Revisão Semanal'**
  String get templateWeeklyReviewName;

  /// No description provided for @templateWeeklyReviewContent.
  ///
  /// In pt, this message translates to:
  /// **'## O que concluí nesta semana\n\n## O que ficou para trás e por quê\n\n## Prioridades da próxima semana\n\n## Reflexões'**
  String get templateWeeklyReviewContent;

  /// No description provided for @templateReadingName.
  ///
  /// In pt, this message translates to:
  /// **'Nota de leitura'**
  String get templateReadingName;

  /// No description provided for @templateReadingContent.
  ///
  /// In pt, this message translates to:
  /// **'**Título do livro:** \n\n**Autor:** \n\n**Resumo da ideia:** '**
  String get templateReadingContent;

  /// No description provided for @templateMeetingName.
  ///
  /// In pt, this message translates to:
  /// **'Nota de Reunião'**
  String get templateMeetingName;

  /// No description provided for @templateMeetingContent.
  ///
  /// In pt, this message translates to:
  /// **'**Tema:** \n\n**Tempo:** \n\n**Participante(s):** \n\n**Objetivos da reunião:** '**
  String get templateMeetingContent;

  /// No description provided for @noteInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações'**
  String get noteInfo;

  /// No description provided for @noteWords.
  ///
  /// In pt, this message translates to:
  /// **'Palavras'**
  String get noteWords;

  /// No description provided for @noteCharacters.
  ///
  /// In pt, this message translates to:
  /// **'Caracteres'**
  String get noteCharacters;

  /// No description provided for @noteCreated.
  ///
  /// In pt, this message translates to:
  /// **'Criado'**
  String get noteCreated;

  /// No description provided for @noteModified.
  ///
  /// In pt, this message translates to:
  /// **'Modificado'**
  String get noteModified;

  /// No description provided for @habitAddSection.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Seção'**
  String get habitAddSection;

  /// No description provided for @habitYearHeatmap.
  ///
  /// In pt, this message translates to:
  /// **'Mapa do ano'**
  String get habitYearHeatmap;

  /// No description provided for @settingsDateFormat.
  ///
  /// In pt, this message translates to:
  /// **'Formato de data'**
  String get settingsDateFormat;

  /// No description provided for @settingsDefaultTag.
  ///
  /// In pt, this message translates to:
  /// **'Tag padrão'**
  String get settingsDefaultTag;

  /// No description provided for @settingsParseUrls.
  ///
  /// In pt, this message translates to:
  /// **'Análise de URL'**
  String get settingsParseUrls;

  /// No description provided for @settingsParseUrlsHint.
  ///
  /// In pt, this message translates to:
  /// **'Um título que é só um link vira o título da página (lê a página na internet)'**
  String get settingsParseUrlsHint;

  /// No description provided for @settingsMiniCalendar.
  ///
  /// In pt, this message translates to:
  /// **'Mini Calendário'**
  String get settingsMiniCalendar;

  /// No description provided for @settingsMiniCalendarHint.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar na barra lateral'**
  String get settingsMiniCalendarHint;

  /// No description provided for @copyOpenOnly.
  ///
  /// In pt, this message translates to:
  /// **'Apenas tarefas incompletas'**
  String get copyOpenOnly;

  /// No description provided for @copyKeepStatus.
  ///
  /// In pt, this message translates to:
  /// **'Todas as tarefas, preservando o status de conclusão'**
  String get copyKeepStatus;

  /// No description provided for @copyAllReopened.
  ///
  /// In pt, this message translates to:
  /// **'Todas as tarefas, sem o status de concluídas'**
  String get copyAllReopened;

  /// No description provided for @addAsNote.
  ///
  /// In pt, this message translates to:
  /// **'Converter para nota'**
  String get addAsNote;

  /// No description provided for @detailLayout.
  ///
  /// In pt, this message translates to:
  /// **'Layout de detalhes da tarefa'**
  String get detailLayout;

  /// No description provided for @detailLayoutPanel.
  ///
  /// In pt, this message translates to:
  /// **'Painel lateral'**
  String get detailLayoutPanel;

  /// No description provided for @detailLayoutPopup.
  ///
  /// In pt, this message translates to:
  /// **'Janela pop-up'**
  String get detailLayoutPopup;

  /// No description provided for @focusBatch.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Lotes'**
  String get focusBatch;

  /// No description provided for @focusExport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar'**
  String get focusExport;

  /// No description provided for @focusExported.
  ///
  /// In pt, this message translates to:
  /// **'Registros exportados'**
  String get focusExported;

  /// No description provided for @focusExportStart.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get focusExportStart;

  /// No description provided for @focusExportEnd.
  ///
  /// In pt, this message translates to:
  /// **'Fim'**
  String get focusExportEnd;

  /// No description provided for @focusExportMinutes.
  ///
  /// In pt, this message translates to:
  /// **'Minutos'**
  String get focusExportMinutes;

  /// No description provided for @focusExportMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo'**
  String get focusExportMode;

  /// No description provided for @focusExportLinked.
  ///
  /// In pt, this message translates to:
  /// **'Vinculado a'**
  String get focusExportLinked;

  /// No description provided for @focusExportTimer.
  ///
  /// In pt, this message translates to:
  /// **'Timer'**
  String get focusExportTimer;

  /// No description provided for @focusExportNote.
  ///
  /// In pt, this message translates to:
  /// **'Nota'**
  String get focusExportNote;

  /// No description provided for @focusFilterDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get focusFilterDate;

  /// No description provided for @focusFilterLength.
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get focusFilterLength;

  /// No description provided for @focusFilterLinked.
  ///
  /// In pt, this message translates to:
  /// **'Status Vinculado'**
  String get focusFilterLinked;

  /// No description provided for @focusLengthShort.
  ///
  /// In pt, this message translates to:
  /// **'Menos de 25m'**
  String get focusLengthShort;

  /// No description provided for @focusLengthLong.
  ///
  /// In pt, this message translates to:
  /// **'25m ou mais'**
  String get focusLengthLong;

  /// No description provided for @focusLinked.
  ///
  /// In pt, this message translates to:
  /// **'Vinculado'**
  String get focusLinked;

  /// No description provided for @focusUnlinked.
  ///
  /// In pt, this message translates to:
  /// **'Não vinculado'**
  String get focusUnlinked;

  /// No description provided for @focusDeleteSelected.
  ///
  /// In pt, this message translates to:
  /// **'Excluir {count, plural, =1{1 registro} other{{count} registros}}?'**
  String focusDeleteSelected(int count);

  /// No description provided for @focusTimerAddRecord.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Registro'**
  String get focusTimerAddRecord;

  /// No description provided for @timerFocusedDays.
  ///
  /// In pt, this message translates to:
  /// **'Dias focados'**
  String get timerFocusedDays;

  /// No description provided for @timerTotal.
  ///
  /// In pt, this message translates to:
  /// **'Foco Total'**
  String get timerTotal;

  /// No description provided for @timerDailyAverage.
  ///
  /// In pt, this message translates to:
  /// **'Média diária: {duration}'**
  String timerDailyAverage(String duration);

  /// No description provided for @suggestedTasks.
  ///
  /// In pt, this message translates to:
  /// **'Experimente Tarefas Sugeridas'**
  String get suggestedTasks;

  /// No description provided for @suggestedUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Próximos dias'**
  String get suggestedUpcoming;

  /// No description provided for @suggestedAddToday.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar a Hoje'**
  String get suggestedAddToday;

  /// No description provided for @suggestedEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma sugestão por enquanto'**
  String get suggestedEmpty;

  /// No description provided for @habitGallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria de hábitos'**
  String get habitGallery;

  /// No description provided for @habitCreateNew.
  ///
  /// In pt, this message translates to:
  /// **'Criar novo'**
  String get habitCreateNew;

  /// No description provided for @habitCardView.
  ///
  /// In pt, this message translates to:
  /// **'Visão em cartão'**
  String get habitCardView;

  /// No description provided for @habitListView.
  ///
  /// In pt, this message translates to:
  /// **'Visão em lista'**
  String get habitListView;

  /// No description provided for @habitGalleryLife.
  ///
  /// In pt, this message translates to:
  /// **'Vida'**
  String get habitGalleryLife;

  /// No description provided for @habitGalleryHealth.
  ///
  /// In pt, this message translates to:
  /// **'Saúde'**
  String get habitGalleryHealth;

  /// No description provided for @habitGalleryExercise.
  ///
  /// In pt, this message translates to:
  /// **'Exercício'**
  String get habitGalleryExercise;

  /// No description provided for @habitGalleryMind.
  ///
  /// In pt, this message translates to:
  /// **'Mente'**
  String get habitGalleryMind;

  /// No description provided for @habitGalleryLifeItems.
  ///
  /// In pt, this message translates to:
  /// **'🌅 Acordar cedo\n🛏️ Arrumar a cama\n🧹 Arrumar a casa\n🪴 Regar as plantas\n🍳 Cozinhar em casa\n💰 Anotar os gastos\n📵 Menos tempo no celular\n📞 Ligar para a família\n🧺 Lavar a roupa\n🛒 Planejar as compras\n🐶 Passear com o cachorro\n📬 Zerar a caixa de entrada\n🌙 Dormir antes das 23h\n🗓️ Planejar o dia\n🎁 Fazer uma gentileza'**
  String get habitGalleryLifeItems;

  /// No description provided for @habitGalleryHealthItems.
  ///
  /// In pt, this message translates to:
  /// **'💧 Beber água\n🥗 Comer salada\n🍎 Comer uma fruta\n💊 Tomar vitaminas\n🦷 Passar fio dental\n🚭 Não fumar\n🍬 Menos açúcar\n☕ Menos café\n😴 Dormir 8 horas\n🧴 Cuidar da pele\n🥛 Tomar café da manhã\n🚰 Sem refrigerante\n🧘 Alongar\n👀 Descansar a vista\n🍷 Sem álcool'**
  String get habitGalleryHealthItems;

  /// No description provided for @habitGalleryExerciseItems.
  ///
  /// In pt, this message translates to:
  /// **'🏃 Correr\n🚶 Caminhar 30 minutos\n👟 10 mil passos\n🏋️ Musculação\n🚴 Pedalar\n🏊 Nadar\n🧘 Yoga\n🤸 Abdominais\n💪 Flexões\n⛹️ Praticar esporte\n🪜 Usar a escada\n🥊 Treino funcional\n🕺 Dançar\n🧗 Escalar\n🤾 Pular corda'**
  String get habitGalleryExerciseItems;

  /// No description provided for @habitGalleryMindItems.
  ///
  /// In pt, this message translates to:
  /// **'📚 Ler\n🧘 Meditar\n✍️ Escrever no diário\n🙏 Gratidão\n🗣️ Estudar um idioma\n🎹 Praticar um instrumento\n🎨 Desenhar\n🧩 Aprender algo novo\n📝 Revisar o dia\n🎧 Ouvir um podcast\n🌳 Tempo na natureza\n🤔 Refletir\n📖 Ler antes de dormir\n🧠 Exercício de memória\n😊 Sorrir'**
  String get habitGalleryMindItems;

  /// No description provided for @toastUndone.
  ///
  /// In pt, this message translates to:
  /// **'Desfeito'**
  String get toastUndone;

  /// No description provided for @toastRedone.
  ///
  /// In pt, this message translates to:
  /// **'Refeito'**
  String get toastRedone;

  /// No description provided for @shortcutUndo.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer'**
  String get shortcutUndo;

  /// No description provided for @shortcutRedo.
  ///
  /// In pt, this message translates to:
  /// **'Refazer'**
  String get shortcutRedo;

  /// No description provided for @addFieldSimple.
  ///
  /// In pt, this message translates to:
  /// **'Estilo: Simples'**
  String get addFieldSimple;

  /// No description provided for @addFieldDetailed.
  ///
  /// In pt, this message translates to:
  /// **'Estilo: Detalhado'**
  String get addFieldDetailed;

  /// No description provided for @addFieldAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get addFieldAdd;

  /// No description provided for @formatImmersive.
  ///
  /// In pt, this message translates to:
  /// **'Escrita Imersiva'**
  String get formatImmersive;

  /// No description provided for @paletteModules.
  ///
  /// In pt, this message translates to:
  /// **'Módulos'**
  String get paletteModules;

  /// No description provided for @paletteFolders.
  ///
  /// In pt, this message translates to:
  /// **'Pastas'**
  String get paletteFolders;

  /// No description provided for @shortcutCalendarToday.
  ///
  /// In pt, this message translates to:
  /// **'Calendário: voltar para hoje'**
  String get shortcutCalendarToday;

  /// No description provided for @menuAttach.
  ///
  /// In pt, this message translates to:
  /// **'Carregar anexo'**
  String get menuAttach;

  /// No description provided for @countdownMinutesShort.
  ///
  /// In pt, this message translates to:
  /// **'{count} M'**
  String countdownMinutesShort(int count);

  /// No description provided for @countdownHoursShort.
  ///
  /// In pt, this message translates to:
  /// **'{count} H'**
  String countdownHoursShort(int count);

  /// No description provided for @repeatSkipWeekends.
  ///
  /// In pt, this message translates to:
  /// **'Pular finais de semana'**
  String get repeatSkipWeekends;

  /// No description provided for @countdownNoteHint.
  ///
  /// In pt, this message translates to:
  /// **'Adicione uma nota…'**
  String get countdownNoteHint;

  /// No description provided for @settingsInterfaceStyle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo da Interface'**
  String get settingsInterfaceStyle;

  /// No description provided for @interfaceFlat.
  ///
  /// In pt, this message translates to:
  /// **'Plano'**
  String get interfaceFlat;

  /// No description provided for @interfaceCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão'**
  String get interfaceCard;

  /// No description provided for @summaryToNote.
  ///
  /// In pt, this message translates to:
  /// **'Inserir numa nota'**
  String get summaryToNote;

  /// No description provided for @summaryNoteCreated.
  ///
  /// In pt, this message translates to:
  /// **'Nota criada'**
  String get summaryNoteCreated;

  /// No description provided for @matrixSwapWith.
  ///
  /// In pt, this message translates to:
  /// **'Trocar de lugar com \"{name}\"'**
  String matrixSwapWith(String name);

  /// No description provided for @habitMottoHint.
  ///
  /// In pt, this message translates to:
  /// **'Frase motivacional (opcional)'**
  String get habitMottoHint;

  /// No description provided for @calendarHideBefore.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar horas antes de (h)'**
  String get calendarHideBefore;

  /// No description provided for @calendarHideAfter.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar horas a partir de (h)'**
  String get calendarHideAfter;

  /// No description provided for @countdownIconText.
  ///
  /// In pt, this message translates to:
  /// **'Texto'**
  String get countdownIconText;

  /// No description provided for @countdownIconTextHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite 1 caractere'**
  String get countdownIconTextHint;

  /// No description provided for @helpHome.
  ///
  /// In pt, this message translates to:
  /// **'Página inicial'**
  String get helpHome;

  /// No description provided for @helpAbout.
  ///
  /// In pt, this message translates to:
  /// **'Sobre o Ordo'**
  String get helpAbout;

  /// No description provided for @commentImage.
  ///
  /// In pt, this message translates to:
  /// **'Imagem'**
  String get commentImage;

  /// No description provided for @toastConverted.
  ///
  /// In pt, this message translates to:
  /// **'Convertido'**
  String get toastConverted;

  /// No description provided for @quickAddModalHint.
  ///
  /// In pt, this message translates to:
  /// **'O que você gostaria de fazer?'**
  String get quickAddModalHint;

  /// No description provided for @summaryAllLists.
  ///
  /// In pt, this message translates to:
  /// **'Todas as listas'**
  String get summaryAllLists;

  /// No description provided for @summaryAllStatuses.
  ///
  /// In pt, this message translates to:
  /// **'Todos os status'**
  String get summaryAllStatuses;

  /// No description provided for @summaryAllTags.
  ///
  /// In pt, this message translates to:
  /// **'Todas as tags'**
  String get summaryAllTags;

  /// No description provided for @summaryAllPriorities.
  ///
  /// In pt, this message translates to:
  /// **'Todas as prioridades'**
  String get summaryAllPriorities;

  /// No description provided for @focusEndBreak.
  ///
  /// In pt, this message translates to:
  /// **'Terminar'**
  String get focusEndBreak;

  /// No description provided for @habitSortByStatusHint.
  ///
  /// In pt, this message translates to:
  /// **'Os hábitos desmarcados serão mostrados no topo da lista'**
  String get habitSortByStatusHint;

  /// No description provided for @tagMergeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mesclar Tags'**
  String get tagMergeTitle;

  /// No description provided for @tagMergeExplain.
  ///
  /// In pt, this message translates to:
  /// **'Você pode mesclar as tarefas relacionadas da tag \'{name}\' com outra tag. Após a fusão, a tag \'{name}\' será excluída.'**
  String tagMergeExplain(String name);

  /// No description provided for @actionConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get actionConfirm;

  /// No description provided for @kanbanOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Em atraso'**
  String get kanbanOverdue;

  /// No description provided for @linkPickerHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get linkPickerHint;

  /// No description provided for @linkPickerEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sem tarefas'**
  String get linkPickerEmptyTitle;

  /// No description provided for @linkPickerEmptyBody.
  ///
  /// In pt, this message translates to:
  /// **'Tente alternar listas ou pesquisar'**
  String get linkPickerEmptyBody;

  /// No description provided for @countdownHideGroup.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar Grupo'**
  String get countdownHideGroup;

  /// No description provided for @countdownAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get countdownAll;

  /// No description provided for @summaryFieldTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título da Tarefa'**
  String get summaryFieldTitle;

  /// No description provided for @summarySaveTemplateHint.
  ///
  /// In pt, this message translates to:
  /// **'Salvar a configuração atual como um modelo e selecioná-lo para geração rápida ao usar novamente.'**
  String get summarySaveTemplateHint;

  /// No description provided for @countdownIconEvent.
  ///
  /// In pt, this message translates to:
  /// **'Evento'**
  String get countdownIconEvent;

  /// No description provided for @countdownIconPerson.
  ///
  /// In pt, this message translates to:
  /// **'Pessoa'**
  String get countdownIconPerson;

  /// No description provided for @countdownIconParty.
  ///
  /// In pt, this message translates to:
  /// **'Festas'**
  String get countdownIconParty;

  /// No description provided for @countdownIconSport.
  ///
  /// In pt, this message translates to:
  /// **'Esporte'**
  String get countdownIconSport;

  /// No description provided for @countdownIconAnimal.
  ///
  /// In pt, this message translates to:
  /// **'Animal'**
  String get countdownIconAnimal;

  /// No description provided for @settingsAutoBackup.
  ///
  /// In pt, this message translates to:
  /// **'Backups automáticos'**
  String get settingsAutoBackup;

  /// No description provided for @settingsAutoBackupHint.
  ///
  /// In pt, this message translates to:
  /// **'Uma cópia por dia das tarefas e configurações, guardada neste dispositivo. Ficam as 7 mais recentes. Os anexos não entram nela e continuam onde estão.'**
  String get settingsAutoBackupHint;

  /// No description provided for @xlsxExport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar para Excel'**
  String get xlsxExport;

  /// No description provided for @xlsxExportHint.
  ///
  /// In pt, this message translates to:
  /// **'Uma planilha com uma aba por módulo: tarefas, hábitos, finanças, dieta e diário'**
  String get xlsxExportHint;

  /// No description provided for @xlsxExported.
  ///
  /// In pt, this message translates to:
  /// **'Planilha salva'**
  String get xlsxExported;

  /// No description provided for @xlsxImport.
  ///
  /// In pt, this message translates to:
  /// **'Importar do Excel'**
  String get xlsxImport;

  /// No description provided for @xlsxImportHint.
  ///
  /// In pt, this message translates to:
  /// **'Acrescenta as tarefas e os lançamentos de uma planilha no mesmo formato. Nada é apagado.'**
  String get xlsxImportHint;

  /// No description provided for @xlsxImportInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Este arquivo não parece uma planilha do Excel (.xlsx)'**
  String get xlsxImportInvalid;

  /// No description provided for @xlsxImportNothing.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma tarefa ou lançamento encontrado na planilha'**
  String get xlsxImportNothing;

  /// No description provided for @xlsxImportTasks.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{nenhuma tarefa} =1{1 tarefa} other{{count} tarefas}}'**
  String xlsxImportTasks(num count);

  /// No description provided for @xlsxImportEntries.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{nenhum lançamento} =1{1 lançamento} other{{count} lançamentos}}'**
  String xlsxImportEntries(num count);

  /// No description provided for @xlsxImportErrors.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{nenhuma linha com erro} =1{1 linha com erro} other{{count} linhas com erro}}'**
  String xlsxImportErrors(num count);

  /// No description provided for @xlsxImportSummary.
  ///
  /// In pt, this message translates to:
  /// **'{tasks}, {entries}; {errors}'**
  String xlsxImportSummary(String tasks, String entries, String errors);

  /// No description provided for @xlsxImportSkipped.
  ///
  /// In pt, this message translates to:
  /// **'Abas não importadas (só Tarefas e Lançamentos entram): {names}'**
  String xlsxImportSkipped(String names);

  /// No description provided for @xlsxImportSafety.
  ///
  /// In pt, this message translates to:
  /// **'Tudo é acrescentado, nada é substituído. Antes de gravar, um backup automático é feito.'**
  String get xlsxImportSafety;

  /// No description provided for @xlsxImportMoreErrors.
  ///
  /// In pt, this message translates to:
  /// **'… e mais {count}'**
  String xlsxImportMoreErrors(int count);

  /// No description provided for @xlsxImportDone.
  ///
  /// In pt, this message translates to:
  /// **'Importado: {tasks} e {entries}'**
  String xlsxImportDone(String tasks, String entries);

  /// No description provided for @xlsxErrorRow.
  ///
  /// In pt, this message translates to:
  /// **'{sheet}, linha {row}: {reason}'**
  String xlsxErrorRow(String sheet, int row, String reason);

  /// No description provided for @xlsxErrorMissingColumns.
  ///
  /// In pt, this message translates to:
  /// **'faltam as colunas {columns}'**
  String xlsxErrorMissingColumns(String columns);

  /// No description provided for @xlsxErrorNoTitle.
  ///
  /// In pt, this message translates to:
  /// **'sem título'**
  String get xlsxErrorNoTitle;

  /// No description provided for @xlsxErrorDate.
  ///
  /// In pt, this message translates to:
  /// **'data inválida em \"{column}\"'**
  String xlsxErrorDate(String column);

  /// No description provided for @xlsxErrorAmount.
  ///
  /// In pt, this message translates to:
  /// **'valor inválido \"{value}\"'**
  String xlsxErrorAmount(String value);

  /// No description provided for @xlsxErrorKind.
  ///
  /// In pt, this message translates to:
  /// **'tipo desconhecido \"{value}\"'**
  String xlsxErrorKind(String value);

  /// No description provided for @xlsxErrorStatus.
  ///
  /// In pt, this message translates to:
  /// **'status desconhecido \"{value}\"'**
  String xlsxErrorStatus(String value);

  /// No description provided for @xlsxErrorPriority.
  ///
  /// In pt, this message translates to:
  /// **'prioridade desconhecida \"{value}\"'**
  String xlsxErrorPriority(String value);

  /// No description provided for @xlsxErrorCard.
  ///
  /// In pt, this message translates to:
  /// **'cartão não encontrado \"{value}\"'**
  String xlsxErrorCard(String value);

  /// No description provided for @xlsxSheetTasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get xlsxSheetTasks;

  /// No description provided for @xlsxSheetHabits.
  ///
  /// In pt, this message translates to:
  /// **'Hábitos'**
  String get xlsxSheetHabits;

  /// No description provided for @xlsxSheetEntries.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos'**
  String get xlsxSheetEntries;

  /// No description provided for @xlsxSheetCards.
  ///
  /// In pt, this message translates to:
  /// **'Cartões'**
  String get xlsxSheetCards;

  /// No description provided for @xlsxSheetInvoicePayments.
  ///
  /// In pt, this message translates to:
  /// **'Faturas pagas'**
  String get xlsxSheetInvoicePayments;

  /// No description provided for @xlsxSheetLoans.
  ///
  /// In pt, this message translates to:
  /// **'Empréstimos'**
  String get xlsxSheetLoans;

  /// No description provided for @xlsxSheetLoanPayments.
  ///
  /// In pt, this message translates to:
  /// **'Recebimentos'**
  String get xlsxSheetLoanPayments;

  /// No description provided for @xlsxSheetGoals.
  ///
  /// In pt, this message translates to:
  /// **'Caixinhas'**
  String get xlsxSheetGoals;

  /// No description provided for @xlsxSheetGoalMoves.
  ///
  /// In pt, this message translates to:
  /// **'Movimentações'**
  String get xlsxSheetGoalMoves;

  /// No description provided for @xlsxSheetDiet.
  ///
  /// In pt, this message translates to:
  /// **'Dieta'**
  String get xlsxSheetDiet;

  /// No description provided for @xlsxSheetJournal.
  ///
  /// In pt, this message translates to:
  /// **'Diário'**
  String get xlsxSheetJournal;

  /// No description provided for @xlsxColFolder.
  ///
  /// In pt, this message translates to:
  /// **'Pasta'**
  String get xlsxColFolder;

  /// No description provided for @xlsxColList.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get xlsxColList;

  /// No description provided for @xlsxColSection.
  ///
  /// In pt, this message translates to:
  /// **'Seção'**
  String get xlsxColSection;

  /// No description provided for @xlsxColTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get xlsxColTitle;

  /// No description provided for @xlsxColNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get xlsxColNotes;

  /// No description provided for @xlsxColStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get xlsxColStatus;

  /// No description provided for @xlsxColPriority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade'**
  String get xlsxColPriority;

  /// No description provided for @xlsxColStart.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get xlsxColStart;

  /// No description provided for @xlsxColDue.
  ///
  /// In pt, this message translates to:
  /// **'Prazo'**
  String get xlsxColDue;

  /// No description provided for @xlsxColTags.
  ///
  /// In pt, this message translates to:
  /// **'Etiquetas'**
  String get xlsxColTags;

  /// No description provided for @xlsxColCreated.
  ///
  /// In pt, this message translates to:
  /// **'Criada em'**
  String get xlsxColCreated;

  /// No description provided for @xlsxColCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluída em'**
  String get xlsxColCompleted;

  /// No description provided for @xlsxColHabit.
  ///
  /// In pt, this message translates to:
  /// **'Hábito'**
  String get xlsxColHabit;

  /// No description provided for @xlsxColDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get xlsxColDate;

  /// No description provided for @xlsxColValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get xlsxColValue;

  /// No description provided for @xlsxColGoal.
  ///
  /// In pt, this message translates to:
  /// **'Meta'**
  String get xlsxColGoal;

  /// No description provided for @xlsxColUnit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get xlsxColUnit;

  /// No description provided for @xlsxColMood.
  ///
  /// In pt, this message translates to:
  /// **'Humor'**
  String get xlsxColMood;

  /// No description provided for @xlsxColNote.
  ///
  /// In pt, this message translates to:
  /// **'Observação'**
  String get xlsxColNote;

  /// No description provided for @xlsxColKind.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get xlsxColKind;

  /// No description provided for @xlsxColCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get xlsxColCategory;

  /// No description provided for @xlsxColDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get xlsxColDescription;

  /// No description provided for @xlsxColCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão'**
  String get xlsxColCard;

  /// No description provided for @xlsxColInvoice.
  ///
  /// In pt, this message translates to:
  /// **'Fatura'**
  String get xlsxColInvoice;

  /// No description provided for @xlsxColInstallment.
  ///
  /// In pt, this message translates to:
  /// **'Parcela'**
  String get xlsxColInstallment;

  /// No description provided for @xlsxColClosingDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia do fechamento'**
  String get xlsxColClosingDay;

  /// No description provided for @xlsxColDueDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia do vencimento'**
  String get xlsxColDueDay;

  /// No description provided for @xlsxColCreditLimit.
  ///
  /// In pt, this message translates to:
  /// **'Limite'**
  String get xlsxColCreditLimit;

  /// No description provided for @xlsxColBorrower.
  ///
  /// In pt, this message translates to:
  /// **'Quem pegou emprestado'**
  String get xlsxColBorrower;

  /// No description provided for @xlsxColLentOn.
  ///
  /// In pt, this message translates to:
  /// **'Emprestado em'**
  String get xlsxColLentOn;

  /// No description provided for @xlsxColPrincipal.
  ///
  /// In pt, this message translates to:
  /// **'Valor emprestado'**
  String get xlsxColPrincipal;

  /// No description provided for @xlsxColTotal.
  ///
  /// In pt, this message translates to:
  /// **'A receber'**
  String get xlsxColTotal;

  /// No description provided for @xlsxColDueOn.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento'**
  String get xlsxColDueOn;

  /// No description provided for @xlsxColInstallments.
  ///
  /// In pt, this message translates to:
  /// **'Parcelas'**
  String get xlsxColInstallments;

  /// No description provided for @xlsxColReceived.
  ///
  /// In pt, this message translates to:
  /// **'Recebido'**
  String get xlsxColReceived;

  /// No description provided for @xlsxColSavingsGoal.
  ///
  /// In pt, this message translates to:
  /// **'Caixinha'**
  String get xlsxColSavingsGoal;

  /// No description provided for @xlsxColSaved.
  ///
  /// In pt, this message translates to:
  /// **'Guardado'**
  String get xlsxColSaved;

  /// No description provided for @xlsxColMeal.
  ///
  /// In pt, this message translates to:
  /// **'Refeição'**
  String get xlsxColMeal;

  /// No description provided for @xlsxColFood.
  ///
  /// In pt, this message translates to:
  /// **'Alimento'**
  String get xlsxColFood;

  /// No description provided for @xlsxColQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get xlsxColQuantity;

  /// No description provided for @xlsxColMeasure.
  ///
  /// In pt, this message translates to:
  /// **'Medida'**
  String get xlsxColMeasure;

  /// No description provided for @xlsxColGrams.
  ///
  /// In pt, this message translates to:
  /// **'Gramas'**
  String get xlsxColGrams;

  /// No description provided for @xlsxColKcal.
  ///
  /// In pt, this message translates to:
  /// **'kcal'**
  String get xlsxColKcal;

  /// No description provided for @xlsxColProtein.
  ///
  /// In pt, this message translates to:
  /// **'Proteínas (g)'**
  String get xlsxColProtein;

  /// No description provided for @xlsxColCarbs.
  ///
  /// In pt, this message translates to:
  /// **'Carboidratos (g)'**
  String get xlsxColCarbs;

  /// No description provided for @xlsxColFat.
  ///
  /// In pt, this message translates to:
  /// **'Gorduras (g)'**
  String get xlsxColFat;

  /// No description provided for @xlsxColFiber.
  ///
  /// In pt, this message translates to:
  /// **'Fibras (g)'**
  String get xlsxColFiber;

  /// No description provided for @xlsxColEnergy.
  ///
  /// In pt, this message translates to:
  /// **'Energia'**
  String get xlsxColEnergy;

  /// No description provided for @xlsxColHighlight.
  ///
  /// In pt, this message translates to:
  /// **'Destaque'**
  String get xlsxColHighlight;

  /// No description provided for @xlsxStatusOpen.
  ///
  /// In pt, this message translates to:
  /// **'Aberta'**
  String get xlsxStatusOpen;

  /// No description provided for @xlsxStatusCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluída'**
  String get xlsxStatusCompleted;

  /// No description provided for @xlsxStatusWontDo.
  ///
  /// In pt, this message translates to:
  /// **'Não será feita'**
  String get xlsxStatusWontDo;

  /// No description provided for @autoBackupNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum backup automático ainda.'**
  String get autoBackupNone;

  /// No description provided for @autoBackupRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get autoBackupRestore;

  /// No description provided for @countdownIconBackground.
  ///
  /// In pt, this message translates to:
  /// **'Cor de fundo'**
  String get countdownIconBackground;

  /// No description provided for @calendarShowWeekends.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar fins de semana'**
  String get calendarShowWeekends;

  /// No description provided for @calendarDimPast.
  ///
  /// In pt, this message translates to:
  /// **'Reduzir o brilho de eventos passados'**
  String get calendarDimPast;

  /// No description provided for @dateFull.
  ///
  /// In pt, this message translates to:
  /// **'{weekday}, {day} de {month} de {year}'**
  String dateFull(String weekday, int day, String month, int year);

  /// No description provided for @calendarDayOfTotal.
  ///
  /// In pt, this message translates to:
  /// **'(Dia {day}/{total})'**
  String calendarDayOfTotal(int day, int total);

  /// No description provided for @calendarCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get calendarCreate;

  /// No description provided for @calendarMyCalendars.
  ///
  /// In pt, this message translates to:
  /// **'Meus calendários'**
  String get calendarMyCalendars;

  /// No description provided for @calendarOtherCalendars.
  ///
  /// In pt, this message translates to:
  /// **'Outros calendários'**
  String get calendarOtherCalendars;

  /// No description provided for @calendarShowOnly.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar só este'**
  String get calendarShowOnly;

  /// No description provided for @calendarAddOther.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar outros calendários'**
  String get calendarAddOther;

  /// No description provided for @calendarTogglePanel.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar ou esconder o painel'**
  String get calendarTogglePanel;

  /// No description provided for @calendarAddTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar título'**
  String get calendarAddTitle;

  /// No description provided for @calendarKindTask.
  ///
  /// In pt, this message translates to:
  /// **'Tarefa'**
  String get calendarKindTask;

  /// No description provided for @calendarKindNote.
  ///
  /// In pt, this message translates to:
  /// **'Nota'**
  String get calendarKindNote;

  /// No description provided for @calendarAddDescription.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar descrição'**
  String get calendarAddDescription;

  /// No description provided for @calendarNoRepeat.
  ///
  /// In pt, this message translates to:
  /// **'Não se repete'**
  String get calendarNoRepeat;

  /// No description provided for @calendarMoreOptions.
  ///
  /// In pt, this message translates to:
  /// **'Mais opções'**
  String get calendarMoreOptions;

  /// No description provided for @calendarNoDate.
  ///
  /// In pt, this message translates to:
  /// **'Sem data'**
  String get calendarNoDate;

  /// No description provided for @calendarNoReminder.
  ///
  /// In pt, this message translates to:
  /// **'Sem lembrete'**
  String get calendarNoReminder;

  /// No description provided for @ordinalsFeminine.
  ///
  /// In pt, this message translates to:
  /// **'primeira,segunda,terceira,quarta'**
  String get ordinalsFeminine;

  /// No description provided for @ordinalsMasculine.
  ///
  /// In pt, this message translates to:
  /// **'primeiro,segundo,terceiro,quarto'**
  String get ordinalsMasculine;

  /// No description provided for @lastFeminine.
  ///
  /// In pt, this message translates to:
  /// **'última'**
  String get lastFeminine;

  /// No description provided for @lastMasculine.
  ///
  /// In pt, this message translates to:
  /// **'último'**
  String get lastMasculine;

  /// No description provided for @repeatMonthlyOn.
  ///
  /// In pt, this message translates to:
  /// **'Mensal {when}'**
  String repeatMonthlyOn(String when);

  /// No description provided for @calendarDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get calendarDetails;

  /// No description provided for @calendarAddReminder.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar lembrete'**
  String get calendarAddReminder;

  /// No description provided for @insightsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Insights de tempo'**
  String get insightsTitle;

  /// No description provided for @insightsMore.
  ///
  /// In pt, this message translates to:
  /// **'Mais insights'**
  String get insightsMore;

  /// No description provided for @insightsBreakdown.
  ///
  /// In pt, this message translates to:
  /// **'Detalhamento do tempo'**
  String get insightsBreakdown;

  /// No description provided for @insightsByList.
  ///
  /// In pt, this message translates to:
  /// **'Lista'**
  String get insightsByList;

  /// No description provided for @insightsByTag.
  ///
  /// In pt, this message translates to:
  /// **'Etiqueta'**
  String get insightsByTag;

  /// No description provided for @insightsByKind.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get insightsByKind;

  /// No description provided for @insightsPerDay.
  ///
  /// In pt, this message translates to:
  /// **'Horas por dia'**
  String get insightsPerDay;

  /// No description provided for @insightsNoTag.
  ///
  /// In pt, this message translates to:
  /// **'Sem etiqueta'**
  String get insightsNoTag;

  /// No description provided for @insightsTasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get insightsTasks;

  /// No description provided for @insightsTotal.
  ///
  /// In pt, this message translates to:
  /// **'no total'**
  String get insightsTotal;

  /// No description provided for @insightsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nada com horário marcado neste período.'**
  String get insightsEmpty;

  /// No description provided for @insightsScheduled.
  ///
  /// In pt, this message translates to:
  /// **'{hours} com horário marcado'**
  String insightsScheduled(String hours);

  /// No description provided for @eventColorNames.
  ///
  /// In pt, this message translates to:
  /// **'Flor de cerejeira,Tomate,Tangerina,Abóbora,Manga,Banana,Cidra,Abacate,Pistache,Manjericão,Sálvia,Eucalipto,Pavão,Mirtilo,Lavanda,Glicínia,Ametista,Uva,Cacau,Bétula,Grafite'**
  String get eventColorNames;

  /// No description provided for @colorLabelsEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar rótulos'**
  String get colorLabelsEdit;

  /// No description provided for @colorLabelsHint.
  ///
  /// In pt, this message translates to:
  /// **'Dê nome às cores: nos Insights de tempo, as tarefas de cada cor aparecem com esse nome.'**
  String get colorLabelsHint;

  /// No description provided for @colorLabelsColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor'**
  String get colorLabelsColor;

  /// No description provided for @colorLabelsName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do rótulo'**
  String get colorLabelsName;

  /// No description provided for @colorLabelsAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar rótulo'**
  String get colorLabelsAdd;

  /// No description provided for @colorDefault.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get colorDefault;

  /// No description provided for @colorOfTask.
  ///
  /// In pt, this message translates to:
  /// **'Cor da tarefa'**
  String get colorOfTask;

  /// No description provided for @insightsByLabel.
  ///
  /// In pt, this message translates to:
  /// **'Rótulo'**
  String get insightsByLabel;

  /// No description provided for @insightsNoLabel.
  ///
  /// In pt, this message translates to:
  /// **'Sem rótulo'**
  String get insightsNoLabel;

  /// No description provided for @recurrenceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Repetição personalizada'**
  String get recurrenceTitle;

  /// No description provided for @recurrenceEvery.
  ///
  /// In pt, this message translates to:
  /// **'Repetir a cada'**
  String get recurrenceEvery;

  /// No description provided for @recurrenceOn.
  ///
  /// In pt, this message translates to:
  /// **'Repetir em'**
  String get recurrenceOn;

  /// No description provided for @recurrenceEnds.
  ///
  /// In pt, this message translates to:
  /// **'Termina'**
  String get recurrenceEnds;

  /// No description provided for @recurrenceNever.
  ///
  /// In pt, this message translates to:
  /// **'Nunca'**
  String get recurrenceNever;

  /// No description provided for @recurrenceOnDate.
  ///
  /// In pt, this message translates to:
  /// **'Em'**
  String get recurrenceOnDate;

  /// No description provided for @recurrenceAfter.
  ///
  /// In pt, this message translates to:
  /// **'Após'**
  String get recurrenceAfter;

  /// No description provided for @recurrenceDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get recurrenceDone;

  /// No description provided for @recurrenceOccurrences.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{ocorrência} other{ocorrências}}'**
  String recurrenceOccurrences(int count);

  /// No description provided for @recurrenceDays.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{dia} other{dias}}'**
  String recurrenceDays(int count);

  /// No description provided for @recurrenceWeeks.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{semana} other{semanas}}'**
  String recurrenceWeeks(int count);

  /// No description provided for @recurrenceMonths.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{mês} other{meses}}'**
  String recurrenceMonths(int count);

  /// No description provided for @recurrenceYears.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{ano} other{anos}}'**
  String recurrenceYears(int count);

  /// No description provided for @recurrenceEveryN.
  ///
  /// In pt, this message translates to:
  /// **'A cada {count} {unit}'**
  String recurrenceEveryN(int count, String unit);

  /// No description provided for @recurrenceWeeklyOn.
  ///
  /// In pt, this message translates to:
  /// **'Semanal: {days}'**
  String recurrenceWeeklyOn(String days);

  /// No description provided for @recurrenceTimes.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 vez} other{{count} vezes}}'**
  String recurrenceTimes(int count);

  /// No description provided for @recurrenceUntil.
  ///
  /// In pt, this message translates to:
  /// **'até {date}'**
  String recurrenceUntil(String date);

  /// No description provided for @colorCode.
  ///
  /// In pt, this message translates to:
  /// **'Código'**
  String get colorCode;

  /// No description provided for @colorSeriesCustom.
  ///
  /// In pt, this message translates to:
  /// **'Outra cor'**
  String get colorSeriesCustom;

  /// No description provided for @calendarEditTask.
  ///
  /// In pt, this message translates to:
  /// **'Editar tarefa'**
  String get calendarEditTask;

  /// No description provided for @calendarDeleteTask.
  ///
  /// In pt, this message translates to:
  /// **'Deletar tarefa'**
  String get calendarDeleteTask;

  /// No description provided for @calendarOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções'**
  String get calendarOptions;

  /// No description provided for @calendarOpenDetail.
  ///
  /// In pt, this message translates to:
  /// **'Abrir detalhes da tarefa'**
  String get calendarOpenDetail;

  /// No description provided for @calendarMarkDone.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como concluída'**
  String get calendarMarkDone;

  /// No description provided for @calendarMarkUndone.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como não concluída'**
  String get calendarMarkUndone;

  /// No description provided for @calendarOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir'**
  String get calendarOpen;

  /// No description provided for @calendarShortAs30.
  ///
  /// In pt, this message translates to:
  /// **'Eventos curtos com o tamanho de 30 minutos'**
  String get calendarShortAs30;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir tarefa repetida'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar tarefa repetida'**
  String get recurringEditTitle;

  /// No description provided for @recurringOne.
  ///
  /// In pt, this message translates to:
  /// **'Somente esta'**
  String get recurringOne;

  /// No description provided for @recurringFollowing.
  ///
  /// In pt, this message translates to:
  /// **'Esta e as seguintes'**
  String get recurringFollowing;

  /// No description provided for @recurringAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get recurringAll;

  /// No description provided for @notificationAlarmChannelName.
  ///
  /// In pt, this message translates to:
  /// **'Despertador do foco'**
  String get notificationAlarmChannelName;

  /// No description provided for @notificationFocusChannelName.
  ///
  /// In pt, this message translates to:
  /// **'Foco em andamento'**
  String get notificationFocusChannelName;

  /// No description provided for @notificationActionStop.
  ///
  /// In pt, this message translates to:
  /// **'Parar'**
  String get notificationActionStop;

  /// No description provided for @focusBreakDoneTitle.
  ///
  /// In pt, this message translates to:
  /// **'A pausa acabou.'**
  String get focusBreakDoneTitle;

  /// No description provided for @focusBreakDoneBody.
  ///
  /// In pt, this message translates to:
  /// **'Hora de voltar ao foco.'**
  String get focusBreakDoneBody;

  /// No description provided for @focusRunningTitle.
  ///
  /// In pt, this message translates to:
  /// **'Focando'**
  String get focusRunningTitle;

  /// No description provided for @focusPausedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Foco pausado'**
  String get focusPausedTitle;

  /// No description provided for @focusBreakTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pausa'**
  String get focusBreakTitle;

  /// No description provided for @notificationAlarmClockChannelName.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes (despertador)'**
  String get notificationAlarmClockChannelName;

  /// No description provided for @trayOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir o Ordo'**
  String get trayOpen;

  /// No description provided for @trayQuit.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get trayQuit;

  /// No description provided for @trayMiniCalendar.
  ///
  /// In pt, this message translates to:
  /// **'Mini calendário'**
  String get trayMiniCalendar;

  /// No description provided for @settingsReminderSound.
  ///
  /// In pt, this message translates to:
  /// **'Som do lembrete'**
  String get settingsReminderSound;

  /// No description provided for @settingsReminderSoundHint.
  ///
  /// In pt, this message translates to:
  /// **'O Despertador toca por alguns segundos; o do Pomodoro fica em Foco → Configurações de foco.'**
  String get settingsReminderSoundHint;

  /// No description provided for @reminderSoundAlarmClock.
  ///
  /// In pt, this message translates to:
  /// **'Despertador'**
  String get reminderSoundAlarmClock;

  /// No description provided for @reminderSoundStandard.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get reminderSoundStandard;

  /// No description provided for @reminderSoundSilent.
  ///
  /// In pt, this message translates to:
  /// **'Silencioso'**
  String get reminderSoundSilent;

  /// No description provided for @settingsBackground.
  ///
  /// In pt, this message translates to:
  /// **'Segundo plano'**
  String get settingsBackground;

  /// No description provided for @settingsCloseToTray.
  ///
  /// In pt, this message translates to:
  /// **'Manter na bandeja ao fechar'**
  String get settingsCloseToTray;

  /// No description provided for @settingsCloseToTrayHint.
  ///
  /// In pt, this message translates to:
  /// **'Os lembretes, o Pomodoro e o som do despertador continuam funcionando. Para sair de vez, use Sair no ícone perto do relógio.'**
  String get settingsCloseToTrayHint;

  /// No description provided for @settingsLaunchAtStartup.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar com o Windows'**
  String get settingsLaunchAtStartup;

  /// No description provided for @settingsLaunchAtStartupHint.
  ///
  /// In pt, this message translates to:
  /// **'Abre escondido na bandeja quando você entra no Windows.'**
  String get settingsLaunchAtStartupHint;

  /// No description provided for @settingsDesktopMini.
  ///
  /// In pt, this message translates to:
  /// **'Mini calendário'**
  String get settingsDesktopMini;

  /// No description provided for @settingsDesktopMiniHint.
  ///
  /// In pt, this message translates to:
  /// **'Uma janelinha com o calendário na área de trabalho, como o widget do celular. Também abre pelo ícone perto do relógio.'**
  String get settingsDesktopMiniHint;

  /// No description provided for @settingsDesktopMiniOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir'**
  String get settingsDesktopMiniOpen;

  /// No description provided for @inFeminine.
  ///
  /// In pt, this message translates to:
  /// **'na'**
  String get inFeminine;

  /// No description provided for @inMasculine.
  ///
  /// In pt, this message translates to:
  /// **'no'**
  String get inMasculine;

  /// No description provided for @recurrenceYearlyOn.
  ///
  /// In pt, this message translates to:
  /// **'Anualmente em {date}'**
  String recurrenceYearlyOn(String date);

  /// No description provided for @navFinance.
  ///
  /// In pt, this message translates to:
  /// **'Finanças'**
  String get navFinance;

  /// No description provided for @featureFinanceHint.
  ///
  /// In pt, this message translates to:
  /// **'Receitas, despesas, cartões, contas fixas e empréstimos.'**
  String get featureFinanceHint;

  /// No description provided for @finTabEntries.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos'**
  String get finTabEntries;

  /// No description provided for @finTabCategories.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get finTabCategories;

  /// No description provided for @finNewEntry.
  ///
  /// In pt, this message translates to:
  /// **'Novo lançamento'**
  String get finNewEntry;

  /// No description provided for @finEditEntry.
  ///
  /// In pt, this message translates to:
  /// **'Editar lançamento'**
  String get finEditEntry;

  /// No description provided for @finIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get finIncome;

  /// No description provided for @finExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa'**
  String get finExpense;

  /// No description provided for @finIncomes.
  ///
  /// In pt, this message translates to:
  /// **'Receitas'**
  String get finIncomes;

  /// No description provided for @finExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get finExpenses;

  /// No description provided for @finBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo'**
  String get finBalance;

  /// No description provided for @finAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get finAmount;

  /// No description provided for @finDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get finDescription;

  /// No description provided for @finDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get finDate;

  /// No description provided for @finCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get finCategory;

  /// No description provided for @finNoCategory.
  ///
  /// In pt, this message translates to:
  /// **'Sem categoria'**
  String get finNoCategory;

  /// No description provided for @finCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão'**
  String get finCard;

  /// No description provided for @finNoCard.
  ///
  /// In pt, this message translates to:
  /// **'Não foi no cartão'**
  String get finNoCard;

  /// No description provided for @finInstallments.
  ///
  /// In pt, this message translates to:
  /// **'Parcelas'**
  String get finInstallments;

  /// No description provided for @finInstallmentsValue.
  ///
  /// In pt, this message translates to:
  /// **'{count}x de {amount}'**
  String finInstallmentsValue(int count, String amount);

  /// No description provided for @finNote.
  ///
  /// In pt, this message translates to:
  /// **'Observação'**
  String get finNote;

  /// No description provided for @finInvalidAmount.
  ///
  /// In pt, this message translates to:
  /// **'Digite um valor maior que zero.'**
  String get finInvalidAmount;

  /// No description provided for @finEntriesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum lançamento neste período.'**
  String get finEntriesEmpty;

  /// No description provided for @finInvoiceOf.
  ///
  /// In pt, this message translates to:
  /// **'Fatura {card} · vence {day}'**
  String finInvoiceOf(String card, String day);

  /// No description provided for @finEntryDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Lançamento excluído'**
  String get finEntryDeleted;

  /// No description provided for @finDeleteInstallments.
  ///
  /// In pt, this message translates to:
  /// **'Excluir compra parcelada'**
  String get finDeleteInstallments;

  /// No description provided for @finDeleteOneInstallment.
  ///
  /// In pt, this message translates to:
  /// **'Só esta parcela'**
  String get finDeleteOneInstallment;

  /// No description provided for @finDeleteAllInstallments.
  ///
  /// In pt, this message translates to:
  /// **'Todas as {count} parcelas'**
  String finDeleteAllInstallments(int count);

  /// No description provided for @finDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar'**
  String get finDuplicate;

  /// No description provided for @finLimitNear.
  ///
  /// In pt, this message translates to:
  /// **'{category}: {percent} do limite do mês ({spent} de {limit}).'**
  String finLimitNear(String category, String percent, String spent, String limit);

  /// No description provided for @finLimitOver.
  ///
  /// In pt, this message translates to:
  /// **'{category} passou do limite do mês: {spent} de {limit}.'**
  String finLimitOver(String category, String spent, String limit);

  /// No description provided for @finNewCategory.
  ///
  /// In pt, this message translates to:
  /// **'Nova categoria'**
  String get finNewCategory;

  /// No description provided for @finEditCategory.
  ///
  /// In pt, this message translates to:
  /// **'Editar categoria'**
  String get finEditCategory;

  /// No description provided for @finCategoryName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get finCategoryName;

  /// No description provided for @finMonthlyLimit.
  ///
  /// In pt, this message translates to:
  /// **'Limite por mês'**
  String get finMonthlyLimit;

  /// No description provided for @finLimitHint.
  ///
  /// In pt, this message translates to:
  /// **'Em branco, sem limite. O aviso vem a partir de 80% do limite.'**
  String get finLimitHint;

  /// No description provided for @finLimitProgress.
  ///
  /// In pt, this message translates to:
  /// **'{spent} de {limit}'**
  String finLimitProgress(String spent, String limit);

  /// No description provided for @finSpentThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'{spent} neste mês'**
  String finSpentThisMonth(String spent);

  /// No description provided for @finDeleteCategory.
  ///
  /// In pt, this message translates to:
  /// **'Excluir a categoria \"{name}\"? Os lançamentos dela ficam sem categoria.'**
  String finDeleteCategory(String name);

  /// No description provided for @finIcon.
  ///
  /// In pt, this message translates to:
  /// **'Ícone'**
  String get finIcon;

  /// No description provided for @finPeriodMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get finPeriodMonth;

  /// No description provided for @finPeriodYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get finPeriodYear;

  /// No description provided for @finAllCategories.
  ///
  /// In pt, this message translates to:
  /// **'Todas as categorias'**
  String get finAllCategories;

  /// No description provided for @finAllKinds.
  ///
  /// In pt, this message translates to:
  /// **'Receitas e despesas'**
  String get finAllKinds;

  /// No description provided for @finSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar na descrição'**
  String get finSearchHint;

  /// No description provided for @finCatFood.
  ///
  /// In pt, this message translates to:
  /// **'Alimentação'**
  String get finCatFood;

  /// No description provided for @finCatMarket.
  ///
  /// In pt, this message translates to:
  /// **'Mercado'**
  String get finCatMarket;

  /// No description provided for @finCatTransport.
  ///
  /// In pt, this message translates to:
  /// **'Transporte'**
  String get finCatTransport;

  /// No description provided for @finCatHome.
  ///
  /// In pt, this message translates to:
  /// **'Moradia'**
  String get finCatHome;

  /// No description provided for @finCatBills.
  ///
  /// In pt, this message translates to:
  /// **'Contas da casa'**
  String get finCatBills;

  /// No description provided for @finCatHealth.
  ///
  /// In pt, this message translates to:
  /// **'Saúde'**
  String get finCatHealth;

  /// No description provided for @finCatEducation.
  ///
  /// In pt, this message translates to:
  /// **'Educação'**
  String get finCatEducation;

  /// No description provided for @finCatLeisure.
  ///
  /// In pt, this message translates to:
  /// **'Lazer'**
  String get finCatLeisure;

  /// No description provided for @finCatShopping.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get finCatShopping;

  /// No description provided for @finCatSubscriptions.
  ///
  /// In pt, this message translates to:
  /// **'Assinaturas'**
  String get finCatSubscriptions;

  /// No description provided for @finCatOther.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get finCatOther;

  /// No description provided for @finCatSalary.
  ///
  /// In pt, this message translates to:
  /// **'Salário'**
  String get finCatSalary;

  /// No description provided for @finCatExtra.
  ///
  /// In pt, this message translates to:
  /// **'Renda extra'**
  String get finCatExtra;

  /// No description provided for @finTabCards.
  ///
  /// In pt, this message translates to:
  /// **'Cartões'**
  String get finTabCards;

  /// No description provided for @finTabRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Contas fixas'**
  String get finTabRecurring;

  /// No description provided for @finTabLoans.
  ///
  /// In pt, this message translates to:
  /// **'Empréstimos'**
  String get finTabLoans;

  /// No description provided for @finTabReports.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get finTabReports;

  /// No description provided for @finNewCard.
  ///
  /// In pt, this message translates to:
  /// **'Novo cartão'**
  String get finNewCard;

  /// No description provided for @finEditCard.
  ///
  /// In pt, this message translates to:
  /// **'Editar cartão'**
  String get finEditCard;

  /// No description provided for @finCardName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do cartão'**
  String get finCardName;

  /// No description provided for @finClosingDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia do fechamento'**
  String get finClosingDay;

  /// No description provided for @finDueDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia do vencimento'**
  String get finDueDay;

  /// No description provided for @finCreditLimit.
  ///
  /// In pt, this message translates to:
  /// **'Limite do cartão (opcional)'**
  String get finCreditLimit;

  /// No description provided for @finCardDays.
  ///
  /// In pt, this message translates to:
  /// **'Fecha dia {closing} · vence dia {due}'**
  String finCardDays(int closing, int due);

  /// No description provided for @finCardUsed.
  ///
  /// In pt, this message translates to:
  /// **'{used} usados de {limit}'**
  String finCardUsed(String used, String limit);

  /// No description provided for @finInvoiceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fatura de {month}'**
  String finInvoiceTitle(String month);

  /// No description provided for @finInvoiceOpen.
  ///
  /// In pt, this message translates to:
  /// **'Aberta'**
  String get finInvoiceOpen;

  /// No description provided for @finInvoiceClosed.
  ///
  /// In pt, this message translates to:
  /// **'Fechada'**
  String get finInvoiceClosed;

  /// No description provided for @finInvoicePaid.
  ///
  /// In pt, this message translates to:
  /// **'Paga'**
  String get finInvoicePaid;

  /// No description provided for @finInvoiceOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Vencida'**
  String get finInvoiceOverdue;

  /// No description provided for @finInvoiceEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem compras'**
  String get finInvoiceEmpty;

  /// No description provided for @finInvoiceDates.
  ///
  /// In pt, this message translates to:
  /// **'Fecha em {closing} · vence em {due}'**
  String finInvoiceDates(String closing, String due);

  /// No description provided for @finInvoiceTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get finInvoiceTotal;

  /// No description provided for @finInvoicePaidAmount.
  ///
  /// In pt, this message translates to:
  /// **'Pago'**
  String get finInvoicePaidAmount;

  /// No description provided for @finInvoiceRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Falta pagar'**
  String get finInvoiceRemaining;

  /// No description provided for @finPayInvoice.
  ///
  /// In pt, this message translates to:
  /// **'Pagar fatura'**
  String get finPayInvoice;

  /// No description provided for @finPaymentAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor pago'**
  String get finPaymentAmount;

  /// No description provided for @finPaymentDate.
  ///
  /// In pt, this message translates to:
  /// **'Data do pagamento'**
  String get finPaymentDate;

  /// No description provided for @finPayments.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos'**
  String get finPayments;

  /// No description provided for @finPurchases.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get finPurchases;

  /// No description provided for @finNoCards.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum cartão ainda. Cadastre um para lançar compras no cartão e acompanhar as faturas.'**
  String get finNoCards;

  /// No description provided for @finArchive.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar'**
  String get finArchive;

  /// No description provided for @finUnarchive.
  ///
  /// In pt, this message translates to:
  /// **'Desarquivar'**
  String get finUnarchive;

  /// No description provided for @finArchivedCards.
  ///
  /// In pt, this message translates to:
  /// **'Arquivados'**
  String get finArchivedCards;

  /// No description provided for @finCardDeleteBlocked.
  ///
  /// In pt, this message translates to:
  /// **'Este cartão tem compras ou pagamentos. Arquive-o para escondê-lo.'**
  String get finCardDeleteBlocked;

  /// No description provided for @finDeleteCard.
  ///
  /// In pt, this message translates to:
  /// **'Excluir o cartão \"{name}\"?'**
  String finDeleteCard(String name);

  /// No description provided for @finPaymentDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento excluído'**
  String get finPaymentDeleted;

  /// No description provided for @finNewRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Nova conta fixa'**
  String get finNewRecurring;

  /// No description provided for @finEditRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Editar conta fixa'**
  String get finEditRecurring;

  /// No description provided for @finNoRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta fixa ainda. Cadastre aluguel, assinaturas, salário…'**
  String get finNoRecurring;

  /// No description provided for @finRecurringHint.
  ///
  /// In pt, this message translates to:
  /// **'Aluguel, internet, salário…'**
  String get finRecurringHint;

  /// No description provided for @finRecurringInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Preencha a descrição e um valor maior que zero.'**
  String get finRecurringInvalid;

  /// No description provided for @finOverdueBills.
  ///
  /// In pt, this message translates to:
  /// **'Atrasadas'**
  String get finOverdueBills;

  /// No description provided for @finDueThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Vencimentos do mês'**
  String get finDueThisMonth;

  /// No description provided for @finRecurringBills.
  ///
  /// In pt, this message translates to:
  /// **'Contas cadastradas'**
  String get finRecurringBills;

  /// No description provided for @finEveryMonthOn.
  ///
  /// In pt, this message translates to:
  /// **'Todo dia {day}'**
  String finEveryMonthOn(int day);

  /// No description provided for @finEveryYearOn.
  ///
  /// In pt, this message translates to:
  /// **'Todo ano em {date}'**
  String finEveryYearOn(String date);

  /// No description provided for @finDueOn.
  ///
  /// In pt, this message translates to:
  /// **'vence {date}'**
  String finDueOn(String date);

  /// No description provided for @finPaidOn.
  ///
  /// In pt, this message translates to:
  /// **'pago em {date}'**
  String finPaidOn(String date);

  /// No description provided for @finConfirmPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pagar'**
  String get finConfirmPaid;

  /// No description provided for @finConfirmReceived.
  ///
  /// In pt, this message translates to:
  /// **'Receber'**
  String get finConfirmReceived;

  /// No description provided for @finUndoPayment.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer pagamento'**
  String get finUndoPayment;

  /// No description provided for @finPaymentUndone.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento desfeito'**
  String get finPaymentUndone;

  /// No description provided for @finDeleteRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Excluir a conta fixa \"{name}\"? Os lançamentos já feitos continuam.'**
  String finDeleteRecurring(String name);

  /// No description provided for @finMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get finMonthly;

  /// No description provided for @finYearly.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get finYearly;

  /// No description provided for @finReminder.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete'**
  String get finReminder;

  /// No description provided for @finNoReminder.
  ///
  /// In pt, this message translates to:
  /// **'Sem lembrete'**
  String get finNoReminder;

  /// No description provided for @finRemindOnDay.
  ///
  /// In pt, this message translates to:
  /// **'No dia do vencimento'**
  String get finRemindOnDay;

  /// No description provided for @finRemindDaysBefore.
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, =1{1 dia antes} other{{days} dias antes}}'**
  String finRemindDaysBefore(int days);

  /// No description provided for @finStartsOn.
  ///
  /// In pt, this message translates to:
  /// **'Começa em'**
  String get finStartsOn;

  /// No description provided for @finEndsOn.
  ///
  /// In pt, this message translates to:
  /// **'Termina em'**
  String get finEndsOn;

  /// No description provided for @finNoEnd.
  ///
  /// In pt, this message translates to:
  /// **'Sem fim'**
  String get finNoEnd;

  /// No description provided for @finNewLoan.
  ///
  /// In pt, this message translates to:
  /// **'Novo empréstimo'**
  String get finNewLoan;

  /// No description provided for @finEditLoan.
  ///
  /// In pt, this message translates to:
  /// **'Editar empréstimo'**
  String get finEditLoan;

  /// No description provided for @finNoLoans.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum empréstimo ainda.'**
  String get finNoLoans;

  /// No description provided for @finNoLoansHere.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum empréstimo aqui.'**
  String get finNoLoansHere;

  /// No description provided for @finLoansOpen.
  ///
  /// In pt, this message translates to:
  /// **'Em aberto'**
  String get finLoansOpen;

  /// No description provided for @finLoansOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasados'**
  String get finLoansOverdue;

  /// No description provided for @finLoansPaid.
  ///
  /// In pt, this message translates to:
  /// **'Quitados'**
  String get finLoansPaid;

  /// No description provided for @finLoansAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get finLoansAll;

  /// No description provided for @finLentOpen.
  ///
  /// In pt, this message translates to:
  /// **'Emprestado'**
  String get finLentOpen;

  /// No description provided for @finToReceive.
  ///
  /// In pt, this message translates to:
  /// **'A receber'**
  String get finToReceive;

  /// No description provided for @finInterestReceived.
  ///
  /// In pt, this message translates to:
  /// **'Juros recebidos'**
  String get finInterestReceived;

  /// No description provided for @finOverdueAmount.
  ///
  /// In pt, this message translates to:
  /// **'Em atraso'**
  String get finOverdueAmount;

  /// No description provided for @finLoansCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{nenhum} =1{1 empréstimo} other{{count} empréstimos}}'**
  String finLoansCount(int count);

  /// No description provided for @finInterestToCome.
  ///
  /// In pt, this message translates to:
  /// **'{amount} de juros a receber'**
  String finInterestToCome(String amount);

  /// No description provided for @finLoanInterest.
  ///
  /// In pt, this message translates to:
  /// **'Juros de empréstimos'**
  String get finLoanInterest;

  /// No description provided for @finChartGeneral.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get finChartGeneral;

  /// No description provided for @finChartDetailed.
  ///
  /// In pt, this message translates to:
  /// **'Detalhado'**
  String get finChartDetailed;

  /// No description provided for @finLentTotal.
  ///
  /// In pt, this message translates to:
  /// **'{amount} emprestados no total'**
  String finLentTotal(String amount);

  /// No description provided for @finLoanOnTime.
  ///
  /// In pt, this message translates to:
  /// **'Em dia'**
  String get finLoanOnTime;

  /// No description provided for @finLoanLate.
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, =0{Atrasado} =1{Atrasado há 1 dia} other{Atrasado há {days} dias}}'**
  String finLoanLate(int days);

  /// No description provided for @finLoanPaid.
  ///
  /// In pt, this message translates to:
  /// **'Quitado'**
  String get finLoanPaid;

  /// No description provided for @finLoanLeft.
  ///
  /// In pt, this message translates to:
  /// **'Falta {amount}'**
  String finLoanLeft(String amount);

  /// No description provided for @finProfit.
  ///
  /// In pt, this message translates to:
  /// **'lucro {amount} ({rate})'**
  String finProfit(String amount, String rate);

  /// No description provided for @finDeleteLoan.
  ///
  /// In pt, this message translates to:
  /// **'Excluir o empréstimo de {name} e os pagamentos dele?'**
  String finDeleteLoan(String name);

  /// No description provided for @finLoanDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Empréstimo excluído'**
  String get finLoanDeleted;

  /// No description provided for @finLent.
  ///
  /// In pt, this message translates to:
  /// **'Valor emprestado'**
  String get finLent;

  /// No description provided for @finLoanTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total a receber'**
  String get finLoanTotal;

  /// No description provided for @finProfitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Lucro'**
  String get finProfitLabel;

  /// No description provided for @finReceived.
  ///
  /// In pt, this message translates to:
  /// **'Recebido'**
  String get finReceived;

  /// No description provided for @finLoanBalance.
  ///
  /// In pt, this message translates to:
  /// **'Falta receber'**
  String get finLoanBalance;

  /// No description provided for @finLentOn.
  ///
  /// In pt, this message translates to:
  /// **'Data do empréstimo'**
  String get finLentOn;

  /// No description provided for @finDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento'**
  String get finDueDate;

  /// No description provided for @finAddLoanPayment.
  ///
  /// In pt, this message translates to:
  /// **'Registrar pagamento'**
  String get finAddLoanPayment;

  /// No description provided for @finBorrower.
  ///
  /// In pt, this message translates to:
  /// **'Quem pegou emprestado'**
  String get finBorrower;

  /// No description provided for @finInterestRate.
  ///
  /// In pt, this message translates to:
  /// **'Juros'**
  String get finInterestRate;

  /// No description provided for @finProfitPreview.
  ///
  /// In pt, this message translates to:
  /// **'Lucro: {amount}'**
  String finProfitPreview(String amount);

  /// No description provided for @finLoanInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Preencha quem pegou, o valor emprestado e um total a receber igual ou maior que ele.'**
  String get finLoanInvalid;

  /// No description provided for @finLoanRemind.
  ///
  /// In pt, this message translates to:
  /// **'Lembrar no vencimento e se atrasar'**
  String get finLoanRemind;

  /// No description provided for @finByCategory.
  ///
  /// In pt, this message translates to:
  /// **'Gastos por categoria'**
  String get finByCategory;

  /// No description provided for @finNoExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum gasto neste mês.'**
  String get finNoExpenses;

  /// No description provided for @finIncomeVsExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Receitas × despesas'**
  String get finIncomeVsExpenses;

  /// No description provided for @finCompareMonths.
  ///
  /// In pt, this message translates to:
  /// **'Comparação entre meses'**
  String get finCompareMonths;

  /// No description provided for @finVersus.
  ///
  /// In pt, this message translates to:
  /// **'com'**
  String get finVersus;

  /// No description provided for @finChange.
  ///
  /// In pt, this message translates to:
  /// **'Variação'**
  String get finChange;

  /// No description provided for @finTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get finTotal;

  /// No description provided for @finLoansSummary.
  ///
  /// In pt, this message translates to:
  /// **'Empréstimos'**
  String get finLoansSummary;

  /// No description provided for @finReminderBillTitle.
  ///
  /// In pt, this message translates to:
  /// **'{name} vence hoje'**
  String finReminderBillTitle(String name);

  /// No description provided for @finReminderBillSoon.
  ///
  /// In pt, this message translates to:
  /// **'{name} vence em {date}'**
  String finReminderBillSoon(String name, String date);

  /// No description provided for @finReminderLoanDue.
  ///
  /// In pt, this message translates to:
  /// **'Hoje vence o empréstimo de {name}'**
  String finReminderLoanDue(String name);

  /// No description provided for @finReminderLoanLate.
  ///
  /// In pt, this message translates to:
  /// **'Empréstimo de {name} atrasado'**
  String finReminderLoanLate(String name);

  /// No description provided for @finReminderLoanBody.
  ///
  /// In pt, this message translates to:
  /// **'Falta receber {amount}'**
  String finReminderLoanBody(String amount);

  /// No description provided for @finByDueMonth.
  ///
  /// In pt, this message translates to:
  /// **'Por mês do vencimento'**
  String get finByDueMonth;

  /// No description provided for @finByLentMonth.
  ///
  /// In pt, this message translates to:
  /// **'Por mês do empréstimo'**
  String get finByLentMonth;

  /// No description provided for @finMonthLoanTotals.
  ///
  /// In pt, this message translates to:
  /// **'a receber {amount} · lucro {profit}'**
  String finMonthLoanTotals(String amount, String profit);

  /// No description provided for @calendarShowFinance.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar finanças (contas, faturas e cobranças)'**
  String get calendarShowFinance;

  /// No description provided for @finCalendarInvoice.
  ///
  /// In pt, this message translates to:
  /// **'Fatura {card}'**
  String finCalendarInvoice(String card);

  /// No description provided for @finCalendarLoan.
  ///
  /// In pt, this message translates to:
  /// **'Cobrar {name}'**
  String finCalendarLoan(String name);

  /// No description provided for @finThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get finThisMonth;

  /// No description provided for @finCurrentInvoice.
  ///
  /// In pt, this message translates to:
  /// **'Fatura atual'**
  String get finCurrentInvoice;

  /// No description provided for @finMonthSpending.
  ///
  /// In pt, this message translates to:
  /// **'Gastos do mês'**
  String get finMonthSpending;

  /// No description provided for @finMoreReports.
  ///
  /// In pt, this message translates to:
  /// **'Mais relatórios'**
  String get finMoreReports;

  /// No description provided for @finCategoriesFilter.
  ///
  /// In pt, this message translates to:
  /// **'Categorias…'**
  String get finCategoriesFilter;

  /// No description provided for @finNewEntryOnDay.
  ///
  /// In pt, this message translates to:
  /// **'Novo lançamento neste dia'**
  String get finNewEntryOnDay;

  /// No description provided for @finOpenInFinance.
  ///
  /// In pt, this message translates to:
  /// **'Abrir em Finanças'**
  String get finOpenInFinance;

  /// No description provided for @finTabGoals.
  ///
  /// In pt, this message translates to:
  /// **'Caixinhas'**
  String get finTabGoals;

  /// No description provided for @finNewGoal.
  ///
  /// In pt, this message translates to:
  /// **'Nova caixinha'**
  String get finNewGoal;

  /// No description provided for @finEditGoal.
  ///
  /// In pt, this message translates to:
  /// **'Editar caixinha'**
  String get finEditGoal;

  /// No description provided for @finGoalName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da caixinha'**
  String get finGoalName;

  /// No description provided for @finGoalTarget.
  ///
  /// In pt, this message translates to:
  /// **'Meta'**
  String get finGoalTarget;

  /// No description provided for @finGoalDueOn.
  ///
  /// In pt, this message translates to:
  /// **'Data-alvo'**
  String get finGoalDueOn;

  /// No description provided for @finGoalNoDue.
  ///
  /// In pt, this message translates to:
  /// **'Sem data'**
  String get finGoalNoDue;

  /// No description provided for @finGoalColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor'**
  String get finGoalColor;

  /// No description provided for @finGoalInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Preencha o nome e uma meta maior que zero.'**
  String get finGoalInvalid;

  /// No description provided for @finGoalSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get finGoalSave;

  /// No description provided for @finGoalWithdraw.
  ///
  /// In pt, this message translates to:
  /// **'Retirar'**
  String get finGoalWithdraw;

  /// No description provided for @finGoalSaved.
  ///
  /// In pt, this message translates to:
  /// **'Guardado'**
  String get finGoalSaved;

  /// No description provided for @finGoalTakenOut.
  ///
  /// In pt, this message translates to:
  /// **'Retirado'**
  String get finGoalTakenOut;

  /// No description provided for @finGoalLeft.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {amount}'**
  String finGoalLeft(String amount);

  /// No description provided for @finGoalLeftLabel.
  ///
  /// In pt, this message translates to:
  /// **'Falta'**
  String get finGoalLeftLabel;

  /// No description provided for @finGoalReached.
  ///
  /// In pt, this message translates to:
  /// **'Meta alcançada'**
  String get finGoalReached;

  /// No description provided for @finGoalProgress.
  ///
  /// In pt, this message translates to:
  /// **'{saved} de {target}'**
  String finGoalProgress(String saved, String target);

  /// No description provided for @finGoalPerMonth.
  ///
  /// In pt, this message translates to:
  /// **'Guarde {amount} por mês até {date}'**
  String finGoalPerMonth(String amount, String date);

  /// No description provided for @finGoalPastDue.
  ///
  /// In pt, this message translates to:
  /// **'A data-alvo passou ({date})'**
  String finGoalPastDue(String date);

  /// No description provided for @finGoalMoves.
  ///
  /// In pt, this message translates to:
  /// **'Movimentos'**
  String get finGoalMoves;

  /// No description provided for @finGoalMoveDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Movimento excluído'**
  String get finGoalMoveDeleted;

  /// No description provided for @finGoalDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Caixinha excluída'**
  String get finGoalDeleted;

  /// No description provided for @finDeleteGoal.
  ///
  /// In pt, this message translates to:
  /// **'Excluir a caixinha \"{name}\" e os movimentos dela?'**
  String finDeleteGoal(String name);

  /// No description provided for @finGoalArchived.
  ///
  /// In pt, this message translates to:
  /// **'Caixinha arquivada'**
  String get finGoalArchived;

  /// No description provided for @finArchivedGoals.
  ///
  /// In pt, this message translates to:
  /// **'Arquivadas'**
  String get finArchivedGoals;

  /// No description provided for @finNoGoals.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma caixinha ainda. Crie uma para juntar dinheiro para uma meta.'**
  String get finNoGoals;

  /// No description provided for @finNoGoalsHere.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma caixinha aqui.'**
  String get finNoGoalsHere;

  /// No description provided for @finGoalMoveIn.
  ///
  /// In pt, this message translates to:
  /// **'Guardar em {name}'**
  String finGoalMoveIn(String name);

  /// No description provided for @finGoalMoveOut.
  ///
  /// In pt, this message translates to:
  /// **'Retirar de {name}'**
  String finGoalMoveOut(String name);

  /// No description provided for @finEditGoalMove.
  ///
  /// In pt, this message translates to:
  /// **'Editar movimento'**
  String get finEditGoalMove;

  /// No description provided for @finGoalsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{nenhuma caixinha} =1{1 caixinha} other{{count} caixinhas}}'**
  String finGoalsCount(int count);

  /// No description provided for @finGoalTargetsHint.
  ///
  /// In pt, this message translates to:
  /// **'de {amount} em metas'**
  String finGoalTargetsHint(String amount);

  /// No description provided for @finGoalsSavedLine.
  ///
  /// In pt, this message translates to:
  /// **'Guardado nas caixinhas: {total} · neste mês {month}'**
  String finGoalsSavedLine(String total, String month);

  /// No description provided for @finLoanAtOnce.
  ///
  /// In pt, this message translates to:
  /// **'Pago à vista'**
  String get finLoanAtOnce;

  /// No description provided for @finLoanInInstallments.
  ///
  /// In pt, this message translates to:
  /// **'Parcelado'**
  String get finLoanInInstallments;

  /// No description provided for @finLoanInstallmentCount.
  ///
  /// In pt, this message translates to:
  /// **'Número de parcelas'**
  String get finLoanInstallmentCount;

  /// No description provided for @finLoanInstallmentAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor da parcela'**
  String get finLoanInstallmentAmount;

  /// No description provided for @finLoanFirstDue.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento da 1ª parcela'**
  String get finLoanFirstDue;

  /// No description provided for @finLoanInstallmentsTotal.
  ///
  /// In pt, this message translates to:
  /// **'{count}x de {amount} = {total}'**
  String finLoanInstallmentsTotal(int count, String amount, String total);

  /// No description provided for @finInstallmentPaid.
  ///
  /// In pt, this message translates to:
  /// **'Paga'**
  String get finInstallmentPaid;

  /// No description provided for @finInstallmentOpen.
  ///
  /// In pt, this message translates to:
  /// **'Em aberto'**
  String get finInstallmentOpen;

  /// No description provided for @finInstallmentOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasada'**
  String get finInstallmentOverdue;

  /// No description provided for @finInstallmentPaidOn.
  ///
  /// In pt, this message translates to:
  /// **'paga em {date}'**
  String finInstallmentPaidOn(String date);

  /// No description provided for @finInstallmentLabel.
  ///
  /// In pt, this message translates to:
  /// **'Parcela {number} de {count}'**
  String finInstallmentLabel(int number, int count);

  /// No description provided for @finReceiveInstallment.
  ///
  /// In pt, this message translates to:
  /// **'Receber parcela'**
  String get finReceiveInstallment;

  /// No description provided for @finInstallmentReceived.
  ///
  /// In pt, this message translates to:
  /// **'Parcela {number} recebida'**
  String finInstallmentReceived(int number);

  /// No description provided for @finLoanNextInstallment.
  ///
  /// In pt, this message translates to:
  /// **'parcela {number}/{count} vence {date}'**
  String finLoanNextInstallment(int number, int count, String date);

  /// No description provided for @finSituation.
  ///
  /// In pt, this message translates to:
  /// **'Situação'**
  String get finSituation;

  /// No description provided for @finGroupBy.
  ///
  /// In pt, this message translates to:
  /// **'Agrupar'**
  String get finGroupBy;

  /// No description provided for @finCreditAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Limite disponível'**
  String get finCreditAvailable;

  /// No description provided for @habitPanelDone.
  ///
  /// In pt, this message translates to:
  /// **'Feitos'**
  String get habitPanelDone;

  /// No description provided for @habitPanelLeft.
  ///
  /// In pt, this message translates to:
  /// **'Faltam'**
  String get habitPanelLeft;

  /// No description provided for @habitPanelNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum hábito para hoje.'**
  String get habitPanelNone;

  /// No description provided for @habitPanelShow.
  ///
  /// In pt, this message translates to:
  /// **'Exibir'**
  String get habitPanelShow;

  /// No description provided for @countdownTypes.
  ///
  /// In pt, this message translates to:
  /// **'Tipos'**
  String get countdownTypes;

  /// No description provided for @countdownCreateWhich.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get countdownCreateWhich;

  /// No description provided for @matrixQuadrants.
  ///
  /// In pt, this message translates to:
  /// **'Quadrantes'**
  String get matrixQuadrants;

  /// No description provided for @focusShortcuts.
  ///
  /// In pt, this message translates to:
  /// **'Atalhos'**
  String get focusShortcuts;

  /// No description provided for @habitColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor do hábito'**
  String get habitColor;

  /// No description provided for @habitColorMenu.
  ///
  /// In pt, this message translates to:
  /// **'Cor'**
  String get habitColorMenu;

  /// No description provided for @finNewPurchase.
  ///
  /// In pt, this message translates to:
  /// **'Nova compra'**
  String get finNewPurchase;

  /// No description provided for @habitNewButton.
  ///
  /// In pt, this message translates to:
  /// **'Novo hábito'**
  String get habitNewButton;

  /// No description provided for @countdownNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova contagem'**
  String get countdownNew;

  /// No description provided for @focusTimerNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo temporizador'**
  String get focusTimerNew;

  /// No description provided for @finEditPayment.
  ///
  /// In pt, this message translates to:
  /// **'Editar pagamento'**
  String get finEditPayment;

  /// No description provided for @habitDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir o hábito \"{name}\" e todos os check-ins dele? Isso não pode ser desfeito.'**
  String habitDeleteConfirm(String name);

  /// No description provided for @habitLogDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir registro'**
  String get habitLogDelete;

  /// No description provided for @countdownDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir \"{name}\"? Isso não pode ser desfeito.'**
  String countdownDeleteConfirm(String name);

  /// No description provided for @focusTimerDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir o temporizador \"{name}\"? Os registros de foco continuam.'**
  String focusTimerDeleteConfirm(String name);

  /// No description provided for @focusRecordDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir este registro de foco? Isso não pode ser desfeito.'**
  String get focusRecordDeleteConfirm;

  /// No description provided for @tagDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir a etiqueta \"{name}\"? As tarefas continuam, sem ela.'**
  String tagDeleteConfirm(String name);

  /// No description provided for @listDeleteMenu.
  ///
  /// In pt, this message translates to:
  /// **'Deletar lista'**
  String get listDeleteMenu;

  /// No description provided for @syncTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar com outro aparelho'**
  String get syncTitle;

  /// No description provided for @syncMenu.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar aparelhos'**
  String get syncMenu;

  /// No description provided for @syncIntro.
  ///
  /// In pt, this message translates to:
  /// **'Deixe o celular e o computador iguais pelo Wi-Fi, sem internet e sem conta: um aparelho envia tudo o que tem, e o outro fica igual a ele.'**
  String get syncIntro;

  /// No description provided for @syncSend.
  ///
  /// In pt, this message translates to:
  /// **'Enviar deste aparelho'**
  String get syncSend;

  /// No description provided for @syncSendHint.
  ///
  /// In pt, this message translates to:
  /// **'O outro aparelho fica igual a este.'**
  String get syncSendHint;

  /// No description provided for @syncReceive.
  ///
  /// In pt, this message translates to:
  /// **'Receber neste aparelho'**
  String get syncReceive;

  /// No description provided for @syncReceiveHint.
  ///
  /// In pt, this message translates to:
  /// **'Este aparelho fica igual ao outro. Antes, é feita uma cópia de segurança dos dados daqui (em Configurações → Conta → Backups automáticos).'**
  String get syncReceiveHint;

  /// No description provided for @syncSameWifi.
  ///
  /// In pt, this message translates to:
  /// **'Os dois precisam estar no mesmo Wi-Fi, com o Ordo aberto e na mesma versão.'**
  String get syncSameWifi;

  /// No description provided for @syncWaiting.
  ///
  /// In pt, this message translates to:
  /// **'No outro aparelho, abra Sincronizar → Enviar deste aparelho, escolha \"{name}\" e digite este código:'**
  String syncWaiting(String name);

  /// No description provided for @syncAddress.
  ///
  /// In pt, this message translates to:
  /// **'Se \"{name}\" não aparecer lá, toque em Digitar endereço e use: {address}'**
  String syncAddress(String name, String address);

  /// No description provided for @syncFirewall.
  ///
  /// In pt, this message translates to:
  /// **'No Windows, se o Firewall perguntar, clique em Permitir acesso.'**
  String get syncFirewall;

  /// No description provided for @syncReceiving.
  ///
  /// In pt, this message translates to:
  /// **'Recebendo os dados…'**
  String get syncReceiving;

  /// No description provided for @syncReceived.
  ///
  /// In pt, this message translates to:
  /// **'Pronto! Este aparelho ficou igual a \"{name}\".'**
  String syncReceived(String name);

  /// No description provided for @syncReceiveFailed.
  ///
  /// In pt, this message translates to:
  /// **'Os dados recebidos não puderam ser usados (as versões do app são diferentes?). Nada mudou aqui.'**
  String get syncReceiveFailed;

  /// No description provided for @syncSearching.
  ///
  /// In pt, this message translates to:
  /// **'Procurando aparelhos no Wi-Fi…'**
  String get syncSearching;

  /// No description provided for @syncTypeAddress.
  ///
  /// In pt, this message translates to:
  /// **'Digitar endereço'**
  String get syncTypeAddress;

  /// No description provided for @syncAddressLabel.
  ///
  /// In pt, this message translates to:
  /// **'Endereço (ex.: 192.168.0.10:50000)'**
  String get syncAddressLabel;

  /// No description provided for @syncEnterCode.
  ///
  /// In pt, this message translates to:
  /// **'Digite o código que aparece em \"{name}\"'**
  String syncEnterCode(String name);

  /// No description provided for @syncSendButton.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get syncSendButton;

  /// No description provided for @syncSending.
  ///
  /// In pt, this message translates to:
  /// **'Enviando… o outro aparelho está ficando igual a este.'**
  String get syncSending;

  /// No description provided for @syncDone.
  ///
  /// In pt, this message translates to:
  /// **'Pronto! \"{name}\" ficou igual a este aparelho.'**
  String syncDone(String name);

  /// No description provided for @syncWrongCode.
  ///
  /// In pt, this message translates to:
  /// **'Código errado. Confira o código na tela do outro aparelho.'**
  String get syncWrongCode;

  /// No description provided for @syncRefused.
  ///
  /// In pt, this message translates to:
  /// **'O outro aparelho parou de aceitar depois de muitas tentativas. Lá, feche e abra Receber de novo.'**
  String get syncRefused;

  /// No description provided for @syncFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não deu certo. Confira se os dois estão no mesmo Wi-Fi, com o Ordo aberto e na mesma versão.'**
  String get syncFailed;

  /// No description provided for @syncCodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código'**
  String get syncCodeLabel;

  /// No description provided for @syncWaitingOther.
  ///
  /// In pt, this message translates to:
  /// **'Esperando o outro aparelho enviar…'**
  String get syncWaitingOther;

  /// No description provided for @widgetDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get widgetDay;

  /// No description provided for @widgetWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana'**
  String get widgetWeek;

  /// No description provided for @widgetMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get widgetMonth;

  /// No description provided for @widgetEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nada neste dia'**
  String get widgetEmpty;

  /// No description provided for @widgetAllDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia todo'**
  String get widgetAllDay;

  /// No description provided for @miniLayerTop.
  ///
  /// In pt, this message translates to:
  /// **'Por cima das janelas'**
  String get miniLayerTop;

  /// No description provided for @miniLayerNormal.
  ///
  /// In pt, this message translates to:
  /// **'Normal'**
  String get miniLayerNormal;

  /// No description provided for @miniLayerDesktop.
  ///
  /// In pt, this message translates to:
  /// **'Na área de trabalho'**
  String get miniLayerDesktop;

  /// No description provided for @miniClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get miniClose;

  /// No description provided for @reorderSortCustom.
  ///
  /// In pt, this message translates to:
  /// **'Agora a ordem desta lista é a sua (Ordenar por: Personalizado).'**
  String get reorderSortCustom;

  /// No description provided for @navDiet.
  ///
  /// In pt, this message translates to:
  /// **'Dieta'**
  String get navDiet;

  /// No description provided for @featureDietHint.
  ///
  /// In pt, this message translates to:
  /// **'Diário de refeições com a Tabela TACO: calorias e macros do dia'**
  String get featureDietHint;

  /// No description provided for @dietTabDiary.
  ///
  /// In pt, this message translates to:
  /// **'Diário'**
  String get dietTabDiary;

  /// No description provided for @dietTabFoods.
  ///
  /// In pt, this message translates to:
  /// **'Alimentos'**
  String get dietTabFoods;

  /// No description provided for @dietAddFood.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar alimento'**
  String get dietAddFood;

  /// No description provided for @dietAddTo.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar em {meal}'**
  String dietAddTo(String meal);

  /// No description provided for @dietNewFood.
  ///
  /// In pt, this message translates to:
  /// **'Novo alimento'**
  String get dietNewFood;

  /// No description provided for @dietEditFood.
  ///
  /// In pt, this message translates to:
  /// **'Editar alimento'**
  String get dietEditFood;

  /// No description provided for @dietEditEntry.
  ///
  /// In pt, this message translates to:
  /// **'Editar alimento do dia'**
  String get dietEditEntry;

  /// No description provided for @dietMealBreakfast.
  ///
  /// In pt, this message translates to:
  /// **'Café da manhã'**
  String get dietMealBreakfast;

  /// No description provided for @dietMealMorningSnack.
  ///
  /// In pt, this message translates to:
  /// **'Lanche da manhã'**
  String get dietMealMorningSnack;

  /// No description provided for @dietMealLunch.
  ///
  /// In pt, this message translates to:
  /// **'Almoço'**
  String get dietMealLunch;

  /// No description provided for @dietMealAfternoonSnack.
  ///
  /// In pt, this message translates to:
  /// **'Lanche da tarde'**
  String get dietMealAfternoonSnack;

  /// No description provided for @dietMealDinner.
  ///
  /// In pt, this message translates to:
  /// **'Jantar'**
  String get dietMealDinner;

  /// No description provided for @dietMealSupper.
  ///
  /// In pt, this message translates to:
  /// **'Ceia'**
  String get dietMealSupper;

  /// No description provided for @dietMeal.
  ///
  /// In pt, this message translates to:
  /// **'Refeição'**
  String get dietMeal;

  /// No description provided for @dietKcal.
  ///
  /// In pt, this message translates to:
  /// **'Calorias'**
  String get dietKcal;

  /// No description provided for @dietProtein.
  ///
  /// In pt, this message translates to:
  /// **'Proteínas'**
  String get dietProtein;

  /// No description provided for @dietCarbs.
  ///
  /// In pt, this message translates to:
  /// **'Carboidratos'**
  String get dietCarbs;

  /// No description provided for @dietFat.
  ///
  /// In pt, this message translates to:
  /// **'Gorduras'**
  String get dietFat;

  /// No description provided for @dietFiber.
  ///
  /// In pt, this message translates to:
  /// **'Fibras'**
  String get dietFiber;

  /// No description provided for @dietSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar alimento (ex.: arroz, banana, frango)'**
  String get dietSearchHint;

  /// No description provided for @dietQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get dietQuantity;

  /// No description provided for @dietGrams.
  ///
  /// In pt, this message translates to:
  /// **'gramas'**
  String get dietGrams;

  /// No description provided for @dietNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Não achei: cadastrar alimento'**
  String get dietNotFound;

  /// No description provided for @dietKcalFromMacros.
  ///
  /// In pt, this message translates to:
  /// **'Pelos macros: P×4 + C×4 + G×9'**
  String get dietKcalFromMacros;

  /// No description provided for @dietPer100.
  ///
  /// In pt, this message translates to:
  /// **'Valores por 100 g (deixe em branco o que não souber)'**
  String get dietPer100;

  /// No description provided for @dietName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get dietName;

  /// No description provided for @dietNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Dê um nome ao alimento.'**
  String get dietNameRequired;

  /// No description provided for @dietMeasureName.
  ///
  /// In pt, this message translates to:
  /// **'Medida caseira (opcional, ex.: colher de sopa)'**
  String get dietMeasureName;

  /// No description provided for @dietMeasureGrams.
  ///
  /// In pt, this message translates to:
  /// **'Gramas dessa medida'**
  String get dietMeasureGrams;

  /// No description provided for @dietDayEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nada lançado neste dia.'**
  String get dietDayEmpty;

  /// No description provided for @dietMyFoods.
  ///
  /// In pt, this message translates to:
  /// **'Meus alimentos'**
  String get dietMyFoods;

  /// No description provided for @dietMyFoodsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não cadastrou alimentos. Use + Novo alimento ou \"Não achei\" ao lançar.'**
  String get dietMyFoodsEmpty;

  /// No description provided for @dietMine.
  ///
  /// In pt, this message translates to:
  /// **'Meu alimento'**
  String get dietMine;

  /// No description provided for @dietSource.
  ///
  /// In pt, this message translates to:
  /// **'Tabela TACO: NEPA/Unicamp, 4ª edição. Valores por 100 g da parte comestível.'**
  String get dietSource;

  /// No description provided for @dietEntryDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Alimento removido do dia'**
  String get dietEntryDeleted;

  /// No description provided for @dietFoodDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Alimento excluído'**
  String get dietFoodDeleted;

  /// No description provided for @dietIncomplete.
  ///
  /// In pt, this message translates to:
  /// **'Alguns alimentos não têm todos os valores na tabela: o total é um mínimo.'**
  String get dietIncomplete;

  /// No description provided for @dietChangeFood.
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get dietChangeFood;

  /// No description provided for @dietPerHundred.
  ///
  /// In pt, this message translates to:
  /// **'{kcal} kcal/100 g'**
  String dietPerHundred(String kcal);

  /// No description provided for @dietPortionResult.
  ///
  /// In pt, this message translates to:
  /// **'= {grams} g · {kcal} kcal'**
  String dietPortionResult(String grams, String kcal);

  /// No description provided for @dietQuantityRequired.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um alimento e uma quantidade maior que zero.'**
  String get dietQuantityRequired;

  /// No description provided for @dietSaveAndUse.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar e usar'**
  String get dietSaveAndUse;

  /// No description provided for @dietAddToDay.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar ao dia'**
  String get dietAddToDay;

  /// No description provided for @dietDayTotals.
  ///
  /// In pt, this message translates to:
  /// **'Totais do dia'**
  String get dietDayTotals;

  /// No description provided for @dietEnergy.
  ///
  /// In pt, this message translates to:
  /// **'Energia'**
  String get dietEnergy;

  /// No description provided for @dietLegendProtein.
  ///
  /// In pt, this message translates to:
  /// **'Prot. {pct}'**
  String dietLegendProtein(String pct);

  /// No description provided for @dietLegendCarbs.
  ///
  /// In pt, this message translates to:
  /// **'Carb. {pct}'**
  String dietLegendCarbs(String pct);

  /// No description provided for @dietLegendFat.
  ///
  /// In pt, this message translates to:
  /// **'Gord. {pct}'**
  String dietLegendFat(String pct);

  /// No description provided for @dietNewMeal.
  ///
  /// In pt, this message translates to:
  /// **'Nova refeição'**
  String get dietNewMeal;

  /// No description provided for @dietEditMeal.
  ///
  /// In pt, this message translates to:
  /// **'Editar refeição'**
  String get dietEditMeal;

  /// No description provided for @dietMealTime.
  ///
  /// In pt, this message translates to:
  /// **'Horário'**
  String get dietMealTime;

  /// No description provided for @dietMealNoTime.
  ///
  /// In pt, this message translates to:
  /// **'Sem horário'**
  String get dietMealNoTime;

  /// No description provided for @dietMealTimeHint.
  ///
  /// In pt, this message translates to:
  /// **'O horário escolhe a refeição sugerida ao adicionar um alimento.'**
  String get dietMealTimeHint;

  /// No description provided for @dietMealNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Dê um nome à refeição.'**
  String get dietMealNameRequired;

  /// No description provided for @dietMoveUp.
  ///
  /// In pt, this message translates to:
  /// **'Mover para cima'**
  String get dietMoveUp;

  /// No description provided for @dietMoveDown.
  ///
  /// In pt, this message translates to:
  /// **'Mover para baixo'**
  String get dietMoveDown;

  /// No description provided for @dietMealArchived.
  ///
  /// In pt, this message translates to:
  /// **'Refeição arquivada'**
  String get dietMealArchived;

  /// No description provided for @dietMealDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Refeição excluída'**
  String get dietMealDeleted;

  /// No description provided for @dietMealArchivedTag.
  ///
  /// In pt, this message translates to:
  /// **'arquivada'**
  String get dietMealArchivedTag;

  /// No description provided for @dietArchivedMeals.
  ///
  /// In pt, this message translates to:
  /// **'Refeições arquivadas ({count})'**
  String dietArchivedMeals(int count);

  /// No description provided for @dietMeasures.
  ///
  /// In pt, this message translates to:
  /// **'Medidas caseiras'**
  String get dietMeasures;

  /// No description provided for @dietAddMeasure.
  ///
  /// In pt, this message translates to:
  /// **'Medida'**
  String get dietAddMeasure;

  /// No description provided for @dietNewMeasure.
  ///
  /// In pt, this message translates to:
  /// **'Nova medida'**
  String get dietNewMeasure;

  /// No description provided for @dietMeasureDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Medida excluída'**
  String get dietMeasureDeleted;

  /// No description provided for @dietMeasureLabel.
  ///
  /// In pt, this message translates to:
  /// **'Medida (ex.: colher de sopa)'**
  String get dietMeasureLabel;

  /// No description provided for @dietMeasureGramsShort.
  ///
  /// In pt, this message translates to:
  /// **'Gramas'**
  String get dietMeasureGramsShort;

  /// No description provided for @dietTacoMeasures.
  ///
  /// In pt, this message translates to:
  /// **'Da tabela TACO'**
  String get dietTacoMeasures;

  /// No description provided for @dietMyMeasures.
  ///
  /// In pt, this message translates to:
  /// **'Suas medidas'**
  String get dietMyMeasures;

  /// No description provided for @dietNoMeasures.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma medida ainda.'**
  String get dietNoMeasures;

  /// No description provided for @dietTargets.
  ///
  /// In pt, this message translates to:
  /// **'Metas'**
  String get dietTargets;

  /// No description provided for @dietTargetsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Metas diárias'**
  String get dietTargetsTitle;

  /// No description provided for @dietTargetsHint.
  ///
  /// In pt, this message translates to:
  /// **'Deixe em branco o que não quiser acompanhar.'**
  String get dietTargetsHint;

  /// No description provided for @dietTargetsFromMacros.
  ///
  /// In pt, this message translates to:
  /// **'Calcular as calorias pelos macros (P×4 + C×4 + G×9)'**
  String get dietTargetsFromMacros;

  /// No description provided for @dietTabPlan.
  ///
  /// In pt, this message translates to:
  /// **'Plano'**
  String get dietTabPlan;

  /// No description provided for @dietAddToPlan.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar ao plano'**
  String get dietAddToPlan;

  /// No description provided for @dietEditPlanItem.
  ///
  /// In pt, this message translates to:
  /// **'Editar item do plano'**
  String get dietEditPlanItem;

  /// No description provided for @dietPlanItemDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Item removido do plano'**
  String get dietPlanItemDeleted;

  /// No description provided for @dietPlanEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Seu plano está vazio. Monte o cardápio prescrito com + Adicionar ao plano.'**
  String get dietPlanEmpty;

  /// No description provided for @dietPlanEveryDay.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dias'**
  String get dietPlanEveryDay;

  /// No description provided for @dietPlanDays.
  ///
  /// In pt, this message translates to:
  /// **'Dias da semana (nenhum marcado = todos os dias)'**
  String get dietPlanDays;

  /// No description provided for @dietPlanAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get dietPlanAll;

  /// No description provided for @dietPlanTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total do plano'**
  String get dietPlanTotal;

  /// No description provided for @dietImportPlan.
  ///
  /// In pt, this message translates to:
  /// **'Importar plano do dia'**
  String get dietImportPlan;

  /// No description provided for @dietPlanImported.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{O plano do dia já está no diário} =1{1 alimento importado do plano} other{{count} alimentos importados do plano}}'**
  String dietPlanImported(int count);

  /// No description provided for @dietAdherence.
  ///
  /// In pt, this message translates to:
  /// **'Adesão'**
  String get dietAdherence;

  /// No description provided for @dietAdherenceWeek.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 7 dias'**
  String get dietAdherenceWeek;

  /// No description provided for @dietAdherenceDay.
  ///
  /// In pt, this message translates to:
  /// **'Adesão do dia: {pct}'**
  String dietAdherenceDay(String pct);

  /// No description provided for @dietAdherenceHelp.
  ///
  /// In pt, this message translates to:
  /// **'Cada item do plano comido como planejado vale 100%; com outra quantidade ou trocado, 50%; pulado, 0%. Com meta de calorias, a nota é 70% o plano e 30% as calorias (100% dentro de ±10% da meta).'**
  String get dietAdherenceHelp;

  /// No description provided for @dietAdherenceLess.
  ///
  /// In pt, this message translates to:
  /// **'Menos'**
  String get dietAdherenceLess;

  /// No description provided for @dietAdherenceMore.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get dietAdherenceMore;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['la', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'la':
      return AppLocalizationsLa();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
