import 'dart:ui' show ViewFocusEvent, ViewFocusState;

import 'package:flutter/widgets.dart';

/// Puts the keyboard focus back where it was when the window comes back (Alt+Tab on Windows).
///
/// Flutter parks the focus when the window is left and, when it comes back, gives it to the first
/// focusable widget of the window, so the field being typed in loses it. This remembers the last
/// focused widget that is not a scope and asks for it again once the window has the focus.
class FocusRestorer with WidgetsBindingObserver {
  FocusNode? _last;
  FocusNode? _left;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_track);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeListener(_track);
  }

  void _track() {
    final node = FocusManager.instance.primaryFocus;
    if (node != null && node is! FocusScopeNode) _last = node;
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    switch (event.state) {
      case ViewFocusState.unfocused:
        _left = _last;
      case ViewFocusState.focused:
        final node = _left;
        _left = null;
        // Runs after Flutter's own choice (its observer came first), so this request wins.
        if (node != null && node.context != null && node.canRequestFocus) node.requestFocus();
    }
  }
}
