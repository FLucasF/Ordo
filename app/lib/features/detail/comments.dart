import 'dart:async';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/emoji_picker.dart';
import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/image_viewer.dart';

final _commentsProvider = StreamProvider.family<List<Comment>, String>((ref, taskId) => ref.watch(repositoryProvider).watchComments(taskId));

/// "Comentários N" at the end of the detail: avatar, name, time and text; editing and
/// deleting show on hover (always on phones).
class CommentsSection extends ConsumerWidget {
  const CommentsSection({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(_commentsProvider(taskId)).value ?? const <Comment>[];
    if (comments.isEmpty) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${t.commentsTitle} ${comments.length}',
            style: TextStyle(fontWeight: FontWeight.w600, color: tt.textSecondary, fontSize: TtText.small),
          ),
          const SizedBox(height: 8),
          for (final c in comments) _CommentTile(comment: c),
        ],
      ),
    );
  }
}

/// "Agora mesmo", "há 5 min", "há 3 h", then the date.
String commentTime(AppLocalizations t, DateTime created, DateTime now) {
  final diff = now.difference(created);
  if (diff.inMinutes < 1) return t.commentJustNow;
  if (diff.inMinutes < 60) return t.commentMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return t.commentHoursAgo(diff.inHours);
  return DateLabels(t).detailDate(created, isAllDay: false, today: startOfDay(now));
}

class _CommentTile extends ConsumerStatefulWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  ConsumerState<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<_CommentTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final c = widget.comment;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final touch = Theme.of(context).platform == TargetPlatform.android || Theme.of(context).platform == TargetPlatform.iOS;
    final repo = ref.read(repositoryProvider);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFF7B2FBE),
              child: Text(t.commentAuthor.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        t.commentAuthor,
                        style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w600, color: tt.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(commentTime(t, c.createdAt.toLocal(), now), style: TextStyle(fontSize: 11, color: tt.textTertiary)),
                      const Spacer(),
                      if (_hover || touch) ...[
                        InkWell(
                          onTap: () async {
                            final text = await promptText(context, title: t.commentEdit, initial: c.body);
                            if (text != null && text.trim().isNotEmpty) await repo.editComment(c.id, text);
                          },
                          child: Tooltip(
                            message: t.commentEdit,
                            child: Icon(Icons.edit_outlined, size: 15, color: tt.textTertiary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => unawaited(repo.deleteComment(c.id)),
                          child: Tooltip(
                            message: t.commentDelete,
                            child: Icon(Icons.delete_outline, size: 15, color: tt.textTertiary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Text, and the pictures sent with "![file](…)".
                  if (_commentText(c.body) case final text when text.isNotEmpty)
                    Text(
                      text,
                      style: TextStyle(color: tt.text, fontSize: TtText.body),
                    ),
                  for (final reference in _commentImages(c.body))
                    if (ref.read(attachmentStoreProvider).fileOf(reference) case final file? when file.existsSync())
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GestureDetector(
                          onTap: () => unawaited(showImageViewer(context, file)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 320),
                              child: Image.file(file, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The comment field above the detail footer: Enter sends and keeps it open; Esc closes it.
class CommentInput extends ConsumerStatefulWidget {
  const CommentInput({super.key, required this.taskId, required this.onClose});

  final String taskId;
  final VoidCallback onClose;

  @override
  ConsumerState<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends ConsumerState<CommentInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    await ref.read(repositoryProvider).addComment(widget.taskId, text);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tt.fieldFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tt.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: CallbackShortcuts(
              bindings: {const SingleActivator(LogicalKeyboardKey.escape): widget.onClose},
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                style: TextStyle(color: tt.text, fontSize: TtText.body),
                decoration: InputDecoration(hintText: t.commentHint, border: InputBorder.none, isCollapsed: true),
                onSubmitted: (text) => unawaited(_send(text)),
              ),
            ),
          ),
          // Emoji at the cursor.
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.emoji_emotions_outlined, size: 16, color: tt.textTertiary),
            onPressed: () async {
              final emoji = await showEmojiPicker(context);
              if (emoji == null || emoji.isEmpty) return;
              final selection = _controller.selection;
              final at = selection.isValid ? selection.start : _controller.text.length;
              final end = selection.isValid ? selection.end : at;
              _controller.value = TextEditingValue(
                text: _controller.text.replaceRange(at, end, emoji),
                selection: TextSelection.collapsed(offset: at + emoji.length),
              );
              _focus.requestFocus();
            },
          ),
          // A picture, stored with the task's attachments and sent right away.
          IconButton(
            tooltip: t.commentImage,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.image_outlined, size: 16, color: tt.textTertiary),
            onPressed: () async {
              final picked = await FilePicker.platform.pickFiles(type: FileType.image);
              final path = picked?.files.single.path;
              if (path == null) return;
              final reference = await ref.read(attachmentStoreProvider).add(File(path));
              final text = _controller.text.trim();
              await _send([if (text.isNotEmpty) text, '![file]($reference)'].join('\n'));
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.send, size: 16, color: tt.primary),
            onPressed: () => unawaited(_send(_controller.text)),
          ),
        ],
      ),
    );
  }
}

final _imagePattern = RegExp(r'!\[file\]\(([^)]+)\)');

/// The pictures of a comment (attachment references).
List<String> _commentImages(String body) => [for (final m in _imagePattern.allMatches(body)) m.group(1)!];

/// A comment without its pictures.
String _commentText(String body) => body.replaceAll(_imagePattern, '').trim();
