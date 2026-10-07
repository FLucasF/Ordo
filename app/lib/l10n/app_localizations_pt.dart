// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Tarefas';

  @override
  String get inbox => 'Caixa de Entrada';

  @override
  String get smartAll => 'Todas';

  @override
  String get smartToday => 'Hoje';

  @override
  String get smartTomorrow => 'Amanhã';

  @override
  String get smartNext7Days => 'Próximos 7 dias';

  @override
  String get smartCompleted => 'Concluído';

  @override
  String get smartWontDo => 'Não será feito';

  @override
  String get smartTrash => 'Lixeira';

  @override
  String get sidebarLists => 'Listas';

  @override
  String get sidebarFilters => 'Filtros';

  @override
  String get sidebarTags => 'Etiquetas';

  @override
  String get sidebarFiltersHelp => 'Mostrar tarefas filtradas por lista, data, prioridade, etiqueta e mais.';

  @override
  String get sidebarTagsHelp => 'Categorize suas tarefas com etiquetas. Digite # no campo de tarefa para criar.';

  @override
  String get archivedLists => 'Listas Arquivadas';

  @override
  String get navTasks => 'Tarefas';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navSync => 'Sincronizar';

  @override
  String get navNotifications => 'Notificações';

  @override
  String get navHelp => 'Ajuda';

  @override
  String get groupPinned => 'Fixado';

  @override
  String get groupUnpinned => 'Não fixado';

  @override
  String get groupUnsectioned => 'Não Classificado';

  @override
  String get groupOverdue => 'Atrasadas';

  @override
  String get groupNext7Days => 'Próximos 7 dias';

  @override
  String get groupLater => 'Mais tarde';

  @override
  String get groupNoDate => 'Sem Data';

  @override
  String get groupNoTag => 'Sem etiquetas';

  @override
  String get groupCompleted => 'Concluído';

  @override
  String get groupCompletedAndWontDo => 'Concluído e Não Farei.';

  @override
  String get groupPriorityHigh => 'Prioridade alta';

  @override
  String get groupPriorityMedium => 'Prioridade média';

  @override
  String get groupPriorityLow => 'Prioridade baixa';

  @override
  String get groupPriorityNone => 'Sem prioridade';

  @override
  String get showMore => 'Ver mais';

  @override
  String get weekdayMonday => 'Segunda-feira';

  @override
  String get weekdayTuesday => 'Terça-feira';

  @override
  String get weekdayWednesday => 'Quarta-feira';

  @override
  String get weekdayThursday => 'Quinta-feira';

  @override
  String get weekdayFriday => 'Sexta-feira';

  @override
  String get weekdaySaturday => 'Sábado';

  @override
  String get weekdaySunday => 'Domingo';

  @override
  String get weekdayShortMonday => 'Seg';

  @override
  String get weekdayShortTuesday => 'Ter';

  @override
  String get weekdayShortWednesday => 'Qua';

  @override
  String get weekdayShortThursday => 'Qui';

  @override
  String get weekdayShortFriday => 'Sex';

  @override
  String get weekdayShortSaturday => 'Sáb';

  @override
  String get weekdayShortSunday => 'Dom';

  @override
  String get monthJanuary => 'janeiro';

  @override
  String get monthFebruary => 'fevereiro';

  @override
  String get monthMarch => 'março';

  @override
  String get monthApril => 'abril';

  @override
  String get monthMay => 'maio';

  @override
  String get monthJune => 'junho';

  @override
  String get monthJuly => 'julho';

  @override
  String get monthAugust => 'agosto';

  @override
  String get monthSeptember => 'setembro';

  @override
  String get monthOctober => 'outubro';

  @override
  String get monthNovember => 'novembro';

  @override
  String get monthDecember => 'dezembro';

  @override
  String get monthShortJanuary => 'jan';

  @override
  String get monthShortFebruary => 'fev';

  @override
  String get monthShortMarch => 'mar';

  @override
  String get monthShortApril => 'abr';

  @override
  String get monthShortMay => 'mai';

  @override
  String get monthShortJune => 'jun';

  @override
  String get monthShortJuly => 'jul';

  @override
  String get monthShortAugust => 'ago';

  @override
  String get monthShortSeptember => 'set';

  @override
  String get monthShortOctober => 'out';

  @override
  String get monthShortNovember => 'nov';

  @override
  String get monthShortDecember => 'dez';

  @override
  String get relativeToday => 'Hoje';

  @override
  String get relativeTomorrow => 'Amanhã';

  @override
  String get relativeYesterday => 'Ontem';

  @override
  String get emptyNoTasks => 'Sem tarefas';

  @override
  String get emptyInbox => 'Capture aqui as tarefas e ideias';

  @override
  String get emptyList => 'Clique na caixa de entrada para adicionar';

  @override
  String get emptyNoNotes => 'Sem notas';

  @override
  String get emptyNotes => 'Registre inspiração e tempo aqui';

  @override
  String get emptyTag => 'Relaxe um pouco';

  @override
  String get emptySmart => 'Relaxe um pouco';

  @override
  String get emptyCompletedTitle => 'Ainda não há tarefas concluídas';

  @override
  String get emptyCompleted => 'Continue assim :)';

  @override
  String get emptyWontDo => 'As tarefas que você não fará aparecem aqui';

  @override
  String get emptyTrashTitle => 'A lixeira está limpa';

  @override
  String get emptyTrash => 'Não há tarefas excluídas';

  @override
  String get addTask => 'Adicionar tarefa';

  @override
  String get addNote => 'Adicionar nota';

  @override
  String addTaskTo(String name) {
    return 'Adicionar tarefa a \'$name\'';
  }

  @override
  String addTaskToTag(String name) {
    return 'Adicionar tarefa a \'#$name\'';
  }

  @override
  String get addDescriptionHint => 'Shift+Enter adicionar descrição';

  @override
  String get toastTaskCompleted => 'Tarefa concluída';

  @override
  String get toastFirstTaskOfDay => 'Completou a primeira tarefa do dia!';

  @override
  String get toastUndo => 'Desfazer';

  @override
  String get toastTaskDeleted => 'Tarefa excluída';

  @override
  String get toastRestored => 'Restaurado para a lista original.';

  @override
  String get toastWontDo => 'Você desistiu da tarefa.';

  @override
  String toastMovedTo(String name) {
    return 'Movido para $name';
  }

  @override
  String get toastMovedToToday => 'Movido para \"Hoje\".';

  @override
  String get toastSaved => 'Salvo';

  @override
  String get toastArchived => 'Arquivado';

  @override
  String get toastLinkCopied => 'Link copiado';

  @override
  String get errorInboxCannotBeArchived => 'A Caixa de Entrada não pode ser arquivada.';

  @override
  String get errorInboxCannotBeDeleted => 'A Caixa de Entrada não pode ser excluída.';

  @override
  String get errorTaskCannotBeItsOwnParent => 'Uma tarefa não pode ser subtarefa dela mesma.';

  @override
  String get errorSubtaskDepthLimit => 'As subtarefas vão até 5 níveis.';

  @override
  String get errorTaskWithSubtasksCannotBecomeNote => 'Tarefas com sub-tarefas não podem ser convertidas em notas.';

  @override
  String get errorTagNameTaken => 'Já existe uma etiqueta com esse nome.';

  @override
  String get menuDate => 'Data';

  @override
  String get menuPriority => 'Prioridade';

  @override
  String get menuAddSubtask => 'Adicionar subtarefa';

  @override
  String get menuLinkParent => 'Vincular Tarefa Pai';

  @override
  String get menuPin => 'Fixar';

  @override
  String get menuUnpin => 'Desafixar';

  @override
  String get menuWontDo => 'Não farei';

  @override
  String get menuMoveTo => 'Mover para';

  @override
  String get menuTags => 'Etiquetas';

  @override
  String get menuDuplicate => 'Duplicar';

  @override
  String get menuCopyLink => 'Copiar link';

  @override
  String get menuConvertToNote => 'Converter para nota';

  @override
  String get menuConvertToTask => 'Converter para tarefa';

  @override
  String get menuDelete => 'Deletar';

  @override
  String get menuRestore => 'Restaurar';

  @override
  String get menuDeleteForever => 'Excluir definitivamente';

  @override
  String get menuReopen => 'Reabrir';

  @override
  String get menuMore => 'Mais';

  @override
  String get dateToday => 'Hoje';

  @override
  String get dateTomorrow => 'Amanhã';

  @override
  String get dateNextWeek => 'Próxima Semana';

  @override
  String get dateCustom => 'Personalizado';

  @override
  String get dateClear => 'Limpar';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityMedium => 'Média';

  @override
  String get priorityLow => 'Baixa';

  @override
  String get priorityNone => 'Nenhuma';

  @override
  String get detailDueDatePlaceholder => 'Dia do vencimento';

  @override
  String get detailTitlePlaceholder => 'O que você gostaria de fazer?';

  @override
  String get detailContentPlaceholder => 'Digite o conteúdo ou use \"/\" para o menu';

  @override
  String get detailNotePlaceholder => 'Escreva algo ou use um modelo';

  @override
  String get detailSetReminder => 'Definir lembrete';

  @override
  String get detailChecklistTooltip => 'Lista de verificação';

  @override
  String get detailChecklistHint => 'Pressione \'Entrar\' para adicionar item na lista';

  @override
  String get detailAddSubtask => 'Adicionar subtarefa';

  @override
  String get detailAddTag => 'Adicionar etiqueta';

  @override
  String get untitled => 'Sem título';

  @override
  String get listAddTitle => 'Adicionar lista';

  @override
  String get listEditTitle => 'Editar lista';

  @override
  String get listNameHint => 'Nome';

  @override
  String get listColor => 'Cor da Lista';

  @override
  String get listViewType => 'Tipo de Visualização';

  @override
  String get viewList => 'Lista';

  @override
  String get viewKanban => 'Kanban';

  @override
  String get viewTimeline => 'Linha do tempo';

  @override
  String get listFolder => 'Pasta';

  @override
  String get folderNone => 'Nenhuma';

  @override
  String get folderNew => 'Nova Pasta';

  @override
  String get listType => 'Tipo de lista';

  @override
  String get listTypeTasks => 'Lista de tarefas';

  @override
  String get listTypeNotes => 'Lista de notas';

  @override
  String get listShowInSmartList => 'Mostrar na Lista Inteligente';

  @override
  String get listShowAllTasks => 'Todas as tarefas';

  @override
  String get listDontShow => 'Não mostrar';

  @override
  String get notesListCreated => 'Uma lista de notas foi criada com sucesso. Você pode escrever suas notas aqui.';

  @override
  String get gotIt => 'Eu sei';

  @override
  String get copySuffix => ' copiar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionAdd => 'Adicionar';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionClose => 'Fechar';

  @override
  String get actionOk => 'OK';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionRename => 'Renomear';

  @override
  String get actionDuplicate => 'Duplicar';

  @override
  String get actionArchive => 'Arquivar';

  @override
  String get actionUnarchive => 'Lista de desarquivamento';

  @override
  String get actionDelete => 'Deletar';

  @override
  String get actionAddList => 'Adicionar lista';

  @override
  String get actionUngroup => 'Desagrupar';

  @override
  String get archiveListConfirm =>
      'Se arquivada, esta lista será agrupada na pasta \'Listas Arquivadas\'. As tarefas e notas dentro desta lista não serão lembradas ou exibidas em \'Todas\' e outras Listas Inteligentes.';

  @override
  String get deleteListConfirm => 'A lista será excluída e as tarefas irão para a Lixeira.';

  @override
  String get tagAddTitle => 'Adicionar Tags';

  @override
  String get tagEditTitle => 'Editar tag';

  @override
  String get tagNameHint => 'Nome';

  @override
  String get tagColor => 'Cor';

  @override
  String get tagParent => 'Tag principal';

  @override
  String get tagParentNone => 'Nenhuma';

  @override
  String get tagAddSubtag => 'Adicionar Sub-tag';

  @override
  String get tagMerge => 'Mesclar Tags';

  @override
  String tagMergeInto(String name) {
    return 'Mesclar \'$name\' em:';
  }

  @override
  String get colorNone => 'Nenhuma';

  @override
  String get sectionAdd => 'Adicionar Seção';

  @override
  String get sectionNew => 'Nova seção';

  @override
  String get sectionAddLeft => 'Adicionar Seção à Esquerda';

  @override
  String get sectionAddRight => 'Adicionar Seção à Direita';

  @override
  String get sortButtonTooltip => 'Ordenar e agrupar';

  @override
  String get groupByLabel => 'Agrupar por';

  @override
  String get sortByLabel => 'Ordenar por';

  @override
  String get optionCustom => 'Personalizado';

  @override
  String get optionDate => 'Data';

  @override
  String get optionModifiedTime => 'Hora de modificação';

  @override
  String get optionCreatedTime => 'Data de criação';

  @override
  String get optionTitle => 'Título';

  @override
  String get optionTag => 'Tag';

  @override
  String get optionPriority => 'Prioridade';

  @override
  String get optionNone => 'Nenhuma';

  @override
  String get hideCompleted => 'Esconder concluídas';

  @override
  String get showCompleted => 'Mostrar concluídas';

  @override
  String get showDetails => 'Mostrar detalhes';

  @override
  String get hideDetails => 'Ocultar Detalhes';

  @override
  String get viewLabel => 'Visualização';

  @override
  String get smartListShow => 'Mostrar';

  @override
  String get smartListHide => 'Esconder';

  @override
  String get smartListShowIfNotEmpty => 'Mostrar se não estiver vazio';

  @override
  String get accountSettings => 'Configurações';

  @override
  String get accountBackup => 'Gerar Backup';

  @override
  String get accountImportBackup => 'Importar backups locais';

  @override
  String get backupSaved => 'Backup salvo';

  @override
  String get backupImported => 'Backup importado. O app vai recarregar os dados.';

  @override
  String get backupImportConfirm => 'Importar este backup substitui todos os dados atuais deste aparelho. Continuar?';

  @override
  String get backupInvalid => 'Arquivo de backup inválido.';

  @override
  String get emptyTrashTooltip => 'Esvaziar lixeira';

  @override
  String get emptyTrashConfirm => 'Excluir definitivamente todas as tarefas da lixeira? Isso não pode ser desfeito.';

  @override
  String get slashText => 'Texto';

  @override
  String get slashHeading1 => 'Título 1';

  @override
  String get slashHeading2 => 'Título 2';

  @override
  String get slashHeading3 => 'Título 3';

  @override
  String get slashBulletedList => 'Lista com marcadores';

  @override
  String get slashNumberedList => 'Lista numerada';

  @override
  String get slashChecklistItem => 'Item de verificação';

  @override
  String get slashQuote => 'Citação';

  @override
  String get slashDivider => 'Linha horizontal';

  @override
  String get pickerTabDate => 'Data';

  @override
  String get pickerTime => 'Hora';

  @override
  String get pickerReminder => 'Lembrete';

  @override
  String get pickerRepeat => 'Repetir';

  @override
  String get pickerNone => 'Nenhuma';

  @override
  String get pickerNextMonth => 'Próximo mês';

  @override
  String get pickerToday => 'Hoje';

  @override
  String get weekInitialSunday => 'D';

  @override
  String get weekInitialMonday => 'S';

  @override
  String get weekInitialTuesday => 'T';

  @override
  String get weekInitialWednesday => 'Q';

  @override
  String get weekInitialThursday => 'Q';

  @override
  String get weekInitialFriday => 'S';

  @override
  String get weekInitialSaturday => 'S';

  @override
  String get repeatDaily => 'Diariamente';

  @override
  String repeatWeekly(String weekday) {
    return 'Semanal ($weekday)';
  }

  @override
  String repeatMonthly(int day) {
    return 'Mensal ($dayº)';
  }

  @override
  String repeatYearly(int day, String month) {
    return 'Anualmente ($dayº $month)';
  }

  @override
  String get repeatWeekdays => 'Todos os dias úteis (Seg-Sex)';

  @override
  String get repeatCustom => 'Personalizado';

  @override
  String get repeatEnds => 'A repetição termina';

  @override
  String get repeatEndsNever => 'Para sempre';

  @override
  String get repeatEndsOnDate => 'Termina na data';

  @override
  String get repeatEndsAfterCount => 'Terminar por uma contagem repetida';

  @override
  String repeatTimesLeft(int count) {
    return 'Em $count tempos';
  }

  @override
  String get repeatTimesHint => 'repetir vezes';

  @override
  String get repeatFromDue => 'Por datas de vencimento';

  @override
  String get repeatFromCompletion => 'Por Data de Conclusão';

  @override
  String get repeatEvery => 'A cada';

  @override
  String get unitDay => 'Dia';

  @override
  String get unitWeek => 'Semana';

  @override
  String get unitMonth => 'Mês';

  @override
  String get unitYear => 'Ano';

  @override
  String get unitMinutes => 'Minutos';

  @override
  String get unitHours => 'Horas';

  @override
  String get unitDays => 'Dias';

  @override
  String get reminderOnTime => 'Na hora';

  @override
  String get reminder5m => '5 minutos antes';

  @override
  String get reminder30m => '30 minutos antes';

  @override
  String get reminder1h => '1 hora antes';

  @override
  String get reminder1d => '1 dia antes';

  @override
  String get reminderOnTheDay => 'No dia (09:00)';

  @override
  String get reminder1dAt9 => '1 dia antes (09:00)';

  @override
  String get reminder2dAt9 => '2 dias antes (09:00)';

  @override
  String get reminder3dAt9 => '3 dias antes (09:00)';

  @override
  String get reminder1wAt9 => '1 semana antes (09:00)';

  @override
  String get reminderCustom => 'Personalizado';

  @override
  String reminderCustomValue(int value, String unit) {
    return '$value $unit antes';
  }

  @override
  String reminderPreview(String time) {
    return 'Lembre-se em $time';
  }

  @override
  String get notificationChannelName => 'Lembretes';

  @override
  String get notificationChannelDescription => 'Lembretes das tarefas';

  @override
  String get notificationActionComplete => 'Concluído';

  @override
  String get notificationActionSnooze => 'Adiar 15 min';

  @override
  String snoozedUntil(String time) {
    return 'adiar até $time';
  }

  @override
  String get reminderPopupSnooze => 'Adiar';

  @override
  String get reminderPopupDone => 'Concluído';

  @override
  String get reminderPopupDismiss => 'Dispensar';

  @override
  String get snooze15m => '15 minutos';

  @override
  String get snooze30m => '30 minutos';

  @override
  String get snooze1h => '1 hora';

  @override
  String get snooze3h => '3 horas';

  @override
  String get snoozeTonight => 'Hoje à noite';

  @override
  String get snoozeTomorrow => 'Amanhã';

  @override
  String get snoozeCustom => 'Personalizado';

  @override
  String get repeatSpecificDates => 'Por datas específicas';

  @override
  String get repeatMonthEach => 'Cada';

  @override
  String get repeatMonthOn => 'No';

  @override
  String get repeatMonthWorkday => 'Dia útil';

  @override
  String get repeatLastDay => 'Último dia';

  @override
  String get ordinalFirst => 'primeiro';

  @override
  String get ordinalSecond => 'segundo';

  @override
  String get ordinalThird => 'terceiro';

  @override
  String get ordinalFourth => 'quarto';

  @override
  String get ordinalLast => 'último';

  @override
  String get workdayFirst => 'Primeiro dia útil';

  @override
  String get workdayLast => 'Último dia útil';

  @override
  String get repeatPickDates => 'Escolha os dias no calendário';

  @override
  String quickAddCreateTag(String name) {
    return 'Criar Tag \'$name\'';
  }

  @override
  String quickAddNextWeekday(String weekday) {
    return 'Próxima $weekday';
  }

  @override
  String get pickerTabDuration => 'Duração';

  @override
  String get pickerStart => 'Início';

  @override
  String get pickerEnd => 'Fim';

  @override
  String get pickerAllDay => 'Dia inteiro';

  @override
  String get viewOptions => 'Visualizar Opções';

  @override
  String get showDateBy => 'Mostrar Data por';

  @override
  String get dateDisplayDate => 'Tempo da tarefa';

  @override
  String get dateDisplayCountdown => 'Contagem regressiva';

  @override
  String countdownInDays(int count) {
    return 'em $count dias';
  }

  @override
  String countdownDaysAgo(int count) {
    return 'há $count dias';
  }

  @override
  String dailyDigestTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Você tem $count tarefas para hoje', one: 'Você tem 1 tarefa para hoje');
    return '$_temp0';
  }

  @override
  String get settingsDailyNotifications => 'Notificações diárias';

  @override
  String get settingsDailyNotificationsHint => 'Um lembrete por dia com as tarefas de hoje';

  @override
  String get settingsDailyAlertTime => 'Horário de Alerta Diário';

  @override
  String get settingsConstantReminder => 'Lembrete Constante Global';

  @override
  String get settingsConstantReminderHint => 'A notificação persiste até você agir';

  @override
  String get checklistItemReminder => 'Lembrete do item';

  @override
  String get shortcutsTitle => 'Atalhos';

  @override
  String get shortcutsGeneral => 'Geral';

  @override
  String get shortcutsTask => 'Tarefa';

  @override
  String get shortcutsEditTask => 'Editar tarefa';

  @override
  String get shortcutsNavigation => 'Navegação';

  @override
  String get shortcutCancel => 'Cancelar';

  @override
  String get shortcutPalette => 'Menu de comandos';

  @override
  String get shortcutList => 'Lista de atalhos';

  @override
  String get shortcutAddTask => 'Adicionar tarefa';

  @override
  String get shortcutAddTaskBelow => 'Adicionar tarefa abaixo';

  @override
  String get shortcutAddSubtask => 'Adicionar subtarefa';

  @override
  String get shortcutToggleSubtasks => 'Expandir/Recolher subtarefas';

  @override
  String get shortcutComplete => 'Concluir';

  @override
  String get shortcutPin => 'Fixar';

  @override
  String get shortcutDelete => 'Excluir';

  @override
  String get shortcutSetDate => 'Definir data';

  @override
  String get shortcutNoDate => 'Sem data';

  @override
  String get shortcutQuickDates => 'Hoje / Amanhã / Próx. semana';

  @override
  String get shortcutPriority => 'Prioridade';

  @override
  String get shortcutSearch => 'Pesquisar';

  @override
  String get shortcutSettings => 'Ir para Configurações';

  @override
  String get shortcutGoSmart => 'Todas / Hoje / Amanhã / Próx. 7 dias';

  @override
  String get shortcutGoInbox => 'Caixa de entrada';

  @override
  String get paletteHint => 'Digite um comando ou pesquise';

  @override
  String get paletteNewTask => 'Nova tarefa';

  @override
  String paletteSearchFor(String term) {
    return 'Buscar \'$term\'';
  }

  @override
  String get searchHint => 'Pesquisar';

  @override
  String get searchTabTask => 'Tarefa';

  @override
  String get searchTabTag => 'Tag';

  @override
  String get searchTabList => 'Lista';

  @override
  String get searchNoResults => 'Nenhum resultado';

  @override
  String get searchNotFound => 'Ainda não encontrou o que procura?';

  @override
  String get searchFullPage => 'Experimente a pesquisa completa.';

  @override
  String get searchLookFor => 'Procurar por';

  @override
  String get searchFilterLists => 'Listas';

  @override
  String get searchFilterTag => 'Tag';

  @override
  String get searchFilterDate => 'Data';

  @override
  String get searchFilterPriority => 'Prioridade';

  @override
  String get searchFilterType => 'Tipo';

  @override
  String get searchFilterStatus => 'Status';

  @override
  String get searchAll => 'Todas';

  @override
  String get searchDateAll => 'Todos';

  @override
  String searchDateThisWeek(String range) {
    return 'Esta semana ($range)';
  }

  @override
  String get searchDateNextWeek => 'Próxima Semana';

  @override
  String get searchDateLastWeek => 'Semana passada';

  @override
  String get searchDateThisMonth => 'Este mês';

  @override
  String get searchDateLastMonth => 'Mês passado';

  @override
  String get searchDateCustom => 'Personalizado';

  @override
  String get searchTypeTask => 'Tarefa';

  @override
  String get searchTypeNote => 'Nota';

  @override
  String get searchStatusOpen => 'Incompleta';

  @override
  String get searchStatusCompleted => 'Concluído';

  @override
  String get searchStatusWontDo => 'Não será feito';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count tarefas', one: '1 tarefa', zero: 'Nenhuma tarefa');
    return '$_temp0';
  }

  @override
  String get quickAddButton => 'Adicionar';

  @override
  String get menuSelect => 'Selecionar';

  @override
  String batchSelected(int count) {
    return 'Você escolheu $count itens';
  }

  @override
  String get batchDueDate => 'Dia do vencimento';

  @override
  String get batchPostpone => 'Atrasar';

  @override
  String get postpone1Day => 'Adiar por 1 dia';

  @override
  String get postpone1Week => 'Adiar por 1 semana';

  @override
  String get postponeCustom => 'Personalizado';

  @override
  String get postponeDaysPrompt => 'Adiar por quantos dias?';

  @override
  String get batchPriority => 'Prioridade';

  @override
  String get batchList => 'Lista';

  @override
  String get batchTags => 'Etiquetas';

  @override
  String get batchComplete => 'Concluído';

  @override
  String get batchPin => 'Fixar';

  @override
  String get batchWontDo => 'Não farei';

  @override
  String get batchLinkParent => 'Vincular Tarefa Pai';

  @override
  String get batchMerge => 'Mesclar';

  @override
  String get batchDuplicate => 'Duplicar';

  @override
  String get batchConvertNote => 'Converter para nota';

  @override
  String get batchCopyText => 'Copiar Texto';

  @override
  String get batchDelete => 'Deletar';

  @override
  String mergeConfirm(int count) {
    return 'Estas $count tarefas serão convertidas em sub-tarefas do novo trabalho combinado.';
  }

  @override
  String get mergedTitle => 'Nova tarefa mesclada.';

  @override
  String get selectAll => 'Selecionar Tudo';

  @override
  String get deselectAll => 'Desmarcar Todos';

  @override
  String get toastCopied => 'Copiado';

  @override
  String get templateSave => 'Salvar como modelo';

  @override
  String get templateSaveHint => 'O conteúdo e as tags serão salvos no modelo.';

  @override
  String get templateNameHint => 'Nome do modelo';

  @override
  String get templateAddFrom => 'Adicionar a partir do modelo';

  @override
  String get templatePickerTitle => 'Modelo de tarefa';

  @override
  String get templateManage => 'Gerenciar modelo';

  @override
  String get templateEmpty => 'Nenhum modelo';

  @override
  String get templateBeforeWorkName => 'Tarefas antes do trabalho';

  @override
  String get templateBeforeWorkItems =>
      'Revisar a agenda do dia\nConferir os e-mails importantes\nDefinir as 3 prioridades do dia\nPreparar os materiais das reuniões\nOrganizar a mesa de trabalho\nAtualizar a lista de tarefas\nBeber um copo de água';

  @override
  String get templateDailyRecordName => 'Daily record';

  @override
  String get templateDailyRecordContent =>
      '**O que eu fiz hoje?**\n\n**O que deu certo?**\n\n**O que posso melhorar amanhã?**\n\n**Pelo que sou grato hoje?**';

  @override
  String get templateTravelName => 'Coisas para embalar para viajar';

  @override
  String get templateTravelItems =>
      'Documentos e passaporte\nCarteira e cartões\nCelular e carregador\nFones de ouvido\nRoupas\nRoupas íntimas e meias\nPijama\nSapatos\nEscova e pasta de dente\nDesodorante\nXampu e condicionador\nRemédios\nProtetor solar\nÓculos\nGuarda-chuva';

  @override
  String get commentsTitle => 'Comentários';

  @override
  String get commentHint => 'Escrever um comentário';

  @override
  String get commentAuthor => 'Você';

  @override
  String get commentJustNow => 'Agora mesmo';

  @override
  String commentMinutesAgo(int count) {
    return 'há $count min';
  }

  @override
  String commentHoursAgo(int count) {
    return 'há $count h';
  }

  @override
  String get commentEdit => 'Editar';

  @override
  String get commentDelete => 'Excluir';

  @override
  String get slashLinkedTask => 'Tarefa/nota vinculada';

  @override
  String get slashAttachment => 'Anexo';

  @override
  String get menuExport => 'Exportar';

  @override
  String get menuPrint => 'Imprimir';

  @override
  String get exportMarkdown => 'Markdown';

  @override
  String get exportPlainText => 'Plain Text';

  @override
  String get exportCopy => 'Copiar';

  @override
  String get exportDownload => 'Baixar';

  @override
  String get navCountdown => 'Contagem Regressiva';

  @override
  String get countdownActive => 'Ativo';

  @override
  String get countdownArchived => 'Arquivado';

  @override
  String get countdownArchivedTitle => 'Contagens Regressivas Arquivadas';

  @override
  String get countdownShowGroup => 'Mostrar Grupo';

  @override
  String get countdownTypeCountdown => 'Contagem Regressiva';

  @override
  String get countdownTypeSpecial => 'Data Especial';

  @override
  String get countdownTypeBirthday => 'Aniversário';

  @override
  String get countdownTypeHoliday => 'Feriado';

  @override
  String countdownToday(String date) {
    return 'Hoje $date';
  }

  @override
  String countdownDaysUntil(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Dias até $date', one: 'Dia até $date');
    return '$_temp0';
  }

  @override
  String countdownDaysSince(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Dias desde $date', one: 'Dia desde $date');
    return '$_temp0';
  }

  @override
  String countdownAge(int age) {
    return '$age anos';
  }

  @override
  String countdownDaysAway(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Em $count dias', one: 'Amanhã', zero: 'Hoje');
    return '$_temp0';
  }

  @override
  String get countdownName => 'Nome';

  @override
  String get countdownDate => 'Data';

  @override
  String get countdownType => 'Tipo';

  @override
  String get countdownCountMode => 'Modo de Cálculo de Dias';

  @override
  String get countModeStandard => 'Padrão';

  @override
  String get countModeStandardHint => 'O Dia 1 começa no dia seguinte à data selecionada';

  @override
  String get countModePlusOne => 'Padrão +1 dia';

  @override
  String get countModePlusOneHint => 'O Dia 1 começa na data selecionada';

  @override
  String get countdownVisibility => 'Mostrar na Lista Inteligente';

  @override
  String get visibilityOnTheDay => 'No dia';

  @override
  String get visibilityThreeDays => '3 dias de antecedência';

  @override
  String get visibilitySevenDays => '7 dias de antecedência';

  @override
  String get visibilityAlways => 'Sempre mostrar';

  @override
  String get visibilityNever => 'Não mostrar';

  @override
  String get countdownIgnoreYear => 'Ignorar ano';

  @override
  String get countdownShowAge => 'Mostrar idade';

  @override
  String get actionNext => 'Próximo';

  @override
  String get actionBack => 'Voltar';

  @override
  String get countdownStyle => 'Estilo';

  @override
  String get countdownColor => 'Cor';

  @override
  String get countdownEdit => 'Editar';

  @override
  String get countdownNotes => 'Notas';

  @override
  String get countdownArchive => 'Arquivar';

  @override
  String get countdownRestore => 'Restaurar';

  @override
  String get countdownDelete => 'Deletar';

  @override
  String get countdownPin => 'Fixar';

  @override
  String get countdownUnpin => 'Desafixar';

  @override
  String get countdownEmpty => 'Nenhuma contagem regressiva';

  @override
  String get countdownSeedUseApp => 'Use o Tarefas';

  @override
  String get countdownSeedWeekend => 'Fim de semana';

  @override
  String get countdownSeedNewYear => 'Dia de Ano Novo';

  @override
  String get countdownSpecialSuggestions =>
      'Aniversário de Graduação\nAniversário de Trabalho\nAniversário de Namoro\nDia do Pedido de Casamento\nDia da Licença de Casamento\nAniversário de Casamento\n100 Dias Juntos\nAniversário de Matrícula';

  @override
  String get navFocus => 'Foco';

  @override
  String get focusTitle => 'Pomodoro';

  @override
  String get focusTabPomo => 'Pomo';

  @override
  String get focusTabStopwatch => 'Cronômetro';

  @override
  String get focusLink => 'Foco';

  @override
  String get focusStart => 'Começar';

  @override
  String get focusPause => 'Pausar';

  @override
  String get focusContinue => 'Continuar';

  @override
  String get focusEnd => 'Fim';

  @override
  String get focusPaused => 'Pausado';

  @override
  String get focusNotes => 'Foco em Notas';

  @override
  String get focusNotesHint => 'O que você tem em mente? Registre suas ideias…';

  @override
  String get focusDoneTitle => 'Você tem um Pomo.';

  @override
  String focusDoneBody(int minutes) {
    return 'Descanse por $minutes minutos.';
  }

  @override
  String get focusRelax => 'Relaxar';

  @override
  String get focusSkip => 'Pular';

  @override
  String get focusExit => 'Sair';

  @override
  String get focusBreak => 'Pausa';

  @override
  String get focusLongBreak => 'Pausa longa';

  @override
  String get focusOverview => 'Visão geral';

  @override
  String get focusTodayPomos => 'Pomo de hoje';

  @override
  String get focusTodayDuration => 'Foco de hoje';

  @override
  String get focusTotalPomos => 'Pomo Total';

  @override
  String get focusTotalDuration => 'Duração Total Focada';

  @override
  String get focusRecords => 'Foco em registro.';

  @override
  String get focusRecordsEmpty => 'Ainda não há registro de foco.';

  @override
  String get focusDeleteAll => 'Excluir tudo';

  @override
  String get focusAddRecord => 'Adicionar registro';

  @override
  String get focusSettings => 'Configurações de foco';

  @override
  String get focusPomoLength => 'Duração do Pomo';

  @override
  String get focusShortBreakLength => 'Duração da Pausa Curta';

  @override
  String get focusLongBreakLength => 'Duração da Pausa Longa';

  @override
  String get focusLongEvery => 'Pomos para intervalo longo';

  @override
  String get focusAutoPomo => 'Início automático: Próximo Pomo';

  @override
  String get focusAutoBreak => 'Início automático: Pausa';

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
  String get focusStartFocus => 'Começar o foco';

  @override
  String get focusStartPomo => 'Comece Pomo';

  @override
  String get focusStartStopwatch => 'Iniciar cronômetro';

  @override
  String get focusRecordStart => 'Início';

  @override
  String get focusRecordEnd => 'Fim';

  @override
  String get focusNoTask => 'Sem tarefa';

  @override
  String get navHabit => 'Hábito';

  @override
  String get habitActive => 'Ativo';

  @override
  String get habitArchived => 'Arquivado';

  @override
  String get habitEmptyTitle => 'Desenvolver um hábito';

  @override
  String get habitEmptyBody => 'A perseverança nos faz brilhar';

  @override
  String get habitArchivedEmptyTitle => 'Nenhum hábito arquivado';

  @override
  String get habitArchivedEmptyBody => 'Você pode arquivar os hábitos e restaurá-los posteriormente.';

  @override
  String get habitNew => 'Criar Hábito';

  @override
  String get habitEditTitle => 'Editar hábito';

  @override
  String get habitNameHint => 'Check-in diário';

  @override
  String get habitFrequency => 'Frequência';

  @override
  String get habitDaily => 'Diariamente';

  @override
  String get habitWeekly => 'Semanal';

  @override
  String get habitInterval => 'Repetir';

  @override
  String habitTimesPerWeek(int count) {
    return '$count vezes por semana';
  }

  @override
  String habitEveryDays(int count) {
    return 'A cada $count dias';
  }

  @override
  String get habitGoal => 'Objetivo';

  @override
  String get habitGoalAll => 'Conquiste tudo';

  @override
  String get habitGoalAmount => 'Atingir uma certa quantia';

  @override
  String get habitUnit => 'Unidade';

  @override
  String get habitUnitDefault => 'Contagem';

  @override
  String get habitPerDay => 'Por dia';

  @override
  String get habitStep => 'Recorde (Contagem)';

  @override
  String get habitCheckMode => 'Ao verificar';

  @override
  String get habitCheckAuto => 'Automático';

  @override
  String get habitCheckManual => 'Manual';

  @override
  String get habitCheckAll => 'Complete todos';

  @override
  String get habitStartDate => 'Data de início';

  @override
  String get habitTargetDays => 'Dias de meta';

  @override
  String get habitForever => 'Para sempre';

  @override
  String habitDaysValue(int count) {
    return '$count dias';
  }

  @override
  String get habitSection => 'Seção';

  @override
  String get habitSectionMorning => 'Manhã';

  @override
  String get habitSectionAfternoon => 'Tarde';

  @override
  String get habitSectionEvening => 'Noite';

  @override
  String get habitSectionOthers => 'Outros';

  @override
  String get habitReminder => 'Lembrete';

  @override
  String get habitAutoLog => 'Auto exibição do registro de hábito';

  @override
  String habitSummary(int total, int streak) {
    String _temp0 = intl.Intl.pluralLogic(total, locale: localeName, other: '$total dias', one: '1 dia', zero: '0 dia');
    String _temp1 = intl.Intl.pluralLogic(streak, locale: localeName, other: '$streak dias', one: '1 dia', zero: '0 dia');
    return '$_temp0 · $_temp1';
  }

  @override
  String get habitLog => 'Registro de hábitos';

  @override
  String get habitReset => 'Reiniciar hábito';

  @override
  String get habitSkip => 'Pular';

  @override
  String get habitFail => 'Incompleta';

  @override
  String get habitLogPrompt => 'Check-in realizado! O que você tem em mente?';

  @override
  String get habitArchive => 'Arquivar';

  @override
  String get habitRestore => 'Adquira o hábito';

  @override
  String get toastRestoredHabit => 'Pegou';

  @override
  String get habitDelete => 'Deletar';

  @override
  String get habitMonthRecords => 'Registros mensais';

  @override
  String get habitTotalCheckins => 'Total de check-ins';

  @override
  String get habitMonthRate => 'Taxa de check-in mensal';

  @override
  String get habitStreak => 'Sequência atual';

  @override
  String habitMonthLog(String month) {
    return 'Log de hábito em $month';
  }

  @override
  String get habitMonthLogEmpty => 'Ainda não há pensamentos de check-in para compartilhar este mês';

  @override
  String get habitIncrease => 'Aumentar';

  @override
  String get habitSettings => 'Configurações';

  @override
  String get habitShowInToday => 'Mostrar em \"Hoje\" e \"Próximos 7 dias\"';

  @override
  String get habitSortByStatus => 'Classificar por status de check-in';

  @override
  String get habitFreeDay => 'Essa data está livre de tarefas';

  @override
  String habitAmount(String value, String goal, String unit) {
    return '$value/$goal $unit';
  }

  @override
  String get habitDetailClose => 'Fechar';

  @override
  String get navMatrix => 'Matriz de Eisenhower';

  @override
  String get matrixQ1 => 'Urgente e Importante';

  @override
  String get matrixQ2 => 'Não Urgente e Importante';

  @override
  String get matrixQ3 => 'Urgente e não importante';

  @override
  String get matrixQ4 => 'Não urgente e não importante';

  @override
  String get matrixEditTitle => 'Editar Matriz';

  @override
  String get matrixRestore => 'Restaurar';

  @override
  String get matrixHideCompleted => 'Esconder concluídas';

  @override
  String get matrixShowCompleted => 'Mostrar concluídas';

  @override
  String get matrixAll => 'Todas';

  @override
  String get matrixName => 'Nome';

  @override
  String get filterAddTitle => 'Adicionar Filtro';

  @override
  String get filterEditTitle => 'Editar Filtro';

  @override
  String get filterName => 'Nome';

  @override
  String get filterNormal => 'Normal';

  @override
  String get filterAdvanced => 'Avançado';

  @override
  String get filterFieldList => 'Listas';

  @override
  String get filterFieldTag => 'Tags';

  @override
  String get filterFieldDate => 'Data';

  @override
  String get filterFieldPriority => 'Prioridade';

  @override
  String get filterFieldType => 'Tipo';

  @override
  String get filterKeyword => 'Palavra-chave';

  @override
  String get filterKeywordHint => 'Título ou descrição contém';

  @override
  String get filterIs => 'é';

  @override
  String get filterIsNot => 'não é';

  @override
  String get filterAnd => 'E';

  @override
  String get filterOr => 'OU';

  @override
  String get filterAddCondition => 'Adicionar condição';

  @override
  String get filterPreview => 'Prévia';

  @override
  String filterPreviewCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarefas encontradas',
      one: '1 tarefa encontrada',
      zero: 'Nenhuma tarefa encontrada',
    );
    return '$_temp0';
  }

  @override
  String get filterDateOverdue => 'Atrasadas';

  @override
  String get filterDateToday => 'Hoje';

  @override
  String get filterDateTomorrow => 'Amanhã';

  @override
  String get filterDateThisWeek => 'Esta semana';

  @override
  String get filterDateNextWeek => 'Próxima semana';

  @override
  String get filterDateThisMonth => 'Este mês';

  @override
  String get filterDateNextMonth => 'Próximo mês';

  @override
  String get filterDateNoDate => 'Sem data';

  @override
  String get filterSaveAs => 'Salvar como filtro';

  @override
  String filterDeleteConfirm(Object name) {
    return 'Excluir o filtro \"$name\"? As tarefas não serão afetadas.';
  }

  @override
  String filterSaved(Object name) {
    return 'Filtro \"$name\" criado';
  }

  @override
  String get navCalendar => 'Calendário';

  @override
  String get calendarModeDay => 'Dia';

  @override
  String get calendarModeWeek => 'Semana';

  @override
  String get calendarModeMonth => 'Mês';

  @override
  String get calendarModeYear => 'Ano';

  @override
  String get calendarModeAgenda => 'Agenda';

  @override
  String get calendarModeMultiDay => 'Multi-Dia';

  @override
  String get calendarModeMultiWeek => 'Multi-Semana';

  @override
  String get calendarToday => 'Hoje';

  @override
  String get calendarAllDay => 'Dia inteiro';

  @override
  String get calendarNoon => 'Meio-dia';

  @override
  String get calendarArrange => 'Organizar tarefas';

  @override
  String get calendarArrangeHint => 'Arraste as tarefas sem data para o calendário.';

  @override
  String get calendarArrangeEmpty => 'Nenhuma tarefa sem data';

  @override
  String get calendarViewOptions => 'Opções de visualização';

  @override
  String get calendarShowCompleted => 'Mostrar concluídas';

  @override
  String get calendarShowChecklist => 'Mostrar itens de checklist';

  @override
  String get calendarShowRepeats => 'Mostrar ciclos futuros';

  @override
  String get calendarShowHabits => 'Mostrar hábitos';

  @override
  String get calendarShowFocus => 'Mostrar registros de foco';

  @override
  String get calendarShowCountdowns => 'Mostrar contagem regressiva';

  @override
  String get calendarColorBy => 'Cor por';

  @override
  String get calendarColorByList => 'Lista';

  @override
  String get calendarColorByTag => 'Tag';

  @override
  String get calendarColorByPriority => 'Prioridade';

  @override
  String calendarMultiDays(Object count) {
    return '$count dias';
  }

  @override
  String calendarMultiWeeks(Object count) {
    return '$count Semanas';
  }

  @override
  String get calendarListFilter => 'Filtro de listas';

  @override
  String get calendarAgendaEmpty => 'Nenhuma tarefa neste período';

  @override
  String get calendarFocusRecord => 'Foco';

  @override
  String calendarMore(Object count) {
    return '+$count';
  }

  @override
  String get timelineEmpty => 'Nenhuma tarefa com data.\nClique na régua para criar uma ou arraste do painel \"Organizar tarefas\".';

  @override
  String get timelineArrangeHint => 'Tarefas sem data. Arraste para a régua.';

  @override
  String get shortcutViews => 'Visualização Lista / Kanban / Linha do tempo';

  @override
  String get shortcutCalendarModes => 'Calendário: Dia / Semana / Mês / Ano / Agenda';

  @override
  String get activityTaskTitle => 'Atividades da tarefa';

  @override
  String get activityListTitleDialog => 'Atividades da lista';

  @override
  String get activityEmpty => 'Nenhuma atividade ainda';

  @override
  String get activityCreated => 'Você criou a tarefa';

  @override
  String get activityCompleted => 'Você concluiu a tarefa';

  @override
  String get activityReopened => 'Você reabriu a tarefa';

  @override
  String get activityWontDo => 'Você marcou a tarefa como Não farei';

  @override
  String get activityDeleted => 'Você moveu a tarefa para a Lixeira';

  @override
  String get activityRestored => 'Você restaurou a tarefa';

  @override
  String activityTitle(Object title) {
    return 'Você mudou o título para \"$title\"';
  }

  @override
  String get activityContent => 'Você editou a descrição';

  @override
  String activityDate(Object date) {
    return 'Você mudou a data para $date';
  }

  @override
  String get activityDateRemoved => 'Você removeu a data';

  @override
  String activityPriority(Object priority) {
    return 'Você mudou a prioridade para $priority';
  }

  @override
  String activityMoved(Object list) {
    return 'Você moveu a tarefa para $list';
  }

  @override
  String get activityRepeat => 'Você mudou a repetição';

  @override
  String get activityRepeatRemoved => 'Você removeu a repetição';

  @override
  String get activityListCreated => 'Você criou a lista';

  @override
  String activityListTitle(Object name) {
    return 'Você renomeou a lista para \"$name\"';
  }

  @override
  String get matrixGroupBy => 'Agrupar por';

  @override
  String get matrixSortBy => 'Ordenar por';

  @override
  String get matrixOrder => 'Ordem';

  @override
  String get matrixByTime => 'Tempo';

  @override
  String get matrixByList => 'Lista';

  @override
  String get matrixByPriority => 'Prioridade';

  @override
  String get matrixByTag => 'Tag';

  @override
  String get matrixByTitle => 'Título';

  @override
  String get matrixByNone => 'Nenhum';

  @override
  String get matrixAscending => 'Crescente';

  @override
  String get matrixDescending => 'Decrescente';

  @override
  String get statsTitle => 'Estatísticas';

  @override
  String get statsOverview => 'Visão geral';

  @override
  String get statsTask => 'Tarefa';

  @override
  String get statsFocus => 'Foco';

  @override
  String get statsDone => 'Concluído';

  @override
  String get statsTasksLabel => 'Tarefas';

  @override
  String get statsCompletedLabel => 'Concluído';

  @override
  String get statsListsLabel => 'Listas';

  @override
  String get statsDaysLabel => 'Dias';

  @override
  String get statsTodayCompletion => 'Conclusão de Hoje';

  @override
  String get statsTotalCompletion => 'Conclusão Total';

  @override
  String get statsAchievement => 'Minha pontuação de conquista';

  @override
  String statsLevel(Object level) {
    return 'Nível $level';
  }

  @override
  String statsNextLevel(Object level, Object points) {
    return 'Faltam $points pontos para o Nível $level';
  }

  @override
  String get statsTopLevel => 'Nível máximo';

  @override
  String get statsCompletionCurve => 'Curva de conclusão recente';

  @override
  String get statsRateCurve => 'Curva de taxa de conclusão recente';

  @override
  String get statsPomoCurve => 'Curva Pomo recente';

  @override
  String get statsFocusCurve => 'Curva de duração de foco recente';

  @override
  String get statsHabitsWeek => 'Status semanal dos hábitos';

  @override
  String get statsNoHabits => 'Nenhum hábito ainda';

  @override
  String get statsDaily => 'Diariamente';

  @override
  String get statsWeekly => 'Semanalmente';

  @override
  String get statsMonthly => 'Mensalmente';

  @override
  String get statsTaskCompleted => 'Tarefa Concluída';

  @override
  String get statsRate => 'Taxa de Realização';

  @override
  String get statsVsDay => 'vs ontem';

  @override
  String get statsVsWeek => 'vs semana passada';

  @override
  String get statsVsMonth => 'vs mês passado';

  @override
  String get statsDistribution => 'Distribuição da taxa de conclusão';

  @override
  String get statsOnTime => 'Concluídas no prazo';

  @override
  String get statsLate => 'Concluídas com atraso';

  @override
  String get statsUndone => 'Não concluídas';

  @override
  String get statsByCategory => 'Estatísticas de conclusão';

  @override
  String get statsByList => 'Lista';

  @override
  String get statsByTag => 'Tag';

  @override
  String get statsByPriority => 'Prioridade';

  @override
  String get statsByTask => 'Tarefa';

  @override
  String get statsFocusDetails => 'Detalhes';

  @override
  String get statsUnlinked => 'Sem vínculo';

  @override
  String get statsTrends => 'Tendências';

  @override
  String statsDailyAverage(Object value) {
    return 'Média diária: $value';
  }

  @override
  String get statsWeekTimeline => 'Linha do Tempo';

  @override
  String get statsMostFocused => 'Tempo mais concentrado';

  @override
  String get statsYearGrid => 'Grade anual';

  @override
  String get statsNoData => 'Sem dados neste período';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsAccount => 'Conta';

  @override
  String get settingsFeatures => 'Funcionalidades';

  @override
  String get settingsSmartLists => 'Lista inteligente';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsLocalAccount => 'Conta local';

  @override
  String get settingsLocalAccountHint => 'Seus dados ficam só neste aparelho, sem conta nem servidor.';

  @override
  String get settingsBackup => 'Backup & Recuperação';

  @override
  String get settingsBackupGenerate => 'Gerar Backup';

  @override
  String get settingsBackupImport => 'Importar backups locais';

  @override
  String get featureHabitSettings => 'Configurações de hábitos';

  @override
  String get featureCalendarHint => 'Seis visualizações de calendário';

  @override
  String get featureMatrixHint => 'Organize por importante e urgente';

  @override
  String get featureHabitHint => 'Crie e acompanhe hábitos';

  @override
  String get featureFocus => 'Pomodoro';

  @override
  String get featureFocusHint => 'Temporizador Pomo ou cronômetro';

  @override
  String get featureCountdownHint => 'Lembre-se de cada dia especial';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeSystem => 'Seguir o modo escuro do sistema';

  @override
  String get settingsColorSeries => 'Série de Cores';

  @override
  String get colorStandard => 'Padrão';

  @override
  String get colorSky => 'Céu';

  @override
  String get colorTurquoise => 'Turquesa';

  @override
  String get colorTeal => 'Azul teal';

  @override
  String get colorReed => 'Junco';

  @override
  String get colorYellow => 'Amarelo';

  @override
  String get colorPinkPear => 'Rosa Pêra';

  @override
  String get colorLilac => 'Lilás';

  @override
  String get colorEbony => 'Ébano';

  @override
  String get colorNavy => 'Azul Escuro';

  @override
  String get colorGrey => 'Cinza';

  @override
  String get settingsDisplay => 'Exibição';

  @override
  String get settingsSidebarCount => 'Contagem na barra lateral';

  @override
  String get sidebarCountAll => 'Mostrar (Tudo)';

  @override
  String get sidebarCountHideNotes => 'Mostrar (Ocultar Nota)';

  @override
  String get sidebarCountNone => 'Ocultar (Tudo)';

  @override
  String get settingsCompletedStyle => 'Estilo de Tarefa Concluída';

  @override
  String get completedStyleDefault => 'Padrão';

  @override
  String get completedStyleStrike => 'Rasurado';

  @override
  String aboutVersion(Object version) {
    return 'Versão $version';
  }

  @override
  String get aboutText =>
      'Tarefas é um clone pessoal do TickTick, feito em Flutter para Windows e Android. Tudo fica salvo neste aparelho; use Gerar Backup para levar seus dados para outro lugar.';

  @override
  String get settingsMore => 'Mais configurações';

  @override
  String get settingsSmartRecognition => 'Reconhecimento Inteligente';

  @override
  String get settingsRecognizeDates => 'Reconhecimento de Data';

  @override
  String get settingsRecognizeDatesHint => 'Detecta a data e a hora no título e as usa na tarefa';

  @override
  String get settingsRemoveDateText => 'Remover textos nas tarefas';

  @override
  String get settingsRemoveDateTextHint => 'Tira do título a data reconhecida';

  @override
  String get settingsTagRecognition => 'Reconhecimento de tag';

  @override
  String get tagTextRemove => 'Remover do título';

  @override
  String get tagTextKeep => 'Manter no título';

  @override
  String get settingsTaskDefaults => 'Padrão de Tarefas';

  @override
  String get settingsDefaultDate => 'Data padrão';

  @override
  String get defaultDateNone => 'Nenhuma';

  @override
  String get defaultDateDayAfter => 'Depois de amanhã';

  @override
  String get settingsDefaultTimedReminder => 'Lembrete padrão, tarefa com hora';

  @override
  String get settingsDefaultAllDayReminder => 'Lembrete padrão, tarefa de dia inteiro';

  @override
  String get reminderNoneOption => 'Nenhum';

  @override
  String get settingsDefaultPriority => 'Prioridade padrão';

  @override
  String get settingsDefaultList => 'Lista padrão';

  @override
  String get settingsNewTaskPosition => 'Adicionar nova tarefa';

  @override
  String get positionTopOfList => 'Topo da lista';

  @override
  String get positionEndOfList => 'Fim da lista';

  @override
  String get settingsOverduePosition => 'Posição da seção \"Atrasadas\"';

  @override
  String get positionTop => 'Topo';

  @override
  String get positionEnd => 'Fim';

  @override
  String get settingsResetDefaults => 'Redefinir padrão';

  @override
  String get settingsTemplates => 'Modelos de tarefa';

  @override
  String get settingsTemplatesHint => 'Escolha um modelo para criar uma tarefa na lista padrão';

  @override
  String get settingsDateTime => 'Data e hora';

  @override
  String get settingsTimeFormat => 'Formato da hora';

  @override
  String get timeFormat24 => '24 horas (13:00)';

  @override
  String get timeFormat12 => '12 horas (1:00 PM)';

  @override
  String get settingsWeekStart => 'Dia de início da semana';

  @override
  String get settingsWeekNumbers => 'Mostrar números da semana';

  @override
  String get settingsWeekNumbersHint => 'No Mês e na Multi-Semana do Calendário';

  @override
  String weekNumber(Object number) {
    return 'S$number';
  }

  @override
  String get settingsShortcuts => 'Atalhos';

  @override
  String get shortcutFocusToggle => 'Iniciar/Pausar foco';

  @override
  String get smartSummary => 'Resumo';

  @override
  String get summaryEmpty => 'Nenhuma tarefa pode ser encontrada com os filtros atuais.';

  @override
  String get summaryCompleted => 'Concluído';

  @override
  String get summaryWontDo => 'Não será feito';

  @override
  String get summaryInProgress => 'Em andamento';

  @override
  String get summaryUndone => 'Desfeito';

  @override
  String get summaryIncomplete => 'Incompleta';

  @override
  String get summaryNotCompleted => 'Não concluídas';

  @override
  String summaryParent(Object title) {
    return 'em $title';
  }

  @override
  String get summaryTemplates => 'Modelo';

  @override
  String get summarySaveTemplate => 'Salvar como modelo';

  @override
  String get summaryTemplateName => 'Nome do modelo';

  @override
  String get summaryFilter => 'Filtro';

  @override
  String get summaryDisplay => 'Opções de Exibição';

  @override
  String get summaryByStatus => 'Por Status de Conclusão';

  @override
  String get summaryByList => 'Por lista';

  @override
  String get summaryByCompletionDate => 'Por Data de Conclusão';

  @override
  String get summaryByTaskDate => 'Por Data da Tarefa';

  @override
  String get summaryByTag => 'Por Tag';

  @override
  String get summaryByPriority => 'Por Prioridade';

  @override
  String get summaryFieldStatus => 'Status';

  @override
  String get summaryFieldProgress => 'Progresso';

  @override
  String get summaryFieldCompletionTime => 'Tempo de conclusão';

  @override
  String get summaryFieldTaskTime => 'Tempo da tarefa';

  @override
  String get summaryFieldParent => 'Tarefa Pai';

  @override
  String get summaryFieldTag => 'Tag';

  @override
  String get summaryFieldList => 'Lista';

  @override
  String get summaryFieldDetail => 'Detalhe';

  @override
  String get summaryNextPeriod => 'Tarefas do Próximo Período';

  @override
  String get summaryCopy => 'Copiar';

  @override
  String get summarySavePdf => 'Salvar como PDF';

  @override
  String get shortcutGoClosed => 'Concluído / Não será feito / Resumo / Lixeira';

  @override
  String get habitExport => 'Exportar';

  @override
  String get habitExported => 'Hábitos exportados';

  @override
  String get habitExportHabit => 'Hábito';

  @override
  String get habitExportDate => 'Data';

  @override
  String get habitExportValue => 'Valor';

  @override
  String get habitExportGoal => 'Meta';

  @override
  String get habitExportUnit => 'Unidade';

  @override
  String get habitExportStatus => 'Status';

  @override
  String get habitExportMood => 'Humor';

  @override
  String get habitExportNote => 'Nota';

  @override
  String get habitExportDone => 'Concluído';

  @override
  String get habitExportPartial => 'Parcial';

  @override
  String get habitExportSkipped => 'Pulado';

  @override
  String get habitExportFailed => 'Não alcançado';

  @override
  String get focusLinkTask => 'Escolher tarefa…';

  @override
  String get focusUnlink => 'Remover vínculo';

  @override
  String get focusTimers => 'Timers';

  @override
  String get focusTimersEmpty => 'Crie atalhos de foco com nome, modo e duração.';

  @override
  String get focusTimerAdd => 'Adicionar temporizador';

  @override
  String get focusTimerEdit => 'Editar timer';

  @override
  String get focusTimerName => 'Nome do timer';

  @override
  String focusTimerTotal(Object duration) {
    return 'Total $duration';
  }

  @override
  String get settingsImports => 'Integrações e Importação';

  @override
  String get importSection => 'Importar';

  @override
  String get importTickTick => 'Backup do TickTick (.csv)';

  @override
  String get importTickTickHint =>
      'No TickTick: Configurações → Conta → Backup & Recuperação → Gerar Backup. Traz pastas, listas, seções, tags, subtarefas, checklists e concluídas.';

  @override
  String get importIcal => 'Arquivo iCal (.ics)';

  @override
  String get importIcalHint => 'Tarefas (VTODO) e eventos (VEVENT) viram tarefas, com datas, alarmes, repetição e categorias como tags.';

  @override
  String get importIcalList => 'Importar para Lista';

  @override
  String importConfirm(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Importar $count tarefas?', one: 'Importar 1 tarefa?');
    return '$_temp0';
  }

  @override
  String get importAction => 'Importar';

  @override
  String importDone(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count tarefas importadas', one: '1 tarefa importada');
    return '$_temp0';
  }

  @override
  String get importNothing => 'Nenhuma tarefa encontrada no arquivo';

  @override
  String get importInvalidBackup => 'Este arquivo não parece um backup do TickTick';

  @override
  String get importInvalidIcal => 'Este arquivo não parece um calendário iCal';

  @override
  String get subscriptionsTitle => 'Calendários assinados';

  @override
  String get subscriptionHolidaysName => 'Feriados do Brasil';

  @override
  String get subscriptionHolidaysHint => 'Feriados nacionais e pontos facultativos, calculados no aparelho';

  @override
  String get subscriptionAddHolidays => 'Adicionar feriados do Brasil';

  @override
  String get subscriptionAddUrl => 'Assinar por URL (.ics)';

  @override
  String get subscriptionUrl => 'Endereço do calendário';

  @override
  String get subscriptionName => 'Nome';

  @override
  String get subscriptionSubscribe => 'Assinar';

  @override
  String get subscriptionAdded => 'Calendário assinado';

  @override
  String get subscriptionUpdated => 'Calendário atualizado';

  @override
  String get subscriptionFailed => 'Não foi possível baixar o calendário';

  @override
  String get subscriptionRefresh => 'Atualizar';

  @override
  String get subscriptionNeverFetched => 'Ainda não baixado';

  @override
  String subscriptionFetched(Object when) {
    return 'Atualizado: $when';
  }

  @override
  String get emojiSearch => 'Buscar emoji';

  @override
  String get emojiPeople => 'Pessoas e Corpo';

  @override
  String get emojiNature => 'Natureza';

  @override
  String get emojiFood => 'Comida';

  @override
  String get emojiActivities => 'Atividades';

  @override
  String get emojiTravel => 'Viagem';

  @override
  String get emojiObjects => 'Objetos';

  @override
  String get emojiSymbols => 'Símbolos';

  @override
  String get emojiFlags => 'Bandeiras';

  @override
  String get emojiResults => 'Resultados';

  @override
  String get emojiRandom => 'Aleatório';

  @override
  String get emojiReset => 'Redefinir';

  @override
  String shortcutGoTo(Object name) {
    return 'Ir para $name';
  }

  @override
  String shortcutViewAs(Object name) {
    return 'Visualização $name';
  }

  @override
  String get shortcutNone => 'Sem atalho';

  @override
  String get shortcutEditHint => 'Clique numa ação para trocar o atalho.';

  @override
  String get shortcutRestoreAll => 'Restaurar';

  @override
  String shortcutRecordTitle(Object name) {
    return 'Atalho: $name';
  }

  @override
  String get shortcutRecordHint => 'Pressione as teclas (segure Tab para Tab+tecla). Esc cancela.';

  @override
  String get shortcutSequence => 'Duas teclas em sequência (ex.: G → T)';

  @override
  String get shortcutRemove => 'Remover';

  @override
  String shortcutConflict(Object name) {
    return 'O atalho saiu de \"$name\"';
  }

  @override
  String get searchInArchived => 'Pesquisar em Arquivados';

  @override
  String get searchActiveLists => 'Voltar às listas ativas';

  @override
  String searchArchivedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados nas listas arquivadas',
      one: '1 resultado nas listas arquivadas',
      zero: 'Nenhum resultado nas listas arquivadas',
    );
    return '$_temp0';
  }

  @override
  String get activityPinned => 'Você fixou a tarefa';

  @override
  String get activityUnpinned => 'Você desafixou a tarefa';

  @override
  String activityParent(Object title) {
    return 'Você colocou a tarefa dentro de \"$title\"';
  }

  @override
  String get activityParentRemoved => 'Você tirou a tarefa de dentro da tarefa-pai';

  @override
  String activityTags(Object tags) {
    return 'Você mudou as tags para $tags';
  }

  @override
  String get activityTagsRemoved => 'Você tirou as tags';

  @override
  String countdownUnitWeeks(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'semanas', one: 'semana');
    return '$_temp0';
  }

  @override
  String countdownUnitMonths(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'meses', one: 'mês');
    return '$_temp0';
  }

  @override
  String countdownUnitYears(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'anos', one: 'ano');
    return '$_temp0';
  }

  @override
  String get countdownIcon => 'Ícone';

  @override
  String get countdownImage => 'Imagem de fundo';

  @override
  String get countdownImagePick => 'Escolher imagem';

  @override
  String get countdownImageRemove => 'Remover imagem';

  @override
  String get colorCustom => 'Cor personalizada';

  @override
  String get colorHue => 'Tom';

  @override
  String get colorLightness => 'Luz';

  @override
  String get summarySaveImage => 'Salvar como Imagem';

  @override
  String get summaryImageSaved => 'Imagem salva';

  @override
  String get reminderAtEnd => 'No fim';

  @override
  String get settingsDefaultDuration => 'Duração padrão, tarefa com hora';

  @override
  String get settingsListColor => 'Cor da Lista';

  @override
  String get calendarShowLists => 'Mostrar listas ao lado';

  @override
  String get statsMedals => 'Medalhas';

  @override
  String get medalPerseverance => 'Perseverança';

  @override
  String get medalGetThingsDone => 'Get Things Done';

  @override
  String get medalMindfulness => 'Mindfulness';

  @override
  String get medalSelfDiscipline => 'Autodisciplina';

  @override
  String get medalLocked => 'Bloqueada';

  @override
  String get medalMinutes => 'min de foco';

  @override
  String get medalCheckins => 'check-ins';

  @override
  String get focusLess5 => '−5 minutos';

  @override
  String get focusMore5 => '+5 minutos';

  @override
  String get focusExtraTime => 'Adicionar tempo extra';

  @override
  String get focusEditDuration => 'Editar duração do foco';

  @override
  String get focusMinutesSuffix => 'minutos';

  @override
  String get calendarStyle => 'Estilo';

  @override
  String get calendarStyleModern => 'Moderno';

  @override
  String get calendarStyleClassic => 'Clássico';

  @override
  String get calendarShowIcons => 'Mostrar ícones';

  @override
  String get calendarTimeZones => 'Fusos adicionais';

  @override
  String get calendarAddTimeZone => 'Adicionar fuso horário';

  @override
  String get calendarSearchTimeZone => 'Buscar cidade ou fuso';

  @override
  String get summaryFieldFocus => 'Dados de foco';

  @override
  String get summarySendEmail => 'Enviar email';

  @override
  String get summaryNoMailApp => 'Nenhum app de email encontrado. O texto foi copiado.';

  @override
  String get settingsTimeZone => 'Fuso horário';

  @override
  String get settingsTimeZoneHint => 'Escolher o fuso ao definir a hora da tarefa';

  @override
  String get pickerTimeZone => 'Fuso horário';

  @override
  String get zoneFixed => 'Fuso horário fixo';

  @override
  String get zoneChoose => 'Escolher';

  @override
  String get zoneFloating => 'Tempo flutuante';

  @override
  String get zoneFloatingHint => 'Quando o fuso horário muda, o tempo permanece o mesmo.';

  @override
  String get focusEstimate => 'Estimativa';

  @override
  String get estimatePomos => 'Pomo Estimado';

  @override
  String get estimateDuration => 'Duração estimada';

  @override
  String estimatePomoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Pomos', one: '1 Pomo');
    return '$_temp0';
  }

  @override
  String get estimateFocused => 'Focado em';

  @override
  String get focusFocusing => 'Focando';

  @override
  String get focusTimersArchivedEmpty => 'Nenhum timer arquivado';

  @override
  String get focusSound => 'Som do Pomo';

  @override
  String get focusSoundStandard => 'Padrão';

  @override
  String get focusSoundAlarm => 'Despertador';

  @override
  String get focusSoundReminder => 'Lembrete';

  @override
  String get focusSoundMessage => 'Mensagem';

  @override
  String get focusSoundSilent => 'Silencioso';

  @override
  String get notificationSilentChannelName => 'Fim do Pomo silencioso';

  @override
  String get focusTimeInTitle => 'Tempo de execução no título da janela';

  @override
  String get sectionInsertAbove => 'Inserir seção acima';

  @override
  String get sectionInsertBelow => 'Inserir seção abaixo';

  @override
  String get slashSubtask => 'Subtarefa';

  @override
  String get slashTag => 'Tag';

  @override
  String get slashTemplate => 'Adicionar a partir do modelo';

  @override
  String get closedAllDates => 'Todas as datas';

  @override
  String get closedOtherMonth => 'Outro mês';

  @override
  String get closedAllLists => 'Todas as listas';

  @override
  String get orderLabel => 'Ordem';

  @override
  String get orderAscending => 'Crescente';

  @override
  String get orderDescending => 'Decrescente';

  @override
  String get optionList => 'Lista';

  @override
  String get matrixExamples => 'Exemplos';

  @override
  String get matrixPresetPriority => 'Só prioridade';

  @override
  String get matrixPresetTime => 'Tempo + prioridade';

  @override
  String get formatBar => 'Formatar';

  @override
  String get formatHeading => 'Título';

  @override
  String get formatBold => 'Negrito';

  @override
  String get formatItalic => 'Itálico';

  @override
  String get formatUnderline => 'Sublinhado';

  @override
  String get formatStrikethrough => 'Tachado';

  @override
  String get formatTime => 'Tempo';

  @override
  String get formatLink => 'Link';

  @override
  String get formatCode => 'Código';

  @override
  String get countdownDirection => 'Modo de Contagem';

  @override
  String get countdownDirectionDown => 'Contagem regressiva';

  @override
  String get countdownDirectionUp => 'Cronômetro';

  @override
  String get reminderConstant => 'Lembrete constante';

  @override
  String get templateNotesTitle => 'Modelo de nota';

  @override
  String get templateWeeklyReviewName => 'Revisão Semanal';

  @override
  String get templateWeeklyReviewContent =>
      '## O que concluí nesta semana\n\n## O que ficou para trás e por quê\n\n## Prioridades da próxima semana\n\n## Reflexões';

  @override
  String get templateReadingName => 'Nota de leitura';

  @override
  String get templateReadingContent => '**Título do livro:** \n\n**Autor:** \n\n**Resumo da ideia:** ';

  @override
  String get templateMeetingName => 'Nota de Reunião';

  @override
  String get templateMeetingContent => '**Tema:** \n\n**Tempo:** \n\n**Participante(s):** \n\n**Objetivos da reunião:** ';

  @override
  String get noteInfo => 'Informações';

  @override
  String get noteWords => 'Palavras';

  @override
  String get noteCharacters => 'Caracteres';

  @override
  String get noteCreated => 'Criado';

  @override
  String get noteModified => 'Modificado';

  @override
  String get habitAddSection => 'Adicionar Seção';

  @override
  String get habitYearHeatmap => 'Mapa do ano';

  @override
  String get settingsDateFormat => 'Formato de data';

  @override
  String get settingsDefaultTag => 'Tag padrão';

  @override
  String get settingsParseUrls => 'Análise de URL';

  @override
  String get settingsParseUrlsHint => 'Um título que é só um link vira o título da página (lê a página na internet)';

  @override
  String get settingsMiniCalendar => 'Mini Calendário';

  @override
  String get settingsMiniCalendarHint => 'Mostrar na barra lateral';

  @override
  String get copyOpenOnly => 'Apenas tarefas incompletas';

  @override
  String get copyKeepStatus => 'Todas as tarefas, preservando o status de conclusão';

  @override
  String get copyAllReopened => 'Todas as tarefas, sem o status de concluídas';

  @override
  String get addAsNote => 'Converter para nota';

  @override
  String get detailLayout => 'Layout de detalhes da tarefa';

  @override
  String get detailLayoutPanel => 'Painel lateral';

  @override
  String get detailLayoutPopup => 'Janela pop-up';

  @override
  String get focusBatch => 'Gestão de Lotes';

  @override
  String get focusExport => 'Exportar';

  @override
  String get focusExported => 'Registros exportados';

  @override
  String get focusExportStart => 'Início';

  @override
  String get focusExportEnd => 'Fim';

  @override
  String get focusExportMinutes => 'Minutos';

  @override
  String get focusExportMode => 'Modo';

  @override
  String get focusExportLinked => 'Vinculado a';

  @override
  String get focusExportTimer => 'Timer';

  @override
  String get focusExportNote => 'Nota';

  @override
  String get focusFilterDate => 'Data';

  @override
  String get focusFilterLength => 'Duração';

  @override
  String get focusFilterLinked => 'Status Vinculado';

  @override
  String get focusLengthShort => 'Menos de 25m';

  @override
  String get focusLengthLong => '25m ou mais';

  @override
  String get focusLinked => 'Vinculado';

  @override
  String get focusUnlinked => 'Não vinculado';

  @override
  String focusDeleteSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count registros', one: '1 registro');
    return 'Excluir $_temp0?';
  }

  @override
  String get focusTimerAddRecord => 'Adicionar Registro';

  @override
  String get timerFocusedDays => 'Dias focados';

  @override
  String get timerTotal => 'Foco Total';

  @override
  String timerDailyAverage(String duration) {
    return 'Média diária: $duration';
  }

  @override
  String get suggestedTasks => 'Experimente Tarefas Sugeridas';

  @override
  String get suggestedUpcoming => 'Próximos dias';

  @override
  String get suggestedAddToday => 'Adicionar a Hoje';

  @override
  String get suggestedEmpty => 'Nenhuma sugestão por enquanto';

  @override
  String get habitGallery => 'Galeria de hábitos';

  @override
  String get habitCreateNew => 'Criar novo';

  @override
  String get habitCardView => 'Visão em cartão';

  @override
  String get habitListView => 'Visão em lista';

  @override
  String get habitGalleryLife => 'Vida';

  @override
  String get habitGalleryHealth => 'Saúde';

  @override
  String get habitGalleryExercise => 'Exercício';

  @override
  String get habitGalleryMind => 'Mente';

  @override
  String get habitGalleryLifeItems =>
      '🌅 Acordar cedo\n🛏️ Arrumar a cama\n🧹 Arrumar a casa\n🪴 Regar as plantas\n🍳 Cozinhar em casa\n💰 Anotar os gastos\n📵 Menos tempo no celular\n📞 Ligar para a família\n🧺 Lavar a roupa\n🛒 Planejar as compras\n🐶 Passear com o cachorro\n📬 Zerar a caixa de entrada\n🌙 Dormir antes das 23h\n🗓️ Planejar o dia\n🎁 Fazer uma gentileza';

  @override
  String get habitGalleryHealthItems =>
      '💧 Beber água\n🥗 Comer salada\n🍎 Comer uma fruta\n💊 Tomar vitaminas\n🦷 Passar fio dental\n🚭 Não fumar\n🍬 Menos açúcar\n☕ Menos café\n😴 Dormir 8 horas\n🧴 Cuidar da pele\n🥛 Tomar café da manhã\n🚰 Sem refrigerante\n🧘 Alongar\n👀 Descansar a vista\n🍷 Sem álcool';

  @override
  String get habitGalleryExerciseItems =>
      '🏃 Correr\n🚶 Caminhar 30 minutos\n👟 10 mil passos\n🏋️ Musculação\n🚴 Pedalar\n🏊 Nadar\n🧘 Yoga\n🤸 Abdominais\n💪 Flexões\n⛹️ Praticar esporte\n🪜 Usar a escada\n🥊 Treino funcional\n🕺 Dançar\n🧗 Escalar\n🤾 Pular corda';

  @override
  String get habitGalleryMindItems =>
      '📚 Ler\n🧘 Meditar\n✍️ Escrever no diário\n🙏 Gratidão\n🗣️ Estudar um idioma\n🎹 Praticar um instrumento\n🎨 Desenhar\n🧩 Aprender algo novo\n📝 Revisar o dia\n🎧 Ouvir um podcast\n🌳 Tempo na natureza\n🤔 Refletir\n📖 Ler antes de dormir\n🧠 Exercício de memória\n😊 Sorrir';

  @override
  String get toastUndone => 'Desfeito';

  @override
  String get toastRedone => 'Refeito';

  @override
  String get shortcutUndo => 'Desfazer';

  @override
  String get shortcutRedo => 'Refazer';

  @override
  String get addFieldSimple => 'Estilo: Simples';

  @override
  String get addFieldDetailed => 'Estilo: Detalhado';

  @override
  String get addFieldAdd => 'Adicionar';

  @override
  String get formatImmersive => 'Escrita Imersiva';

  @override
  String get paletteModules => 'Módulos';

  @override
  String get paletteFolders => 'Pastas';

  @override
  String get shortcutCalendarToday => 'Calendário: voltar para hoje';

  @override
  String get menuAttach => 'Carregar anexo';

  @override
  String countdownMinutesShort(int count) {
    return '$count M';
  }

  @override
  String countdownHoursShort(int count) {
    return '$count H';
  }

  @override
  String get repeatSkipWeekends => 'Pular finais de semana';

  @override
  String get countdownNoteHint => 'Adicione uma nota…';

  @override
  String get settingsInterfaceStyle => 'Estilo da Interface';

  @override
  String get interfaceFlat => 'Plano';

  @override
  String get interfaceCard => 'Cartão';

  @override
  String get summaryToNote => 'Inserir numa nota';

  @override
  String get summaryNoteCreated => 'Nota criada';

  @override
  String matrixSwapWith(String name) {
    return 'Trocar de lugar com \"$name\"';
  }

  @override
  String get habitMottoHint => 'Frase motivacional (opcional)';

  @override
  String get calendarHideBefore => 'Ocultar horas antes de (h)';

  @override
  String get calendarHideAfter => 'Ocultar horas a partir de (h)';

  @override
  String get countdownIconText => 'Texto';

  @override
  String get countdownIconTextHint => 'Digite 1 caractere';

  @override
  String get helpHome => 'Página inicial';

  @override
  String get helpAbout => 'Sobre o Tarefas';

  @override
  String get commentImage => 'Imagem';

  @override
  String get toastConverted => 'Convertido';

  @override
  String get quickAddModalHint => 'O que você gostaria de fazer?';

  @override
  String get summaryAllLists => 'Todas as listas';

  @override
  String get summaryAllStatuses => 'Todos os status';

  @override
  String get summaryAllTags => 'Todas as tags';

  @override
  String get summaryAllPriorities => 'Todas as prioridades';

  @override
  String get focusEndBreak => 'Terminar';

  @override
  String get habitSortByStatusHint => 'Os hábitos desmarcados serão mostrados no topo da lista';

  @override
  String get tagMergeTitle => 'Mesclar Tags';

  @override
  String tagMergeExplain(String name) {
    return 'Você pode mesclar as tarefas relacionadas da tag \'$name\' com outra tag. Após a fusão, a tag \'$name\' será excluída.';
  }

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get kanbanOverdue => 'Em atraso';

  @override
  String get linkPickerHint => 'Buscar';

  @override
  String get linkPickerEmptyTitle => 'Sem tarefas';

  @override
  String get linkPickerEmptyBody => 'Tente alternar listas ou pesquisar';

  @override
  String get countdownHideGroup => 'Ocultar Grupo';

  @override
  String get countdownAll => 'Todas';

  @override
  String get summaryFieldTitle => 'Título da Tarefa';

  @override
  String get summarySaveTemplateHint => 'Salvar a configuração atual como um modelo e selecioná-lo para geração rápida ao usar novamente.';

  @override
  String get countdownIconEvent => 'Evento';

  @override
  String get countdownIconPerson => 'Pessoa';

  @override
  String get countdownIconParty => 'Festas';

  @override
  String get countdownIconSport => 'Esporte';

  @override
  String get countdownIconAnimal => 'Animal';

  @override
  String get settingsAutoBackup => 'Backups automáticos';

  @override
  String get settingsAutoBackupHint =>
      'Uma cópia por dia das tarefas e configurações, guardada neste dispositivo. Ficam as 7 mais recentes. Os anexos não entram nela e continuam onde estão.';

  @override
  String get autoBackupNone => 'Nenhum backup automático ainda.';

  @override
  String get autoBackupRestore => 'Restaurar';

  @override
  String get countdownIconBackground => 'Cor de fundo';

  @override
  String get calendarShowWeekends => 'Mostrar fins de semana';

  @override
  String get calendarDimPast => 'Reduzir o brilho de eventos passados';

  @override
  String dateFull(String weekday, int day, String month, int year) {
    return '$weekday, $day de $month de $year';
  }

  @override
  String calendarDayOfTotal(int day, int total) {
    return '(Dia $day/$total)';
  }

  @override
  String get calendarCreate => 'Criar';

  @override
  String get calendarMyCalendars => 'Meus calendários';

  @override
  String get calendarOtherCalendars => 'Outros calendários';

  @override
  String get calendarShowOnly => 'Mostrar só este';

  @override
  String get calendarAddOther => 'Adicionar outros calendários';

  @override
  String get calendarTogglePanel => 'Mostrar ou esconder o painel';

  @override
  String get calendarAddTitle => 'Adicionar título';

  @override
  String get calendarKindTask => 'Tarefa';

  @override
  String get calendarKindNote => 'Nota';

  @override
  String get calendarAddDescription => 'Adicionar descrição';

  @override
  String get calendarNoRepeat => 'Não se repete';

  @override
  String get calendarMoreOptions => 'Mais opções';

  @override
  String get calendarNoDate => 'Sem data';

  @override
  String get calendarNoReminder => 'Sem lembrete';

  @override
  String get ordinalsFeminine => 'primeira,segunda,terceira,quarta';

  @override
  String get ordinalsMasculine => 'primeiro,segundo,terceiro,quarto';

  @override
  String get lastFeminine => 'última';

  @override
  String get lastMasculine => 'último';

  @override
  String repeatMonthlyOn(String when) {
    return 'Mensal $when';
  }

  @override
  String get calendarDetails => 'Detalhes';

  @override
  String get calendarAddReminder => 'Adicionar lembrete';

  @override
  String get insightsTitle => 'Insights de tempo';

  @override
  String get insightsMore => 'Mais insights';

  @override
  String get insightsBreakdown => 'Detalhamento do tempo';

  @override
  String get insightsByList => 'Lista';

  @override
  String get insightsByTag => 'Etiqueta';

  @override
  String get insightsByKind => 'Tipo';

  @override
  String get insightsPerDay => 'Horas por dia';

  @override
  String get insightsNoTag => 'Sem etiqueta';

  @override
  String get insightsTasks => 'Tarefas';

  @override
  String get insightsTotal => 'no total';

  @override
  String get insightsEmpty => 'Nada com horário marcado neste período.';

  @override
  String insightsScheduled(String hours) {
    return '$hours com horário marcado';
  }

  @override
  String get eventColorNames =>
      'Flor de cerejeira,Tomate,Tangerina,Abóbora,Manga,Banana,Cidra,Abacate,Pistache,Manjericão,Sálvia,Eucalipto,Pavão,Mirtilo,Lavanda,Glicínia,Ametista,Uva,Cacau,Bétula,Grafite';

  @override
  String get colorLabelsEdit => 'Editar rótulos';

  @override
  String get colorLabelsHint => 'Dê nome às cores: nos Insights de tempo, as tarefas de cada cor aparecem com esse nome.';

  @override
  String get colorLabelsColor => 'Cor';

  @override
  String get colorLabelsName => 'Nome do rótulo';

  @override
  String get colorLabelsAdd => 'Adicionar rótulo';

  @override
  String get colorDefault => 'Padrão';

  @override
  String get colorOfTask => 'Cor da tarefa';

  @override
  String get insightsByLabel => 'Rótulo';

  @override
  String get insightsNoLabel => 'Sem rótulo';

  @override
  String get recurrenceTitle => 'Repetição personalizada';

  @override
  String get recurrenceEvery => 'Repetir a cada';

  @override
  String get recurrenceOn => 'Repetir em';

  @override
  String get recurrenceEnds => 'Termina';

  @override
  String get recurrenceNever => 'Nunca';

  @override
  String get recurrenceOnDate => 'Em';

  @override
  String get recurrenceAfter => 'Após';

  @override
  String get recurrenceDone => 'Concluído';

  @override
  String recurrenceOccurrences(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'ocorrências', one: 'ocorrência');
    return '$_temp0';
  }

  @override
  String recurrenceDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'dias', one: 'dia');
    return '$_temp0';
  }

  @override
  String recurrenceWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'semanas', one: 'semana');
    return '$_temp0';
  }

  @override
  String recurrenceMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'meses', one: 'mês');
    return '$_temp0';
  }

  @override
  String recurrenceYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'anos', one: 'ano');
    return '$_temp0';
  }

  @override
  String recurrenceEveryN(int count, String unit) {
    return 'A cada $count $unit';
  }

  @override
  String recurrenceWeeklyOn(String days) {
    return 'Semanal: $days';
  }

  @override
  String recurrenceTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count vezes', one: '1 vez');
    return '$_temp0';
  }

  @override
  String recurrenceUntil(String date) {
    return 'até $date';
  }

  @override
  String get colorCode => 'Código';

  @override
  String get colorSeriesCustom => 'Outra cor';

  @override
  String get calendarEditTask => 'Editar tarefa';

  @override
  String get calendarDeleteTask => 'Deletar tarefa';

  @override
  String get calendarOptions => 'Opções';

  @override
  String get calendarOpenDetail => 'Abrir detalhes da tarefa';

  @override
  String get calendarMarkDone => 'Marcar como concluída';

  @override
  String get calendarMarkUndone => 'Marcar como não concluída';

  @override
  String get calendarOpen => 'Abrir';

  @override
  String get calendarShortAs30 => 'Eventos curtos com o tamanho de 30 minutos';

  @override
  String get recurringDeleteTitle => 'Excluir tarefa repetida';

  @override
  String get recurringEditTitle => 'Editar tarefa repetida';

  @override
  String get recurringOne => 'Somente esta';

  @override
  String get recurringFollowing => 'Esta e as seguintes';

  @override
  String get recurringAll => 'Todas';

  @override
  String get notificationAlarmChannelName => 'Despertador do foco';

  @override
  String get notificationFocusChannelName => 'Foco em andamento';

  @override
  String get notificationActionStop => 'Parar';

  @override
  String get focusBreakDoneTitle => 'A pausa acabou.';

  @override
  String get focusBreakDoneBody => 'Hora de voltar ao foco.';

  @override
  String get focusRunningTitle => 'Focando';

  @override
  String get focusPausedTitle => 'Foco pausado';

  @override
  String get focusBreakTitle => 'Pausa';

  @override
  String get notificationAlarmClockChannelName => 'Lembretes (despertador)';

  @override
  String get trayOpen => 'Abrir o Tarefas';

  @override
  String get trayQuit => 'Sair';

  @override
  String get settingsReminderSound => 'Som do lembrete';

  @override
  String get settingsReminderSoundHint => 'O Despertador toca por alguns segundos; o do Pomodoro fica em Foco → Configurações de foco.';

  @override
  String get reminderSoundAlarmClock => 'Despertador';

  @override
  String get reminderSoundStandard => 'Padrão';

  @override
  String get reminderSoundSilent => 'Silencioso';

  @override
  String get settingsBackground => 'Segundo plano';

  @override
  String get settingsCloseToTray => 'Manter na bandeja ao fechar';

  @override
  String get settingsCloseToTrayHint =>
      'Os lembretes, o Pomodoro e o som do despertador continuam funcionando. Para sair de vez, use Sair no ícone perto do relógio.';

  @override
  String get settingsLaunchAtStartup => 'Iniciar com o Windows';

  @override
  String get settingsLaunchAtStartupHint => 'Abre escondido na bandeja quando você entra no Windows.';

  @override
  String get inFeminine => 'na';

  @override
  String get inMasculine => 'no';

  @override
  String recurrenceYearlyOn(String date) {
    return 'Anualmente em $date';
  }

  @override
  String get navFinance => 'Finanças';

  @override
  String get featureFinanceHint => 'Receitas, despesas, cartões, contas fixas e empréstimos.';

  @override
  String get finTabEntries => 'Lançamentos';

  @override
  String get finTabCategories => 'Categorias';

  @override
  String get finNewEntry => 'Novo lançamento';

  @override
  String get finEditEntry => 'Editar lançamento';

  @override
  String get finIncome => 'Receita';

  @override
  String get finExpense => 'Despesa';

  @override
  String get finIncomes => 'Receitas';

  @override
  String get finExpenses => 'Despesas';

  @override
  String get finBalance => 'Saldo';

  @override
  String get finAmount => 'Valor';

  @override
  String get finDescription => 'Descrição';

  @override
  String get finDate => 'Data';

  @override
  String get finCategory => 'Categoria';

  @override
  String get finNoCategory => 'Sem categoria';

  @override
  String get finCard => 'Cartão';

  @override
  String get finNoCard => 'Não foi no cartão';

  @override
  String get finInstallments => 'Parcelas';

  @override
  String finInstallmentsValue(int count, String amount) {
    return '${count}x de $amount';
  }

  @override
  String get finNote => 'Observação';

  @override
  String get finInvalidAmount => 'Digite um valor maior que zero.';

  @override
  String get finEntriesEmpty => 'Nenhum lançamento neste período.';

  @override
  String finInvoiceOf(String card, String day) {
    return 'Fatura $card · vence $day';
  }

  @override
  String get finEntryDeleted => 'Lançamento excluído';

  @override
  String get finDeleteInstallments => 'Excluir compra parcelada';

  @override
  String get finDeleteOneInstallment => 'Só esta parcela';

  @override
  String finDeleteAllInstallments(int count) {
    return 'Todas as $count parcelas';
  }

  @override
  String get finDuplicate => 'Duplicar';

  @override
  String finLimitNear(String category, String percent, String spent, String limit) {
    return '$category: $percent do limite do mês ($spent de $limit).';
  }

  @override
  String finLimitOver(String category, String spent, String limit) {
    return '$category passou do limite do mês: $spent de $limit.';
  }

  @override
  String get finNewCategory => 'Nova categoria';

  @override
  String get finEditCategory => 'Editar categoria';

  @override
  String get finCategoryName => 'Nome';

  @override
  String get finMonthlyLimit => 'Limite por mês';

  @override
  String get finLimitHint => 'Em branco, sem limite. O aviso vem a partir de 80% do limite.';

  @override
  String finLimitProgress(String spent, String limit) {
    return '$spent de $limit';
  }

  @override
  String finSpentThisMonth(String spent) {
    return '$spent neste mês';
  }

  @override
  String finDeleteCategory(String name) {
    return 'Excluir a categoria \"$name\"? Os lançamentos dela ficam sem categoria.';
  }

  @override
  String get finIcon => 'Ícone';

  @override
  String get finPeriodMonth => 'Mês';

  @override
  String get finPeriodYear => 'Ano';

  @override
  String get finAllCategories => 'Todas as categorias';

  @override
  String get finAllKinds => 'Receitas e despesas';

  @override
  String get finSearchHint => 'Buscar na descrição';

  @override
  String get finCatFood => 'Alimentação';

  @override
  String get finCatMarket => 'Mercado';

  @override
  String get finCatTransport => 'Transporte';

  @override
  String get finCatHome => 'Moradia';

  @override
  String get finCatBills => 'Contas da casa';

  @override
  String get finCatHealth => 'Saúde';

  @override
  String get finCatEducation => 'Educação';

  @override
  String get finCatLeisure => 'Lazer';

  @override
  String get finCatShopping => 'Compras';

  @override
  String get finCatSubscriptions => 'Assinaturas';

  @override
  String get finCatOther => 'Outros';

  @override
  String get finCatSalary => 'Salário';

  @override
  String get finCatExtra => 'Renda extra';

  @override
  String get finTabCards => 'Cartões';

  @override
  String get finTabRecurring => 'Contas fixas';

  @override
  String get finTabLoans => 'Empréstimos';

  @override
  String get finTabReports => 'Relatórios';

  @override
  String get finNewCard => 'Novo cartão';

  @override
  String get finEditCard => 'Editar cartão';

  @override
  String get finCardName => 'Nome do cartão';

  @override
  String get finClosingDay => 'Dia do fechamento';

  @override
  String get finDueDay => 'Dia do vencimento';

  @override
  String get finCreditLimit => 'Limite do cartão (opcional)';

  @override
  String finCardDays(int closing, int due) {
    return 'Fecha dia $closing · vence dia $due';
  }

  @override
  String finCardUsed(String used, String limit) {
    return '$used usados de $limit';
  }

  @override
  String finInvoiceTitle(String month) {
    return 'Fatura de $month';
  }

  @override
  String get finInvoiceOpen => 'Aberta';

  @override
  String get finInvoiceClosed => 'Fechada';

  @override
  String get finInvoicePaid => 'Paga';

  @override
  String get finInvoiceOverdue => 'Vencida';

  @override
  String get finInvoiceEmpty => 'Sem compras';

  @override
  String finInvoiceDates(String closing, String due) {
    return 'Fecha em $closing · vence em $due';
  }

  @override
  String get finInvoiceTotal => 'Total';

  @override
  String get finInvoicePaidAmount => 'Pago';

  @override
  String get finInvoiceRemaining => 'Falta pagar';

  @override
  String get finPayInvoice => 'Pagar fatura';

  @override
  String get finPaymentAmount => 'Valor pago';

  @override
  String get finPaymentDate => 'Data do pagamento';

  @override
  String get finPayments => 'Pagamentos';

  @override
  String get finPurchases => 'Compras';

  @override
  String get finNoCards => 'Nenhum cartão ainda. Cadastre um para lançar compras no cartão e acompanhar as faturas.';

  @override
  String get finArchive => 'Arquivar';

  @override
  String get finUnarchive => 'Desarquivar';

  @override
  String get finArchivedCards => 'Arquivados';

  @override
  String get finCardDeleteBlocked => 'Este cartão tem compras ou pagamentos. Arquive-o para escondê-lo.';

  @override
  String finDeleteCard(String name) {
    return 'Excluir o cartão \"$name\"?';
  }

  @override
  String get finPaymentDeleted => 'Pagamento excluído';

  @override
  String get finNewRecurring => 'Nova conta fixa';

  @override
  String get finEditRecurring => 'Editar conta fixa';

  @override
  String get finNoRecurring => 'Nenhuma conta fixa ainda. Cadastre aluguel, assinaturas, salário…';

  @override
  String get finRecurringHint => 'Aluguel, internet, salário…';

  @override
  String get finRecurringInvalid => 'Preencha a descrição e um valor maior que zero.';

  @override
  String get finOverdueBills => 'Atrasadas';

  @override
  String get finDueThisMonth => 'Vencimentos do mês';

  @override
  String get finRecurringBills => 'Contas cadastradas';

  @override
  String finEveryMonthOn(int day) {
    return 'Todo dia $day';
  }

  @override
  String finEveryYearOn(String date) {
    return 'Todo ano em $date';
  }

  @override
  String finDueOn(String date) {
    return 'vence $date';
  }

  @override
  String finPaidOn(String date) {
    return 'pago em $date';
  }

  @override
  String get finConfirmPaid => 'Pagar';

  @override
  String get finConfirmReceived => 'Receber';

  @override
  String get finUndoPayment => 'Desfazer pagamento';

  @override
  String get finPaymentUndone => 'Pagamento desfeito';

  @override
  String finDeleteRecurring(String name) {
    return 'Excluir a conta fixa \"$name\"? Os lançamentos já feitos continuam.';
  }

  @override
  String get finMonthly => 'Mensal';

  @override
  String get finYearly => 'Anual';

  @override
  String get finReminder => 'Lembrete';

  @override
  String get finNoReminder => 'Sem lembrete';

  @override
  String get finRemindOnDay => 'No dia do vencimento';

  @override
  String finRemindDaysBefore(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days dias antes', one: '1 dia antes');
    return '$_temp0';
  }

  @override
  String get finStartsOn => 'Começa em';

  @override
  String get finEndsOn => 'Termina em';

  @override
  String get finNoEnd => 'Sem fim';

  @override
  String get finNewLoan => 'Novo empréstimo';

  @override
  String get finEditLoan => 'Editar empréstimo';

  @override
  String get finNoLoans => 'Nenhum empréstimo ainda.';

  @override
  String get finNoLoansHere => 'Nenhum empréstimo aqui.';

  @override
  String get finLoansOpen => 'Em aberto';

  @override
  String get finLoansOverdue => 'Atrasados';

  @override
  String get finLoansPaid => 'Quitados';

  @override
  String get finLoansAll => 'Todos';

  @override
  String get finLentOpen => 'Emprestado';

  @override
  String get finToReceive => 'A receber';

  @override
  String get finInterestReceived => 'Juros recebidos';

  @override
  String get finOverdueAmount => 'Em atraso';

  @override
  String finLoansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count empréstimos', one: '1 empréstimo', zero: 'nenhum');
    return '$_temp0';
  }

  @override
  String finInterestToCome(String amount) {
    return '$amount de juros a receber';
  }

  @override
  String finLentTotal(String amount) {
    return '$amount emprestados no total';
  }

  @override
  String get finLoanOnTime => 'Em dia';

  @override
  String finLoanLate(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: 'Atrasado há $days dias', one: 'Atrasado há 1 dia', zero: 'Atrasado');
    return '$_temp0';
  }

  @override
  String get finLoanPaid => 'Quitado';

  @override
  String finLoanLeft(String amount) {
    return 'Falta $amount';
  }

  @override
  String finProfit(String amount, String rate) {
    return 'lucro $amount ($rate)';
  }

  @override
  String finDeleteLoan(String name) {
    return 'Excluir o empréstimo de $name e os pagamentos dele?';
  }

  @override
  String get finLoanDeleted => 'Empréstimo excluído';

  @override
  String get finLent => 'Valor emprestado';

  @override
  String get finLoanTotal => 'Total a receber';

  @override
  String get finProfitLabel => 'Lucro';

  @override
  String get finReceived => 'Recebido';

  @override
  String get finLoanBalance => 'Falta receber';

  @override
  String get finLentOn => 'Data do empréstimo';

  @override
  String get finDueDate => 'Vencimento';

  @override
  String get finAddLoanPayment => 'Registrar pagamento';

  @override
  String get finBorrower => 'Quem pegou emprestado';

  @override
  String get finInterestRate => 'Juros';

  @override
  String finProfitPreview(String amount) {
    return 'Lucro: $amount';
  }

  @override
  String get finLoanInvalid => 'Preencha quem pegou, o valor emprestado e um total a receber igual ou maior que ele.';

  @override
  String get finLoanRemind => 'Lembrar no vencimento e se atrasar';

  @override
  String get finByCategory => 'Gastos por categoria';

  @override
  String get finNoExpenses => 'Nenhum gasto neste mês.';

  @override
  String get finIncomeVsExpenses => 'Receitas × despesas';

  @override
  String get finCompareMonths => 'Comparação entre meses';

  @override
  String get finVersus => 'com';

  @override
  String get finChange => 'Variação';

  @override
  String get finTotal => 'Total';

  @override
  String get finLoansSummary => 'Empréstimos';

  @override
  String finReminderBillTitle(String name) {
    return '$name vence hoje';
  }

  @override
  String finReminderBillSoon(String name, String date) {
    return '$name vence em $date';
  }

  @override
  String finReminderLoanDue(String name) {
    return 'Hoje vence o empréstimo de $name';
  }

  @override
  String finReminderLoanLate(String name) {
    return 'Empréstimo de $name atrasado';
  }

  @override
  String finReminderLoanBody(String amount) {
    return 'Falta receber $amount';
  }

  @override
  String get finByDueMonth => 'Por mês do vencimento';

  @override
  String get finByLentMonth => 'Por mês do empréstimo';

  @override
  String finMonthLoanTotals(String amount, String profit) {
    return 'a receber $amount · lucro $profit';
  }

  @override
  String get calendarShowFinance => 'Mostrar finanças (contas, faturas e cobranças)';

  @override
  String finCalendarInvoice(String card) {
    return 'Fatura $card';
  }

  @override
  String finCalendarLoan(String name) {
    return 'Cobrar $name';
  }

  @override
  String get finThisMonth => 'Este mês';

  @override
  String get finCurrentInvoice => 'Fatura atual';

  @override
  String get finMonthSpending => 'Gastos do mês';

  @override
  String get finMoreReports => 'Mais relatórios';

  @override
  String get finCategoriesFilter => 'Categorias…';

  @override
  String get finSituation => 'Situação';

  @override
  String get finGroupBy => 'Agrupar';

  @override
  String get finCreditAvailable => 'Limite disponível';

  @override
  String get habitPanelDone => 'Feitos';

  @override
  String get habitPanelLeft => 'Faltam';

  @override
  String get habitPanelNone => 'Nenhum hábito para hoje.';

  @override
  String get habitPanelShow => 'Exibir';

  @override
  String get countdownTypes => 'Tipos';

  @override
  String get countdownCreateWhich => 'Criar';

  @override
  String get matrixQuadrants => 'Quadrantes';

  @override
  String get focusShortcuts => 'Atalhos';

  @override
  String get habitColor => 'Cor do hábito';

  @override
  String get habitColorMenu => 'Cor';

  @override
  String get finNewPurchase => 'Nova compra';

  @override
  String get habitNewButton => 'Novo hábito';

  @override
  String get countdownNew => 'Nova contagem';

  @override
  String get focusTimerNew => 'Novo temporizador';

  @override
  String get finEditPayment => 'Editar pagamento';

  @override
  String habitDeleteConfirm(String name) {
    return 'Excluir o hábito \"$name\" e todos os check-ins dele? Isso não pode ser desfeito.';
  }

  @override
  String get habitLogDelete => 'Excluir registro';

  @override
  String countdownDeleteConfirm(String name) {
    return 'Excluir \"$name\"? Isso não pode ser desfeito.';
  }

  @override
  String focusTimerDeleteConfirm(String name) {
    return 'Excluir o temporizador \"$name\"? Os registros de foco continuam.';
  }

  @override
  String get focusRecordDeleteConfirm => 'Excluir este registro de foco? Isso não pode ser desfeito.';

  @override
  String tagDeleteConfirm(String name) {
    return 'Excluir a etiqueta \"$name\"? As tarefas continuam, sem ela.';
  }

  @override
  String get listDeleteMenu => 'Deletar lista';

  @override
  String get syncTitle => 'Sincronizar com outro aparelho';

  @override
  String get syncMenu => 'Sincronizar aparelhos';

  @override
  String get syncIntro =>
      'Deixe o celular e o computador iguais pelo Wi-Fi, sem internet e sem conta: um aparelho envia tudo o que tem, e o outro fica igual a ele.';

  @override
  String get syncSend => 'Enviar deste aparelho';

  @override
  String get syncSendHint => 'O outro aparelho fica igual a este.';

  @override
  String get syncReceive => 'Receber neste aparelho';

  @override
  String get syncReceiveHint =>
      'Este aparelho fica igual ao outro. Antes, é feita uma cópia de segurança dos dados daqui (em Configurações → Conta → Backups automáticos).';

  @override
  String get syncSameWifi => 'Os dois precisam estar no mesmo Wi-Fi, com o Tarefas aberto e na mesma versão.';

  @override
  String syncWaiting(String name) {
    return 'No outro aparelho, abra Sincronizar → Enviar deste aparelho, escolha \"$name\" e digite este código:';
  }

  @override
  String syncAddress(String name, String address) {
    return 'Se \"$name\" não aparecer lá, toque em Digitar endereço e use: $address';
  }

  @override
  String get syncFirewall => 'No Windows, se o Firewall perguntar, clique em Permitir acesso.';

  @override
  String get syncReceiving => 'Recebendo os dados…';

  @override
  String syncReceived(String name) {
    return 'Pronto! Este aparelho ficou igual a \"$name\".';
  }

  @override
  String get syncReceiveFailed => 'Os dados recebidos não puderam ser usados (as versões do app são diferentes?). Nada mudou aqui.';

  @override
  String get syncSearching => 'Procurando aparelhos no Wi-Fi…';

  @override
  String get syncTypeAddress => 'Digitar endereço';

  @override
  String get syncAddressLabel => 'Endereço (ex.: 192.168.0.10:50000)';

  @override
  String syncEnterCode(String name) {
    return 'Digite o código que aparece em \"$name\"';
  }

  @override
  String get syncSendButton => 'Enviar';

  @override
  String get syncSending => 'Enviando… o outro aparelho está ficando igual a este.';

  @override
  String syncDone(String name) {
    return 'Pronto! \"$name\" ficou igual a este aparelho.';
  }

  @override
  String get syncWrongCode => 'Código errado. Confira o código na tela do outro aparelho.';

  @override
  String get syncRefused => 'O outro aparelho parou de aceitar depois de muitas tentativas. Lá, feche e abra Receber de novo.';

  @override
  String get syncFailed => 'Não deu certo. Confira se os dois estão no mesmo Wi-Fi, com o Tarefas aberto e na mesma versão.';

  @override
  String get syncCodeLabel => 'Código';

  @override
  String get syncWaitingOther => 'Esperando o outro aparelho enviar…';

  @override
  String get widgetDay => 'Dia';

  @override
  String get widgetWeek => 'Semana';

  @override
  String get widgetMonth => 'Mês';

  @override
  String get widgetEmpty => 'Nada neste dia';

  @override
  String get widgetAllDay => 'Dia todo';
}
