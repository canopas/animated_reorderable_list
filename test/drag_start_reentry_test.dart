import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:animated_reorderable_list/src/builder/reorderable_animated_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpFor(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _dragApp({
  required List<int> starts,
  required List<int> ends,
  required List<(int, int)> reorders,
}) =>
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: Scaffold(
        body: AnimatedReorderableListView<String>(
          items: const ['a', 'b', 'c'],
          isSameItem: (a, b) => a == b,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          nonDraggableItems: const ['a', 'b', 'c'],
          onReorderStart: starts.add,
          onReorderEnd: ends.add,
          onReorder: (from, to) => reorders.add((from, to)),
          proxyDecorator: (child, index, animation) => ColoredBox(
            key: const ValueKey('drag-proxy'),
            color: Colors.red,
            child: child,
          ),
          itemBuilder: (context, index) => SizedBox(
            key: ValueKey('drag-item-$index'),
            height: 40,
            child: const ColoredBox(color: Colors.blue),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
      'same pointer can start immediate and delayed drags on the same state', (
    tester,
  ) async {
    final starts = <int>[];
    final ends = <int>[];
    final reorders = <(int, int)>[];
    await tester.pumpWidget(
      _dragApp(starts: starts, ends: ends, reorders: reorders),
    );
    await _pumpFor(tester, 400);
    final state = tester.state<ReorderableAnimatedBuilderState>(
      find.byType(ReorderableAnimatedBuilder),
    );
    final position = tester.getCenter(
      find.byKey(const ValueKey('drag-item-0')),
    );
    final gesture = await tester.startGesture(position, pointer: 1);
    final delayedRecognizer = DelayedMultiDragGestureRecognizer();
    addTearDown(delayedRecognizer.dispose);
    state.startItemDragReorder(
      index: 0,
      event: PointerDownEvent(pointer: 1, position: position),
      recognizer: delayedRecognizer,
    );

    // Accept the delayed recognizer before registering the immediate one in a
    // new arena for the same pointer, while the delayed timer is still pending.
    GestureBinding.instance.gestureArena.close(1);
    await tester.pump();
    state.startItemDragReorder(
      index: 0,
      event: PointerDownEvent(pointer: 1, position: position),
      recognizer: ImmediateMultiDragGestureRecognizer(),
    );
    GestureBinding.instance.gestureArena.close(1);
    await tester.pump();
    expect(starts, [0]);
    await _pumpFor(tester, 600);
    expect(starts, [0, 0]);
    expect(find.byKey(const ValueKey('drag-proxy')), findsOneWidget);

    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.up();
    await _pumpFor(tester, 400);
    expect(ends, [1]);
    expect(reorders, [(0, 1)]);
    expect(find.byKey(const ValueKey('drag-proxy')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final callback in ['update', 'end', 'cancel', 'completed']) {
    testWidgets('ignores stale $callback during and after the replacement drag',
        (
      tester,
    ) async {
      final starts = <int>[];
      final ends = <int>[];
      final reorders = <(int, int)>[];
      await tester.pumpWidget(
        _dragApp(starts: starts, ends: ends, reorders: reorders),
      );
      final state = tester.state<ReorderableAnimatedBuilderState>(
        find.byType(ReorderableAnimatedBuilder),
      );
      final position = tester.getCenter(
        find.byKey(const ValueKey('drag-item-0')),
      );
      final gesture = await tester.startGesture(position, pointer: 1);
      final recognizer = ImmediateMultiDragGestureRecognizer();
      state.startItemDragReorder(
        index: 0,
        event: PointerDownEvent(pointer: 1, position: position),
        recognizer: recognizer,
      );

      // Start one drag directly, then let arena acceptance re-enter onStart.
      // Dynamic access lets us replay callbacks without exposing the private type.
      final dynamic oldDrag = recognizer.onStart!(position);
      GestureBinding.instance.gestureArena.close(1);
      await tester.pump();
      await _pumpFor(tester, 300);
      expect(starts, [0, 0]);
      expect(find.byKey(const ValueKey('drag-proxy')), findsOneWidget);
      final proxyPosition = tester.getTopLeft(
        find.byKey(const ValueKey('drag-proxy')),
      );

      void sendOldCallback() {
        switch (callback) {
          case 'update':
            oldDrag.onUpdate(oldDrag, position, const Offset(0, 80));
            break;
          case 'end':
            oldDrag.onEnd(oldDrag);
            break;
          case 'cancel':
            oldDrag.onCancel(oldDrag);
            break;
          case 'completed':
            oldDrag.onDragCompleted(oldDrag);
            break;
        }
      }

      sendOldCallback();
      // A late end on the disposed drag must not animate or notify listeners.
      (oldDrag as Drag).end(DragEndDetails());
      await tester.pump();
      expect(ends, isEmpty);
      expect(reorders, isEmpty);
      expect(find.byKey(const ValueKey('drag-proxy')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('drag-proxy'))),
        proxyPosition,
      );

      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('drag-proxy'))),
        proxyPosition + const Offset(0, 40),
      );
      await gesture.up();
      await _pumpFor(tester, 400);
      // Replay the notification after the replacement has reset the state.
      sendOldCallback();
      oldDrag.end(DragEndDetails());
      await tester.pump();
      expect(ends, [1]);
      expect(reorders, [(0, 1)]);
      expect(find.byKey(const ValueKey('drag-proxy')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('next drag offset is zero when not dragging', (tester) async {
    await tester.pumpWidget(_dragApp(starts: [], ends: [], reorders: []));
    await _pumpFor(tester, 400);
    final state = tester.state<ReorderableAnimatedBuilderState>(
      find.byType(ReorderableAnimatedBuilder),
    );
    expect(state.calculateNextDragOffset(0), Offset.zero);
    expect(tester.takeException(), isNull);
  });
}
