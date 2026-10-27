import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/sort_order.dart';

/// A row of [ReorderableRows]: its [key] (the item's id) and how it is built around the drag handle
/// (null when the list can't be reordered now, e.g. sorted by something else).
typedef ReorderableRow = ({Key key, Widget Function(Widget? handle) build});

/// Rows the user puts in order by dragging the handle (⠿) each one shows, as the checklist's items.
/// The handle, not a long press, starts the drag: rows keep their own long press for the menu.
///
/// [orders] are the rows' current sort orders, in the order shown; [onReorder] gets the new orders of
/// the rows whose order changed, by their index in [rows] (usually only the moved one; all of them
/// when no room was left).
/// [enabled] false shows no handles (another sort, or a filter that hides part of the list).
class ReorderableRows extends StatelessWidget {
  const ReorderableRows({super.key, required this.rows, required this.orders, required this.onReorder, this.enabled = true});

  final List<ReorderableRow> rows;
  final List<int> orders;
  final void Function(Map<int, int> changed) onReorder;
  final bool enabled;

  /// [to] counts without the moved row (onReorderItem).
  void _moved(int from, int to) {
    final updated = SortOrder.moved(orders, from, to);
    // Which row sits at each position after the move.
    final rowAt = [for (var i = 0; i < rows.length; i++) i]
      ..removeAt(from)
      ..insert(to, from);
    final changed = {
      for (var i = 0; i < updated.length; i++)
        if (updated[i] != orders[rowAt[i]]) rowAt[i]: updated[i],
    };
    if (changed.isNotEmpty) onReorder(changed);
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled || rows.length < 2) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final r in rows) KeyedSubtree(key: r.key, child: r.build(null))]);
    }
    final tt = context.tt;
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorderItem: _moved,
      proxyDecorator: (child, _, _) => Material(elevation: 4, color: tt.screen, borderRadius: BorderRadius.circular(8), child: child),
      children: [
        for (final (index, r) in rows.indexed)
          KeyedSubtree(
            key: r.key,
            child: r.build(
              ReorderableDragStartListener(
                index: index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Icon(Icons.drag_indicator, size: 16, color: tt.textFaint),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
