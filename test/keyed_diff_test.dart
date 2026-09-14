import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  List<int> items, {
  Object Function(int item)? keyOf,
  bool Function(int a, int b)? isSameItem,
}) =>
    MaterialApp(
      home: Scaffold(
        body: AnimatedListView<int>(
          items: items,
          isSameItem: isSameItem,
          keyOf: keyOf,
          insertDuration: Duration.zero,
          removeDuration: Duration.zero,
          itemBuilder: (context, index) => SizedBox(
            key: ValueKey<int>(items[index]),
            height: 20,
            child: Text('${items[index]}'),
          ),
        ),
      ),
    );

List<int> _rendered(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => int.parse(t.data!))
    .toList();

void main() {
  // keyOf must be a drop-in for isSameItem.
  for (final mode in <String>['isSameItem', 'keyOf']) {
    testWidgets('$mode: insert, remove and replace land the same', (
      tester,
    ) async {
      Widget host(List<int> items) => mode == 'keyOf'
          ? _host(items, keyOf: (i) => i)
          : _host(items, isSameItem: (a, b) => a == b);

      await tester.pumpWidget(host(<int>[1, 2, 3]));
      expect(_rendered(tester), <int>[1, 2, 3]);

      await tester.pumpWidget(host(<int>[1, 9, 2, 3]));
      await tester.pumpAndSettle();
      expect(_rendered(tester), <int>[1, 9, 2, 3]);

      await tester.pumpWidget(host(<int>[1, 9, 3]));
      await tester.pumpAndSettle();
      expect(_rendered(tester), <int>[1, 9, 3]);

      await tester.pumpWidget(host(<int>[7, 8]));
      await tester.pumpAndSettle();
      expect(_rendered(tester), <int>[7, 8]);
    });
  }

  // Equal lengths take the swap branch, which used to ignore keyOf.
  testWidgets('keyOf drives the equal-length path too', (tester) async {
    var isSameItemCalls = 0;
    bool countingIsSameItem(int a, int b) {
      isSameItemCalls++;
      return a == b;
    }

    Widget host(List<int> items) =>
        _host(items, keyOf: (i) => i, isSameItem: countingIsSameItem);

    await tester.pumpWidget(host(<int>[3, 2, 1]));
    await tester.pump(const Duration(milliseconds: 400));

    // New id, same length, so the swap branch runs.
    isSameItemCalls = 0;
    await tester.pumpWidget(host(<int>[9, 3, 1]));
    await tester.pump(const Duration(milliseconds: 400));

    expect(_rendered(tester), <int>[9, 3, 1]);
    expect(isSameItemCalls, 0, reason: 'keyOf should be the only identity');
  });

  testWidgets('keyOf keeps the equal-length path linear', (tester) async {
    const n = 200;
    var isSameItemCalls = 0;
    bool countingIsSameItem(int a, int b) {
      isSameItemCalls++;
      return a == b;
    }

    // Newest first, the way the server sorts it.
    List<int> descending(Iterable<int> ids) =>
        ids.toList()..sort((a, b) => b - a);
    final items = descending(List<int>.generate(n, (i) => i));

    Widget host(List<int> items) =>
        _host(items, keyOf: (i) => i, isSameItem: countingIsSameItem);

    await tester.pumpWidget(host(items));
    await tester.pump(const Duration(milliseconds: 400));

    // Edited row re-sorts to the front, shifting nearly every position.
    isSameItemCalls = 0;
    final edited = descending([...items.where((i) => i != n ~/ 2), n + 10]);
    await tester.pumpWidget(host(edited));
    await tester.pump(const Duration(milliseconds: 400));

    expect(edited.length, items.length);
    expect(isSameItemCalls, 0, reason: 'diff fell back to pairwise comparison');
  });

  // The whole point of keyOf.
  testWidgets('keyOf keeps the diff linear', (tester) async {
    const n = 200;
    var calls = 0;
    Object countingKeyOf(int item) {
      calls++;
      return item;
    }

    final items = List<int>.generate(n, (i) => i);
    await tester.pumpWidget(_host(items, keyOf: countingKeyOf));
    // Explicit pumps: a 300ms timer per item means pumpAndSettle never drains.
    await tester.pump(const Duration(milliseconds: 400));

    calls = 0;
    await tester.pumpWidget(_host(<int>[...items, n], keyOf: countingKeyOf));
    await tester.pump(const Duration(milliseconds: 400));

    expect(calls, greaterThan(0), reason: 'keyOf should drive the diff');
    expect(calls, lessThan(n * 5), reason: 'diff went quadratic again');
  });
}
