import 'package:flutter/material.dart';

import '../../app/format/date_labels.dart';
import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../appearance/backdrop.dart';
import '../shell/app_shell.dart';

// The Calendar's look (Google Calendar's), shared by the module screens: a left panel with collapsible
// sections, a top bar with the title, a view pill, a "Hoje" pill, ‹ › and the blue "+ Novo …" of the
// screen, the sections as tabs under it, and lists laid out as the Agenda (a day column, a dot, a
// secondary column, the title and ⋯ with what can be done to the line).

/// Width of the left panel.
const shellPanelWidth = 256.0;

/// The page: the left panel (wide windows, while [panelOpen]), then the top bar over the body.
class ShellLayout extends StatelessWidget {
  const ShellLayout({
    super.key,
    required this.topBar,
    required this.body,
    this.panel,
    this.panelOpen = true,
    this.trailing,
    this.onCreate,
    this.createLabel,
  });

  final Widget topBar;
  final Widget body;
  final Widget? panel;
  final bool panelOpen;

  /// A panel on the right (a detail), with its own divider.
  final Widget? trailing;

  /// On a phone, where the panel's "+ Criar" is not shown: a "+" floating in the corner.
  final VoidCallback? onCreate;
  final String? createLabel;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    // Over a "Papel de parede" only the body shows it: the panels keep the solid color.
    return Container(
      color: context.paneColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (panel != null && panelOpen && !narrow) ...[ColoredBox(color: tt.screen, child: panel), VerticalDivider(width: 1, color: tt.divider)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                topBar,
                Expanded(
                  child: narrow && onCreate != null
                      ? Stack(
                          children: [
                            Positioned.fill(child: body),
                            Positioned(
                              right: 16,
                              bottom: 16,
                              child: FloatingActionButton(
                                tooltip: createLabel ?? AppLocalizations.of(context).calendarCreate,
                                backgroundColor: tt.primary,
                                foregroundColor: Colors.white,
                                onPressed: onCreate,
                                child: const Icon(Icons.add),
                              ),
                            ),
                          ],
                        )
                      : body,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[VerticalDivider(width: 1, color: tt.divider), ColoredBox(color: tt.screen, child: trailing)],
        ],
      ),
    );
  }
}

/// The left panel: [children] (sections).
class ShellPanel extends StatelessWidget {
  const ShellPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: shellPanelWidth,
    color: context.tt.screen,
    child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 24), children: children),
  );
}

/// The screen's main action, "+ Novo lançamento": it says what it creates, in the app's blue, at the
/// end of the top bar (and in empty screens).
class CreateButton extends StatelessWidget {
  const CreateButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: tt.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.add, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: onPressed,
    );
  }
}

/// The sections of a screen as tabs under the top bar ("Lançamentos · Cartões · …"): always in sight,
/// the current one in the app's blue and underlined. They scroll sideways when they don't fit.
class ShellTabs<T extends Object> extends StatelessWidget {
  const ShellTabs({super.key, required this.tabs, required this.selected, required this.onSelected});

  final List<({T value, String label, IconData icon})> tabs;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tt.divider)),
      ),
      padding: EdgeInsets.symmetric(horizontal: narrow ? 4 : 12),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs)
              Semantics(
                selected: tab.value == selected,
                button: true,
                child: InkWell(
                  onTap: () => onSelected(tab.value),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: narrow ? 10 : 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: tab.value == selected ? tt.primary : Colors.transparent, width: 3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab.icon, size: 18, color: tab.value == selected ? tt.primary : tt.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: TtText.body,
                            fontWeight: tab.value == selected ? FontWeight.w600 : FontWeight.w500,
                            color: tab.value == selected ? tt.primary : tt.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "⋯" at the end of a line: the same menu as its right click (or long press), for who doesn't know
/// those. [onMenu] gets the point to open the menu at.
class RowMenuButton extends StatelessWidget {
  const RowMenuButton({super.key, required this.onMenu});

  final ValueChanged<Offset> onMenu;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context).menuMore,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    iconSize: 18,
    icon: Icon(Icons.more_horiz, color: context.tt.textTertiary),
    onPressed: () {
      final box = context.findRenderObject()! as RenderBox;
      onMenu(box.localToGlobal(box.size.bottomLeft(Offset.zero)));
    },
  );
}

/// A section title of the panel ("Meus calendários") with ⌃/⌄ and an optional action (a "+").
class PanelSectionHeader extends StatelessWidget {
  const PanelSectionHeader({super.key, required this.title, required this.open, required this.onToggle, this.action});

  final String title;
  final bool open;
  final VoidCallback onToggle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: TtText.body, fontWeight: FontWeight.w600, color: tt.text),
            ),
          ),
          ?action,
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: Icon(open ? Icons.expand_less : Icons.expand_more, color: tt.textSecondary),
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}

/// A section of the panel that opens and closes by itself.
class PanelSection extends StatefulWidget {
  const PanelSection({super.key, required this.title, required this.children, this.action});

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  State<PanelSection> createState() => _PanelSectionState();
}

class _PanelSectionState extends State<PanelSection> {
  bool _open = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PanelSectionHeader(title: widget.title, open: _open, onToggle: () => setState(() => _open = !_open), action: widget.action),
      if (_open) ...widget.children,
    ],
  );
}

/// A row of the panel with a checkbox in [color] ("Meus calendários"); on hover, "⋮" offers
/// [onOnly] ("Mostrar só este").
class PanelCheckRow extends StatefulWidget {
  const PanelCheckRow({
    super.key,
    required this.color,
    required this.label,
    required this.shown,
    required this.onChanged,
    this.onOnly,
    this.trailing,
  });

  final Color color;
  final String label;
  final bool shown;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onOnly;

  /// A small text at the end (a count, an amount).
  final String? trailing;

  @override
  State<PanelCheckRow> createState() => _PanelCheckRowState();
}

class _PanelCheckRowState extends State<PanelCheckRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => widget.onChanged(!widget.shown),
        child: SizedBox(
          height: 34,
          child: Row(
            children: [
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.shown ? widget.color : null,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: widget.color, width: 2),
                ),
                child: widget.shown ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: TtText.body, color: tt.text),
                ),
              ),
              if (_hover && widget.onOnly != null)
                PopupMenuButton<String>(
                  tooltip: '',
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(Icons.more_vert, color: tt.textSecondary),
                  onSelected: (_) => widget.onOnly!(),
                  itemBuilder: (_) => [PopupMenuItem(value: 'only', height: 36, child: Text(t.calendarShowOnly))],
                )
              else if (widget.trailing case final text?)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    text,
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of the panel that picks a place (a card, a tab): an icon or a colored dot, the name and a
/// small text at the end; the chosen one is tinted.
class PanelNavRow extends StatelessWidget {
  const PanelNavRow({super.key, required this.label, required this.selected, required this.onTap, this.icon, this.color, this.trailing});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Material(
      color: selected ? tt.primary.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: SizedBox(
          height: 34,
          child: Row(
            children: [
              const SizedBox(width: 6),
              if (icon != null)
                Icon(icon, size: 18, color: selected ? tt.primary : (color ?? tt.textSecondary))
              else
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: color ?? tt.primary, shape: BoxShape.circle),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: TtText.body,
                    color: selected ? tt.primary : tt.text,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    trailing!,
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The top bar: ☰ (the drawer on a phone; the left panel on a wide window when [onTogglePanel]),
/// the title, then [actions] (pills, ‹ ›, ⋯).
class ShellTopBar extends StatelessWidget {
  const ShellTopBar({
    super.key,
    required this.title,
    this.onTogglePanel,
    this.actions = const [],
    this.titleTrailing,
    this.leading,
    this.onCreate,
    this.createLabel,
  });

  final String title;

  /// The screen's "+ Novo …" ([CreateButton]), last; on a phone the layout's round "+" does it.
  final VoidCallback? onCreate;
  final String? createLabel;

  /// Just before the title (a "‹" back).
  final Widget? leading;
  final VoidCallback? onTogglePanel;
  final List<Widget> actions;

  /// Right after the title (a "▾" menu on the title).
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    // A Builder: the ☰ reads the drawer from below the ModuleScaffold.
    return Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(narrow ? 4 : 20, 12, narrow ? 4 : 12, 10),
        child: Row(
          children: [
            const DrawerMenuButton(),
            if (!narrow && onTogglePanel != null)
              IconButton(
                tooltip: t.calendarTogglePanel,
                icon: Icon(Icons.menu, color: tt.textSecondary),
                onPressed: onTogglePanel,
              ),
            ?leading,
            // The title takes the room left; the actions stay at the end.
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: narrow ? 17 : TtText.listTitle, fontWeight: FontWeight.w600, color: tt.text),
                    ),
                  ),
                  ?titleTrailing,
                ],
              ),
            ),
            ...actions,
            if (onCreate != null && !narrow) ...[
              const SizedBox(width: 8),
              CreateButton(label: createLabel ?? t.calendarCreate, onPressed: onCreate!),
            ],
          ],
        ),
      ),
    );
  }
}

/// The view pill ("Semana ▾"): a soft rounded box with the current choice; [items] as a menu.
class ViewPill<T extends Object> extends StatelessWidget {
  const ViewPill({super.key, required this.label, required this.items, required this.onSelected});

  final String label;
  final List<PopupMenuEntry<T>> Function() items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return PopupMenuButton<T>(
      tooltip: '',
      onSelected: onSelected,
      itemBuilder: (_) => items(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: TtText.body, color: tt.textSecondary),
            ),
            Icon(Icons.expand_more, size: 16, color: tt.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// The outlined "Hoje" pill (or "Este mês").
class TodayPill extends StatelessWidget {
  const TodayPill({super.key, required this.label, required this.onPressed, this.tooltip});

  final String label;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final text = Text(label);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        visualDensity: narrow ? const VisualDensity(horizontal: -3, vertical: -3) : VisualDensity.compact,
        padding: narrow ? const EdgeInsets.symmetric(horizontal: 8) : null,
        foregroundColor: tt.textSecondary,
        side: BorderSide(color: tt.divider),
      ),
      onPressed: onPressed,
      child: tooltip == null ? text : Tooltip(message: tooltip, child: text),
    );
  }
}

/// ‹ › of the top bar.
class ShellArrows extends StatelessWidget {
  const ShellArrows({super.key, required this.onPrevious, required this.onNext});

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    const compact = VisualDensity(horizontal: -3, vertical: -3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: narrow ? compact : null,
          icon: Icon(Icons.chevron_left, color: tt.textSecondary),
          onPressed: onPrevious,
        ),
        IconButton(
          visualDensity: narrow ? compact : null,
          icon: Icon(Icons.chevron_right, color: tt.textSecondary),
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// A block of the Agenda: the day (its number, today in a filled circle, and "SET, QUI") beside
/// [children]; [label] replaces "SET, QUI" when the block is not a plain day. With [onAdd], the day
/// is a button with a "+" ([addTooltip]) to create something on it.
class AgendaBlock extends StatelessWidget {
  const AgendaBlock({
    super.key,
    required this.day,
    required this.today,
    required this.children,
    this.label,
    this.bigText,
    this.onAdd,
    this.addTooltip,
  });

  final DateTime day;
  final DateTime today;
  final List<Widget> children;
  final String? label;

  /// Shown instead of the day's number (a count of days, an amount).
  final String? bigText;
  final VoidCallback? onAdd;
  final String? addTooltip;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = DateLabels(t);
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final isToday = bigText == null && day == today;
    final heading = Row(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 34),
          height: 34,
          alignment: Alignment.center,
          decoration: isToday ? BoxDecoration(color: tt.primary, shape: BoxShape.circle) : null,
          child: Text(bigText ?? '${day.day}', style: TextStyle(fontSize: 20, color: isToday ? Colors.white : tt.text)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            (label ?? '${labels.monthShort(day)}, ${labels.weekdayShort(day)}').toUpperCase(),
            maxLines: 2,
            style: TextStyle(fontSize: 10, letterSpacing: 0.4, fontWeight: FontWeight.w600, color: isToday ? tt.primary : tt.textTertiary),
          ),
        ),
        if (onAdd != null) Icon(Icons.add, size: 16, color: tt.textTertiary),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: narrow ? 92 : 112,
            child: onAdd == null
                ? heading
                : Tooltip(
                    message: addTooltip ?? '',
                    child: InkWell(onTap: onAdd, borderRadius: BorderRadius.circular(6), child: heading),
                  ),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ],
      ),
    );
  }
}

/// A line of the Agenda: a dot in [color], a narrow [secondary] column ("Dia inteiro", a category),
/// the [title] in bold, and [trailing] (an amount, a button).
class AgendaLine extends StatelessWidget {
  const AgendaLine({
    super.key,
    required this.color,
    required this.title,
    this.secondary,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onMenu,
    this.faded = false,
    this.struck = false,
  });

  final Color color;
  final String title;
  final String? secondary;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Right click, long press or its "⋯", at the pointer.
  final ValueChanged<Offset>? onMenu;
  final bool faded;
  final bool struck;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    return GestureDetector(
      onSecondaryTapUp: onMenu == null ? null : (d) => onMenu!(d.globalPosition),
      onLongPressStart: onMenu == null ? null : (d) => onMenu!(d.globalPosition),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: faded ? color.withValues(alpha: 0.4) : color, shape: BoxShape.circle),
              ),
              SizedBox(width: narrow ? 8 : 14),
              // On a phone the column would squeeze the title: it goes under it.
              if (secondary != null && !narrow)
                SizedBox(
                  width: narrow ? 84 : 118,
                  child: Text(
                    secondary!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: TtText.small, color: faded ? tt.textTertiary : tt.textSecondary),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: TtText.body,
                        fontWeight: FontWeight.w600,
                        color: faded ? tt.textTertiary : tt.text,
                        decoration: struck ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (narrow ? secondary != null || subtitle != null : subtitle != null)
                      Text(
                        [if (narrow) ?secondary, ?subtitle].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (onMenu != null) ...[const SizedBox(width: 2), RowMenuButton(onMenu: onMenu!)],
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of figures under the top bar ("RECEITAS  R$ 6.500,00"): small uppercase labels over the
/// values, as the Calendar's day headers.
class FigureStrip extends StatelessWidget {
  const FigureStrip({super.key, required this.figures});

  final List<({String label, String value, Color? color, String? hint})> figures;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Wrap(
      spacing: 32,
      runSpacing: 12,
      children: [
        for (final f in figures)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                f.label.toUpperCase(),
                style: TextStyle(fontSize: 11, letterSpacing: 0.4, fontWeight: FontWeight.w600, color: tt.textTertiary),
              ),
              const SizedBox(height: 2),
              Text(
                f.value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: f.color ?? tt.text),
              ),
              if (f.hint != null) Text(f.hint!, style: TextStyle(fontSize: 11, color: tt.textTertiary)),
            ],
          ),
      ],
    );
  }
}

/// A heading inside the body ("Gastos por categoria"), as the panel's section titles.
class BodyHeading extends StatelessWidget {
  const BodyHeading(this.text, {super.key, this.trailing, this.color});

  final String text;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: TtText.body, fontWeight: FontWeight.w600, color: color ?? context.tt.text),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// The panel's month picker (the mini calendar of the month screens): the year with ‹ ○ ›, then
/// its months; the chosen one filled, this month in the primary color.
class MonthGridPicker extends StatefulWidget {
  const MonthGridPicker({super.key, required this.selected, required this.today, required this.onPick});

  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onPick;

  @override
  State<MonthGridPicker> createState() => _MonthGridPickerState();
}

class _MonthGridPickerState extends State<MonthGridPicker> {
  /// The year browsed with ‹ ›; null follows the chosen month.
  int? _year;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = DateLabels(t);
    final year = _year ?? widget.selected.year;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$year',
                style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_left, size: 18),
              onPressed: () => setState(() => _year = year - 1),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: t.pickerToday,
              icon: const Icon(Icons.circle_outlined, size: 10),
              onPressed: () {
                setState(() => _year = null);
                widget.onPick(DateTime(widget.today.year, widget.today.month));
              },
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_right, size: 18),
              onPressed: () => setState(() => _year = year + 1),
            ),
          ],
        ),
        for (var row = 0; row < 3; row++)
          Row(
            children: [
              for (var col = 0; col < 4; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final month = DateTime(year, row * 4 + col + 1);
                      final selected = month.year == widget.selected.year && month.month == widget.selected.month;
                      final current = month.year == widget.today.year && month.month == widget.today.month;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() => _year = null);
                          widget.onPick(month);
                        },
                        child: Container(
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          alignment: Alignment.center,
                          decoration: selected ? BoxDecoration(color: tt.primary, borderRadius: BorderRadius.circular(16)) : null,
                          child: Text(
                            labels.monthShort(month),
                            style: TextStyle(
                              fontSize: 13,
                              color: selected ? Colors.white : (current ? tt.primary : tt.text),
                              fontWeight: current ? FontWeight.w700 : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// One part of a [PanelBarSummary].
typedef BarSlice = ({String name, double value, Color color, String valueLabel});

/// The panel's summary ("Insights de tempo"): the period in small capitals, a bar split in [slices]
/// (a card lists them on hover or tap), [empty] when there are none, and an outlined "Mais …" pill.
class PanelBarSummary extends StatefulWidget {
  const PanelBarSummary({super.key, required this.period, required this.slices, required this.empty, required this.moreLabel, required this.onMore});

  final String period;
  final List<BarSlice> slices;
  final String empty;
  final String moreLabel;
  final VoidCallback onMore;

  @override
  State<PanelBarSummary> createState() => _PanelBarSummaryState();
}

class _PanelBarSummaryState extends State<PanelBarSummary> {
  final _card = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final slices = widget.slices.where((s) => s.value > 0).toList();
    final total = slices.fold(0.0, (sum, x) => sum + x.value);
    final bar = SizedBox(
      height: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: slices.isEmpty
            ? ColoredBox(color: tt.text.withValues(alpha: 0.07))
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, s) in slices.indexed) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: (s.value * 1000 / total).round().clamp(1, 1000),
                      child: ColoredBox(color: s.color),
                    ),
                  ],
                ],
              ),
      ),
    );

    Widget card(BuildContext context) => CompositedTransformFollower(
      link: _link,
      targetAnchor: Alignment.bottomLeft,
      offset: const Offset(-4, 6),
      child: Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final s in slices)
                    SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: TtText.body, color: tt.text),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            s.valueLabel,
                            style: TextStyle(fontSize: TtText.body, color: tt.textSecondary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.period.toUpperCase(),
          style: TextStyle(fontSize: 11, letterSpacing: 0.4, fontWeight: FontWeight.w600, color: tt.textSecondary),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _card,
            overlayChildBuilder: card,
            child: MouseRegion(
              onEnter: (_) {
                if (slices.isNotEmpty) _card.show();
              },
              onExit: (_) => _card.hide(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: slices.isEmpty ? null : _card.toggle,
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: bar),
              ),
            ),
          ),
        ),
        if (slices.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.empty,
              style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
            ),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              foregroundColor: tt.primary,
              side: BorderSide(color: tt.divider),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: widget.onMore,
            child: Text(widget.moreLabel),
          ),
        ),
      ],
    );
  }
}
