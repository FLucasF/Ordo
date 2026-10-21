import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/quick_add.dart' show foldForSearch;
import '../../l10n/app_localizations.dart';
import 'emoji_data.dart';

/// The list icon picker: every emoji (lib/features/common/emoji_data.dart), searched by its Portuguese
/// words, in categories (Pessoas e Corpo, Natureza, Comida, Atividades, Viagem, Objetos, Símbolos,
/// Bandeiras), with "Aleatório" and "Redefinir". Returns the emoji,
/// '' for "Redefinir" (no icon), or null when closed.
Future<String?> showEmojiPicker(BuildContext context) => showDialog<String>(context: context, builder: (_) => const _EmojiPicker());

/// The categories' icons, in [emojiCategories]' order.
const _icons = [
  Icons.emoji_emotions_outlined,
  Icons.eco_outlined,
  Icons.restaurant_outlined,
  Icons.sports_soccer_outlined,
  Icons.flight_outlined,
  Icons.lightbulb_outline,
  Icons.tag,
  Icons.flag_outlined,
];

/// Each category's entries with their words already folded for the search (no accents, lower case).
final _searchable = [
  for (final entries in emojiCategories)
    [for (final e in entries) (emoji: e.split(' ').first, words: foldForSearch(e.substring(e.split(' ').first.length)))],
];

class _EmojiPicker extends StatefulWidget {
  const _EmojiPicker();

  @override
  State<_EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<_EmojiPicker> {
  final _search = TextEditingController();
  int _category = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final raw = _search.text.trim();
    final query = foldForSearch(raw);
    final names = [t.emojiPeople, t.emojiNature, t.emojiFood, t.emojiActivities, t.emojiTravel, t.emojiObjects, t.emojiSymbols, t.emojiFlags];
    final shown = query.isEmpty
        ? [for (final e in _searchable[_category]) e.emoji]
        : [
            for (final entries in _searchable)
              for (final e in entries)
                // A pasted emoji finds itself (and its skin tones) too.
                if (e.words.contains(query) || e.emoji.startsWith(raw)) e.emoji,
          ];
    return Dialog(
      child: SizedBox(
        width: 380,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: t.emojiSearch,
                  filled: true,
                  fillColor: tt.fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                ),
              ),
            ),
            if (query.isEmpty)
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < _icons.length; i++)
                      IconButton(
                        tooltip: names[i],
                        visualDensity: VisualDensity.compact,
                        icon: Icon(_icons[i], size: 18, color: i == _category ? tt.primary : tt.textTertiary),
                        onPressed: () => setState(() => _category = i),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                query.isEmpty ? names[_category] : t.emojiResults,
                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
              ),
            ),
            Expanded(
              // Built as it scrolls: a category has up to a few thousand.
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: shown.length,
                itemBuilder: (context, i) => InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Navigator.pop(context, shown[i]),
                  child: Center(child: Text(shown[i], style: const TextStyle(fontSize: 22))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.shuffle, size: 16),
                    label: Text(t.emojiRandom),
                    onPressed: () {
                      final all = [for (final entries in _searchable) ...entries];
                      Navigator.pop(context, all[math.Random().nextInt(all.length)].emoji);
                    },
                  ),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context, ''), child: Text(t.emojiReset)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
