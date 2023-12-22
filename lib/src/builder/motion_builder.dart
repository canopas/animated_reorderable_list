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
      endOffset: _itemOffsetAt(itemIndex) ?? Offset.zero,
      startOffset: _itemOffsetAt(itemIndex) ?? Offset.zero,
    );
    final updatedChildrenMap = <int, MotionData>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key == itemIndex) {
          updatedChildrenMap[itemIndex] = incomingItem;
          updatedChildrenMap[entry.key + 1] = entry.value.copyWith(
            index: entry.key + 1,
            startOffset:
                _itemOffsetAt(entry.key, includeAnimation: true) ?? Offset.zero,
            endOffset: _itemOffsetAt(entry.key + 1) ?? Offset.zero,
          );
        } else if (entry.key > itemIndex) {
          updatedChildrenMap[entry.key + 1] = entry.value.copyWith(
            index: entry.key + 1,
            startOffset:
                _itemOffsetAt(entry.key, includeAnimation: true) ?? Offset.zero,
            endOffset: _itemOffsetAt(entry.key + 1) ?? Offset.zero,
          );
        } else {
          updatedChildrenMap[entry.key] = entry.value;
        }
      }
      childrenMap.clear();
      childrenMap.addAll(updatedChildrenMap);
    } else {
      childrenMap[itemIndex] = incomingItem;
    }
    // print("updated map ${childrenMap}");
  }

  void removeItem(int index) {
    assert(index >= 0);
    final int itemIndex = index;
    if (itemIndex < 0 || itemIndex >= childrenMap.length) {
      return;
    }
    print("removeItem $index");
    if (childrenMap.containsKey(itemIndex)) {
      // _items[itemIndex]?.animateExit();
      childrenMap[itemIndex] = childrenMap[itemIndex]!.copyWith(exit: true);
      _onItemDeleted(itemIndex);
    }
    print("ChildrenMap ${childrenMap.length}");
  }

  void _onItemDeleted(int itemIndex) {
    print("_onItemDeleted $itemIndex");
    final updatedChildrenMap = <int, MotionData>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key < itemIndex) {
          updatedChildrenMap[entry.key] = childrenMap[entry.key]!;
        } else if (entry.key == itemIndex) {
          continue;
        } else {
          updatedChildrenMap[entry.key - 1] = childrenMap[entry.key]!.copyWith(
            index: entry.key - 1,
            startOffset:
                _itemOffsetAt(entry.key, includeAnimation: true) ?? Offset.zero,
            endOffset: _itemOffsetAt(entry.key - 1) ?? Offset.zero,
          );
        }
      }
    }
    childrenMap.clear();
    childrenMap.addAll(updatedChildrenMap);
    print("updated map $childrenMap");
  }

  Offset? _itemOffsetAt(int index, {bool includeAnimation = false}) {
    final currentOffset = includeAnimation
        ? (_items[index]?.currentAnimatedOffset ?? Offset.zero)
        : Offset.zero;
    final itemRenderBox =
        _items[index]?.context.findRenderObject() as RenderBox?;
    if (itemRenderBox == null) return null;
    return itemRenderBox.localToGlobal(Offset.zero) + currentOffset;
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
    assert(() {
      if (child.key == null) {
        throw FlutterError(
          'Every item of MotionList must have a unique key.',
        );
      }
      return true;
    }());
    final Key itemGlobalKey = _MotionBuilderItemGlobalKey(child.key!, this);
    print("Key $itemGlobalKey index $index length ${childrenMap.length}");
    return MotionAnimatedContent(
      index: index,
      key: itemGlobalKey,
      motionData: childrenMap[index]!,
      enter: false,
      exit: false,
      insertAnimationBuilder: widget.insertAnimationBuilder,
      removeAnimationBuilder: widget.removeAnimationBuilder,
      updateMotionData: (MotionData) {
        print("updateMotionData $index");
        childrenMap[index] = MotionData.copyWith(
          startOffset: _itemOffsetAt(index),
          // frontItemOffset: _itemOffsetAt(index - 1),
          //nextItemOffset: _itemOffsetAt(index + 1),
          endOffset: _itemOffsetAt(index),
          enter: false,
          exit: false,
        );
        print("updateMotionData ${childrenMap[index]}");
      },
      //   onItemRemoved: _onItemDeleted,
      child: widget.itemBuilder(context, index),
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
