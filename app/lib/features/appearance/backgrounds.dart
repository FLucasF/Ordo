import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/ids.dart';
import '../../data/preferences_repository.dart';
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';

/// Where the pictures chosen as backgrounds are kept (main.dart points it to the app's data folder).
final backgroundsDirProvider = Provider<Directory>((ref) => Directory(p.join(Directory.systemTemp.path, 'tarefas_backgrounds')));

/// A background is stored as text, the same in the preferences and in lists and folders:
/// `gradient:<name>` for a built-in one, [noBackground] for an explicit plain one, or the file name
/// of a picture in [backgroundsDirProvider]'s folder. On a list or folder, null follows the one above.
const noBackground = 'none';
const _gradientPrefix = 'gradient:';

/// The built-in gradients: soft in the light theme, deep in the dark one, so the text keeps its
/// contrast before the veil ("Escurecer") is even applied.
enum BuiltInGradient {
  dawn([Color(0xFFFFE3B8), Color(0xFFF7B9CF), Color(0xFFB9C8F4)], [Color(0xFF3A2A48), Color(0xFF5E3452), Color(0xFF283A5C)]),
  sunset([Color(0xFFFFC59E), Color(0xFFF28B82)], [Color(0xFF4A1F2E), Color(0xFF6E3426)]),
  ocean([Color(0xFFA6C8FD), Color(0xFFC6EBFA)], [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]),
  forest([Color(0xFFD9F5A6), Color(0xFF9EDFA8)], [Color(0xFF0D2A1C), Color(0xFF1E4A2B), Color(0xFF2E5A38)]),
  lavender([Color(0xFFE3C9FB), Color(0xFFA9CCFA)], [Color(0xFF2B1E3F), Color(0xFF3D2B5C), Color(0xFF1F2A4A)]),
  night([Color(0xFFC9D3F2), Color(0xFFDCD9EC)], [Color(0xFF0F0C29), Color(0xFF2A2660), Color(0xFF24243E)]),
  peach([Color(0xFFFFEBD2), Color(0xFFFCBBA3)], [Color(0xFF3D2620), Color(0xFF5A392C)]),
  mint([Color(0xFFC6F1E2), Color(0xFFDDEFC6)], [Color(0xFF0F2E29), Color(0xFF1D4840)]);

  const BuiltInGradient(this.light, this.dark);
  final List<Color> light;
  final List<Color> dark;

  String get code => '$_gradientPrefix$name';

  LinearGradient gradient({required bool dark}) =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: dark ? this.dark : light);

  static BuiltInGradient? fromCode(String? code) =>
      code == null || !code.startsWith(_gradientPrefix) ? null : values.where((g) => g.code == code).firstOrNull;
}

/// The picture's file name of a [code], or null when it's no picture.
String? backgroundPicture(String? code) => code == null || code == noBackground || code.startsWith(_gradientPrefix) || code.isEmpty ? null : code;

/// Whether [code] paints anything (a known gradient or a picture).
bool hasBackground(String? code) => BuiltInGradient.fromCode(code) != null || backgroundPicture(code) != null;

/// The background shown for [scope]: an open list's own, else its parent list's, else its folder's,
/// else the app's ([app]). A folder's view uses the folder's. [noBackground] on the way stops it, plain.
/// Returns null when nothing is painted.
String? backgroundFor(Snapshot snapshot, Scope? scope, {required String? app}) {
  String? own;
  switch (scope) {
    case ListScope(:final listId):
      final start = snapshot.listById[listId];
      var list = start;
      // Up the sublists (3 levels at most; the guard also stops a cycle); a sublist keeps its parent's folder.
      for (var depth = 0; list != null && depth < 4 && own == null; depth++) {
        own = list.background;
        list = list.parentId == null ? null : snapshot.listById[list.parentId];
      }
      own ??= snapshot.folderById[start?.folderId]?.background;
    case FolderScope(:final folderId):
      own = snapshot.folderById[folderId]?.background;
    default:
  }
  final code = own ?? app;
  return hasBackground(code) ? code : null;
}

/// "Temas prontos": a color, a background and the corners ("Estilo da Interface") together; "Noite"
/// also turns the dark theme on. Applying one changes those settings, which stay editable.
enum ThemePreset {
  standard(ColorSeries.standard, null, card: false),
  studies(ColorSeries.lilac, BuiltInGradient.lavender, card: true),
  work(ColorSeries.teal, BuiltInGradient.mint, card: false),
  night(ColorSeries.navy, BuiltInGradient.night, card: true, theme: ThemeChoice.dark),
  nature(ColorSeries.reed, BuiltInGradient.forest, card: true),
  beach(ColorSeries.turquoise, BuiltInGradient.ocean, card: true),
  cozy(ColorSeries.pinkPear, BuiltInGradient.sunset, card: true);

  const ThemePreset(this.series, this.gradient, {required this.card, this.theme});
  final ColorSeries series;
  final BuiltInGradient? gradient;
  final bool card;
  final ThemeChoice? theme;

  /// Whether the settings are this preset's (the theme apart: it may be changed afterwards).
  bool matches(Preferences prefs) =>
      prefs.customAccent == null && prefs.colorSeries == series && prefs.cardStyle == card && prefs.background == gradient?.code;

  Future<void> apply(PreferencesRepository repo) async {
    await repo.setColorSeries(series);
    await repo.setBackground(gradient?.code);
    await repo.setCardStyle(enabled: card);
    if (theme case final theme?) await repo.setTheme(theme);
  }
}

String gradientName(AppLocalizations t, BuiltInGradient g) => switch (g) {
  BuiltInGradient.dawn => t.gradientDawn,
  BuiltInGradient.sunset => t.gradientSunset,
  BuiltInGradient.ocean => t.gradientOcean,
  BuiltInGradient.forest => t.gradientForest,
  BuiltInGradient.lavender => t.gradientLavender,
  BuiltInGradient.night => t.gradientNight,
  BuiltInGradient.peach => t.gradientPeach,
  BuiltInGradient.mint => t.gradientMint,
};

String presetName(AppLocalizations t, ThemePreset preset) => switch (preset) {
  ThemePreset.standard => t.presetStandard,
  ThemePreset.studies => t.presetStudies,
  ThemePreset.work => t.presetWork,
  ThemePreset.night => t.presetNight,
  ThemePreset.nature => t.presetNature,
  ThemePreset.beach => t.presetBeach,
  ThemePreset.cozy => t.presetCozy,
};

/// Copies a picture the user picks into the backgrounds folder; returns its code (the file name).
Future<String?> pickBackgroundPicture(WidgetRef ref) async {
  final picked = await FilePicker.platform.pickFiles(type: FileType.image);
  final path = picked?.files.single.path;
  if (path == null) return null;
  final dir = ref.read(backgroundsDirProvider);
  await dir.create(recursive: true);
  final name = '${newId()}${p.extension(path)}';
  await File(path).copy(p.join(dir.path, name));
  return name;
}
