import '../../data/db/database.dart';
import '../quick_add.dart' show foldForSearch;
import '../task_export.dart' show plainTextOf;

// Diário: one entry per day with a mood and an energy from 1 to 5, the day's notes (markdown) and its
// highlight. Days are stored at UTC midnight of the local day, as Dieta's and Finanças'.

/// A stored day (UTC midnight) as the local day.
DateTime journalDay(DateTime stored) => DateTime(stored.year, stored.month, stored.day);

/// A local day as stored (UTC midnight).
DateTime journalStoredDay(DateTime day) => DateTime.utc(day.year, day.month, day.day);

/// Whether nothing was told that day (a row left behind by clearing everything): history leaves it out.
bool journalEntryIsEmpty(JournalEntry e) => e.mood == null && e.energy == null && e.notes.trim().isEmpty && e.highlight.trim().isEmpty;

/// The notes as one line of plain text (no markup, no pictures), at most [max] characters; the
/// highlight when there are no notes.
String journalExcerpt(JournalEntry e, {int max = 160}) {
  var text = plainTextOf(e.notes).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) text = e.highlight.trim();
  return text.length <= max ? text : '${text.substring(0, max).trimRight()}…';
}

/// Whether every word of [query] is in the notes or the highlight, accents and case ignored.
bool journalMatches(JournalEntry e, String query) {
  final words = foldForSearch(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return true;
  final text = foldForSearch('${plainTextOf(e.notes)} ${e.highlight}');
  return words.every(text.contains);
}

/// The history: entries with something told, matching [query] and, when not empty, one of [moods]
/// and one of [energies]; newest first.
List<JournalEntry> journalHistory(List<JournalEntry> entries, {String query = '', Set<int> moods = const {}, Set<int> energies = const {}}) {
  final found = [
    for (final e in entries)
      if (!journalEntryIsEmpty(e) &&
          (moods.isEmpty || moods.contains(e.mood)) &&
          (energies.isEmpty || energies.contains(e.energy)) &&
          journalMatches(e, query))
        e,
  ];
  return found..sort((a, b) => b.day.compareTo(a.day));
}

/// One point of the mood and energy chart.
typedef JournalPoint = ({DateTime day, int? mood, int? energy});

/// The days between [from] and [to] (exclusive) with a mood or an energy, oldest first.
List<JournalPoint> journalSeries(List<JournalEntry> entries, DateTime from, DateTime to) {
  final points = [
    for (final e in entries)
      if ((e.mood != null || e.energy != null) && !journalDay(e.day).isBefore(from) && journalDay(e.day).isBefore(to))
        (day: journalDay(e.day), mood: e.mood, energy: e.energy),
  ];
  return points..sort((a, b) => a.day.compareTo(b.day));
}
