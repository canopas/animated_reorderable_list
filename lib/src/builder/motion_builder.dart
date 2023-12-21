import 'package:flutter/widgets.dart';
import 'package:motion_list/src/component/motion_animated_content.dart';

import '../../motion_list.dart';
import '../model/motion_data.dart';
import 'motion_animation_builder.dart';

class MotionBuilder<E> extends StatefulWidget {
  final AnimatedWidgetBuilder insertAnimationBuilder;
  final AnimatedWidgetBuilder removeAnimationBuilder;
  final ItemBuilder itemBuilder;
  final int initialCount;
  final SliverGridDelegate? delegateBuilder;

  const MotionBuilder(
      {Key? key,
      required this.insertAnimationBuilder,
      required this.removeAnimationBuilder,
      this.initialCount = 0,
      this.delegateBuilder,
      required this.itemBuilder})
      : assert(initialCount >= 0),
        super(key: key);

  @override
  State<MotionBuilder> createState() => MotionBuilderState();
}

class MotionBuilderState extends State<MotionBuilder>
    with AutomaticKeepAliveClientMixin {
  // int _itemsCount = 0;
  Map<int, MotionData> childrenMap = <int, MotionData>{};
  final Map<int, MotionAnimatedContentState> _items =
      <int, MotionAnimatedContentState>{};

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    // _itemsCount = widget.initialCount;
    for (int i = 0; i < widget.initialCount; i++) {
      childrenMap[i] = MotionData(index: i);
    }
    super.initState();
  }

  void registerItem(MotionAnimatedContentState item) {
    _items[item.index] = item;
    // if (item.index == _dragInfo?.index) {
    //   item.dragging = true;
    //   item.rebuild();
    // }
  }

  void unregisterItem(int index, MotionAnimatedContentState item) {
    final MotionAnimatedContentState? currentItem = _items[index];
    if (currentItem == item) {
      _items.remove(index);
    }
  }

  Future<void> insertItem(int index) async {
    print(" ---- INSERT --- ");
    assert(index >= 0);
    final int itemIndex = index;

    if (itemIndex < 0 || itemIndex > childrenMap.length) {
      return;
    }

    final incomingItem = MotionData(
      index: itemIndex,
      enter: true,
      // frontItemOffset: _itemOffsetAt(itemIndex - 1) ?? Offset.zero,
      target: _itemOffsetAt(itemIndex) ?? Offset.zero,
      //  nextItemOffset: _itemOffsetAt(itemIndex + 1) ?? Offset.zero,
    );
    final updatedChildrenMap = <int, MotionData>{};
    // print("old map ${childrenMap}");
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key == itemIndex) {
          //  print("update and forward ${entry.key} to ${entry.key + 1}");

          updatedChildrenMap[itemIndex] = incomingItem;
          updatedChildrenMap[entry.key + 1] = entry.value.copyWith(
            index: entry.key + 1,
            //  frontItemOffset: _itemOffsetAt(entry.key),
            //  nextItemOffset: _itemOffsetAt(entry.key + 2),
            offset: _itemOffsetAt(entry.key) ?? Offset.zero,
          );
        } else if (entry.key > itemIndex) {
          //print("forward ${entry.key} to ${entry.key + 1}");

          updatedChildrenMap[entry.key + 1] = entry.value.copyWith(
            index: entry.key + 1,
            offset: _itemOffsetAt(entry.key) ?? Offset.zero,
            //  frontItemOffset: _itemOffsetAt(entry.key - 1),
            //  nextItemOffset: _itemOffsetAt(entry.key + 1),
          );
        } else {
          //print("else ${entry.key}");
          updatedChildrenMap[entry.key] = entry.value;
        }
      }
      childrenMap.clear();
      childrenMap.addAll(updatedChildrenMap);
    } else {
      childrenMap[itemIndex] = incomingItem;
    }
    print("updated map ${childrenMap}");
  }

  Future<void> removeItem(int index) async {
    // print(" ---- REMOVE --- ");
    // assert(index >= 0);
    // final int itemIndex = index;
    //
    // if (itemIndex < 0 || itemIndex > childrenMap.length) {
    //   return;
    // }
    //
    // final incomingItem = MotionData(
    //   index: itemIndex,
    //   enter: true,
    //   // frontItemOffset: _itemOffsetAt(itemIndex - 1) ?? Offset.zero,
    //   target: _itemOffsetAt(itemIndex) ?? Offset.zero,
    //   //  nextItemOffset: _itemOffsetAt(itemIndex + 1) ?? Offset.zero,
    // );
    // final updatedChildrenMap = <int, MotionData>{};
    // // print("old map ${childrenMap}");
    // if (childrenMap.containsKey(itemIndex)) {
    //   for (final entry in childrenMap.entries) {
    //     if (entry.key == itemIndex) {
    //       //  print("update and forward ${entry.key} to ${entry.key + 1}");
    //
    //       updatedChildrenMap[itemIndex] = incomingItem;
    //       updatedChildrenMap[entry.key + 1] = entry.value.copyWith(
    //         index: entry.key + 1,
    //         //  frontItemOffset: _itemOffsetAt(entry.key),
    //         //  nextItemOffset: _itemOffsetAt(entry.key + 2),
    //         offset: _itemOffsetAt(entry.key) ?? Offset.zero,
    //       );
    //     } else if (entry.key > itemIndex) {
    //       //print("forward ${entry.key} to ${entry.key + 1}");
    //
    //       updatedChildrenMap[entry.key + 1] = entry.value.copyWith(
    //         index: entry.key + 1,
    //         offset: _itemOffsetAt(entry.key) ?? Offset.zero,
    //         //  frontItemOffset: _itemOffsetAt(entry.key - 1),
    //         //  nextItemOffset: _itemOffsetAt(entry.key + 1),
    //       );
    //     } else {
    //       //print("else ${entry.key}");
    //       updatedChildrenMap[entry.key] = entry.value;
    //     }
    //   }
    //   childrenMap.clear();
    //   childrenMap.addAll(updatedChildrenMap);
    // } else {
    //   childrenMap[itemIndex] = incomingItem;
    // }
    //  print("updated map $childrenMap");
  }

  Offset? _itemOffsetAt(int index) {
    final itemRenderBox =
        _items[index]?.context.findRenderObject() as RenderBox?;
    if (itemRenderBox == null) return null;
    return itemRenderBox.localToGlobal(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.delegateBuilder != null
        ? SliverGrid(
            gridDelegate: widget.delegateBuilder!, delegate: _createDelegate())
        : SliverList(delegate: _createDelegate());
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final Widget child = widget.itemBuilder(context, index);

    final Key itemGlobalKey =
        _MotionBuilderItemGlobalKey(child.key ?? Key('$index'), this);
    print("key $itemGlobalKey index $index");
    return MotionAnimatedContent(
      index: index,
      key: itemGlobalKey,
      motionData: childrenMap[index]!,
      enter: false,
      exit: false,
      insertAnimationBuilder: widget.insertAnimationBuilder,
      removeAnimationBuilder: widget.removeAnimationBuilder,
      child: widget.itemBuilder(context, index),
      updateMotionData: (MotionData) {
        print("updateMotionData");
        childrenMap[index] = MotionData.copyWith(
          offset: _itemOffsetAt(index),
          //  frontItemOffset: _itemOffsetAt(index - 1),
          //  nextItemOffset: _itemOffsetAt(index + 1),
          enter: false,
          exit: false,
        );
      },
    );
  }

  SliverChildDelegate _createDelegate() {
    return SliverChildBuilderDelegate(_itemBuilder,
        childCount: childrenMap.length);
  }

  static MotionBuilderState of(BuildContext context) {
    final MotionBuilderState? result =
        context.findAncestorStateOfType<MotionBuilderState>();
    assert(() {
      if (result == null) {
        throw FlutterError(
          'MotionBuilderState.of() called with a context that does not contain a MotionBuilderState.\n'
          'No MotionBuilderState ancestor could be found starting from the '
          'context that was passed to MotionBuilderState.of(). This can '
          'happen when the context provided is from the same StatefulWidget that '
          'built the AnimatedList.'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return result!;
  }

  static MotionBuilderState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<MotionBuilderState>();
  }
}

@optionalTypeArgs
class _MotionBuilderItemGlobalKey extends GlobalObjectKey {
  const _MotionBuilderItemGlobalKey(this.subKey, this.state) : super(subKey);

  final Key subKey;
  final State state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _MotionBuilderItemGlobalKey &&
        other.subKey == subKey &&
        other.state == state;
  }

  @override
  int get hashCode => Object.hash(subKey, state);
}
