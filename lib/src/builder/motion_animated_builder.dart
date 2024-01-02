import 'package:animated_reorderable_list/src/component/motion_animated_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../animated_reorderable_list.dart';
import '../model/motion_data.dart';

typedef AnimatedWidgetBuilder = Widget Function(
    BuildContext context, Widget child, Animation<double> animation);

class MotionBuilder<E> extends StatefulWidget {
  final AnimatedWidgetBuilder insertAnimationBuilder;
  final AnimatedWidgetBuilder removeAnimationBuilder;
  final ItemBuilder itemBuilder;
  final int initialCount;
  final Axis scrollDirection;
  final SliverGridDelegate? delegateBuilder;

  const MotionBuilder(
      {Key? key,
      required this.insertAnimationBuilder,
      required this.removeAnimationBuilder,
      this.initialCount = 0,
      this.delegateBuilder,
      this.scrollDirection = Axis.vertical,
      required this.itemBuilder})
      : assert(initialCount >= 0),
        super(key: key);

  @override
  State<MotionBuilder> createState() => MotionBuilderState();
}

class MotionBuilderState extends State<MotionBuilder>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<_ActiveItem> _incomingItems = <_ActiveItem>[];
  final List<_ActiveItem> _outgoingItems = <_ActiveItem>[];
  int _itemsCount = 0;

  Map<int, MotionData> childrenMap = <int, MotionData>{};
  final Map<Key?, MotionAnimatedContentState> _items =
      <Key?, MotionAnimatedContentState>{};

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    _itemsCount = widget.initialCount;
    for (int i = 0; i < widget.initialCount; i++) {
      childrenMap[i] = MotionData();
    }
    super.initState();
  }

  void registerItem(MotionAnimatedContentState item) {
    _items[item.key] = item;
  }

  void unregisterItem(MotionAnimatedContentState item) {
    final MotionAnimatedContentState? currentItem = _items[item.key];
    if (currentItem == item) {
      _items.remove(item.key);
    }
  }

  @override
  void dispose() {
    for (final _ActiveItem item in _incomingItems.followedBy(_outgoingItems)) {
      item.controller?.dispose();
    }
    super.dispose();
  }

  _ActiveItem? _removeActiveItemAt(List<_ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, _ActiveItem.index(itemIndex));
    return i == -1 ? null : items.removeAt(i);
  }

  _ActiveItem? _activeItemAt(List<_ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, _ActiveItem.index(itemIndex));
    return i == -1 ? null : items[i];
  }

  int _indexToItemIndex(int index) {
    int itemIndex = index;
    for (final _ActiveItem item in _outgoingItems) {
      if (item.itemIndex <= itemIndex) {
        itemIndex += 1;
      } else {
        break;
      }
    }
    return itemIndex;
  }

  int _itemIndexToIndex(int itemIndex) {
    int index = itemIndex;
    for (final _ActiveItem item in _outgoingItems) {
      assert(item.itemIndex != itemIndex);
      if (item.itemIndex < itemIndex) {
        index -= 1;
      } else {
        break;
      }
    }
    return index;
  }

  void insertItem(int index, {required Duration insertDuration}) {
    assert(index >= 0);
    final int itemIndex = _indexToItemIndex(index);

    if (itemIndex < 0 || itemIndex > _itemsCount) {
      return;
    }

    for (final _ActiveItem item in _incomingItems) {
      if (item.itemIndex >= itemIndex) item.itemIndex += 1;
    }
    for (final _ActiveItem item in _outgoingItems) {
      if (item.itemIndex >= itemIndex) item.itemIndex += 1;
    }

    final AnimationController controller = AnimationController(
      duration: insertDuration,
      vsync: this,
    );

    final _ActiveItem incomingItem = _ActiveItem.animation(
      controller,
      itemIndex,
    );

    _incomingItems
      ..add(incomingItem)
      ..sort();

    final motionData = MotionData(
        endOffset: Offset.zero,
        startOffset: Offset.zero,
        duration: insertDuration);

    _measureChild();
    final updatedChildrenMap = <int, MotionData>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key == itemIndex) {
          updatedChildrenMap[itemIndex] = motionData;
          updatedChildrenMap[entry.key + 1] =
              entry.value.copyWith(duration: insertDuration);
        } else if (entry.key > itemIndex) {
          updatedChildrenMap[entry.key + 1] =
              entry.value.copyWith(duration: insertDuration);
        } else {
          updatedChildrenMap[entry.key] =
              entry.value.copyWith(duration: insertDuration);
        }
      }
      childrenMap.clear();
      childrenMap.addAll(updatedChildrenMap);
      Future.delayed(insertDuration).then((value) {
        controller.forward().then<void>((_) {
          _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)!
              .controller!
              .dispose();
        });
      });
    } else {
      childrenMap[itemIndex] = motionData.copyWith(duration: insertDuration);
      controller.forward().then<void>((_) {
        _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)!
            .controller!
            .dispose();
      });
    }

    setState(() {
      _itemsCount = childrenMap.length;
    });
  }

  void removeItem(int index, {required Duration removeItemDuration}) {
    assert(index >= 0);
    final int itemIndex = _indexToItemIndex(index);
    if (itemIndex < 0 || itemIndex >= _itemsCount) {
      return;
    }

    assert(_activeItemAt(_outgoingItems, itemIndex) == null);
    _measureChild();
    if (childrenMap.containsKey(itemIndex)) {
      final _ActiveItem? incomingItem =
          _removeActiveItemAt(_incomingItems, itemIndex);

      final AnimationController controller = incomingItem?.controller ??
          AnimationController(
              duration: removeItemDuration, value: 1.0, vsync: this);
      final _ActiveItem outgoingItem =
          _ActiveItem.animation(controller, itemIndex);
      setState(() {
        _outgoingItems
          ..add(outgoingItem)
          ..sort();
      });

      controller.reverse().then<void>((void value) {
        _removeActiveItemAt(_outgoingItems, outgoingItem.itemIndex)!
            .controller!
            .dispose();

        // Decrement the incoming and outgoing item indices to account
        // for the removal.
        for (final _ActiveItem item in _incomingItems) {
          if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
        }
        for (final _ActiveItem item in _outgoingItems) {
          if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
        }

        _onItemRemoved(itemIndex, removeItemDuration);
      });
    }
  }

  void _onItemRemoved(int itemIndex, Duration removeDuration) {
    final updatedChildrenMap = <int, MotionData>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key < itemIndex) {
          updatedChildrenMap[entry.key] =
              childrenMap[entry.key]!.copyWith(duration: removeDuration);
        } else if (entry.key == itemIndex) {
          continue;
        } else {
          updatedChildrenMap[entry.key - 1] =
              childrenMap[entry.key]!.copyWith(duration: removeDuration);
        }
      }
    }
    childrenMap.clear();
    childrenMap.addAll(updatedChildrenMap);

    setState(() => _itemsCount -= 1);
  }

  Offset? _itemOffsetAt(Key? key, {bool includeAnimation = false}) {
    final item = _items[key];
    if (item == null || !mounted || !item.mounted) {
      return null;
    }

    final currentOffset = includeAnimation
        ? (_items[key]?.currentAnimatedOffset ?? Offset.zero)
        : Offset.zero;
    final itemRenderBox = _items[key]?.context.findRenderObject() as RenderBox?;
    if (itemRenderBox == null) return null;
    return itemRenderBox.localToGlobal(Offset.zero) + currentOffset;
  }

  void _measureChild() {
    childrenMap.forEach((key, value) {
      final data = childrenMap[key];
      final childKey = data?.key;

      childrenMap[key] = data!.copyWith(
          startOffset: _itemOffsetAt(childKey),
          endOffset: _itemOffsetAt(childKey));
    });
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
    final _ActiveItem? outgoingItem = _activeItemAt(_outgoingItems, index);
    final _ActiveItem? incomingItem = _activeItemAt(_incomingItems, index);

    if (outgoingItem != null) {
      final child = _items[index]!.widget;
      return _removeItemBuilder(outgoingItem, child);
    }

    final Widget child = widget.itemBuilder(context, _itemIndexToIndex(index));

    assert(() {
      if (child.key == null) {
        throw FlutterError(
          'Every item of MotionList must have a unique key.',
        );
      }
      return true;
    }());

    final Key itemGlobalKey = _MotionBuilderItemGlobalKey(child.key!, this);
    final Widget builder = _insertItemBuilder(incomingItem, child);

    final motionData = childrenMap[index];
    if (motionData == null) return builder;
    return MotionAnimatedContent(
      index: index,
      key: itemGlobalKey,
      motionData: motionData,
      updateMotionData: (MotionData motionData) {
        childrenMap[index] = motionData.copyWith(
            startOffset: _itemOffsetAt(itemGlobalKey),
            endOffset: _itemOffsetAt(itemGlobalKey),
            key: itemGlobalKey);
      },
      child: builder,
    );
  }

  SliverChildDelegate _createDelegate() {
    return SliverChildBuilderDelegate(_itemBuilder, childCount: _itemsCount);
  }

  Widget _removeItemBuilder(_ActiveItem outgoingItem, Widget child) {
    final Animation<double> animation =
        outgoingItem.controller ?? kAlwaysCompleteAnimation;
    return widget.removeAnimationBuilder(
      context,
      child,
      animation,
    );
  }

  Widget _insertItemBuilder(_ActiveItem? incomingItem, Widget child) {
    final Animation<double> animation =
        incomingItem?.controller ?? kAlwaysCompleteAnimation;
    return widget.insertAnimationBuilder(
      context,
      child,
      animation,
    );
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

class _ActiveItem implements Comparable<_ActiveItem> {
  _ActiveItem.animation(this.controller, this.itemIndex);

  _ActiveItem.index(this.itemIndex) : controller = null;

  final AnimationController? controller;
  int itemIndex;

  @override
  int compareTo(_ActiveItem other) => itemIndex - other.itemIndex;
}
