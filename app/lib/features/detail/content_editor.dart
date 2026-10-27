import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../app/theme/app_theme.dart';
import '../../data/attachment_store.dart';
import '../../l10n/app_localizations.dart';
import '../editor/attachment_block.dart';
import '../editor/markdown_codec.dart';
import '../editor/format_bar.dart';
import '../editor/slash_menu.dart';
import '../search/task_link_picker.dart';

/// Markdown content editor of the task. Saves after a short pause in typing.
class ContentEditor extends StatefulWidget {
  const ContentEditor({
    super.key,
    required this.markdown,
    required this.onChanged,
    required this.placeholder,
    this.taskId,
    this.onOpenTask,
    this.attachments,
    this.onAddSubtask,
    this.onAddTag,
    this.templateMarkdown,
    this.showFormatBar = false,
    this.now = DateTime.now,
    this.onImmersive,
    this.minHeight = 32,
  });

  final String markdown;
  final ValueChanged<String> onChanged;
  final String placeholder;

  /// The task being edited (left out of the "[[" list).
  final String? taskId;

  /// Opens a linked task (`[título](task:<id>)`).
  final void Function(String taskId)? onOpenTask;

  /// Where attached files are kept ("/ Anexo").
  final AttachmentStore? attachments;

  /// "/ Subtarefa" and "/ Tag".
  final VoidCallback? onAddSubtask;
  final VoidCallback? onAddTag;

  /// "/ Adicionar a partir do modelo": picks a template and returns its content as
  /// markdown, inserted where the cursor is; null when cancelled.
  final Future<String?> Function()? templateMarkdown;

  /// The formatting bar above the text (the "A" of the detail footer).
  final bool showFormatBar;

  /// The clock for the bar's "Tempo".
  final DateTime Function() now;

  /// "Escrita Imersiva" (the bar's button and Ctrl+Alt+U).
  final VoidCallback? onImmersive;

  /// The box's least height: room to click into before there is text (the task's notes have more).
  final double minHeight;

  @override
  State<ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<ContentEditor> {
  late EditorState _editor;

  /// appflowy lays the document out as a plain column ("shrinkWrap"): where the text ends does not
  /// depend on the box's height, so fitting the box to it settles at once. (Its default lazy list
  /// scrolled itself while the box was fitted, and typing past the end of a line fought it until
  /// the app froze.)
  late EditorScrollController _scroll;
  StreamSubscription<EditorTransactionValue>? _subscription;
  Timer? _debounce;

  /// The markdown the document was built from or last saved as. Set in [initState], not lazily: read
  /// for the first time in [didUpdateWidget], a lazy value would already be the new markdown and the
  /// change would be missed.
  late String _lastSaved;

  @override
  void initState() {
    super.initState();
    _lastSaved = widget.markdown;
    _editor = _build(widget.markdown);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
  }

  /// Height given to the editor. appflowy's overlay always fills its box, so the box follows the content:
  /// after each edit it is measured to where the text ends (a mark after the last block), and it grows
  /// from the scroll metrics when that mark is out of sight. It never drops small and grows back on
  /// each key: on a phone that jumped at every letter.
  /// appflowy loops forever when the caret's line is taller than the box, so with a heading (or an
  /// attachment card) the box never goes below a Título 1 line.
  static const _headingMinHeight = 72.0;
  late double _height = _floor();

  final _box = GlobalKey();

  /// Whether the document has no text, for the placeholder.
  bool _empty = true;

  /// After the last block; a new one for each document (the old editor's may still be in the tree).
  GlobalKey _end = GlobalKey();

  /// Fits the box to where the text ends (the mark after the last block, plus what is scrolled).
  void _fit() {
    final end = _end.currentContext;
    final box = _box.currentContext?.findRenderObject();
    if (!mounted || end == null || box is! RenderBox || !box.hasSize) return;
    final mark = end.findRenderObject();
    if (mark is! RenderBox || !mark.attached) return;
    final scrolled = Scrollable.maybeOf(end)?.position.pixels ?? 0;
    final content = mark.localToGlobal(Offset.zero, ancestor: box).dy + scrolled;
    final height = content < _floor() ? _floor() : content;
    if ((height - _height).abs() > 0.5) setState(() => _height = height);
  }

  double _floor() {
    final heading = _editor.document.root.children.any((n) => n.type == HeadingBlockKeys.type || n.type == AttachmentBlockKeys.type);
    return heading && widget.minHeight < _headingMinHeight ? _headingMinHeight : widget.minHeight;
  }

  /// Keeps the caret in sight in the page around the editor (the detail scrolls, not the editor), as
  /// the text grows below the screen's edge.
  void _keepCaretInView() {
    if (!mounted || _editor.selection == null) return;
    final rects = _editor.selectionRects();
    final outer = Scrollable.maybeOf(context);
    final view = outer?.context.findRenderObject();
    if (rects.isEmpty || outer == null || view is! RenderBox || !view.hasSize) return;
    final caret = rects.last;
    final top = view.localToGlobal(Offset.zero).dy;
    final bottom = top + view.size.height;
    const margin = 24.0;
    final position = outer.position;
    double? to;
    if (caret.bottom > bottom - margin) to = position.pixels + caret.bottom - bottom + margin;
    if (caret.top < top + margin) to = position.pixels - (top + margin - caret.top);
    if (to != null) position.jumpTo(to.clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  /// A click below the text puts the caret at its end, so the whole box is a place to write.
  void _caretToEndIfBelow(PointerUpEvent event) {
    final end = _end.currentContext?.findRenderObject();
    final box = _box.currentContext?.findRenderObject();
    if (end is! RenderBox || box is! RenderBox || !end.attached) return;
    final textEnd = end.localToGlobal(Offset.zero, ancestor: box).dy;
    if (box.globalToLocal(event.position).dy <= textEnd) return;
    // After appflowy's own handling of the click.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final last = _editor.document.root.children.lastOrNull;
      if (last == null) return;
      _editor.selection = Selection.collapsed(Position(path: last.path, offset: last.delta?.length ?? 0));
    });
  }

  EditorState _build(String markdown) {
    final state = EditorState(document: markdown.trim().isEmpty ? Document.blank(withInitialText: true) : markdownToEditorDocument(markdown));
    _end = GlobalKey();
    _scroll = EditorScrollController(editorState: state, shrinkWrap: true);
    _subscription?.cancel();
    _empty = state.document.isEmpty;
    _subscription = state.transactionStream.listen((_) {
      _scheduleSave();
      // The placeholder goes with the first letter and comes back when it is all erased: the editor
      // itself does not rebuild this widget.
      if (mounted && state.document.isEmpty != _empty) setState(() => _empty = state.document.isEmpty);
      // A heading (or attachment) just added needs its taller floor at once: appflowy loops when the
      // caret's line is taller than the box. It never goes down here, only in [_fit].
      final floor = _floor();
      if (mounted && _height < floor) setState(() => _height = floor);
      // Once the edit is laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fit();
        WidgetsBinding.instance.addPostFrameCallback((_) => _keepCaretInView());
      });
    });
    return state;
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _save);
  }

  void _save() {
    final markdown = editorDocumentToMarkdown(_editor.document);
    if (markdown == _lastSaved) return;
    _lastSaved = markdown;
    widget.onChanged(markdown);
  }

  @override
  void didUpdateWidget(ContentEditor old) {
    super.didUpdateWidget(old);
    // Another task opened, or the content changed elsewhere: rebuild the document.
    if (widget.markdown != _lastSaved) {
      _debounce?.cancel();
      final (oldEditor, oldScroll) = (_editor, _scroll);
      _editor = _build(widget.markdown);
      // After the frame: the old editor may still be in the tree for it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldScroll.dispose();
        oldEditor.dispose();
      });
      _lastSaved = widget.markdown;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
    }
  }

  @override
  void dispose() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _save();
    }
    unawaited(_subscription?.cancel());
    _scroll.dispose();
    _editor.dispose();
    super.dispose();
  }

  /// Asks for a task and inserts its title as a link at the cursor.
  Future<void> _insertTaskLink(EditorState editor) async {
    final selection = editor.selection;
    if (selection == null || !mounted) return;
    final task = await pickTaskToLink(context, excludeId: widget.taskId);
    final node = editor.getNodeAtPath(selection.start.path);
    if (task == null || node == null || !mounted) return;
    final t = AppLocalizations.of(context);
    final title = task.title.isEmpty ? t.untitled : task.title;
    final offset = selection.start.offset;
    await editor.apply(
      editor.transaction
        ..insertText(node, offset, title, attributes: {AppFlowyRichTextKeys.href: taskLinkHref(task.id)})
        ..insertText(node, offset + title.length, ' ')
        ..afterSelection = Selection.collapsed(Position(path: selection.start.path, offset: offset + title.length + 1)),
    );
  }

  /// "/ Anexo": picks files, copies them to the store and inserts a card for each.
  Future<void> _attach(EditorState editor) async {
    final store = widget.attachments;
    final selection = editor.selection;
    if (store == null || selection == null) return;
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    final paths = [for (final f in result?.files ?? const <PlatformFile>[]) ?f.path];
    if (paths.isEmpty || !mounted) return;
    final references = [for (final path in paths) await store.add(File(path))];
    final at = selection.end.path.next;
    await editor.apply(
      editor.transaction
        ..insertNodes(at, [for (final r in references) attachmentNode(r), paragraphNode()])
        ..afterSelection = Selection.collapsed(Position(path: at.nextNPath(references.length))),
    );
  }

  /// "/ Adicionar a partir do modelo": the template's content goes in after the current line.
  Future<void> _insertTemplate(EditorState editor) async {
    final pick = widget.templateMarkdown;
    final selection = editor.selection;
    if (pick == null || selection == null) return;
    final markdown = await pick();
    if (markdown == null || markdown.trim().isEmpty || !mounted) return;
    final nodes = [for (final n in markdownToEditorDocument(markdown).root.children) n.deepCopy()];
    if (nodes.isEmpty) return;
    final at = selection.end.path.next;
    await editor.apply(
      editor.transaction
        ..insertNodes(at, nodes)
        ..afterSelection = Selection.collapsed(Position(path: at.nextNPath(nodes.length - 1))),
    );
  }

  Future<void> _openAttachment(String reference) async {
    final file = widget.attachments?.fileOf(reference);
    if (file != null && file.existsSync()) await OpenFilex.open(file.path);
  }

  Future<void> _downloadAttachment(String reference) async {
    final file = widget.attachments?.fileOf(reference);
    if (file == null || !file.existsSync()) return;
    final bytes = await file.readAsBytes();
    final path = await FilePicker.platform.saveFile(fileName: reference.substring(reference.indexOf('/') + 1), bytes: bytes);
    // Desktop returns the chosen path; write it when the picker did not.
    if (path != null && !File(path).existsSync()) await File(path).writeAsBytes(bytes);
  }

  /// "[[": the second "[" opens the task list instead of being typed; the first one is removed.
  CharacterShortcutEvent get _linkShortcut => CharacterShortcutEvent(
    key: 'link a task',
    character: '[',
    handler: (editor) async {
      final selection = editor.selection;
      if (selection == null || !selection.isCollapsed || selection.start.offset == 0) return false;
      final node = editor.getNodeAtPath(selection.start.path);
      final text = node?.delta?.toPlainText() ?? '';
      final offset = selection.start.offset;
      if (node == null || offset > text.length || text[offset - 1] != '[') return false;
      await editor.apply(
        editor.transaction
          ..deleteText(node, offset - 1, 1)
          ..afterSelection = Selection.collapsed(Position(path: selection.start.path, offset: offset - 1)),
      );
      await _insertTaskLink(editor);
      return true;
    },
  );

  /// Task links open the task on a click; other links keep appflowy's behavior.
  TextSpan _decorateLinks(BuildContext context, Node node, int index, TextInsert text, TextSpan before, TextSpan after) {
    final href = text.attributes?[AppFlowyRichTextKeys.href];
    final taskId = href is String ? taskIdOfHref(href) : null;
    if (taskId == null || widget.onOpenTask == null) return defaultTextSpanDecoratorForAttribute(context, node, index, text, before, after);
    return TextSpan(
      style: before.style,
      text: text.text,
      recognizer: TapGestureRecognizer()..onTap = () => widget.onOpenTask!(taskId),
      mouseCursor: SystemMouseCursors.click,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    final mobile = Platform.isAndroid;
    final items = [
      ...formattingSlashMenuItems(t),
      if (widget.attachments != null) SlashMenuItem(t.slashAttachment, Icons.attach_file, _attach),
      if (widget.onAddSubtask case final add?) SlashMenuItem(t.slashSubtask, Icons.subdirectory_arrow_right, (_) async => add()),
      if (widget.onAddTag case final add?) SlashMenuItem(t.slashTag, Icons.sell_outlined, (_) async => add()),
      SlashMenuItem(t.slashLinkedTask, Icons.link, _insertTaskLink),
      if (widget.templateMarkdown != null) SlashMenuItem(t.slashTemplate, Icons.dashboard_customize_outlined, _insertTemplate),
    ];
    final text = TextStyleConfiguration(
      text: TextStyle(color: tt.text, fontSize: TtText.body, height: 21 / 14),
    );
    final style = mobile
        ? EditorStyle.mobile(textStyleConfiguration: text, cursorColor: tt.primary, padding: EdgeInsets.zero, textSpanDecorator: _decorateLinks)
        : EditorStyle.desktop(
            textStyleConfiguration: text,
            cursorColor: tt.primary,
            padding: EdgeInsets.zero,
            selectionColor: tt.primary.withValues(alpha: 0.3),
            textSpanDecorator: _decorateLinks,
          );
    final editor = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        final content = n.metrics.maxScrollExtent + n.metrics.viewportDimension;
        if (n.metrics.maxScrollExtent > 0 && content != _height) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _height = content);
          });
        }
        return false;
      },
      child: Listener(
        onPointerUp: _caretToEndIfBelow,
        child: SizedBox(
          key: _box,
          height: _height,
          child: Stack(
            children: [
              if (_empty)
                IgnorePointer(
                  child: Text(
                    widget.placeholder,
                    style: TextStyle(color: tt.textFaint, fontSize: TtText.body, height: 21 / 14),
                  ),
                ),
              AppFlowyEditor(
                editorState: _editor,
                editorScrollController: _scroll,
                shrinkWrap: true,
                // The box always fits the whole text and the page around it scrolls (see
                // _keepCaretInView): appflowy's own scrolling to the caret, in a box still growing
                // to the new line, looped without end and froze the app (Diário on Windows).
                disableAutoScroll: true,
                editorStyle: style,
                footer: SizedBox(key: _end, height: 0),
                blockComponentBuilders: {
                  ...standardBlockComponentBuilderMap,
                  AttachmentBlockKeys.type: AttachmentBlockBuilder(
                    describeSize: widget.attachments?.describeSize ?? (_) => '',
                    onOpen: (r) => unawaited(_openAttachment(r)),
                    onDownload: (r) => unawaited(_downloadAttachment(r)),
                    fileOf: widget.attachments?.fileOf,
                    openLabel: t.attachmentOpenExternal,
                    downloadLabel: t.exportDownload,
                    deleteLabel: t.actionDelete,
                  ),
                },
                characterShortcutEvents: [
                  _linkShortcut,
                  if (mobile) mobileSlashMenu(items, () => context) else desktopSlashMenu(items),
                  ...standardCharacterShortcutEvents.where((e) => e != slashCommand),
                ],
                commandShortcutEvents: [
                  if (widget.onImmersive case final open?)
                    CommandShortcutEvent(
                      key: 'immersive writing',
                      getDescription: () => 'Escrita Imersiva',
                      command: 'ctrl+alt+u',
                      handler: (_) {
                        open();
                        return KeyEventResult.handled;
                      },
                    ),
                  ...standardCommandShortcutEvents,
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!widget.showFormatBar) return editor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormatBar(editor: _editor, now: widget.now, onImmersive: widget.onImmersive),
        editor,
      ],
    );
  }
}
