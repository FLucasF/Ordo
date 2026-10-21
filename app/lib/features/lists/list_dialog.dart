import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/ids.dart';
import '../../data/db/database.dart';
import '../../data/repository.dart' show maxListLevels;
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../appearance/backdrop.dart';
import '../common/color_choice.dart';
import '../common/emoji_picker.dart';
import '../common/feedback.dart';
import 'folder_dialog.dart';

/// Result of the list dialog.
class ListForm {
  const ListForm({
    required this.name,
    required this.emoji,
    required this.color,
    required this.folderId,
    required this.kind,
    required this.viewMode,
    required this.showInSmartLists,
    this.parentId,
    this.background,
  });

  final String name;
  final String? emoji;
  final String? color;
  final String? folderId;

  /// "Dentro de": the list it is a sublist of; null at the top.
  final String? parentId;
  final ListKind kind;
  final ViewMode viewMode;
  final bool showInSmartLists;

  /// "Fundo" (features/appearance/backgrounds.dart): null = the folder's or the app's.
  final String? background;
}

/// What happens to the sublists of a list that is deleted or archived.
enum SublistFate { moveUp, along }

/// Asks what happens to the sublists of [l] ([along] names going with it); null when cancelled.
Future<SublistFate?> _askSublistFate(BuildContext context, String message, String along) {
  final t = AppLocalizations.of(context);
  return showDialog<SublistFate>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(t.sublistsWhatTitle, style: const TextStyle(fontSize: 15)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: SizedBox(width: 360, child: Text(message)),
        ),
        SimpleDialogOption(onPressed: () => Navigator.pop(context, SublistFate.moveUp), child: Text(t.sublistsMoveUp)),
        SimpleDialogOption(onPressed: () => Navigator.pop(context, SublistFate.along), child: Text(along)),
        SimpleDialogOption(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
      ],
    ),
  );
}

bool _hasSublists(WidgetRef ref, TaskList l) => (ref.read(snapshotProvider).value?.sublistsOf(l.id) ?? const []).isNotEmpty;

/// Deletes a list after asking (its tasks go to the trash; its sublists move up a level or go too);
/// true when it did. Leaving it, when it was open, is the caller's.
Future<bool> deleteListAsking(BuildContext context, WidgetRef ref, TaskList l) async {
  final t = AppLocalizations.of(context);
  final repo = ref.read(repositoryProvider);
  if (_hasSublists(ref, l)) {
    final fate = await _askSublistFate(context, t.deleteListConfirm, t.sublistsDeleteToo);
    if (fate == null || !context.mounted) return false;
    return guarded(context, () => repo.deleteList(l.id, withSublists: fate == SublistFate.along));
  }
  if (!await confirm(context, message: t.deleteListConfirm, confirmLabel: t.actionDelete) || !context.mounted) return false;
  return guarded(context, () => repo.deleteList(l.id));
}

/// Archives a list after asking (and what happens to its sublists); true when it did.
Future<bool> archiveListAsking(BuildContext context, WidgetRef ref, TaskList l) async {
  final t = AppLocalizations.of(context);
  final repo = ref.read(repositoryProvider);
  var fate = SublistFate.moveUp;
  if (_hasSublists(ref, l)) {
    final picked = await _askSublistFate(context, t.archiveListConfirm, t.sublistsArchiveToo);
    if (picked == null) return false;
    fate = picked;
  } else if (!await confirm(context, message: t.archiveListConfirm, confirmLabel: t.actionArchive)) {
    return false;
  }
  if (!context.mounted) return false;
  return guarded(context, () => repo.archiveList(l.id, archived: true, withSublists: fate == SublistFate.along));
}

/// "Adicionar lista" (inside [folderId], or as a sublist of [parentId]) and the list created; its id.
Future<String?> addListWithDialog(BuildContext context, WidgetRef ref, {String? folderId, String? parentId}) async {
  final form = await showListDialog(context, folderId: folderId, parentId: parentId);
  if (form == null || !context.mounted) return null;
  String? id;
  await guarded(
    context,
    () async => id = await ref
        .read(repositoryProvider)
        .createList(
          name: form.name,
          emoji: form.emoji,
          color: form.color,
          folderId: form.folderId,
          parentId: form.parentId,
          kind: form.kind,
          viewMode: form.viewMode,
          showInSmartLists: form.showInSmartLists,
        ),
  );
  if (id case final created? when form.background != null) await ref.read(repositoryProvider).setListBackground(created, form.background);
  return id;
}

/// "Editar lista": the dialog (its bin is [deleteListAsking], then [onDeleted]) and the changes saved.
Future<void> editListWithDialog(BuildContext context, WidgetRef ref, TaskList l, {VoidCallback? onDeleted}) async {
  final repo = ref.read(repositoryProvider);
  final form = await showListDialog(
    context,
    editing: l,
    onDelete: () async {
      final deleted = await deleteListAsking(context, ref, l);
      if (deleted) onDeleted?.call();
      return deleted;
    },
  );
  if (form == null || !context.mounted) return;
  await guarded(
    context,
    () => repo.editList(
      l.id,
      name: form.name,
      emoji: form.emoji,
      color: form.color,
      folderId: form.folderId,
      parentId: Value(form.parentId),
      kind: form.kind,
      viewMode: form.viewMode,
      showInSmartLists: form.showInSmartLists,
    ),
  );
  if (form.background != l.background) await repo.setListBackground(l.id, form.background);
}

/// "Adicionar lista" / "Editar lista". Returns null when cancelled.
///
/// Editing, [onDelete] shows the bin: it asks and deletes, and the dialog closes when it did.
Future<ListForm?> showListDialog(BuildContext context, {TaskList? editing, String? folderId, String? parentId, Future<bool> Function()? onDelete}) =>
    showDialog<ListForm>(
      context: context,
      builder: (_) => _ListDialog(editing: editing, initialFolderId: folderId, initialParentId: parentId, onDelete: onDelete),
    );

class _ListDialog extends ConsumerStatefulWidget {
  const _ListDialog({this.editing, this.initialFolderId, this.initialParentId, this.onDelete});

  final TaskList? editing;
  final String? initialFolderId;
  final String? initialParentId;
  final Future<bool> Function()? onDelete;

  @override
  ConsumerState<_ListDialog> createState() => _ListDialogState();
}

class _ListDialogState extends ConsumerState<_ListDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.editing?.name ?? '');
  late String? _emoji = widget.editing?.emoji;
  late String? _color = widget.editing?.color;
  late String? _folderId = widget.editing?.folderId ?? widget.initialFolderId;
  late String? _parentId = widget.editing?.parentId ?? widget.initialParentId;
  late ListKind _kind = widget.editing?.kind ?? ListKind.tasks;
  late ViewMode _viewMode = widget.editing?.viewMode ?? ViewMode.list;
  late bool _showInSmartLists = widget.editing?.showInSmartLists ?? true;
  late String? _background = widget.editing?.background;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      ListForm(
        name: _name.text.trim(),
        emoji: _emoji,
        color: _color,
        folderId: _folderId,
        parentId: _parentId,
        kind: _kind,
        viewMode: _viewMode,
        showInSmartLists: _showInSmartLists,
        background: _background,
      ),
    );
  }

  /// "Dentro de": the lists this one can go into, with their depth. Not the Inbox, itself or its own
  /// sublists, and none that would take its deepest sublist past [maxListLevels].
  List<(TaskList, int)> _parents(Snapshot s) {
    final editing = widget.editing;
    final own = editing == null ? const <String>{} : {editing.id, for (final l in s.sublistsDeep(editing.id)) l.id};
    int height(String id) => 1 + s.sublistsOf(id).fold(0, (deepest, c) => deepest > height(c.id) ? deepest : height(c.id));
    final levels = editing == null ? 1 : height(editing.id);
    return [
      for (final (l, depth) in s.listTree(s.activeLists.where((l) => l.id != inboxListId)))
        if (!own.contains(l.id) && depth + 1 + levels <= maxListLevels) (l, depth),
    ];
  }

  Future<void> _pickEmoji() async {
    final picked = await showEmojiPicker(context);
    // "Redefinir" ('') removes the icon.
    if (picked != null) setState(() => _emoji = picked.isEmpty ? null : picked);
  }

  Future<void> _newFolder() async {
    final id = await createFolderWithDialog(context, ref);
    if (id != null && mounted) setState(() => _folderId = id);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final folders = s.activeFolders;
    final parents = _parents(s);
    final parent = _parentId == null ? null : s.listById[_parentId];
    final isInbox = widget.editing?.id == inboxListId;

    // Label beside the options on wide screens, above them on phones.
    final narrow = MediaQuery.sizeOf(context).width < 600;
    Widget row(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: tt.textSecondary)),
                const SizedBox(height: 6),
                child,
              ],
            )
          : Row(
              children: [
                SizedBox(
                  width: 170,
                  child: Text(label, style: TextStyle(color: tt.textSecondary)),
                ),
                Expanded(child: child),
              ],
            ),
    );

    Widget segmented<T>(T value, Map<T, String> options, ValueChanged<T> onChanged) => Wrap(
      spacing: 6,
      children: [
        for (final o in options.entries)
          ChoiceChip(
            label: Text(o.value, style: TextStyle(color: o.key == value ? Colors.white : tt.text)),
            selected: o.key == value,
            selectedColor: tt.primary,
            onSelected: (_) => onChanged(o.key),
            showCheckmark: false,
          ),
      ],
    );

    return AlertDialog(
      title: Text(widget.editing == null ? t.listAddTitle : t.listEditTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // The list's icon: without one, a face with a "+" says an emoji can be picked here.
                      Tooltip(
                        message: t.countdownIcon,
                        child: InkWell(
                          onTap: _pickEmoji,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(6)),
                            child: _emoji == null
                                ? Icon(Icons.add_reaction_outlined, size: 20, color: tt.textSecondary)
                                : Text(_emoji!, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _name,
                          autofocus: true,
                          // The preview follows the name.
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: t.listNameHint,
                            filled: true,
                            fillColor: tt.fieldFill,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  row(t.listColor, ColorChoice(value: _color, onChanged: (c) => setState(() => _color = c))),
                  row(
                    t.listViewType,
                    segmented(_viewMode, {
                      ViewMode.list: t.viewList,
                      ViewMode.kanban: t.viewKanban,
                      ViewMode.timeline: t.viewTimeline,
                    }, (v) => setState(() => _viewMode = v)),
                  ),
                  // A sublist is in its parent's area: the area shows, but only the parent changes it.
                  row(
                    t.listFolder,
                    parent != null
                        ? Text(
                            parent.folderId == null ? t.folderNone : (s.folderById[parent.folderId]?.name ?? t.folderNone),
                            style: TextStyle(color: tt.textTertiary),
                          )
                        : DropdownButton<String?>(
                            value: folders.any((f) => f.id == _folderId) ? _folderId : null,
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            items: [
                              DropdownMenuItem(value: null, child: Text(t.folderNone)),
                              for (final f in folders) DropdownMenuItem(value: f.id, child: Text(f.name)),
                              DropdownMenuItem(
                                value: '\u0000new',
                                child: Text('+ ${t.folderNew}', style: TextStyle(color: tt.primary)),
                              ),
                            ],
                            onChanged: (v) => v == '\u0000new' ? _newFolder() : setState(() => _folderId = v),
                          ),
                  ),
                  if (!isInbox)
                    row(
                      t.listParent,
                      DropdownButton<String?>(
                        value: _parentId,
                        isDense: true,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: [
                          DropdownMenuItem(value: null, child: Text(t.listParentNone)),
                          for (final (l, depth) in parents)
                            DropdownMenuItem(
                              value: l.id,
                              child: Padding(
                                padding: EdgeInsets.only(left: 16.0 * depth),
                                child: Text('${l.emoji ?? ''}${l.emoji == null ? '' : ' '}${l.name}', overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          // A parent that is no longer offered (archived) stays shown.
                          if (parent != null && !parents.any((p) => p.$1.id == parent.id))
                            DropdownMenuItem(value: parent.id, child: Text(parent.name)),
                        ],
                        onChanged: (v) => setState(() => _parentId = v),
                      ),
                    ),
                  row(
                    t.listType,
                    segmented(_kind, {ListKind.tasks: t.listTypeTasks, ListKind.notes: t.listTypeNotes}, (v) => setState(() => _kind = v)),
                  ),
                  row(
                    t.listShowInSmartList,
                    segmented(_showInSmartLists, {true: t.listShowAllTasks, false: t.listDontShow}, (v) => setState(() => _showInSmartLists = v)),
                  ),
                  // Shown behind the list when it's open, instead of the app's.
                  row(t.backgroundTitle, BackgroundChoices(value: _background, inherit: true, onChanged: (c) => setState(() => _background = c))),
                ],
              ),
            ),
          ),
          // The live preview on the right.
          if (MediaQuery.sizeOf(context).width >= 900) ...[
            const SizedBox(width: 20),
            _ListPreview(name: _name.text.trim(), emoji: _emoji, color: parseHexColor(_color), viewMode: _viewMode, notes: _kind == ListKind.notes),
          ],
        ],
      ),
      actions: [
        if (widget.editing != null && widget.onDelete != null)
          IconButton(
            tooltip: t.actionDelete,
            icon: Icon(Icons.delete_outline, color: context.tt.overdue),
            onPressed: () async {
              if (await widget.onDelete!() && context.mounted) Navigator.pop(context);
            },
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: _submit, child: Text(widget.editing == null ? t.actionAdd : t.actionSave)),
      ],
    );
  }
}

/// A small drawing of the list as it will look: its name, icon and color, and the chosen view.
class _ListPreview extends StatelessWidget {
  const _ListPreview({required this.name, required this.emoji, required this.color, required this.viewMode, required this.notes});

  final String name;
  final String? emoji;
  final Color? color;
  final ViewMode viewMode;
  final bool notes;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final accent = color ?? tt.primary;
    Widget bar(double width, {double height = 8, Color? fill}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: fill ?? tt.divider, borderRadius: BorderRadius.circular(4)),
    );
    Widget row(double width) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          notes
              ? Icon(Icons.sticky_note_2_outlined, size: 14, color: tt.textFaint)
              : Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    border: Border.all(color: tt.textFaint, width: 1.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
          const SizedBox(width: 8),
          bar(width),
        ],
      ),
    );
    final body = switch (viewMode) {
      ViewMode.kanban => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final n in [3, 2])
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: tt.hover, borderRadius: BorderRadius.circular(6)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(40, height: 6, fill: tt.textFaint),
                    for (var i = 0; i < n; i++)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        height: 22,
                        decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(4)),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ViewMode.timeline => Column(
        children: [
          for (final (left, width) in [(0.0, 90.0), (40.0, 120.0), (100.0, 70.0), (20.0, 60.0)])
            Padding(
              padding: EdgeInsets.only(left: left, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: bar(width, height: 12, fill: accent.withValues(alpha: 0.35)),
              ),
            ),
        ],
      ),
      ViewMode.list => Column(children: [row(150), row(110), row(170), row(90)]),
    };
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: tt.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (emoji != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(emoji!, style: const TextStyle(fontSize: 16)),
                ),
              Expanded(
                child: Text(
                  name.isEmpty ? t.untitled : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, color: name.isEmpty ? tt.textTertiary : tt.text),
                ),
              ),
              if (color != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 26,
            decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(6)),
          ),
          const SizedBox(height: 6),
          body,
        ],
      ),
    );
  }
}
