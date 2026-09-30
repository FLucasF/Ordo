import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repository.dart';
import '../../l10n/app_localizations.dart';
import 'labels.dart';

/// Toast at the bottom of the screen, optionally with "Desfazer".
/// The last action that can be undone with Ctrl+Z (the one whose toast offered "Desfazer") and, once
/// undone, redone with Ctrl+Shift+Z. One step, as the toasts.
abstract final class ActionHistory {
  static Future<void> Function()? _undo;
  static Future<void> Function()? _redo;
  static Future<void> Function()? _undone;

  static void record({required Future<void> Function() undo, Future<void> Function()? redo}) {
    _undo = undo;
    _redo = redo;
    _undone = null;
  }

  /// Undoes the last action; false when there is none.
  static Future<bool> undo() async {
    final undo = _undo;
    if (undo == null) return false;
    _undo = null;
    await undo();
    _undone = _redo;
    return true;
  }

  /// Does again what was just undone; false when there is nothing.
  static Future<bool> redo() async {
    final redo = _undone;
    if (redo == null) return false;
    _undone = null;
    await redo();
    return true;
  }

  static void clear() => _undo = _redo = _undone = null;
}

/// A toast; with [undo], a "Desfazer" button, and Ctrl+Z does the same ([redo] makes Ctrl+Shift+Z work).
void showToast(BuildContext context, String message, {Future<void> Function()? undo, Future<void> Function()? redo}) {
  if (undo != null) ActionHistory.record(undo: undo, redo: redo);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final t = AppLocalizations.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        // With "Desfazer", a bit longer to reach it; then it goes away on its own (Flutter keeps a toast
        // with an action until tapped unless told otherwise).
        duration: Duration(seconds: undo == null ? 3 : 5),
        persist: false,
        action: undo == null ? null : SnackBarAction(label: t.toastUndo, onPressed: () => unawaited(undo())),
      ),
    );
}

/// Runs a write and shows the rule message as a toast when a business rule is broken.
Future<bool> guarded(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } on RuleViolation catch (e) {
    if (context.mounted) showToast(context, Labels(AppLocalizations.of(context)).rule(e.rule));
    return false;
  }
}

Future<bool> confirm(BuildContext context, {required String message, String? confirmLabel}) async {
  final t = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: SizedBox(width: 360, child: Text(message)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.actionCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel ?? t.actionOk)),
      ],
    ),
  );
  return result ?? false;
}

/// Single-field text prompt (rename, new section, new folder).
/// [cancelLabel]: "Fechar" where TickTick says so ("Nova Pasta"); "Cancelar" by default.
/// [message]: explanation above the field ("Salvar como modelo" of the Resumo).
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String initial = '',
  String? hint,
  String? cancelLabel,
  String? message,
}) async {
  final t = AppLocalizations.of(context);
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (message != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(message)),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.all(10)),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(cancelLabel ?? t.actionCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(t.actionSave)),
      ],
    ),
  );
  controller.dispose();
  final trimmed = result?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
