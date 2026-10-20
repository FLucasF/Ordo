import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/focus_restorer.dart';

void main() {
  Future<(FocusNode, FocusNode)> pumpFields(WidgetTester tester) async {
    final first = FocusNode(), second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    // Something focusable outside the page comes first in reading order, as in the app's shell.
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Material(
          child: Column(
            children: [
              const TextField(key: ValueKey('outside')),
              Expanded(child: child!),
            ],
          ),
        ),
        home: Material(
          child: Column(
            children: [
              TextField(focusNode: first),
              TextField(focusNode: second),
            ],
          ),
        ),
      ),
    );
    return (first, second);
  }

  Future<void> altTab(WidgetTester tester) async {
    final id = tester.view.viewId;
    tester.binding.handleViewFocusChanged(ViewFocusEvent(viewId: id, state: ViewFocusState.unfocused, direction: ViewFocusDirection.undefined));
    await tester.pump();
    tester.binding.handleViewFocusChanged(ViewFocusEvent(viewId: id, state: ViewFocusState.focused, direction: ViewFocusDirection.forward));
    await tester.pump();
  }

  testWidgets('back from Alt+Tab, the field being typed in has the focus again', (tester) async {
    final restorer = FocusRestorer()..attach();
    addTearDown(restorer.detach);
    final (first, second) = await pumpFields(tester);
    await tester.tap(find.byType(TextField).last);
    await tester.pump();
    expect(second.hasPrimaryFocus, isTrue);
    await altTab(tester);
    expect(second.hasPrimaryFocus, isTrue);
    expect(first.hasFocus, isFalse);
  });

  testWidgets('a field gone meanwhile is left alone', (tester) async {
    final restorer = FocusRestorer()..attach();
    addTearDown(restorer.detach);
    await pumpFields(tester);
    await tester.tap(find.byType(TextField).last);
    await tester.pump();
    final id = tester.view.viewId;
    tester.binding.handleViewFocusChanged(ViewFocusEvent(viewId: id, state: ViewFocusState.unfocused, direction: ViewFocusDirection.undefined));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    tester.binding.handleViewFocusChanged(ViewFocusEvent(viewId: id, state: ViewFocusState.focused, direction: ViewFocusDirection.forward));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
