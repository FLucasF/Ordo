import 'dart:async';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/labels.dart';
import '../date_picker/date_picker.dart';
import '../templates/templates.dart';
import 'quick_add_input.dart';

/// Global quick add ("N" / "Tab+N" outside a field): a floating box with the title (tokens
/// included), the icons Data · Prioridade · Lista · Tag and "Adicionar". Enter adds and closes.
/// [schedule] starts the modal with a date (the calendar's click or drag).
/// [sectionId]: the section the task goes to (a timeline group).
Future<void> showQuickAddModal(
  BuildContext context, {
  required AddTarget target,
  Priority priority = Priority.none,
  DateSelection? schedule,
  String? sectionId,
}) => showDialog<void>(
  context: context,
  builder: (_) => _QuickAddModal(target: target, priority: priority, schedule: schedule, sectionId: sectionId),
);

class _QuickAddModal extends ConsumerStatefulWidget {
  const _QuickAddModal({required this.target, this.priority = Priority.none, this.schedule, this.sectionId});

  final AddTarget target;
  final DateSelection? schedule;
  final String? sectionId;

  /// Starting priority (the Matrix quadrant's "+").
  final Priority priority;

  @override
  ConsumerState<_QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends ConsumerState<_QuickAddModal> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late DateSelection? _schedule = widget.schedule ?? (widget.target.dueDate == null ? null : DateSelection(dueDate: widget.target.dueDate));
  late Priority _priority = widget.priority;
  late String _listId = widget.target.listId;
  final Set<String> _tags = {};

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// "…" › Anexo and Converter para nota.
  List<String> _files = const [];
  bool _asNote = false;

  Future<void> _add() async {
    final id = await createFromQuickAdd(
      ref,
      AppLocalizations.of(context),
      text: _controller.text,
      // The modal's own choices replace the view's defaults.
      target: AddTarget(listId: _listId, hint: widget.target.hint, tagId: widget.target.tagId),
      schedule: _schedule,
      priority: _priority,
      tagIds: _tags,
      sectionId: widget.sectionId,
      kind: _asNote ? TaskKind.note : null,
    );
    if (id != null && _files.isNotEmpty) {
      final store = ref.read(attachmentStoreProvider);
      final cards = [for (final path in _files) '![file](${await store.add(File(path))})'];
      await ref.read(repositoryProvider).setContent(id, cards.join('\n'));
    }
    if (id != null && mounted) Navigator.pop(context);
  }

  Future<void> _fromTemplate() async {
    final template = await pickTemplate(context);
    if (template == null || !mounted) return;
    await ref.read(repositoryProvider).createTaskFromTemplate(template.id, listId: _listId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showTtDatePicker(context, initial: _schedule ?? const DateSelection(), now: ref.read(clockProvider).now());
    if (picked != null) setState(() => _schedule = picked.dueDate == null ? null : picked);
    _focus.requestFocus();
  }

  Widget _icon(IconData icon, String tooltip, {Color? color, VoidCallback? onPressed, Widget? label}) {
    final tt = context.tt;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: color ?? tt.textTertiary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
      ),
      onPressed: onPressed,
      icon: Tooltip(message: tooltip, child: Icon(icon, size: 18)),
      label: label ?? const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final today = startOfDay(ref.watch(clockProvider).now());
    final list = s.listById[_listId];
    final schedule = _schedule;

    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final extras = <Widget>[
      if (_files.isNotEmpty)
        _icon(
          Icons.attach_file,
          t.slashAttachment,
          color: tt.primary,
          onPressed: () => setState(() => _files = const []),
          label: Text('${_files.length}'),
        ),
      if (_asNote) _icon(Icons.sticky_note_2_outlined, t.addAsNote, color: tt.primary, onPressed: () => setState(() => _asNote = false)),
      // "…": Anexo, Adicionar a partir do modelo, Converter para nota.
      PopupMenuButton<String>(
        tooltip: '',
        icon: Icon(Icons.more_horiz, size: 18, color: tt.textTertiary),
        onSelected: (v) async {
          switch (v) {
            case 'attach':
              final result = await FilePicker.platform.pickFiles(allowMultiple: true);
              final paths = [for (final f in result?.files ?? const <PlatformFile>[]) ?f.path];
              if (paths.isNotEmpty && mounted) setState(() => _files = [..._files, ...paths]);
            case 'note':
              setState(() => _asNote = !_asNote);
            default:
              await _fromTemplate();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'attach', height: 36, child: Text(t.slashAttachment)),
          PopupMenuItem(value: 'template', height: 36, child: Text(t.templateAddFrom)),
          CheckedPopupMenuItem(value: 'note', checked: _asNote, child: Text(t.addAsNote)),
        ],
      ),
    ];

    return Dialog(
      alignment: const Alignment(0, -0.6),
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuickAddTextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                // The hint: "O que você gostaria de fazer?".
                hint: t.quickAddModalHint,
                style: TextStyle(fontSize: 16, color: tt.text),
                onSubmitted: (_) => unawaited(_add()),
              ),
              const SizedBox(height: 12),
              // A phone has the tools on one line and Cancelar / Adicionar on the next; a window, all on one.
              _ToolsAndButtons(
                narrow: narrow,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _icon(
                        Icons.calendar_today_outlined,
                        t.pickerTabDate,
                        color: schedule == null ? null : tt.primary,
                        onPressed: () => unawaited(_pickDate()),
                        label: schedule == null
                            ? null
                            : Text(
                                DateLabels(t).detailDate(schedule.dueDate!, isAllDay: schedule.isAllDay, today: today),
                                style: const TextStyle(fontSize: TtText.small),
                              ),
                      ),
                      PopupMenuButton<Priority>(
                        tooltip: t.menuPriority,
                        onSelected: (p) => setState(() => _priority = p),
                        itemBuilder: (_) => [
                          for (final p in Priority.values.reversed)
                            PopupMenuItem(
                              value: p,
                              height: 36,
                              child: Row(
                                children: [
                                  Icon(Icons.flag, size: 18, color: tt.priorityColor(p)),
                                  const SizedBox(width: 10),
                                  Text(labels.priority(p)),
                                ],
                              ),
                            ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _priority == Priority.none ? Icons.outlined_flag : Icons.flag,
                            size: 18,
                            color: _priority == Priority.none ? tt.textTertiary : tt.priorityColor(_priority),
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: t.searchFilterLists,
                        onSelected: (id) => setState(() => _listId = id),
                        itemBuilder: (_) => [
                          for (final l in s.activeLists) CheckedPopupMenuItem(value: l.id, checked: l.id == _listId, child: Text(labels.listName(l))),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.list, size: 18, color: parseHexColor(list?.color) ?? tt.textTertiary),
                              if (list != null) ...[
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 120),
                                  child: Text(
                                    labels.listName(list),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: t.searchFilterTag,
                        onSelected: (id) => setState(() => _tags.contains(id) ? _tags.remove(id) : _tags.add(id)),
                        itemBuilder: (_) => [
                          for (final tag in s.activeTags) CheckedPopupMenuItem(value: tag.id, checked: _tags.contains(tag.id), child: Text(tag.name)),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sell_outlined, size: 18, color: _tags.isEmpty ? tt.textTertiary : tt.primary),
                              if (_tags.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${_tags.length}',
                                  style: TextStyle(fontSize: TtText.small, color: tt.primary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (narrow) ...extras,
                    ],
                  ),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      if (!narrow) ...extras,
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
                      FilledButton(onPressed: () => unawaited(_add()), child: Text(t.quickAddButton)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tools and the buttons: side by side in a window; on a phone, the buttons under the tools.
class _ToolsAndButtons extends StatelessWidget {
  const _ToolsAndButtons({required this.narrow, required this.children});

  final bool narrow;

  /// The tools, then the buttons.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => narrow
      ? Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            children.first,
            Align(alignment: Alignment.centerRight, child: children.last),
          ],
        )
      : Row(
          children: [
            Expanded(child: children.first),
            children.last,
          ],
        );
}
