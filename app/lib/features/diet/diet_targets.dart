import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../domain/diet/diet.dart';
import '../../domain/diet/targets.dart';
import '../../l10n/app_localizations.dart';
import '../finance/finance_widgets.dart' show FormHeader, showFinanceDialog;
import 'diet_forms.dart';

/// Dieta → ⚙ Metas: the day's calories, protein, carbohydrates and fat (blank = no target), the
/// calories optionally from the macros.
Future<void> showDietTargetsForm(BuildContext context) => showFinanceDialog<void>(context, builder: (_) => const _TargetsForm());

class _TargetsForm extends ConsumerStatefulWidget {
  const _TargetsForm();

  @override
  ConsumerState<_TargetsForm> createState() => _TargetsFormState();
}

class _TargetsFormState extends ConsumerState<_TargetsForm> {
  late final DietTargets _initial = ref.read(preferencesProvider).value?.dietTargets ?? const DietTargets();
  late final _kcal = TextEditingController(text: _text(_initial.kcal));
  late final _protein = TextEditingController(text: _text(_initial.protein));
  late final _carbs = TextEditingController(text: _text(_initial.carbs));
  late final _fat = TextEditingController(text: _text(_initial.fat));
  late bool _fromMacros = _initial.energyFromMacros;

  static String _text(double? v) => v == null ? '' : formatGrams(v);

  @override
  void dispose() {
    for (final c in [_kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  DietTargets get _targets => DietTargets(
    kcal: parseDecimal(_kcal.text),
    protein: parseDecimal(_protein.text),
    carbs: parseDecimal(_carbs.text),
    fat: parseDecimal(_fat.text),
    energyFromMacros: _fromMacros,
  );

  Future<void> _save() async {
    await ref.read(preferencesRepositoryProvider).setDietTargets(DietTargets.fromJson(_targets.toJson()));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final fromMacros = kcalFromMacros(protein: parseDecimal(_protein.text), carbs: parseDecimal(_carbs.text), fat: parseDecimal(_fat.text));
    Widget number(TextEditingController c, String label, String unit) => TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label, suffixText: unit, isDense: true),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(title: t.dietTargetsTitle, onSave: () => unawaited(_save())),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text(
                t.dietTargetsHint,
                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
              ),
              const SizedBox(height: 10),
              // The calories from the macros show in the field, which is then not typed in.
              if (_fromMacros)
                InputDecorator(
                  decoration: InputDecoration(labelText: t.dietKcal, suffixText: 'kcal', isDense: true, enabled: false),
                  child: Text(formatKcal(fromMacros), style: TextStyle(color: tt.textSecondary)),
                )
              else
                number(_kcal, t.dietKcal, 'kcal'),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: _fromMacros,
                title: Text(t.dietTargetsFromMacros, style: TextStyle(color: tt.text)),
                onChanged: (v) => setState(() => _fromMacros = v ?? false),
              ),
              const SizedBox(height: 4),
              number(_protein, t.dietProtein, 'g'),
              const SizedBox(height: 8),
              number(_carbs, t.dietCarbs, 'g'),
              const SizedBox(height: 8),
              number(_fat, t.dietFat, 'g'),
            ],
          ),
        ),
      ],
    );
  }
}
