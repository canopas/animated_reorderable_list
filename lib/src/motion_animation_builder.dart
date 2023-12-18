import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:motion_list/src/reorderable_entity.dart';

typedef OnDragCompleteCallback = void Function(ReorderableItem reorderableItem);
typedef OnCreateCallback = ReorderableItem? Function(
    ReorderableItem reorderableItem);
typedef StartInsertAnimationCallback = void Function(
    _ReorderableItem reorderableItem);

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

  const MotionAnimationBuilder(
      {Key? key,
      required this.insertAnimationBuilder,
      required this.removeAnimationBuilder,
      this.initialCount = 0,
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
  final List<_ReorderableItem> _incomingItems = <_ReorderableItem>[];
  final List<_ReorderableItem> _outgoingItems = <_ReorderableItem>[];
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
    for (final _ReorderableItem item
        in _incomingItems.followedBy(_outgoingItems)) {
      item.animationController!.dispose();
    }
    super.dispose();
  }

  _ReorderableItem? _removeActiveItemAt(
      List<_ReorderableItem> items, int itemIndex) {
    final int i = binarySearch(items, _ReorderableItem.index(itemIndex));
    return i == -1 ? null : items.removeAt(i);
  }

  _ReorderableItem? _activeItemAt(List<_ReorderableItem> items, int itemIndex) {
    final int i = binarySearch(items, _ReorderableItem.index(itemIndex));
    return i == -1 ? null : items[i];
  }

  int _indexToItemIndex(int index) {
    int itemIndex = index;

    for (final _ReorderableItem item in _outgoingItems) {
      if (item.index <= itemIndex) {
        itemIndex += 1;
      } else {
        break;
      }
    }
    return itemIndex;
  }

  int _itemIndexToIndex(int itemIndex) {
    int index = itemIndex;
    for (final _ReorderableItem item in _outgoingItems) {
      assert(item.index != itemIndex);
      if (item.index < itemIndex) {
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

  Offset? _itemOffsetAt(int index) {
    final box = _items[index]?.context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero);
  }

  Future<void> insertItem(int index,
      {Duration insertDuration = _kDuration,
      Duration resizeDuration = _kResizeDuration}) async {
    assert(index >= 0);
    final int itemIndex = _indexToItemIndex(index);

    if (itemIndex < 0 || itemIndex > _itemsCount) {
      return;
    }
    for (final _ReorderableItem item in _incomingItems) {
      if (item.index >= itemIndex) item.index += 1;
    }
    for (final _ReorderableItem item in _outgoingItems) {
      if (item.index >= itemIndex) item.index += 1;
    }
    final AnimationController controller =
        AnimationController(vsync: this, duration: insertDuration);
    final _ReorderableItem incomingItem =
        _ReorderableItem.builder(itemIndex, controller);
    _incomingItems
      ..add(incomingItem)
      ..sort();
    addItem(incomingItem.index);

    if (mounted) {
      setState(() {
        _itemsCount++;
      });
    }
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   childrenMap.forEach((key, value) {
    //     childrenMap[key] = childrenMap[key]!.copywith(
    //         updatedOffset: _itemOffsetAt(key),
    //         visible: value.visible == false ? true : value.visible);
    //     print("--------------------------- Updated offset in insertItem: ${_itemOffsetAt(key)}");
    //
    //   });
    //   setState(() {});
    // });

  }

  void startInsertAnimation(_ReorderableItem? incomingItem) {
    if(incomingItem != null){
      if (incomingItem.animationController != null) {
        incomingItem.animationController!.forward();
        incomingItem.animationController!.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            final activeItem =
            _removeActiveItemAt(_incomingItems, incomingItem.index)!;
            activeItem.animationController!.dispose();
          }
        });
      }
    }
  }

  void addItem(int itemIndex) {
    final updatedChildrenMap = <int, ReorderableItem>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key < itemIndex) {
          updatedChildrenMap[entry.key] = childrenMap[entry.key]!.copywith(
            visible: false,
          );
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
              updatedIndex: entry.key + 1,
              visible: false);
        } else {
          updatedChildrenMap[entry.key + 1] = childrenMap[entry.key]!.copywith(
              key: ValueKey(entry.key + 1),
              updatedIndex: entry.key + 1,
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

    final _ReorderableItem? incomingItem =
        _removeActiveItemAt(_incomingItems, itemIndex);
    final AnimationController controller = incomingItem?.animationController ??
        AnimationController(vsync: this, value: 1.0, duration: removeDuration);
    final _ReorderableItem outgoingItem =
        _ReorderableItem.builder(itemIndex, controller);

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
        deleteItem(outgoingItem.index);

        // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        //   childrenMap.forEach((key, value) {
        //     childrenMap[key] =
        //         childrenMap[key]!.copywith(updatedOffset: _itemOffsetAt(key));
        //   });
        //   setState(() {});
        // });

        final _ReorderableItem? activeItem =
            _removeActiveItemAt(_outgoingItems, outgoingItem.index);

        for (final _ReorderableItem item in _incomingItems) {
          if (item.index > outgoingItem.index) item.index -= 1;
        }
        for (final _ReorderableItem item in _outgoingItems) {
          if (item.index > outgoingItem.index) item.index -= 1;
        }
        activeItem?.animationController?.dispose();
      }
    });
  }

  void deleteItem(int itemIndex) {
    final updatedChildrenMap = <int, ReorderableItem>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key < itemIndex) {
          updatedChildrenMap[entry.key] = childrenMap[entry.key]!;
        } else if (entry.key == itemIndex) {
          continue;
        } else {
          updatedChildrenMap[entry.key - 1] = childrenMap[entry.key]!.copywith(
            key: ValueKey(entry.key - 1),
            updatedIndex: entry.key - 1,
          );
        }
      }
    }
    childrenMap.clear();
    childrenMap.addAll(updatedChildrenMap);
  }

  void onDragComplete(ReorderableItem reorderableItem) {
    final updatedOffset = _itemOffsetAt(reorderableItem.updatedIndex);
    if (updatedOffset != null) {
      childrenMap[reorderableItem.updatedIndex] = reorderableItem.copywith(
        oldOffset: updatedOffset,
        oldIndex: reorderableItem.updatedIndex,
        updatedOffset: updatedOffset,
      );
    }
  }

  ReorderableItem? _onCreated(ReorderableItem reorderableItem) {
    final offset = _itemOffsetAt(reorderableItem.updatedIndex);
    if (offset != null) {
      final updatedReorderableItem = reorderableItem.copywith(
          oldOffset: _itemOffsetAt(reorderableItem.oldIndex),
          updatedOffset: _itemOffsetAt(reorderableItem.updatedIndex));
      childrenMap[reorderableItem.updatedIndex] = updatedReorderableItem;
      return updatedReorderableItem;
    }
    return null;
  }

  SliverChildDelegate _createDelegate() {
    return SliverChildBuilderDelegate((context, index) {
      final _ReorderableItem? outgoingItem =
          _activeItemAt(_outgoingItems, index);
      if (outgoingItem != null) {
        final Widget child = _removeItemBuilder(outgoingItem, index);
        return _ReorderableItem(
          key: childrenMap[index]!.key,
          index: index,
          reorderableItem: childrenMap[index]!.copywith(isNew: true),
          animationController: outgoingItem.animationController,
          onDragCompleteCallback: onDragComplete,
          onCreateCallback: _onCreated,
          child: child,
        );
      } else {
        final _ReorderableItem? incomingItem =
            _activeItemAt(_incomingItems, index);
        final Widget child = _insertItemBuilder(incomingItem, index);
        return _ReorderableItem(
          key: childrenMap[index]!.key,
          index: index,
          reorderableItem: childrenMap[index]!.copywith(isNew: true),
          animationController: incomingItem?.animationController,
          onDragCompleteCallback: onDragComplete,
          onCreateCallback: _onCreated,
          onEndAnimation: () => startInsertAnimation(incomingItem),
          child: child,
        );
      }
    }, childCount: _itemsCount);
  }

  Widget _removeItemBuilder(_ReorderableItem outgoingItem, int itemIndex) {
    final Animation<double> animation =
        outgoingItem.animationController?.view ?? kAlwaysCompleteAnimation;
    return widget.removeAnimationBuilder(
      context,
      itemIndex,
      animation,
    );
  }

  Widget _insertItemBuilder(_ReorderableItem? incomingItem, int itemIndex) {
    final Animation<double> animation =
        incomingItem?.animationController?.view ?? kAlwaysCompleteAnimation;
    return widget.insertAnimationBuilder(
      context,
      _itemIndexToIndex(itemIndex),
      animation,
    );
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

class _ReorderableItem extends StatefulWidget
    implements Comparable<_ReorderableItem> {
  int index;
  final Widget? child;
  final ReorderableItem? reorderableItem;
  final AnimationController? animationController;
  final OnDragCompleteCallback? onDragCompleteCallback;
  final OnCreateCallback? onCreateCallback;
  final VoidCallback? onEndAnimation;

  _ReorderableItem({
    Key? key,
    required this.index,
    required this.reorderableItem,
    required this.child,
    required this.animationController,
    required this.onDragCompleteCallback,
    required this.onCreateCallback,
    this.onEndAnimation,
  }) : super(key: key);

  _ReorderableItem.builder(this.index, this.animationController)
      : child = null,
        reorderableItem = null,
        onDragCompleteCallback = null,
        onCreateCallback = null,
        onEndAnimation = null;

  _ReorderableItem.index(this.index)
      : child = null,
        reorderableItem = null,
        animationController = null,
        onDragCompleteCallback = null,
        onCreateCallback = null,
        onEndAnimation = null;

  @override
  State<_ReorderableItem> createState() => _ReorderableItemState();

  @override
  int compareTo(_ReorderableItem other) {
    return index - other.index;
  }
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
    reorderableItem = widget.reorderableItem!;
    _handleCreated();
    _offsetAnimationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animationOffset = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_offsetAnimationController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (widget.animationController != null) {
            widget.animationController!.forward().then((value) {
              if (widget.animationController!.status ==
                  AnimationStatus.completed) {
                if(widget.onEndAnimation != null){
                  widget.onEndAnimation!.call();
                }
              }
            });
          }

          widget.onDragCompleteCallback!(
              reorderableItem.copywith(updatedIndex: index));
        }
      });
    if (reorderableItem.isNew) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _updateAnimationTranslation();
      });
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _ReorderableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
  //  _offsetAnimationController.reset();
    reorderableItem = widget.reorderableItem!;
    if (oldWidget.index != index) {
      _listState._unregisterItem(index, this);
      _listState._registerItem(this);
    }
    _updateAnimationTranslation();
  }

  void _handleCreated() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final updatedReorderableItem = widget.onCreateCallback!(reorderableItem);
      if (updatedReorderableItem != null) {
        setState(() {
          reorderableItem = updatedReorderableItem;
        });
      }
    });
  }

  void _updateAnimationTranslation() {
    if (reorderableItem.oldIndex == reorderableItem.updatedIndex) {
      _animationOffset = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
          .animate(_offsetAnimationController);
      _offsetAnimationController.forward();
    } else {
      final originalOffset = reorderableItem.oldOffset;
      final updatedOffset = itemOffset();

      Offset offsetDiff = originalOffset - updatedOffset;
      _animationOffset = Tween<Offset>(begin: offsetDiff, end: Offset.zero)
          .animate(_offsetAnimationController);
      if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
        _offsetAnimationController.forward();
      }
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

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }
}
