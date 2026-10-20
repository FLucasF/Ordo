import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/emoji_picker.dart';
import '../common/feedback.dart';

// Folders are "Áreas" on screen ("Saúde", "Faculdade"): they group lists in the sidebar, with an emoji
// and a color of their own.

/// Result of the area dialog.
class FolderForm {
  const FolderForm({required this.name, required this.icon, required this.color});

  final String name;
  final String? icon;
  final String? color;
}

/// "Nova área" / "Editar área". Returns null when cancelled; editing, [onDelete] shows the bin and the
/// dialog closes when it deleted.
Future<FolderForm?> showFolderDialog(BuildContext context, {Folder? editing, Future<bool> Function()? onDelete}) => showDialog<FolderForm>(
  context: context,
  builder: (_) => _FolderDialog(editing: editing, onDelete: onDelete),
);

/// "+ Nova área": asks and creates it; returns its id.
Future<String?> createFolderWithDialog(BuildContext context, WidgetRef ref) async {
  final form = await showFolderDialog(context);
  if (form == null) return null;
  return ref.read(repositoryProvider).createFolder(form.name, icon: form.icon, color: form.color);
}

/// "Deletar área": its lists leave it (nothing else is deleted), with "Desfazer" in the toast.
Future<bool> deleteFolderWithUndo(BuildContext context, WidgetRef ref, Folder folder) async {
  final t = AppLocalizations.of(context);
  final repo = ref.read(repositoryProvider);
  final lists = await repo.deleteFolder(folder.id);
  if (context.mounted) showToast(context, t.folderDeleted(folder.name), undo: () => repo.restoreFolder(folder.id, lists));
  return true;
}

/// "Editar área": the dialog (its bin deletes with "Desfazer") and the changes saved.
Future<void> editFolderWithDialog(BuildContext context, WidgetRef ref, Folder folder, {VoidCallback? onDeleted}) async {
  final form = await showFolderDialog(
    context,
    editing: folder,
    onDelete: () async {
      final deleted = await deleteFolderWithUndo(context, ref, folder);
      if (deleted) onDeleted?.call();
      return deleted;
    },
  );
  if (form == null) return;
  await ref.read(repositoryProvider).editFolder(folder.id, name: form.name, icon: form.icon, color: form.color);
}

/// The area's emoji, or the folder icon.
Widget folderIcon(Folder f, {bool open = false, double size = 15}) => f.icon != null && f.icon!.isNotEmpty
    ? Text(f.icon!, style: TextStyle(fontSize: size))
    : Icon(open ? Icons.folder_open_outlined : Icons.folder_outlined);

class _FolderDialog extends StatefulWidget {
  const _FolderDialog({this.editing, this.onDelete});

  final Folder? editing;
  final Future<bool> Function()? onDelete;

  @override
  State<_FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<_FolderDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.editing?.name ?? '');
  late String? _icon = widget.editing?.icon;
  late String? _color = widget.editing?.color;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(context, FolderForm(name: _name.text.trim(), icon: _icon, color: _color));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return AlertDialog(
      title: Text(widget.editing == null ? t.folderNew : t.folderEditTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Tooltip(
                  message: t.folderIcon,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showEmojiPicker(context);
                      // "Redefinir" ('') goes back to the folder icon.
                      if (picked != null) setState(() => _icon = picked.isEmpty ? null : picked);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(6)),
                      child: _icon == null
                          ? Icon(Icons.folder_outlined, color: parseHexColor(_color) ?? tt.textSecondary)
                          : Text(_icon!, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _name,
                    autofocus: true,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: t.folderNameHint,
                      filled: true,
                      fillColor: tt.fieldFill,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(t.folderColor, style: TextStyle(color: tt.textSecondary)),
            const SizedBox(height: 6),
            ColorChoice(value: _color, onChanged: (c) => setState(() => _color = c)),
          ],
        ),
      ),
      actions: [
        if (widget.editing != null && widget.onDelete != null)
          IconButton(
            tooltip: t.actionDelete,
            icon: Icon(Icons.delete_outline, color: tt.overdue),
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
