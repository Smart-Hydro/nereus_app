part of 'strom_first_use_test.dart';

void _expectNoIdField(WidgetTester tester) {
  expect(
    find.byWidgetPredicate((widget) {
      if (widget is! TextField) return false;
      final label = (widget.decoration?.labelText ?? '').toLowerCase();
      return label.contains(' id') || label.startsWith('id');
    }),
    findsNothing,
  );
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 80));
    if (finder.evaluate().isNotEmpty) return;
  }
  final visible = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .join(' | ');
  fail('No apareció $finder\n$visible');
}

Future<void> _hideSnack(WidgetTester tester) async {
  final scaffolds = find.byType(Scaffold);
  if (scaffolds.evaluate().isEmpty) return;
  ScaffoldMessenger.maybeOf(tester.element(scaffolds.first))?.clearSnackBars();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _selectTab(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(TabBar),
    matching: find.text(label),
  );
  final bar = find.byType(TabBar);
  await tester.scrollUntilVisible(
    tab,
    80,
    scrollable: find.descendant(of: bar, matching: find.byType(Scrollable)),
  );
  await tester.tap(tab);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isNotEmpty) return;
  final scrollables = find.byType(Scrollable);
  expect(scrollables, findsWidgets);
  await tester.scrollUntilVisible(target, 280, scrollable: scrollables.last);
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  await _hideSnack(tester);
  final target = find.text(label);
  await _reveal(tester, target);
  await tester.tap(_hit(target));
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String label) async {
  await _hideSnack(tester);
  final target = find.text(label);
  await _reveal(tester, target);
  await tester.tap(_hit(target));
  await tester.pump();
}

Finder _hit(Finder target) {
  final visible = target.hitTestable();
  return visible.evaluate().isNotEmpty ? visible.last : target.last;
}

Future<void> _fill(WidgetTester tester, String label, String value) async {
  final finder = find.byWidgetPredicate((widget) {
    if (widget is! TextField) return false;
    final text = widget.decoration?.labelText ?? '';
    return text == label || text.startsWith('$label ');
  });
  await _reveal(tester, finder);
  expect(finder, findsWidgets);
  await tester.enterText(finder.first, value);
  await tester.pump();
}
