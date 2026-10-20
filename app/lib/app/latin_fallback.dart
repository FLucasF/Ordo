import 'package:flutter/widgets.dart';

/// Flutter's own texts (Material, Cupertino) for Latin, which Flutter does not have: [inner]'s
/// Portuguese (Brazil) ones.
class LatinFallbackDelegate<T> extends LocalizationsDelegate<T> {
  const LatinFallbackDelegate(this.inner);

  final LocalizationsDelegate<T> inner;

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'la';

  @override
  Future<T> load(Locale locale) => inner.load(const Locale('pt', 'BR'));

  @override
  bool shouldReload(LatinFallbackDelegate<T> old) => false;

  @override
  Type get type => T;
}
