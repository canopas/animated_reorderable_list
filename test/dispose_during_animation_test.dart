import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(List<int> items) => MaterialApp(
      home: Scaffold(
        body: AnimatedListView<int>(
          items: items,
          isSameItem: (a, b) => a == b,
          itemBuilder: (context, index) => SizedBox(
            key: ValueKey<int>(items[index]),
            height: 40,
            child: Text('${items[index]}'),
          ),
        ),
      ),
    );

void main() {
  // insertItem chains forward() onto a 300ms size animation. Tearing down
  // inside that window used to reach an already-disposed controller.
  testWidgets('tearing down mid-insert does not throw', (tester) async {
    await tester.pumpWidget(_host(<int>[1, 2, 3]));

    // Insert in the middle: appending takes a different, unaffected branch.
    await tester.pumpWidget(_host(<int>[1, 9, 2, 3]));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
  });

  testWidgets('tearing down mid-remove does not throw', (tester) async {
    await tester.pumpWidget(_host(<int>[1, 2, 3]));

    await tester.pumpWidget(_host(<int>[1, 3]));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
  });
}
