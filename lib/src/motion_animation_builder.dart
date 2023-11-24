import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

const Duration _kDuration = Duration(milliseconds: 300);
const Duration _kResizeDuration = Duration(milliseconds: 1000);

typedef DelegateBuilder = SliverChildBuilderDelegate Function(
    NullableIndexedWidgetBuilder builder, int itemCount);

typedef AnimatedRemovedItemBuilder = Widget Function(
    BuildContext context, Animation<double> animation);

typedef AnimatedWidgetBuilder = Widget Function(BuildContext context,
    Animation<double>? resizeAnimation, int index, Animation<double> animation);

class MotionAnimationBuilder<E> extends StatefulWidget {
  final AnimatedWidgetBuilder insertAnimationBuilder;
  final AnimatedWidgetBuilder removeAnimationBuilder;
  final int initialCount;
  final SliverGridDelegate? delegateBuilder;
  final bool isGriView;

  const MotionAnimationBuilder(
      {Key? key,
      required this.insertAnimationBuilder,
      required this.removeAnimationBuilder,
      this.initialCount = 0,
      required this.isGriView,
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
  final List<_ActiveItem> _incomingItems = <_ActiveItem>[];
  final List<_ActiveItem> _outgoingItems = <_ActiveItem>[];
  int _itemsCount = 0;
  final Map<int, _ReorderableItemState> _items = <int, _ReorderableItemState>{};

  @override
  void initState() {
    super.initState();
    _itemsCount = widget.initialCount;
  }



  void _registerItem(_ReorderableItemState item) {
    _items[item.index] = item;
    item.rebuild();
  }

  void startDrag(int index) {
    final _ReorderableItemState item = _items[index]!;
    print(item);
    for (final _ReorderableItemState childItem in _items.values) {
      if (childItem == item || !childItem.mounted) continue;
      childItem.updateForGap(index, true);
    }
  }

  Offset calculateNextDragOffset(int index,int insertIndex) {
    if (index < insertIndex) return Offset.zero;
    final int direction = 1;
    return _itemOffsetAt(index - direction) - _itemOffsetAt(index);
  }

  Offset _itemOffsetAt(int index) {
    final box = _items[index]?.context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(Offset.zero);
  }
  void _unregisterItem(int index, _ReorderableItemState item) {
    final _ReorderableItemState? currentItem = _items[index];
    if (currentItem == item) {
      _items.remove(index);
    }
  }



  @override
  void dispose() {
    for (final _ActiveItem item in _incomingItems.followedBy(_outgoingItems)) {
      item.controller!.dispose();
      item.resizeController?.dispose();
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

  void insertItem(int index,
      {Duration insertDuration = _kDuration,
      Duration resizeDuration = _kResizeDuration}) {
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

    final AnimationController addResizeController =
        AnimationController(vsync: this, duration: resizeDuration);

    final AnimationController controller =
        AnimationController(vsync: this, duration: insertDuration);
    final _ActiveItem incomingItem =
        _ActiveItem.builder(controller, itemIndex, addResizeController);
    addResizeController.forward();
    addResizeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.forward().then<void>((_) {
          final activeItem =
              _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)!;
          activeItem.controller!.dispose();
          activeItem.resizeController?.dispose();
        });
      }
    });
    setState(() {
      _incomingItems
        ..add(incomingItem)
        ..sort();
      _itemsCount += 1;
    });
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

    final _ActiveItem? incomingItem =
        _removeActiveItemAt(_incomingItems, itemIndex);
    final AnimationController controller = incomingItem?.controller ??
        AnimationController(vsync: this, value: 1.0, duration: removeDuration);
    final AnimationController resizeController = incomingItem
            ?.resizeController ??
        AnimationController(vsync: this, value: 1.0, duration: resizeDuration);

    controller.reverse();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        resizeController.reverse();
      }
    });
    final _ActiveItem outgoingItem =
        _ActiveItem.builder(controller, itemIndex, resizeController);
    setState(() {
      _outgoingItems
        ..add(outgoingItem)
        ..sort();
    });
    resizeController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        final _ActiveItem? activeItem =
            _removeActiveItemAt(_outgoingItems, outgoingItem.itemIndex);

        for (final _ActiveItem item in _incomingItems) {
          if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
        }
        for (final _ActiveItem item in _outgoingItems) {
          if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
        }
        setState(() {
          _itemsCount -= 1;
        });
        activeItem?.controller?.dispose();
        activeItem?.resizeController?.dispose();
      }
    });
    startDrag(outgoingItem.itemIndex);

  }

  SliverChildDelegate _createDelegate() {
    return SliverChildBuilderDelegate(
        (context, index){
          final Widget child= itemBuilderDelegate(context, index);
          assert(child.key != null, "All grid items must have a key");
          return  _ReorderableItem(key: _ReorderableItemGlobalKey(child.key!,index), index: index, child: child);
        },
        childCount: _itemsCount);
  }

  Widget _removeItemBuilder(_ActiveItem outgoingItem, int itemIndex) {
    final Animation<double> animation =
        outgoingItem.controller?.view ?? kAlwaysCompleteAnimation;
    final Animation<double>? resizeAnimation =
        outgoingItem.resizeController?.view;
    final Widget child = widget.removeAnimationBuilder(
      context,
      resizeAnimation,
      itemIndex,
      animation,
    );
    return child;
  }

  Widget _insertItemBuilder(_ActiveItem? incomingItem, int itemIndex) {
    final Animation<double> animation =
        incomingItem?.controller?.view ?? kAlwaysCompleteAnimation;
    final Animation<double>? resizeAnimation =
        incomingItem?.resizeController?.view;
    return widget.insertAnimationBuilder(
      context,
      resizeAnimation,
      _itemIndexToIndex(itemIndex),
      animation,
    );
  }

  Widget itemBuilderDelegate(BuildContext context, int itemIndex) {
    final _ActiveItem? outgoingItem = _activeItemAt(_outgoingItems, itemIndex);
    if (outgoingItem != null) {
      return _removeItemBuilder(outgoingItem, itemIndex);
    }
    final _ActiveItem? incomingItem = _activeItemAt(_incomingItems, itemIndex);
    return _insertItemBuilder(incomingItem, itemIndex);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.isGriView
        ? SliverGrid(
            gridDelegate: widget.delegateBuilder!, delegate: _createDelegate())
        : SliverList(delegate: _createDelegate());
  }

  @override
  bool get wantKeepAlive => false;
}



class _ActiveItem implements Comparable<_ActiveItem> {
  final AnimationController? controller;
  final AnimationController? resizeController;
  int itemIndex;

  _ActiveItem.builder(this.controller, this.itemIndex, this.resizeController);

  _ActiveItem.index(this.itemIndex)
      : controller = null,
        resizeController = null;

  @override
  int compareTo(_ActiveItem other) {
    return itemIndex - other.itemIndex;
  }
}

class _ReorderableItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _ReorderableItem(
      {required Key key, required this.index, required this.child});

  @override
  State<_ReorderableItem> createState() => _ReorderableItemState();
}

class _ReorderableItemState extends State<_ReorderableItem> {
  late MotionAnimationBuilderState _listState;
  Offset _startOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;
  AnimationController? _offsetAnimation;

  Key get key => widget.key!;

  int get index => widget.index;

  @override
  void initState() {
    _listState = MotionAnimationBuilder.of(context);
    _listState._registerItem(this);
    super.initState();
  }

  @override
  void dispose() {
    _offsetAnimation?.dispose();
    _listState._unregisterItem(index, this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ReorderableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _listState._unregisterItem(oldWidget.index, this);
      _listState._registerItem(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    _listState._registerItem(this);
    return Transform(
      transform: Matrix4.translationValues(offset.dx, offset.dy, 0.0),
      child: widget.child,
    );
  }

  Offset get offset {
    if (_offsetAnimation != null) {
      final double animValue =
      Curves.easeInOut.transform(_offsetAnimation!.value);
      return Offset.lerp(_startOffset, _targetOffset, animValue)!;
    }
    return _targetOffset;
  }

  void updateForGap(int gapIndex, bool animate) {
    if (!mounted) return;

    Offset newTargetOffset = _listState.calculateNextDragOffset(index,gapIndex);
    if (newTargetOffset == _targetOffset) return;

    _targetOffset = newTargetOffset;

    if (animate) {
      if (_offsetAnimation == null) {
        _offsetAnimation = AnimationController(
            vsync: _listState, duration: Duration(milliseconds: 300))
          ..addListener(rebuild)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _startOffset = _targetOffset;
              _offsetAnimation?.dispose();
              _offsetAnimation = null;
            }
          })
          ..forward();
      } else {
        _startOffset = offset;
        _offsetAnimation!.forward(from: 0.0);
      }
    } else {
      if (_offsetAnimation != null) {
        _offsetAnimation?.dispose();
        _offsetAnimation = null;
      }
      _startOffset = _targetOffset;
    }
    rebuild();
  }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }
}

@optionalTypeArgs
class _ReorderableItemGlobalKey extends GlobalObjectKey {
  const _ReorderableItemGlobalKey(this.subKey, this.index) : super(subKey);

  final Key subKey;
  final int index;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _ReorderableItemGlobalKey &&
        other.subKey == subKey &&
        other.index == index;
  }

  @override
  int get hashCode => Object.hash(subKey, index);

}