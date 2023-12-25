import 'package:flutter/foundation.dart';
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
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<_ActiveItem> _incomingItems = <_ActiveItem>[];
  final List<_ActiveItem> _outgoingItems = <_ActiveItem>[];
  int _itemsCount = 0;

  Map<int, MotionData> childrenMap = <int, MotionData>{};
  final Map<int, MotionAnimatedContentState> _items =
      <int, MotionAnimatedContentState>{};

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    _itemsCount = widget.initialCount;
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

  Future<void> insertItem(int index) async {
    print(" ---- INSERT --- ");
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
      duration: kDragDuration,
      vsync: this,
    );

    final motionData = MotionData(
      index: itemIndex,
      enter: true,
      endOffset: _itemOffsetAt(itemIndex) ?? Offset.zero,
      startOffset: _itemOffsetAt(itemIndex) ?? Offset.zero,
    );
    final updatedChildrenMap = <int, MotionData>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key == itemIndex) {
          updatedChildrenMap[itemIndex] = motionData;
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
      childrenMap[itemIndex] = motionData;
    }

    final _ActiveItem incomingItem = _ActiveItem.incoming(
      controller,
      itemIndex,
    );
    setState(() {
      _incomingItems
        ..add(incomingItem)
        ..sort();
      _itemsCount += 1;
    });

    Future.delayed(kDragDuration).then((value) {
      controller.forward().then<void>((_) {
        _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)!
            .controller!
            .dispose();
      });
    });

    // print("updated map ${childrenMap}");
  }

  void removeItem(int index, RemovedItemBuilder builder) {
    assert(index >= 0);
    final int itemIndex = _indexToItemIndex(index);
    if (itemIndex < 0 || itemIndex >= _itemsCount) {
      return;
    }

    assert(_activeItemAt(_outgoingItems, itemIndex) == null);

    if (childrenMap.containsKey(itemIndex)) {
      final _ActiveItem? incomingItem =
          _removeActiveItemAt(_incomingItems, itemIndex);

      final AnimationController controller = incomingItem?.controller ??
          AnimationController(duration: kDragDuration, value: 1.0, vsync: this);
      final _ActiveItem outgoingItem =
          _ActiveItem.outgoing(controller, itemIndex, builder);
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

        _onItemRemoved(itemIndex);
      });
    }
  }

  void _onItemRemoved(int itemIndex) {
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

    _removeActiveItemAt(_outgoingItems, itemIndex);

    for (final _ActiveItem item in _outgoingItems) {
      if (item.itemIndex > itemIndex) item.itemIndex -= 1;
    }
    setState(() => _itemsCount -= 1);
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
    final _ActiveItem? outgoingItem = _activeItemAt(_outgoingItems, index);
    final _ActiveItem? incomingItem = _activeItemAt(_incomingItems, index);

    final Widget child = outgoingItem != null
        ? outgoingItem.removedItemBuilder!(context, index)
        : widget.itemBuilder(context, _itemIndexToIndex(index));

    final Widget builder = outgoingItem != null
        ? _removeItemBuilder(outgoingItem, child)
        : _insertItemBuilder(incomingItem, child);

    assert(() {
      if (child.key == null) {
        throw FlutterError(
          'Every item of MotionList must have a unique key.',
        );
      }
      return true;
    }());
    final outGoingKey =
        outgoingItem != null ? Key('${outgoingItem.itemIndex}') : child.key!;
    final Key itemGlobalKey = _MotionBuilderItemGlobalKey(outGoingKey, this);
    //  print("Key ${itemGlobalKey.toString()}");
    return MotionAnimatedContent(
      index: index,
      key: itemGlobalKey,
      motionData: childrenMap[index]!,
      updateMotionData: (MotionData) {
        childrenMap[index] = MotionData.copyWith(
          startOffset: _itemOffsetAt(index),
          endOffset: _itemOffsetAt(index),
          enter: false,
          exit: false,
        );
        //  print("updateMotionData ${childrenMap[index]}");
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
  _ActiveItem.incoming(this.controller, this.itemIndex)
      : removedItemBuilder = null;

  _ActiveItem.outgoing(
      this.controller, this.itemIndex, this.removedItemBuilder);

  _ActiveItem.index(this.itemIndex)
      : controller = null,
        removedItemBuilder = null;

  final AnimationController? controller;
  final ItemBuilder? removedItemBuilder;
  int itemIndex;

  @override
  int compareTo(_ActiveItem other) => itemIndex - other.itemIndex;
}
