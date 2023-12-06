import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:motion_list/src/reorderable_entity.dart';

enum Operation { insertion, deletion }

const Duration _kDuration = Duration(milliseconds: 300);
const Duration _kResizeDuration = Duration(milliseconds: 1000);

typedef DelegateBuilder = SliverChildBuilderDelegate Function(
    NullableIndexedWidgetBuilder builder, int itemCount);

typedef AnimatedRemovedItemBuilder = Widget Function(
    BuildContext context, Animation<double> animation);

typedef AnimatedWidgetBuilder = Widget Function(
    BuildContext context, int index, Animation<double> animation);

class MotionAnimationBuilder<E> extends StatefulWidget {
  final AnimatedWidgetBuilder insertAnimationBuilder;
  final AnimatedWidgetBuilder removeAnimationBuilder;
  final int initialCount;
  final SliverGridDelegate? delegateBuilder;

  //final bool isGriView;

  const MotionAnimationBuilder(
      {Key? key,
      required this.insertAnimationBuilder,
      required this.removeAnimationBuilder,
      this.initialCount = 0,
      //required this.isGriView,
      this.delegateBuilder})
      : assert(initialCount >= 0),
        super(key: key);

  @override
  MotionAnimationBuilderState createState() => MotionAnimationBuilderState();

  static MotionAnimationBuilderState of(BuildContext context) {
    final MotionAnimationBuilderState? result =
        context.findAncestorStateOfType<MotionAnimationBuilderState>();
    assert(() {
      if (result == null) {
        throw FlutterError(
          'MotionAnimationBuilderState.of() called with a context that does not contain a MotionAnimationBuilderState.\n'
          'No MotionAnimationBuilderState ancestor could be found starting from the '
          'context that was passed to MotionAnimationBuilderState.of(). This can '
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

  static MotionAnimationBuilderState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<MotionAnimationBuilderState>();
  }
}

class MotionAnimationBuilderState extends State<MotionAnimationBuilder>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<ActiveItem> _incomingItems = <ActiveItem>[];
  final List<ActiveItem> _outgoingItems = <ActiveItem>[];
  final Map<int, _ReorderableItemState> _items = <int, _ReorderableItemState>{};
  Map<int, ReorderableItem> childrenMap = <int, ReorderableItem>{};

  int _itemsCount = 0;
  int changeIndex = 0;

  @override
  void initState() {
    super.initState();
    _itemsCount = widget.initialCount;
    for (int i = 0; i < _itemsCount; i++) {
      childrenMap[i] = ReorderableItem(
          oldOffset: Offset.zero,
          updatedOffset: Offset.zero,
          oldIndex: i,
          updatedIndex: i,
          key: ValueKey(i));
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final ActiveItem item in _incomingItems.followedBy(_outgoingItems)) {
      item.controller!.dispose();
    }
    super.dispose();
  }

  ActiveItem? _removeActiveItemAt(List<ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, ActiveItem.index(itemIndex));
    return i == -1 ? null : items.removeAt(i);
  }

  ActiveItem? _activeItemAt(List<ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, ActiveItem.index(itemIndex));
    return i == -1 ? null : items[i];
  }

  int _indexToItemIndex(int index) {
    int itemIndex = index;

    for (final ActiveItem item in _outgoingItems) {
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
    for (final ActiveItem item in _outgoingItems) {
      assert(item.itemIndex != itemIndex);
      if (item.itemIndex < itemIndex) {
        index -= 1;
      } else {
        break;
      }
    }
    return index;
  }

  void _registerItem(_ReorderableItemState item) {
    _items[item.index] = item;
    item.rebuild();
  }

  void _unregisterItem(int index, _ReorderableItemState item) {
    final _ReorderableItemState? currentItem = _items[index];
    if (currentItem == item) {
      _items.remove(index);
    }
  }

  Offset calculateNextDragOffsetForDeletion(int index, int removeIndex) {
    if (index < removeIndex) return Offset.zero;
    const int direction = 1;
    return _itemOffsetAt(index - direction) - _itemOffsetAt(index);
  }

  Offset calculateNextDragOffsetForInsertion(int index, int insertIndex) {
    if (index < insertIndex) return Offset.zero;
    const int direction = 1;
    return _itemOffsetAt((index) + direction) - _itemOffsetAt(index);
  }

  Offset _itemOffsetAt(int index) {
    final box = _items[index]?.context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(Offset.zero);
  }

  // void startDrag(int index, Operation operation, ActiveItem activeItem,
  //     Duration resizeDuration) {
  //   final _ReorderableItemState item = _items[index]!;
  //   for (final _ReorderableItemState childItem in _items.values) {
  //     if (childItem == item && !childItem.mounted) continue;
  //     childItem.updateGap(index, true, operation, activeItem, resizeDuration);
  //   }
  // }

  void _resetItemGap() {
    for (final _ReorderableItemState item in _items.values) {
      item.resetGap();
    }
  }

  Future<void> insertItem(int index,
      {Duration insertDuration = _kDuration,
      Duration resizeDuration = _kResizeDuration}) async {
    assert(index >= 0);
    final int itemIndex = _indexToItemIndex(index);

    if (itemIndex < 0 || itemIndex > _itemsCount) {
      return;
    }
    for (final ActiveItem item in _incomingItems) {
      if (item.itemIndex >= itemIndex) item.itemIndex += 1;
    }
    for (final ActiveItem item in _outgoingItems) {
      if (item.itemIndex >= itemIndex) item.itemIndex += 1;
    }
    final AnimationController controller =
        AnimationController(vsync: this, duration: insertDuration);
    final ActiveItem incomingItem =
        ActiveItem.builder(controller, itemIndex, Operation.insertion);
    _incomingItems
      ..add(incomingItem)
      ..sort();
    addItem(incomingItem.itemIndex);

    if (mounted) {
      setState(() {
        _itemsCount++;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      childrenMap.forEach((key, value) {
        childrenMap[key] = childrenMap[key]!.copywith(
            updatedOffset: _itemOffsetAt(key),
            visible: value.visible == false ? true : value.visible);
      });
      setState(() {});
    });
  }

  void addItem(int itemIndex) {
    final updatedChildrenMap = <int, ReorderableItem>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key < itemIndex) {
          updatedChildrenMap[entry.key] = childrenMap[entry.key]!
              .copywith(visible: false, oldOffset: _itemOffsetAt(entry.key));
        } else if (entry.key == itemIndex) {
          updatedChildrenMap[entry.key] = ReorderableItem(
              key: ValueKey(entry.key),
              oldOffset: Offset.zero,
              updatedOffset: Offset.zero,
              oldIndex: entry.key,
              updatedIndex: entry.key,
              visible: false);
          updatedChildrenMap[entry.key + 1] = childrenMap[entry.key]!.copywith(
              key: ValueKey(entry.key + 1),
              oldOffset: _itemOffsetAt(entry.key),
              visible: false);
        } else {
          updatedChildrenMap[entry.key + 1] = childrenMap[entry.key]!.copywith(
              key: ValueKey(entry.key + 1),
              updatedIndex: entry.key + 1,
              oldOffset: _itemOffsetAt(entry.key),
              visible: false);
        }
      }
    }
    childrenMap.clear();
    childrenMap.addAll(updatedChildrenMap);
  }

  void removeItem(int index,
      {Duration removeDuration = _kDuration,
      Duration resizeDuration = _kResizeDuration}) {
    assert(index >= 0);
    final int itemIndex = _indexToItemIndex(index);
    if (itemIndex < 0 || itemIndex >= _itemsCount) {
      return;
    }
    assert(_activeItemAt(_outgoingItems, itemIndex) == null);

    final ActiveItem? incomingItem =
        _removeActiveItemAt(_incomingItems, itemIndex);
    final AnimationController controller = incomingItem?.controller ??
        AnimationController(vsync: this, value: 1.0, duration: removeDuration);
    final ActiveItem outgoingItem =
        ActiveItem.builder(controller, itemIndex, Operation.deletion);

    controller.reverse();

    _outgoingItems
      ..add(outgoingItem)
      ..sort();

    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _itemsCount -= 1;
          });
        }
        deleteItem(outgoingItem.itemIndex);

        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          childrenMap.forEach((key, value) {
            childrenMap[key] =
                childrenMap[key]!.copywith(updatedOffset: _itemOffsetAt(key));
          });
          setState(() {});
          // startDrag(
          //     itemIndex, Operation.deletion, outgoingItem, resizeDuration);
        });

        final ActiveItem? activeItem =
            _removeActiveItemAt(_outgoingItems, outgoingItem.itemIndex);

        for (final ActiveItem item in _incomingItems) {
          if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
        }
        for (final ActiveItem item in _outgoingItems) {
          if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
        }
        activeItem?.controller?.dispose();
      }
    });
  }

  void deleteItem(int itemIndex) {
    final updatedChildrenMap = <int, ReorderableItem>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key < itemIndex) {
          updatedChildrenMap[entry.key] = childrenMap[entry.key]!.copywith(oldOffset: _itemOffsetAt(entry.key));
        } else if (entry.key == itemIndex) {
          continue;
        } else {
          updatedChildrenMap[entry.key - 1] = childrenMap[entry.key]!.copywith(
            key: ValueKey(entry.key - 1),
            updatedIndex: entry.key - 1,
            oldOffset: _itemOffsetAt(entry.key),
          );
        }
      }
    }
    childrenMap.clear();
    childrenMap.addAll(updatedChildrenMap);
  }

  SliverChildDelegate _createDelegate() {
    return SliverChildBuilderDelegate((context, index) {
      final Widget child = itemBuilderDelegate(context, index);
      return _ReorderableItem(
        key: childrenMap[index]!.key,
        index: index,
        reorderableItem: childrenMap[index]!.copywith(isNew: true),
        child: child,
      );
    }, childCount: _itemsCount);
  }

  Widget _removeItemBuilder(ActiveItem outgoingItem, int itemIndex) {
    final Animation<double> animation =
        outgoingItem.controller?.view ?? kAlwaysCompleteAnimation;
    return widget.removeAnimationBuilder(
      context,
      itemIndex,
      animation,
    );
  }

  Widget _insertItemBuilder(ActiveItem? incomingItem, int itemIndex) {
    final Animation<double> animation =
        incomingItem?.controller?.view ?? kAlwaysCompleteAnimation;
    return widget.insertAnimationBuilder(
      context,
      _itemIndexToIndex(itemIndex),
      animation,
    );
  }

  Widget itemBuilderDelegate(BuildContext context, int itemIndex) {
    final ActiveItem? outgoingItem = _activeItemAt(_outgoingItems, itemIndex);
    if (outgoingItem != null) {
      final Widget child = _removeItemBuilder(outgoingItem, itemIndex);
      return child;
    }
    final ActiveItem? incomingItem = _activeItemAt(_incomingItems, itemIndex);
    final Widget child = _insertItemBuilder(incomingItem, itemIndex);
    return child;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.delegateBuilder != null
        ? SliverGrid(
            gridDelegate: widget.delegateBuilder!, delegate: _createDelegate())
        : SliverList(delegate: _createDelegate());
  }

  @override
  bool get wantKeepAlive => false;
}

class ActiveItem implements Comparable<ActiveItem> {
  final AnimationController? controller;
  int itemIndex;
  Operation? operation;

  ActiveItem.builder(this.controller, this.itemIndex, this.operation);

  ActiveItem.index(this.itemIndex)
      : controller = null,
        operation = null;

  @override
  int compareTo(ActiveItem other) {
    return itemIndex - other.itemIndex;
  }
}

class _ReorderableItem extends StatefulWidget {
  final int index;
  final Widget child;
  final ReorderableItem reorderableItem;

  const _ReorderableItem(
      {Key? key,
      required this.index,
      required this.child,
      required this.reorderableItem})
      : super(key: key);

  @override
  State<_ReorderableItem> createState() => _ReorderableItemState();
}

class _ReorderableItemState extends State<_ReorderableItem>
    with SingleTickerProviderStateMixin {
  late MotionAnimationBuilderState _listState;

  late AnimationController _offsetAnimationController;
  late Animation<Offset> _animationOffset;
  late ReorderableItem reorderableItem;

  int get index => widget.index;

  @override
  void initState() {
    _listState = MotionAnimationBuilder.of(context);
    _listState._registerItem(this);
    reorderableItem = widget.reorderableItem;
    _offsetAnimationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animationOffset = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_offsetAnimationController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {});
    if (reorderableItem.isNew) {
      _updateAnimationTranslation();
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _ReorderableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _offsetAnimationController.reset();
    reorderableItem = widget.reorderableItem;
    if (oldWidget.index != index) {
      _listState._unregisterItem(index, this);
      _listState._registerItem(this);
    }
    _updateAnimationTranslation();
  }

  void _updateAnimationTranslation() {
    final originalOffset = reorderableItem.oldOffset;
    final updatedOffset = reorderableItem.updatedOffset;

    Offset offsetDiff = originalOffset - updatedOffset;
    _animationOffset = Tween<Offset>(begin: offsetDiff, end: Offset.zero)
        .animate(_offsetAnimationController);
    print(offsetDiff);
    if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
      _offsetAnimationController.forward();
    }
  }

  Offset itemOffset() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(Offset.zero);
  }

  @override
  void dispose() {
    _listState._unregisterItem(index, this);
    _offsetAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.translationValues(
          _animationOffset.value.dx, _animationOffset.value.dy, 0.0),
      child: widget.child,
    );
  }








  // Offset get offset {
  //   if (_offsetAnimationController != null) {
  //     final double animValue =
  //         Curves.easeInOut.transform(_offsetAnimationController!.value);
  //     return Offset.lerp(_startOffset, _targetOffset, animValue)!;
  //   }
  //   return _targetOffset;
  // }

  void resetGap() {
    if (_offsetAnimationController != null) {
      _offsetAnimationController!.dispose();
      //_offsetAnimationController = null;
    }
    rebuild();
  }

  // void updateGap(int changeIndex, bool animate, Operation operation,
  //     ActiveItem incomingItem, Duration resizeDuration) {
  //   if (!mounted) return;
  //   if (index < changeIndex) return;
  //   reorderableItem = _listState.childrenMap[index]!;
  //   print("Reorderable Item: $reorderableItem ---Index: $index");
  //   Offset offsetDiff =
  //       reorderableItem.oldOffset - reorderableItem.updatedOffset;
  //   if (offsetDiff == _targetOffset) return;
  //   _startOffset = offsetDiff;
  //   if (animate) {
  //     if (_offsetAnimationController == null) {
  //       _offsetAnimationController =
  //           AnimationController(vsync: _listState, duration: resizeDuration)
  //             ..addListener(rebuild)
  //             ..addStatusListener((status) {
  //               if (status == AnimationStatus.completed) {
  //                 if (operation == Operation.insertion) {
  //                   if (incomingItem.controller != null) {
  //                     incomingItem.controller!.forward().then<void>((_) {
  //                       final activeItem = _listState._removeActiveItemAt(
  //                           _listState._incomingItems, incomingItem.itemIndex)!;
  //                       activeItem.controller!.dispose();
  //                     });
  //                   }
  //                 }
  //                 _startOffset = _targetOffset;
  //                 _offsetAnimationController?.dispose();
  //                // _offsetAnimationController = null;
  //               }
  //             })
  //             ..forward(from: 0.0);
  //     } else {
  //       _startOffset = offset;
  //       _offsetAnimationController!.forward(from: 0.0);
  //     }
  //   } else {
  //     if (_offsetAnimationController != null) {
  //       _offsetAnimationController?.dispose();
  //      // _offsetAnimationController = null;
  //     }
  //     _startOffset = _targetOffset;
  //   }
  //   _listState.childrenMap[index] = _listState.childrenMap[index]!.copywith(
  //       oldIndex: index,
  //       oldOffset: reorderableItem.updatedOffset,
  //       updatedOffset: Offset.zero,
  //       updatedIndex: index);
  //   rebuild();
  // }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }
}
