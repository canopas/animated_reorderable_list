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
  List<GlobalObjectKey> globalKeys = [];
  Map<int, MotionData> childrenMap = <int, MotionData>{};

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    // _itemsCount = widget.initialCount;
    for (int i = 0; i < widget.initialCount; i++) {
      childrenMap[i] = MotionData(index: i);
    }
    _updateGlobalKeys();
    super.initState();
  }

  _updateGlobalKeys() {
    print("Old keys $globalKeys");
    globalKeys = List.generate(
      childrenMap.length,
      (index) => GlobalObjectKey(childrenMap[index]!),
    );
    print("New keys $globalKeys");
  }

  Future<void> insertItem(int index) async {
    assert(index >= 0);
    final int itemIndex = index;

    if (itemIndex < 0 || itemIndex > childrenMap.length) {
      return;
    }

    final incomingItem = MotionData(
      index: itemIndex,
      enter: true,
      frontItemOffset: _itemOffsetAt(itemIndex - 1) ?? Offset.zero,
      nextItemOffset: _itemOffsetAt(itemIndex + 1) ?? Offset.zero,
    );
    final updatedChildrenMap = <int, MotionData>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key == itemIndex) {
          updatedChildrenMap[itemIndex] = incomingItem;
          updatedChildrenMap[entry.key + 1] = entry.value.copyWith(
            index: entry.key + 1,
            frontItemOffset: _itemOffsetAt(entry.key - 1),
            nextItemOffset: _itemOffsetAt(entry.key + 1),
          );
        } else if (entry.key > itemIndex) {
          updatedChildrenMap[entry.key + 1] = entry.value.copyWith(
            index: entry.key + 1,
            frontItemOffset: _itemOffsetAt(entry.key - 1),
            nextItemOffset: _itemOffsetAt(entry.key + 1),
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

    //  setState(() {
    _updateGlobalKeys();
    // });
  }

  Offset? _itemOffsetAt(int index) {
    if (index < 0 || globalKeys.isEmpty || globalKeys.length <= index) {
      return null;
    }
    final box = globalKeys[index].currentState?.context.findRenderObject()
        as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero);
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

    return MotionAnimatedContent(
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
          frontItemOffset: _itemOffsetAt(index - 1),
          nextItemOffset: _itemOffsetAt(index + 1),
          index: MotionData.index,
        );
      },
    );
  }

  SliverChildDelegate _createDelegate() {
    return SliverChildBuilderDelegate(_itemBuilder,
        childCount: childrenMap.length);
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
