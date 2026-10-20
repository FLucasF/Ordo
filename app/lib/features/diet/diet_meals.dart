import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/diet_repository.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../date_picker/date_picker.dart' show showTimeDialog;
import '../finance/finance_widgets.dart' show FormHeader, showFinanceDialog;
import 'diet_forms.dart';

// The meals of Dieta: "+ Refeição", a meal's name and time, archiving or deleting it.

/// Takes a meal out of use: a meal with entries or plan items is archived (its days keep showing
/// it), one without is deleted; a toast undoes either.
Future<void> removeMeal(BuildContext context, WidgetRef ref, DietMeal meal) async {
  final t = AppLocalizations.of(context);
  final repo = ref.read(dietRepositoryProvider);
  final diet = ref.read(dietProvider).value ?? DietSnapshot.empty;
  final used = diet.entries.any((e) => e.meal == meal.id) || diet.planItems.any((i) => i.meal == meal.id);
  if (used) {
    await repo.archiveMeal(meal.id);
    if (context.mounted) {
      showToast(context, t.dietMealArchived, undo: () => repo.archiveMeal(meal.id, restore: true), redo: () => repo.archiveMeal(meal.id));
    }
  } else {
    await repo.deleteMeal(meal.id);
    if (context.mounted) {
      showToast(context, t.dietMealDeleted, undo: () => repo.deleteMeal(meal.id, restore: true), redo: () => repo.deleteMeal(meal.id));
    }
  }
}

/// "Nova refeição" / "Editar refeição": its name and "Horário"; the editing form has the bin.
Future<void> showDietMealForm(BuildContext context, {DietMeal? editing}) =>
    showFinanceDialog<void>(context, builder: (_) => _MealForm(editing: editing));

class _MealForm extends ConsumerStatefulWidget {
  const _MealForm({this.editing});

  final DietMeal? editing;

  @override
  ConsumerState<_MealForm> createState() => _MealFormState();
}

class _MealFormState extends ConsumerState<_MealForm> {
  late final DietMeal? _m = widget.editing;
  late final _name = TextEditingController(text: _m == null ? '' : mealName(AppLocalizations.of(context), _m));
  late int? _time = _m?.time;
  bool _showError = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final initial = _time ?? 12 * 60;
    final picked = await showTimeDialog(
      context,
      initial: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (picked != null && mounted) setState(() => _time = picked.hour * 60 + picked.minute);
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(dietRepositoryProvider);
    var name = _name.text.trim();
    final m = _m;
    final builtIn = m == null ? null : builtInMealLabel(t, m.id);
    // A built-in meal under its label keeps the label, so it follows the language.
    if (builtIn != null && (name.isEmpty || name == builtIn)) name = '';
    if (name.isEmpty && builtIn == null) {
      setState(() => _showError = true);
      return;
    }
    if (m == null) {
      await repo.createMeal(name: name, time: _time);
    } else {
      await repo.updateMeal(m.id, name: name, time: _time);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final m = _m;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(
          title: m == null ? t.dietNewMeal : t.dietEditMeal,
          onSave: () => unawaited(_save()),
          onDelete: m == null
              ? null
              : () {
                  final page = Navigator.of(context).context;
                  Navigator.pop(context);
                  unawaited(removeMeal(page, ref, m));
                },
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              TextField(
                controller: _name,
                autofocus: m == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: t.dietName, isDense: true),
                onSubmitted: (_) => unawaited(_save()),
              ),
              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.dietMealNameRequired,
                    style: TextStyle(color: tt.overdue, fontSize: TtText.small),
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.schedule, size: 20, color: tt.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(t.dietMealTime, style: TextStyle(color: tt.text)),
                  ),
                  TextButton(onPressed: () => unawaited(_pickTime()), child: Text(_time == null ? t.dietMealNoTime : mealTimeText(_time!))),
                  if (_time != null)
                    IconButton(
                      tooltip: t.dietMealNoTime,
                      icon: Icon(Icons.close, size: 18, color: tt.textTertiary),
                      onPressed: () => setState(() => _time = null),
                    ),
                ],
              ),
              Text(
                t.dietMealTimeHint,
                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Refeições arquivadas": each with "Restaurar".
Future<void> showArchivedMeals(BuildContext context) => showFinanceDialog<void>(context, builder: (_) => const _ArchivedMeals());

class _ArchivedMeals extends ConsumerWidget {
  const _ArchivedMeals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final diet = ref.watch(dietProvider).value ?? DietSnapshot.empty;
    final archived = [
      for (final m in diet.meals)
        if (m.archivedAt != null) m,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(t.dietArchivedMeals(archived.length), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose)),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              for (final m in archived)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mealName(t, m),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tt.text),
                      ),
                    ),
                    TextButton(
                      onPressed: () => unawaited(ref.read(dietRepositoryProvider).archiveMeal(m.id, restore: true)),
                      child: Text(t.menuRestore),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
