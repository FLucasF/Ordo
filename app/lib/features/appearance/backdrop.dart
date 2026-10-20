import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/preferences_repository.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import 'backgrounds.dart';

/// A background [code] painted over the theme's screen color, veiled by [dim] of that same color: the
/// veil darkens in the dark theme and lightens in the light one, so the text keeps its contrast.
class BackgroundLayer extends ConsumerWidget {
  const BackgroundLayer({super.key, required this.code, required this.dim});

  final String code;
  final double dim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = context.tt;
    final gradient = BuiltInGradient.fromCode(code);
    final picture = backgroundPicture(code);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: tt.screen),
        if (gradient != null)
          DecoratedBox(
            decoration: BoxDecoration(gradient: gradient.gradient(dark: tt.isDark)),
          )
        else if (picture != null)
          Image.file(
            File(p.join(ref.watch(backgroundsDirProvider).path, picture)),
            fit: BoxFit.cover,
            // Decoded no wider than a large screen: a phone photo would otherwise take a lot of memory.
            cacheWidth: 2560,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        if (dim > 0) ColoredBox(color: tt.screen.withValues(alpha: dim)),
      ],
    );
  }
}

/// Marks the widgets painted over a background: their panes leave their own color out ([paneColor]).
class _OnBackdrop extends InheritedWidget {
  const _OnBackdrop({super.key, required this.active, required super.child});

  final bool active;

  @override
  bool updateShouldNotify(_OnBackdrop old) => old.active != active;
}

extension BackdropContext on BuildContext {
  /// The fill of a page body: the theme's screen color, or nothing over a background ([AppBackdrop]).
  Color get paneColor => (dependOnInheritedWidgetOfExactType<_OnBackdrop>()?.active ?? false) ? Colors.transparent : tt.screen;
}

/// The "Papel de parede" behind [child]: the app's, or for [scope] its list's or folder's
/// ([backgroundFor]). Without one, [child] alone. Bodies under it use [BackdropContext.paneColor].
class AppBackdrop extends ConsumerWidget {
  const AppBackdrop({super.key, this.scope, required this.child});

  final Scope? scope;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final snapshot = scope is ListScope || scope is FolderScope ? ref.watch(snapshotProvider).value : null;
    final code = snapshot == null
        ? (hasBackground(prefs.background) ? prefs.background : null)
        : backgroundFor(snapshot, scope, app: prefs.background);
    // The same tree with or without a background, so turning it on keeps the page's state (scroll, typing).
    return Stack(
      fit: StackFit.expand,
      children: [
        if (code != null) BackgroundLayer(code: code, dim: prefs.backgroundDim),
        _OnBackdrop(key: const ValueKey('content'), active: code != null, child: child),
      ],
    );
  }
}

/// The choice of a background: [inherit] adds "Padrão" (null: the folder's or the app's) before
/// "Nenhum"; then the gradients, the picture in use and "Escolher imagem".
class BackgroundChoices extends ConsumerWidget {
  const BackgroundChoices({super.key, required this.value, required this.onChanged, this.inherit = false});

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool inherit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final none = inherit ? noBackground : null;
    final picture = backgroundPicture(value);

    Widget tile({required String tooltip, required bool selected, required VoidCallback onTap, Widget? fill, IconData? icon}) => Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 32,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tt.fieldFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? tt.primary : tt.divider, width: selected ? 2 : 1),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ?fill,
              if (selected)
                const Center(
                  child: Icon(Icons.check, size: 16, color: Colors.white, shadows: [Shadow(blurRadius: 3)]),
                )
              else if (icon != null)
                Icon(icon, size: 16, color: tt.textSecondary),
            ],
          ),
        ),
      ),
    );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (inherit) tile(tooltip: t.backgroundDefault, selected: value == null, icon: Icons.auto_awesome_outlined, onTap: () => onChanged(null)),
        tile(tooltip: t.backgroundNone, selected: value == none || value == noBackground, icon: Icons.block, onTap: () => onChanged(none)),
        for (final g in BuiltInGradient.values)
          tile(
            tooltip: gradientName(t, g),
            selected: value == g.code,
            fill: DecoratedBox(
              decoration: BoxDecoration(gradient: g.gradient(dark: tt.isDark)),
            ),
            onTap: () => onChanged(g.code),
          ),
        if (picture != null)
          tile(
            tooltip: t.backgroundPicture,
            selected: true,
            fill: BackgroundLayer(code: picture, dim: 0),
            onTap: () {},
          ),
        tile(
          tooltip: t.backgroundPickPicture,
          selected: false,
          icon: Icons.add_photo_alternate_outlined,
          onTap: () async {
            final picked = await pickBackgroundPicture(ref);
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }
}

/// "Fundo" of a folder: the choices in a small dialog. Null when cancelled; else the record with the
/// chosen code (null = the app's).
Future<({String? code})?> showBackgroundDialog(BuildContext context, {required String? initial}) => showDialog<({String? code})>(
  context: context,
  builder: (_) => _BackgroundDialog(initial: initial),
);

class _BackgroundDialog extends ConsumerStatefulWidget {
  const _BackgroundDialog({required this.initial});

  final String? initial;

  @override
  ConsumerState<_BackgroundDialog> createState() => _BackgroundDialogState();
}

class _BackgroundDialogState extends ConsumerState<_BackgroundDialog> {
  late String? _code = widget.initial;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    // "Padrão" previews the app's.
    final shown = _code ?? prefs.background;
    return AlertDialog(
      title: Text(t.backgroundTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 110,
              child: AppearancePreview(background: hasBackground(shown) ? shown : null, dim: prefs.backgroundDim),
            ),
            const SizedBox(height: 14),
            BackgroundChoices(value: _code, inherit: true, onChanged: (c) => setState(() => _code = c)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, (code: _code)), child: Text(t.actionSave)),
      ],
    );
  }
}

/// A small drawing of the app with [background] veiled by [dim] and the theme's corners ([card]): a
/// title, three tasks and the accent, as the list will look.
class AppearancePreview extends StatelessWidget {
  const AppearancePreview({super.key, required this.background, required this.dim, this.card = false});

  final String? background;
  final double dim;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    Widget bar(double width, {Color? color}) => Container(
      width: width,
      height: 7,
      decoration: BoxDecoration(color: color ?? tt.textSecondary, borderRadius: BorderRadius.circular(4)),
    );
    Widget task(double width) => Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              border: Border.all(color: tt.textTertiary, width: 1.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 7),
          Flexible(child: bar(width)),
        ],
      ),
    );
    final body = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: bar(70, color: tt.text)),
              const Spacer(),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: tt.primary, shape: BoxShape.circle),
              ),
            ],
          ),
          task(120),
          task(90),
          task(140),
        ],
      ),
    );
    final code = background;
    final page = code == null
        ? ColoredBox(color: tt.screen, child: body)
        : Stack(
            fit: StackFit.expand,
            children: [
              BackgroundLayer(code: code, dim: dim),
              body,
            ],
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: tt.divider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 16, color: tt.iconBar),
            Expanded(
              child: card
                  ? ColoredBox(
                      color: Color.alphaBlend(tt.primary.withValues(alpha: 0.22), tt.screen),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 6, 6, 6),
                        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: page),
                      ),
                    )
                  : page,
            ),
          ],
        ),
      ),
    );
  }
}
