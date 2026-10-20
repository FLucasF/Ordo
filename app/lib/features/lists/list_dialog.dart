import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../l10n/app_localizations.dart';
import '../appearance/backdrop.dart';
import '../common/color_choice.dart';
import '../common/emoji_picker.dart';
import '../common/feedback.dart';

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
    this.background,
  });

  final String name;
  final String? emoji;
  final String? color;
  final String? folderId;
  final ListKind kind;
  final ViewMode viewMode;
  final bool showInSmartLists;

  /// "Fundo" (features/appearance/backgrounds.dart): null = the folder's or the app's.
  final String? background;
}

/// Deletes a list after asking (its tasks go to the trash); true when it did. Leaving it, when it was
/// open, is the caller's.
Future<bool> deleteListAsking(BuildContext context, WidgetRef ref, TaskList l) async {
  final t = AppLocalizations.of(context);
  if (!await confirm(context, message: t.deleteListConfirm, confirmLabel: t.actionDelete) || !context.mounted) return false;
  final repo = ref.read(repositoryProvider);
  return guarded(context, () => repo.deleteList(l.id));
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
  if (form == null) return;
  await repo.editList(
    l.id,
    name: form.name,
    emoji: form.emoji,
    color: form.color,
    folderId: form.folderId,
    kind: form.kind,
    viewMode: form.viewMode,
    showInSmartLists: form.showInSmartLists,
  );
  if (form.background != l.background) await repo.setListBackground(l.id, form.background);
}

/// "Adicionar lista" / "Editar lista". Returns null when cancelled.
///
/// Editing, [onDelete] shows the bin: it asks and deletes, and the dialog closes when it did.
Future<ListForm?> showListDialog(BuildContext context, {TaskList? editing, String? folderId, Future<bool> Function()? onDelete}) =>
    showDialog<ListForm>(
      context: context,
      builder: (_) => _ListDialog(editing: editing, initialFolderId: folderId, onDelete: onDelete),
    );

class _ListDialog extends ConsumerStatefulWidget {
  const _ListDialog({this.editing, this.initialFolderId, this.onDelete});

  final TaskList? editing;
  final String? initialFolderId;
  final Future<bool> Function()? onDelete;

  @override
  ConsumerState<_ListDialog> createState() => _ListDialogState();
}

class _ListDialogState extends ConsumerState<_ListDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.editing?.name ?? '');
  late String? _emoji = widget.editing?.emoji;
  late String? _color = widget.editing?.color;
  late String? _folderId = widget.editing?.folderId ?? widget.initialFolderId;
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
        kind: _kind,
        viewMode: _viewMode,
        showInSmartLists: _showInSmartLists,
        background: _background,
      ),
    );
  }

  Future<void> _pickEmoji() async {
    final picked = await showEmojiPicker(context);
    // "Redefinir" ('') removes the icon.
    if (picked != null) setState(() => _emoji = picked.isEmpty ? null : picked);
  }

  Future<void> _newFolder() async {
    final t = AppLocalizations.of(context);
    final name = await promptText(context, title: t.folderNew, hint: t.listNameHint, cancelLabel: t.actionClose);
    if (name == null) return;
    final id = await ref.read(repositoryProvider).createFolder(name);
    if (mounted) setState(() => _folderId = id);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final folders = ref.watch(snapshotProvider).value?.activeFolders ?? const <Folder>[];

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
                      InkWell(
                        onTap: _pickEmoji,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(6)),
                          child: _emoji == null ? Icon(Icons.list, color: tt.textSecondary) : Text(_emoji!, style: const TextStyle(fontSize: 18)),
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
                  row(
                    t.listFolder,
                    DropdownButton<String?>(
                      value: _folderId,
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
