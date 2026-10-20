import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/ids.dart';
import '../../data/db/database.dart';
import '../../domain/countdown.dart';
import '../../domain/enums.dart';
import '../../domain/project.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/emoji_picker.dart';
import 'countdown_icons.dart';
import '../../app/format/date_labels.dart';

/// Card layouts of the "Estilo" step.
const countdownStyles = 6;

/// A countdown that is not saved yet, for the style previews.
Countdown previewCountdown({
  required String name,
  required DateTime date,
  required CountdownType type,
  required CountMode mode,
  String? rule,
  bool showAge = false,
  bool ignoreYear = false,
  bool countUp = false,
  String? icon,
  String? iconColor,
  String? image,
}) => Countdown(
  id: '',
  createdAt: DateTime.utc(2000),
  updatedAt: DateTime.utc(2000),
  name: name,
  date: DateTime.utc(date.year, date.month, date.day),
  type: type,
  countMode: mode,
  ignoreYear: ignoreYear,
  showAge: showAge,
  reminders: '',
  repeatRule: rule,
  visibility: CountdownVisibility.onTheDay,
  style: 0,
  note: '',
  sortOrder: 0,
  icon: icon,
  iconColor: iconColor,
  image: image,
  countUp: countUp,
);

/// The countdown's icon: an emoji as it is, or a "Texto" letter in white on its colored circle.
class CountdownIcon extends StatelessWidget {
  const CountdownIcon({super.key, required this.icon, this.color, this.size = 16});

  final String icon;
  final String? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final background = parseHexColor(color);
    if (background == null) return Text(icon, style: TextStyle(fontSize: size));
    return Container(
      width: size * 1.4,
      height: size * 1.4,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        icon,
        style: TextStyle(fontSize: size * 0.8, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

String _date(DateTime d, {bool withYear = true}) => DateLabels.numeric(d, withYear: withYear);

/// "Hoje 24/09/2026", "2 Dias até 26/09/2026", "5 Dias desde 20/09/2026".
String countdownLegend(AppLocalizations t, Countdown c, CountdownStatus status) {
  final date = _date(status.target, withYear: !(c.type == CountdownType.birthday && c.ignoreYear));
  final legend = switch (status.phase) {
    CountdownPhase.today => t.countdownToday(date),
    CountdownPhase.future => t.countdownDaysUntil(status.days, date),
    CountdownPhase.past => t.countdownDaysSince(status.days, date),
  };
  return status.age == null ? legend : '$legend · ${t.countdownAge(status.age!)}';
}

/// Where the countdowns' background pictures are kept (main.dart points it to the app's support folder).
final countdownImagesProvider = Provider<Directory>((ref) => Directory(p.join(Directory.systemTemp.path, 'tarefas_countdown_images')));

/// Units the number of a card cycles through when clicked.
enum CountdownUnit { days, weeks, months, years }

/// [days] from [from] expressed in [unit] (whole weeks, calendar months or years).
int countdownIn(CountdownUnit unit, int days, DateTime from, DateTime target) {
  final early = target.isBefore(from) ? target : from, late = target.isBefore(from) ? from : target;
  var months = (late.year - early.year) * 12 + late.month - early.month;
  if (late.day < early.day) months--;
  return switch (unit) {
    CountdownUnit.days => days,
    CountdownUnit.weeks => days ~/ 7,
    CountdownUnit.months => months,
    CountdownUnit.years => months ~/ 12,
  };
}

/// The card's face in one of the [countdownStyles] layouts, with its icon and background picture.
/// Clicking the number cycles days, weeks, months and years.
class CountdownCardBody extends ConsumerStatefulWidget {
  const CountdownCardBody({super.key, required this.countdown, required this.style, required this.color, this.compact = false, this.progress});

  final Countdown countdown;
  final int style;
  final Color color;
  final bool compact;

  /// A project's done / total tasks, as a bar under the legend; null for a countdown without one.
  final ProjectProgress? progress;

  @override
  ConsumerState<CountdownCardBody> createState() => _CountdownCardBodyState();
}

class _CountdownCardBodyState extends ConsumerState<CountdownCardBody> {
  CountdownUnit _unit = CountdownUnit.days;

  /// A click on the legend flips "N Dias até …" and "N dias desde …".
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final countdown = widget.countdown, style = widget.style, color = widget.color, compact = widget.compact;
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final status = countdownStatus(countdown, now, countUp: countdown.countUp != _flipped);
    final value = countdownIn(_unit, status.days, DateTime(now.year, now.month, now.day), status.target);
    final number = status.phase == CountdownPhase.today && status.days == 0 ? t.relativeToday : '$value';
    final unit = switch (_unit) {
      CountdownUnit.days => null,
      CountdownUnit.weeks => t.countdownUnitWeeks(value),
      CountdownUnit.months => t.countdownUnitMonths(value),
      CountdownUnit.years => t.countdownUnitYears(value),
    };
    final legend = countdownLegend(t, countdown, status);
    final imageName = countdown.image;
    final image = imageName == null ? null : File(p.join(ref.watch(countdownImagesProvider).path, imageName));
    final hasImage = image != null && image.existsSync();
    final filled = style == 1 || style == 2 || hasImage;
    final fg = filled ? Colors.white : tt.text;
    final numberStyle = TextStyle(fontSize: compact ? 22 : 40, fontWeight: FontWeight.w700, color: filled ? Colors.white : color, height: 1.1);
    final nameStyle = TextStyle(fontSize: compact ? 12 : TtText.body, fontWeight: FontWeight.w600, color: fg);
    final legendStyle = TextStyle(fontSize: compact ? 9 : TtText.small, color: filled ? Colors.white70 : tt.textTertiary);
    final base = switch (style) {
      1 => BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      2 => BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.55)]),
        borderRadius: BorderRadius.circular(10),
      ),
      4 => BoxDecoration(
        color: tt.fieldFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
      ),
      5 => BoxDecoration(
        color: tt.fieldFill,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      _ => BoxDecoration(
        color: tt.fieldFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tt.divider),
      ),
    };
    // A picture covers the card, darkened so the white text reads.
    final decoration = hasImage
        ? base.copyWith(
            image: DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.45), BlendMode.darken),
            ),
          )
        : base;
    final centered = style == 3;
    final icon = countdown.icon;
    final name = Text(countdown.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: nameStyle);
    return Container(
      decoration: decoration,
      padding: EdgeInsets.all(compact ? 8 : 16),
      child: Column(
        crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null && icon.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CountdownIcon(icon: icon, color: countdown.iconColor, size: compact ? 12 : 16),
                )
              else if (!compact && countdown.type == CountdownType.holiday)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.celebration, size: 16, color: fg),
                ),
              if (!compact && countdown.pinnedAt != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.push_pin, size: 14, color: fg),
                ),
              if (centered) Expanded(child: Center(child: name)) else Expanded(child: name),
            ],
          ),
          GestureDetector(
            onTap: compact ? null : () => setState(() => _unit = CountdownUnit.values[(_unit.index + 1) % CountdownUnit.values.length]),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: number),
                  if (unit != null && number != t.relativeToday)
                    TextSpan(
                      text: ' $unit',
                      style: numberStyle.copyWith(fontSize: compact ? 11 : 16, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              style: numberStyle,
            ),
          ),
          GestureDetector(
            onTap: compact ? null : () => setState(() => _flipped = !_flipped),
            child: Text(legend, maxLines: 1, overflow: TextOverflow.ellipsis, style: legendStyle),
          ),
          if (widget.progress case final p?)
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: p.ratio,
                      minHeight: 5,
                      color: filled ? Colors.white : color,
                      backgroundColor: (filled ? Colors.white : color).withValues(alpha: 0.25),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${p.done}/${p.total}', style: legendStyle),
              ],
            ),
        ],
      ),
    );
  }
}

/// Copies a picture the user picks into [countdownImagesProvider]'s folder; returns its file name.
Future<String?> pickCountdownImage(WidgetRef ref) async {
  final picked = await FilePicker.platform.pickFiles(type: FileType.image);
  final path = picked?.files.single.path;
  if (path == null) return null;
  final dir = ref.read(countdownImagesProvider);
  await dir.create(recursive: true);
  final name = '${newId()}${p.extension(path)}';
  await File(path).copy(p.join(dir.path, name));
  return name;
}

/// "Ícone" and "Imagem de fundo" of the style step.
class CountdownLookFields extends ConsumerWidget {
  const CountdownLookFields({super.key, required this.icon, this.iconColor, required this.image, required this.onIcon, required this.onImage});

  final String? icon;

  /// Set only for a "Texto" icon.
  final String? iconColor;
  final String? image;

  /// The new icon and, for "Texto", its background color.
  final void Function(String? icon, String? color) onIcon;
  final ValueChanged<String?> onImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        Text(
          t.countdownIcon,
          style: TextStyle(color: tt.textSecondary, fontSize: TtText.body),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () async {
            final picked = await showEmojiPicker(context);
            if (picked != null) onIcon(picked.isEmpty ? null : picked, null);
          },
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(6)),
            child: icon == null
                ? Icon(Icons.add_reaction_outlined, size: 18, color: tt.textTertiary)
                : CountdownIcon(icon: icon!, color: iconColor, size: 18),
          ),
        ),
        // "Ícone": the ready-made icons by category.
        IconButton(
          tooltip: t.countdownIcon,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.interests_outlined, size: 18, color: tt.textTertiary),
          onPressed: () async {
            final picked = await showCountdownIconPicker(context);
            if (picked != null) onIcon(picked, null);
          },
        ),
        // "Texto": one character as the icon ("Digite 1 caractere").
        IconButton(
          tooltip: t.countdownIconText,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.text_fields, size: 18, color: tt.textTertiary),
          onPressed: () async {
            final picked = await _pickTextIcon(context, letter: iconColor == null ? '' : icon ?? '', color: iconColor);
            if (picked != null) onIcon(picked.$1.isEmpty ? null : picked.$1, picked.$1.isEmpty ? null : picked.$2);
          },
        ),
        const SizedBox(width: 20),
        Text(
          t.countdownImage,
          style: TextStyle(color: tt.textSecondary, fontSize: TtText.body),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () async {
            final name = await pickCountdownImage(ref);
            if (name != null) onImage(name);
          },
          child: Text(t.countdownImagePick),
        ),
        if (image != null) IconButton(tooltip: t.countdownImageRemove, icon: const Icon(Icons.close, size: 16), onPressed: () => onImage(null)),
      ],
    );
  }
}

/// "Texto": "Digite 1 caractere" plus the background color. Returns the letter
/// (upper case, '' to remove) and the color, or null when closed.
Future<(String, String)?> _pickTextIcon(BuildContext context, {required String letter, String? color}) {
  final t = AppLocalizations.of(context);
  final controller = TextEditingController(text: letter);
  var chosen = color ?? presetColors[5];
  return showDialog<(String, String)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void done() => Navigator.pop(context, (controller.text.trim().characters.take(1).toString().toUpperCase(), chosen));
        return AlertDialog(
          title: Text(t.countdownIconText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 1,
                  decoration: InputDecoration(hintText: t.countdownIconTextHint, counterText: '', border: const OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => done(),
                ),
                const SizedBox(height: 12),
                Text(t.countdownIconBackground),
                const SizedBox(height: 6),
                ColorChoice(value: chosen, onChanged: (v) => setState(() => chosen = v ?? chosen)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
            FilledButton(onPressed: done, child: Text(t.actionSave)),
          ],
        );
      },
    ),
  );
}
