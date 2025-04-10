import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../component/sliver_constraints_capture.dart';
import '../component/drag_listener.dart';
import '../model/item_transition_data.dart';
import 'reorderable_animated_list_base.dart';

part '../component/drag_item.dart';

part '../component/reorderable_animated_content.dart';

typedef CustomAnimatedWidgetBuilder<E> = Widget Function(
    BuildContext context, Widget child, Animation<double> animation);

class ReorderableAnimatedBuilder<E> extends StatefulWidget {
  final CustomAnimatedWidgetBuilder<E> insertAnimationBuilder;
  final CustomAnimatedWidgetBuilder<E> removeAnimationBuilder;
  final ReorderCallback? onReorder;
  final void Function(int index)? onReorderStart;
  final void Function(int index)? onReorderEnd;

  final ReorderItemProxyDecorator? proxyDecorator;
  final ItemBuilder itemBuilder;
  final int initialCount;
  final Axis scrollDirection;
  final SliverGridDelegate? delegateBuilder;
  final bool buildDefaultDragHandles;
  final bool longPressDraggable;
  final Duration dragStartDelay;
  final List<int> nonDraggableIndices;
  final List<int> lockedIndices;

  const ReorderableAnimatedBuilder(
      {Key? key,
      required this.itemBuilder,
      required this.insertAnimationBuilder,
      required this.removeAnimationBuilder,
      this.onReorder,
      this.onReorderEnd,
      this.onReorderStart,
      this.proxyDecorator,
      this.initialCount = 0,
      this.delegateBuilder,
      this.scrollDirection = Axis.vertical,
      required this.buildDefaultDragHandles,
      this.longPressDraggable = false,
      required this.dragStartDelay,
      required this.nonDraggableIndices,
      required this.lockedIndices})
      : assert(initialCount >= 0),
        super(key: key);

  @override
  State<ReorderableAnimatedBuilder> createState() =>
      ReorderableAnimatedBuilderState();

  static ReorderableAnimatedBuilderState of(BuildContext context) {
    final ReorderableAnimatedBuilderState? result =
        context.findAncestorStateOfType<ReorderableAnimatedBuilderState>();
    assert(() {
      if (result == null) {
        throw FlutterError(
          'ReorderableAnimatedBuilderState.of() called with a context that does not contain a ReorderableAnimatedBuilderState.\n'
          'No ReorderableAnimatedBuilderState ancestor could be found starting from the '
          'context that was passed to ReorderableAnimatedBuilderState.of(). This can '
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

  static ReorderableAnimatedBuilderState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ReorderableAnimatedBuilderState>();
  }
}

class ReorderableAnimatedBuilderState extends State<ReorderableAnimatedBuilder>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<_ActiveItem> _incomingItems = <_ActiveItem>[];
  final List<_ActiveItem> _outgoingItems = <_ActiveItem>[];
  int _itemsCount = 0;

  Map<int, ItemTransitionData> childrenMap = <int, ItemTransitionData>{};
  final Map<int, ReorderableAnimatedContentState> _items =
      <int, ReorderableAnimatedContentState>{};

  OverlayEntry? _overlayEntry;
  int? _dragIndex;
  _DragInfo? _dragInfo;
  int? _insertIndex;
  Offset? _finalDropPosition;
  MultiDragGestureRecognizer? _recognizer;
  int? _recognizerPointer;
  EdgeDraggingAutoScroller? _autoScroller;
  late ScrollableState _scrollable;
  bool _isDragging = false;

  bool autoScrolling = false;

  Axis get scrollDirection => axisDirectionToAxis(_scrollable.axisDirection);

  bool get _reverse =>
      _scrollable.axisDirection == AxisDirection.up ||
      _scrollable.axisDirection == AxisDirection.left;

  bool get isGrid => widget.delegateBuilder != null;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    _itemsCount = widget.initialCount;
    for (int i = 0; i < widget.initialCount; i++) {
      childrenMap[i] = ItemTransitionData();
    }

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable = Scrollable.of(context);
  }

  @override
  void didUpdateWidget(covariant ReorderableAnimatedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCount != oldWidget.initialCount) {
      cancelReorder();
    }
  }

  void startItemDragReorder(
      {required int index,
      required PointerDownEvent event,
      required MultiDragGestureRecognizer recognizer}) {
    assert(0 <= index && index < _itemsCount);
    setState(() {
      if (_dragInfo != null) {
        cancelReorder();
      } else if (_recognizer != null && _recognizerPointer != event.pointer) {
        _recognizer!.dispose();
        _recognizer = null;
        _recognizerPointer = null;
      }
      if (_items.containsKey(index)) {
        _dragIndex = index;
        _recognizer = recognizer
          ..onStart = _dragStart
          ..addPointer(event);
        _recognizerPointer = event.pointer;
      } else {
        throw Exception("Attempting ro start drag on a non-visible item");
      }
    });
  }

  Drag? _dragStart(Offset position) {
    assert(_dragInfo == null);
    final ReorderableAnimatedContentState item = _items[_dragIndex]!;
    _isDragging = true;

    item.dragging = true;
    widget.onReorderStart?.call(_dragIndex!);
    item.rebuild();
    _insertIndex = item.index;
    _dragInfo = _DragInfo(
        item: item,
        initialPosition: position,
        scrollDirection: scrollDirection,
        gridView: isGrid,
        onUpdate: _dragUpdate,
        onCancel: _dragCancel,
        onEnd: _dragEnd,
        onDragCompleted: _dropCompleted,
        proxyDecorator: widget.proxyDecorator,
        tickerProvider: this);

    _dragInfo!.startDrag();
    item.dragSize = _dragInfo!.itemSize;

    final OverlayState overlay = Overlay.of(context, debugRequiredFor: widget);
    assert(_overlayEntry == null);
    _overlayEntry = OverlayEntry(builder: _dragInfo!.createProxy);
    overlay.insert(_overlayEntry!);

    for (final ReorderableAnimatedContentState childItem in _items.values) {
      if (childItem == item || !childItem.mounted) {
        continue;
      }
      item.updateForGap(false);
    }
    return _dragInfo;
  }

  void _dragUpdate(_DragInfo item, Offset position, Offset delta) {
    setState(() {
      _overlayEntry?.markNeedsBuild();
      _dragUpdateItems();
      _autoScrollIfNecessary();
    });
  }

  void _dragCancel(_DragInfo item) {
    setState(() {
      _dragReset();
    });
    _isDragging = false;
  }

  Future<void> _autoScrollIfNecessary() async {
    if (autoScrolling || _dragInfo == null || _dragInfo!.scrollable == null) {
      return;
    }

    final position = _dragInfo!.scrollable!.position;
    double? newOffset;

    const duration = Duration(milliseconds: 14);
    const step = 1.0;
    const overDragMax = 20.0;
    const overDragCoef = 10;

    final isVertical = widget.scrollDirection == Axis.vertical;

    /// get the scroll window position on the screen
    final scrollRenderBox =
        _dragInfo!.scrollable!.context.findRenderObject()! as RenderBox;
    final Offset scrollPosition = scrollRenderBox.localToGlobal(Offset.zero);

    /// calculate the start and end position for the scroll window
    double scrollWindowStart =
        isVertical ? scrollPosition.dy : scrollPosition.dx;
    double scrollWindowEnd = scrollWindowStart +
        (isVertical ? scrollRenderBox.size.height : scrollRenderBox.size.width);

    /// get the proxy (dragged) object's position on the screen
    final proxyObjectPosition = _dragInfo!.dragPosition - _dragInfo!.dragOffset;

    /// calculate the start and end position for the proxy object
    double proxyObjectStart =
        isVertical ? proxyObjectPosition.dy : proxyObjectPosition.dx;
    double proxyObjectEnd = proxyObjectStart +
        (isVertical ? _dragInfo!.itemSize.height : _dragInfo!.itemSize.width);

    if (!_reverse) {
      /// if start of proxy object is before scroll window
      if (proxyObjectStart < scrollWindowStart &&
          position.pixels > position.minScrollExtent) {
        final overDrag = max(scrollWindowStart - proxyObjectStart, overDragMax);
        newOffset = max(position.minScrollExtent,
            position.pixels - step * overDrag / overDragCoef);
      }

      /// if end of proxy object is after scroll window
      else if (proxyObjectEnd > scrollWindowEnd &&
          position.pixels < position.maxScrollExtent) {
        final overDrag = max(proxyObjectEnd - scrollWindowEnd, overDragMax);
        newOffset = min(position.maxScrollExtent,
            position.pixels + step * overDrag / overDragCoef);
      }
    } else {
      /// if start of proxy object is before scroll window
      if (proxyObjectStart < scrollWindowStart &&
          position.pixels < position.maxScrollExtent) {
        final overDrag = max(scrollWindowStart - proxyObjectStart, overDragMax);
        newOffset = max(position.minScrollExtent,
            position.pixels + step * overDrag / overDragCoef);
      }

      /// if end of proxy object is after scroll window
      else if (proxyObjectEnd > scrollWindowEnd &&
          position.pixels > position.minScrollExtent) {
        final overDrag = max(proxyObjectEnd - scrollWindowEnd, overDragMax);
        newOffset = min(position.maxScrollExtent,
            position.pixels - step * overDrag / overDragCoef);
      }
    }

    if (newOffset != null && (newOffset - position.pixels).abs() >= 1.0) {
      autoScrolling = true;
      await position.animateTo(
        newOffset,
        duration: duration,
        curve: Curves.linear,
      );
      autoScrolling = false;
      if (_dragInfo != null) {
        _dragUpdateItems();
        _autoScrollIfNecessary();
      }
    }
  }

  void _dragEnd(_DragInfo item) {
    setState(() {
      if (_insertIndex == item.index || isGrid) {
        _finalDropPosition = _itemOffsetAt(_insertIndex!);
      } else if (_reverse) {
        if (_insertIndex! >= _items.length - 1) {
          _finalDropPosition = _itemStartOffsetAt(_items.length - 1) -
              _extentOffset(item.itemExtent, scrollDirection);
        } else {
          int atIndex =
              _dragIndex! < _insertIndex! ? _insertIndex! + 1 : _insertIndex!;
          if (_dragIndex! > _insertIndex! && widget.lockedIndices.isNotEmpty) {
            atIndex = _insertIndex! + 1;
            if (!widget.lockedIndices.contains(atIndex)) {
              atIndex = _insertIndex!;
            }
          }
          _finalDropPosition = _itemStartOffsetAt(atIndex) +
              _extentOffset(_itemExtent(atIndex), scrollDirection);
        }
      } else {
        if (_insertIndex! == 0) {
          _finalDropPosition = _itemStartOffsetAt(0) -
              _extentOffset(item.itemExtent, scrollDirection);
        } else {
          int atIndex =
              _dragIndex! < _insertIndex! ? _insertIndex! : _insertIndex! - 1;

          // if the item is locked, we need to calculate final position from the previous item
          // if the previous item is locked, then we calculate position from the previous item
          if (_dragIndex! < _insertIndex! && widget.lockedIndices.isNotEmpty) {
            atIndex = _insertIndex! - 1;
            if (!widget.lockedIndices.contains(atIndex)) {
              atIndex = _insertIndex!;
            }
          }
          _finalDropPosition = _itemStartOffsetAt(atIndex) +
              _extentOffset(_itemExtent(atIndex), scrollDirection);
        }
      }
    });
    widget.onReorderEnd?.call(_insertIndex!);
  }

  void _dropCompleted() {
    final int fromIndex = _dragIndex!;
    final int toIndex = _insertIndex!;
    if (fromIndex != toIndex) {
      widget.onReorder?.call(fromIndex, toIndex);
    }
    setState(() {
      _dragReset();
    });
  }

  void cancelReorder() {
    setState(() {
      _dragReset();
    });
    _isDragging = false;
  }

  void _dragReset() {
    if (_dragInfo != null) {
      if (_dragIndex != null && _items.containsKey(_dragIndex)) {
        final ReorderableAnimatedContentState dragItem = _items[_dragIndex]!;
        dragItem.dragging = false;
        dragItem.dragSize = Size.zero;
        dragItem.rebuild();
        _dragIndex = null;
      }
      _dragInfo?.dispose();
      _dragInfo = null;
      _autoScroller?.stopAutoScroll();
      _resetItemGap();
      _recognizer?.dispose();
      _recognizer = null;
      _overlayEntry?.remove();
      _overlayEntry?.dispose();
      _overlayEntry = null;
      _finalDropPosition = null;
    }
  }

  void _resetItemGap() {
    for (final ReorderableAnimatedContentState item in _items.values) {
      item.resetGap();
    }
  }

  void _dragUpdateItems() {
    assert(_dragInfo != null);

    int newIndex = _insertIndex!;

    final dragCenter = _dragInfo!.itemSize
        .center(_dragInfo!.dragPosition - _dragInfo!.dragOffset);

    for (final ReorderableAnimatedContentState item in _items.values) {
      if (!item.mounted) continue;
      final Rect geometry = item.targetGeometryNonOffset();
      if (widget.lockedIndices.contains(item.index)) {
        continue;
      }
      if (geometry.contains(dragCenter)) {
        newIndex = item.index;
        break;
      }
    }

    if (newIndex == _insertIndex) return;
    _insertIndex = newIndex;

    for (final ReorderableAnimatedContentState item in _items.values) {
      if (item.index == _dragIndex ||
          widget.lockedIndices.contains(item.index)) {
        continue;
      }
      item.updateForGap(true);
    }
  }

  Offset calculateNextDragOffset(int index) {
    int minPos = min(_dragIndex!, _insertIndex!);
    int maxPos = max(_dragIndex!, _insertIndex!);
    if (_dragIndex == null || _insertIndex == null) return Offset.zero;

    if (index < minPos || index > maxPos) return Offset.zero;

    int direction = _insertIndex! > _dragIndex! ? -1 : 1;

    int targetIndex = index + direction;

    Offset targetOffset = _extentOffset(_dragInfo!.itemExtent, scrollDirection);

    while (widget.lockedIndices.contains(targetIndex)) {
      targetIndex += direction;
      targetOffset += _extentOffset(_dragInfo!.itemExtent, scrollDirection);
    }
    if (isGrid) {
      return _itemOffsetAt(targetIndex) - _itemOffsetAt(index);
    } else {
      if (_reverse) {
        return _insertIndex! > _dragIndex! ? targetOffset : -targetOffset;
      } else {
        return _insertIndex! > _dragIndex! ? -targetOffset : targetOffset;
      }
    }
  }

  void registerItem(ReorderableAnimatedContentState item) {
    if (_dragInfo != null && _items[item.index] != item) {
      item.updateForGap(false);
    }
    _items[item.index] = item;
    if (item.index == _dragInfo?.index) {
      item.dragging = true;
      item.dragSize = _dragInfo!.itemSize;
      item.rebuild();
    }
  }

  void unregisterItem(int index, ReorderableAnimatedContentState item) {
    final ReorderableAnimatedContentState? currentItem = _items[index];
    if (currentItem == item) {
      _items.remove(index);
    }
  }

  @override
  void dispose() {
    for (final _ActiveItem item in _incomingItems.followedBy(_outgoingItems)) {
      item.controller?.dispose();
    }
    _dragReset();
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
    assert(itemIndex >= 0 && itemIndex <= _itemsCount);

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
    final AnimationController sizeController = AnimationController(
      duration: kAnimationDuration,
      vsync: this,
    );

    final _ActiveItem incomingItem = _ActiveItem.animation(
      controller,
      itemIndex,
      sizeController,
    );

    _incomingItems
      ..add(incomingItem)
      ..sort();

    final updatedChildrenMap = <int, ItemTransitionData>{};

    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key == itemIndex) {
          updatedChildrenMap[itemIndex] = ItemTransitionData(visible: false);
          updatedChildrenMap[entry.key + 1] = entry.value.copyWith(
              startOffset: _itemOffsetAt(entry.key),
              endOffset: _itemNextOffset(entry.key),
              animate: isGrid);
        } else if (entry.key > itemIndex) {
          updatedChildrenMap[entry.key + 1] = entry.value.copyWith(
              startOffset: _itemOffsetAt(entry.key),
              endOffset: _itemNextOffset(entry.key),
              animate: isGrid);
        } else {
          updatedChildrenMap[entry.key] = entry.value;
        }
      }
      childrenMap.clear();
      childrenMap.addAll(updatedChildrenMap);
      sizeController.forward().then((value) {
        controller.forward().then<void>((_) {
          _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)!
              .controller!
              .dispose();
        });
      });
    } else {
      childrenMap[itemIndex] = ItemTransitionData();
      sizeController.value = kAlwaysCompleteAnimation.value;
      controller.forward().then<void>((_) {
        _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)!
            .controller!
            .dispose();
      });
    }
    setState(() {
      _itemsCount += 1;
    });
  }

  void removeItem(int index, {required Duration removeItemDuration}) {
    assert(index >= 0);
    final int itemIndex = _indexToItemIndex(index);
    if (itemIndex < 0 || itemIndex >= _itemsCount) {
      return;
    }
    assert(itemIndex >= 0 && itemIndex < _itemsCount);

    assert(_activeItemAt(_outgoingItems, itemIndex) == null);

    if (childrenMap.containsKey(index)) {
      final _ActiveItem? incomingItem =
          _removeActiveItemAt(_incomingItems, itemIndex);

      final AnimationController sizeController = incomingItem?.sizeAnimation ??
          AnimationController(
              vsync: this, duration: kAnimationDuration, value: 1.0);
      final AnimationController controller = incomingItem?.controller ??
          AnimationController(
              duration: removeItemDuration, value: 1.0, vsync: this)
        ..addStatusListener((status) => ());
      final _ActiveItem outgoingItem =
          _ActiveItem.animation(controller, itemIndex, sizeController);

      _outgoingItems
        ..add(outgoingItem)
        ..sort();

      controller.reverse().then<void>((void value) {
        if (controller.status == AnimationStatus.dismissed) {
          if (childrenMap.containsKey(index)) {
            childrenMap.update(
                index, (value) => value.copyWith(visible: false));
          }
          sizeController.reverse(from: 1.0).then((value) {
            final removedItem =
                _removeActiveItemAt(_outgoingItems, outgoingItem.itemIndex)!;
            removedItem.controller!.dispose();
            removedItem.sizeAnimation!.dispose();

            // Decrement the incoming and outgoing item indices to account
            // for the removal.
            for (final _ActiveItem item in _incomingItems) {
              if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
            }
            for (final _ActiveItem item in _outgoingItems) {
              if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
            }
            _onItemRemoved(index, removeItemDuration);
          });
        }
      });
    }
  }

  void moveItem(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    if (!childrenMap.containsKey(fromIndex) ||
        !childrenMap.containsKey(toIndex)) {
      return;
    }
    if (_dragInfo != null || _isDragging) return;

    final fromOffset = _itemOffsetAt(fromIndex);
    final toOffset = _itemOffsetAt(toIndex);
    childrenMap[toIndex] = childrenMap[fromIndex]!.copyWith(
        startOffset: fromOffset, endOffset: toOffset, animate: !_isDragging);
    childrenMap[fromIndex] = childrenMap[toIndex]!.copyWith(
        startOffset: toOffset, endOffset: fromOffset, animate: !_isDragging);
  }

  void _onItemRemoved(int itemIndex, Duration removeDuration) {
    final updatedChildrenMap = <int, ItemTransitionData>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key < itemIndex) {
          updatedChildrenMap[entry.key] = childrenMap[entry.key]!;
        } else if (entry.key == itemIndex) {
          continue;
        } else {
          updatedChildrenMap[entry.key - 1] = childrenMap[entry.key]!.copyWith(
              startOffset: _itemOffsetAt(entry.key),
              endOffset: _itemOffsetAt(entry.key - 1),
              animate: isGrid);
        }
      }
    }
    childrenMap.clear();
    childrenMap.addAll(updatedChildrenMap);

    setState(() => _itemsCount -= 1);
  }

  Offset _itemOffsetAt(int index) {
    final itemRenderBox =
        _items[index]?.context.findRenderObject() as RenderBox?;
    if (itemRenderBox == null) return Offset.zero;
    return itemRenderBox.localToGlobal(Offset.zero);
  }

  Offset _itemStartOffsetAt(int index) {
    if (!_items.containsKey(index)) return Offset.zero;
    return _items[index]!.targetGeometry().topLeft;
  }

  double _itemExtent(int index) {
    if (!_items.containsKey(index)) return 0;
    return _sizeExtent(_items[index]!.targetGeometry().size, scrollDirection);
  }

  bool _dragEnabled(int index) =>
      widget.onReorder != null &&
      !widget.nonDraggableIndices.contains(index) &&
      !widget.lockedIndices.contains(index);

  double childCrossAxisExtent = 0.0;
  double childMainAxisExtent = 0.0;
  int crossAxisCount = 0;
  double crossAxisSpacing = 0.0;

  void _updateChildExtent(SliverConstraints constraints) {
    if (widget.delegateBuilder == null) return;
    if (widget.delegateBuilder is SliverGridDelegateWithFixedCrossAxisCount) {
      final delegateBuilder =
          widget.delegateBuilder as SliverGridDelegateWithFixedCrossAxisCount;
      crossAxisCount = delegateBuilder.crossAxisCount;
      crossAxisSpacing = delegateBuilder.crossAxisSpacing;
      final childAspectRatio = delegateBuilder.childAspectRatio;
      final usableCrossAxisCount = max(
          0.0,
          constraints.crossAxisExtent -
              crossAxisSpacing * (crossAxisCount - 1));

      childCrossAxisExtent = usableCrossAxisCount / crossAxisCount;
      childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
    }
    if (widget.delegateBuilder is SliverGridDelegateWithMaxCrossAxisExtent) {
      final delegateBuilder =
          widget.delegateBuilder as SliverGridDelegateWithMaxCrossAxisExtent;
      crossAxisSpacing = delegateBuilder.crossAxisSpacing;

      int childCrossAxisCount = (constraints.crossAxisExtent /
              (delegateBuilder.maxCrossAxisExtent + crossAxisSpacing))
          .ceil();

      // Ensure a minimum count of 1, can be zero and result in an infinite extent
      // below when the window size is 0.
      crossAxisCount = max(1, childCrossAxisCount);
      final double usableCrossAxisExtent = max(
        0.0,
        constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1),
      );
      childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
      childMainAxisExtent = delegateBuilder.mainAxisExtent ??
          childCrossAxisExtent / delegateBuilder.childAspectRatio;
    }
  }

  Offset _itemNextOffset(int index) {
    final currentOffset = _itemOffsetAt(index);
    if (!isGrid) {
      return currentOffset;
    }

    final int col = index % crossAxisCount;
    final crossAxisStart = crossAxisSpacing;

    if (col == crossAxisCount - 1) {
      return Offset(crossAxisStart, currentOffset.dy + childMainAxisExtent);
    } else {
      return Offset(currentOffset.dx + childCrossAxisExtent, currentOffset.dy);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.delegateBuilder != null
        ? SliverConstraintsCapture(
            onConstraintsChanged: _updateChildExtent,
            child: SliverGrid(
              gridDelegate: widget.delegateBuilder!,
              delegate: _createDelegate(),
            ),
          )
        : SliverList(delegate: _createDelegate());
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final _ActiveItem? outgoingItem = _activeItemAt(_outgoingItems, index);
    final _ActiveItem? incomingItem = _activeItemAt(_incomingItems, index);

    if (outgoingItem != null) {
      final item = _items[index];
      if (item == null) return const SizedBox();

      final child = item.widget;
      return _removeItemBuilder(outgoingItem, child);
    }
    if (_dragInfo != null && index >= _itemsCount) {
      return SizedBox.fromSize(size: _dragInfo!.itemSize);
    }

    final itemIndex = _itemIndexToIndex(index);

    final Widget child = _dragEnabled(itemIndex)
        ? reorderableItemBuilder(context, itemIndex)
        : widget.itemBuilder(context, itemIndex);

    assert(() {
      if (child.key == null) {
        throw FlutterError(
          'Every item of AnimatedReorderableList must have a unique key.',
        );
      }
      return true;
    }());

    final Key itemGlobalKey = _MotionBuilderItemGlobalKey(child.key!, this);
    final Widget builder = _insertItemBuilder(incomingItem, child);

    final ItemTransitionData? transitionData = childrenMap[index];
    if (transitionData == null) return builder;
    final OverlayState overlay = Overlay.of(context, debugRequiredFor: widget);

    return ReorderableAnimatedContent(
      index: index,
      key: itemGlobalKey,
      transitionData: transitionData,
      updateItemPosition: () {
        final itemOffset = _itemOffsetAt(index);
        childrenMap[index] = ItemTransitionData(
            startOffset: itemOffset,
            endOffset: itemOffset,
            visible: true,
            animate: false);
      },
      capturedThemes:
          InheritedTheme.capture(from: context, to: overlay.context),
      child: builder,
    );
  }

  SliverChildDelegate _createDelegate() {
    return SliverChildBuilderDelegate(_itemBuilder, childCount: _itemsCount);
  }

  Widget reorderableItemBuilder(BuildContext context, int index) {
    final Widget item = widget.itemBuilder(context, index);
    final Widget itemWithSemantics = _wrapWithSemantics(item, index);

    assert(() {
      if (item.key == null) {
        throw FlutterError(
          'Every item of AnimatedReorderableList must have a key.',
        );
      }
      return true;
    }());
    final Key itemGlobalKey = _MotionBuilderItemGlobalKey(item.key!, this);
    if (widget.buildDefaultDragHandles) {
      switch (Theme.of(context).platform) {
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          switch (widget.scrollDirection) {
            case Axis.horizontal:
              return Stack(
                key: itemGlobalKey,
                children: <Widget>[
                  itemWithSemantics,
                  Positioned.directional(
                      textDirection: Directionality.of(context),
                      start: 0,
                      end: 0,
                      bottom: 8,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: ReorderableGridDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                      ))
                ],
              );
            case Axis.vertical:
              return Stack(
                key: itemGlobalKey,
                children: <Widget>[
                  itemWithSemantics,
                  Positioned.directional(
                      textDirection: Directionality.of(context),
                      top: 0,
                      bottom: 0,
                      end: 8,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ReorderableGridDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                      ))
                ],
              );
          }
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.iOS:
          return ReorderableGridDelayedDragStartListener(
              dragStartDelay: widget.dragStartDelay,
              key: itemGlobalKey,
              index: index,
              child: item);
      }
    }

    const bool enable = true;
    return ReorderableGridDelayedDragStartListener(
      dragStartDelay: widget.dragStartDelay,
      key: itemGlobalKey,
      index: index,
      enabled: enable,
      child: itemWithSemantics,
    );
  }

  Widget _wrapWithSemantics(Widget child, int index) {
    void reorder(int startIndex, int endIndex) {
      if (startIndex != endIndex) {
        widget.onReorder?.call(startIndex, endIndex);
      }
    }

    // First, determine which semantics actions apply.
    final Map<CustomSemanticsAction, VoidCallback> semanticsActions =
        <CustomSemanticsAction, VoidCallback>{};

    // Create the appropriate semantics actions.
    void moveToStart() => reorder(index, 0);
    void moveToEnd() => reorder(index, _itemsCount);
    void moveBefore() => reorder(index, index - 1);
    // To move after, we go to index+2 because we are moving it to the space
    // before index+2, which is after the space at index+1.
    void moveAfter() => reorder(index, index + 2);

    final WidgetsLocalizations localizations = WidgetsLocalizations.of(context);

    // If the item can move to before its current position in the grid.
    if (index > 0) {
      semanticsActions[
              CustomSemanticsAction(label: localizations.reorderItemToStart)] =
          moveToStart;
      String reorderItemBefore = localizations.reorderItemUp;
      if (widget.scrollDirection == Axis.horizontal) {
        reorderItemBefore = Directionality.of(context) == TextDirection.ltr
            ? localizations.reorderItemLeft
            : localizations.reorderItemRight;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemBefore)] =
          moveBefore;
    }

    // If the item can move to after its current position in the grid.
    if (index < _itemsCount - 1) {
      String reorderItemAfter = localizations.reorderItemDown;
      if (widget.scrollDirection == Axis.horizontal) {
        reorderItemAfter = Directionality.of(context) == TextDirection.ltr
            ? localizations.reorderItemRight
            : localizations.reorderItemLeft;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemAfter)] =
          moveAfter;
      semanticsActions[
              CustomSemanticsAction(label: localizations.reorderItemToEnd)] =
          moveToEnd;
    }

    // We pass toWrap with a GlobalKey into the item so that when it
    // gets dragged, the accessibility framework can preserve the selected
    // state of the dragging item.
    //
    // We also apply the relevant custom accessibility actions for moving the item
    // up, down, to the start, and to the end of the grid.
    return MergeSemantics(
      child: Semantics(
        customSemanticsActions: semanticsActions,
        child: child,
      ),
    );
  }

  Widget _removeItemBuilder(_ActiveItem outgoingItem, Widget child) {
    final Animation<double> animation =
        outgoingItem.controller ?? kAlwaysCompleteAnimation;
    final Animation<double> sizeAnimation =
        outgoingItem.sizeAnimation ?? kAlwaysCompleteAnimation;
    return SizeTransition(
        sizeFactor: sizeAnimation,
        child: widget.removeAnimationBuilder(context, child, animation));
  }

  Widget _insertItemBuilder(_ActiveItem? incomingItem, Widget child) {
    final Animation<double> animation =
        incomingItem?.controller ?? kAlwaysCompleteAnimation;
    final Animation<double> sizeAnimation =
        incomingItem?.sizeAnimation ?? kAlwaysCompleteAnimation;
    return SizeTransition(
        axis: widget.scrollDirection,
        sizeFactor: sizeAnimation,
        child: widget.insertAnimationBuilder(context, child, animation));
  }
}

Offset _extentOffset(double extent, Axis scrollDirection) {
  switch (scrollDirection) {
    case Axis.horizontal:
      return Offset(extent, 0.0);
    case Axis.vertical:
      return Offset(0.0, extent);
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
  int get hashCode => Object.hash(
        subKey,
        state,
      );
}

class _ActiveItem implements Comparable<_ActiveItem> {
  _ActiveItem.animation(this.controller, this.itemIndex, this.sizeAnimation);

  _ActiveItem.index(this.itemIndex)
      : controller = null,
        sizeAnimation = null;

  final AnimationController? controller;
  final AnimationController? sizeAnimation;
  int itemIndex;

  @override
  int compareTo(_ActiveItem other) => itemIndex - other.itemIndex;
}
