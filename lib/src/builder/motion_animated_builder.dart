import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:animated_reorderable_list/src/component/motion_animated_content.dart';

import '../../animated_reorderable_list.dart';
import '../model/motion_data.dart';

typedef AnimatedWidgetBuilder<E> = Widget Function(
    BuildContext context, Widget child, Animation<double> animation);

class MotionBuilder<E> extends StatefulWidget {
  final AnimatedWidgetBuilder<E> insertAnimationBuilder;
  final AnimatedWidgetBuilder<E> removeAnimationBuilder;
  final ReorderCallback? onReorder;
  final void Function(int index)? onReorderStart;
  final void Function(int index)? onReorderEnd;

  final ReorderItemProxyDecorator? proxyDecorator;
  final ItemBuilder itemBuilder;
  final int initialCount;
  final Axis scrollDirection;
  final SliverGridDelegate? delegateBuilder;

  const MotionBuilder(
      {Key? key,
      required this.insertAnimationBuilder,
      required this.removeAnimationBuilder,
      this.onReorder,
      this.onReorderEnd,
      this.onReorderStart,
      this.proxyDecorator,
      this.initialCount = 0,
      this.delegateBuilder,
      this.scrollDirection = Axis.vertical,
      required this.itemBuilder})
      : assert(initialCount >= 0),
        super(key: key);

  @override
  State<MotionBuilder> createState() => MotionBuilderState();

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

class MotionBuilderState extends State<MotionBuilder>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<_ActiveItem> _incomingItems = <_ActiveItem>[];
  final List<_ActiveItem> _outgoingItems = <_ActiveItem>[];
  int _itemsCount = 0;

  Map<int, MotionData> childrenMap = <int, MotionData>{};
  final Map<int, MotionAnimatedContentState> _items =
      <int, MotionAnimatedContentState>{};

  OverlayEntry? _overlayEntry;
  int? _dragIndex;
  _DragInfo? _dragInfo;
  int? _insertIndex;
  Offset? _finalDropPosition;
  MultiDragGestureRecognizer? _recognizer;
  int? _recognizerPointer;
  EdgeDraggingAutoScroller? _autoScroller;
  late ScrollableState _scrollable;

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
      childrenMap[i] = MotionData();
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable = Scrollable.of(context);
  }

  @override
  void didUpdateWidget(covariant MotionBuilder oldWidget) {
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
    final MotionAnimatedContentState item = _items[_dragIndex]!;
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

    for (final MotionAnimatedContentState childItem in _items.values) {
      if (childItem == item || !childItem.mounted) {
        continue;
      }
      item.updateForGap(_insertIndex!, _dragIndex!, _dragInfo!.itemExtent,
          false, _reverse, isGrid);
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
    setState(() => _finalDropPosition = _itemOffsetAt(_insertIndex!));
  }

  void _dropCompleted() {
    final int fromIndex = _dragIndex!;
    final int toIndex = _insertIndex!;
    childrenMap[_insertIndex] !=
        childrenMap[_insertIndex]!.copyWith(
          index: _dragIndex,
        );
    childrenMap[_dragIndex] !=
        childrenMap[_dragIndex]!.copyWith(index: _insertIndex);
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
  }

  void _dragReset() {
    if (_dragInfo != null) {
      if (_dragIndex != null && _items.containsKey(_dragIndex)) {
        final MotionAnimatedContentState dragItem = _items[_dragIndex]!;
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
    for (final MotionAnimatedContentState item in _items.values) {
      item.resetGap();
    }
  }

  void _dragUpdateItems() {
    assert(_dragInfo != null);

    int newIndex = _insertIndex!;

    final dragCenter = _dragInfo!.itemSize
        .center(_dragInfo!.dragPosition - _dragInfo!.dragOffset);

    for (final MotionAnimatedContentState item in _items.values) {
      if (!item.mounted) continue;
      final Rect geometry = item.targetGeometryNonOffset();

      if (geometry.contains(dragCenter)) {
        newIndex = item.index;
        break;
      }
    }

    if (newIndex == _insertIndex) return;
    _insertIndex = newIndex;

    for (final MotionAnimatedContentState item in _items.values) {
      if (item.index == _dragIndex) continue;
      item.updateForGap(_insertIndex!, _dragIndex!, _dragInfo!.itemExtent, true,
          _reverse, isGrid);
    }
  }

  Offset calculateNextDragOffset(int index) {
    int minPos = min(_dragIndex!, _insertIndex!);
    int maxPos = max(_dragIndex!, _insertIndex!);
    if (index < minPos || index > maxPos) return Offset.zero;

    final int direction = _insertIndex! > _dragIndex! ? -1 : 1;
    if (isGrid) {
      return _itemOffsetAt(index + direction) - _itemOffsetAt(index);
    } else {
      final Offset offset =
          _extentOffset(_dragInfo!.itemExtent, scrollDirection);
      return _insertIndex! > _dragIndex! ? -offset : offset;
    }
  }

  void registerItem(MotionAnimatedContentState item) {
    _items[item.index] = item;
    if (item.index == _dragInfo?.index) {
      item.dragging = true;
      item.dragSize = _dragInfo!.itemSize;
      item.rebuild();
    }
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

    final updatedChildrenMap = <int, MotionData>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key == itemIndex) {
          updatedChildrenMap[itemIndex] = motionData;
          updatedChildrenMap[entry.key + 1] = entry.value
              .copyWith(index: entry.key + 1, duration: insertDuration);
        } else if (entry.key > itemIndex) {
          updatedChildrenMap[entry.key + 1] = entry.value
              .copyWith(index: entry.key + 1, duration: insertDuration);
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

    if (childrenMap.containsKey(itemIndex)) {
      final _ActiveItem? incomingItem =
          _removeActiveItemAt(_incomingItems, itemIndex);

      final AnimationController controller = incomingItem?.controller ??
          AnimationController(
              duration: removeItemDuration, value: 1.0, vsync: this);
      final _ActiveItem outgoingItem =
          _ActiveItem.animation(controller, itemIndex);
      _outgoingItems
        ..add(outgoingItem)
        ..sort();

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
          updatedChildrenMap[entry.key - 1] = childrenMap[entry.key]!
              .copyWith(index: entry.key - 1, duration: removeDuration);
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
    if (_dragInfo != null && index >= _itemsCount) {
      return SizedBox.fromSize(size: _dragInfo!.itemSize);
    }

    final Widget child = widget.onReorder != null
        ? widgetBuilder(context, _itemIndexToIndex(index))
        : widget.itemBuilder(context, _itemIndexToIndex(index));

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

    final motionData = childrenMap[index];
    if (motionData == null) return builder;
    final OverlayState overlay = Overlay.of(context, debugRequiredFor: widget);

    return MotionAnimatedContent(
      index: index,
      key: itemGlobalKey,
      motionData: motionData,
      updateMotionData: (MotionData motionData) {
        childrenMap[index] = motionData.copyWith(
          startOffset: _itemOffsetAt(index),
          endOffset: _itemOffsetAt(index),
        );
      },
      capturedThemes:
          InheritedTheme.capture(from: context, to: overlay.context),
      child: builder,
    );
  }

  SliverChildDelegate _createDelegate() {
    return SliverChildBuilderDelegate(_itemBuilder, childCount: _itemsCount);
  }

  Widget widgetBuilder(BuildContext context, int index) {
    final Widget item = widget.itemBuilder(context, index);
    assert(() {
      if (item.key == null) {
        throw FlutterError(
          'Every item of AnimatedReorderableList must have a key.',
        );
      }
      return true;
    }());

    final Widget itemWithSemantics = _wrapWithSemantics(item, index);
    final Key itemGlobalKey = _MotionBuilderItemGlobalKey(item.key!, this);
    // final bool enable = widget.itemDragEnable(index);
    const bool enable = true;
    return ReorderableGridDelayedDragStartListener(
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
}

typedef _DragItemUpdate = void Function(
    _DragInfo item, Offset position, Offset delta);
typedef _DragItemCallback = void Function(_DragInfo item);

class _DragInfo extends Drag {
  final bool gridView;
  final Axis scrollDirection;
  final _DragItemUpdate? onUpdate;
  final _DragItemCallback? onEnd;
  final _DragItemCallback? onCancel;
  final VoidCallback? onDragCompleted;
  final ReorderItemProxyDecorator? proxyDecorator;
  final TickerProvider tickerProvider;

  late MotionBuilderState listState;
  late int index;
  late Widget child;
  late Offset dragPosition;
  late Offset dragOffset;
  late Size itemSize;
  late double itemExtent;
  late CapturedThemes capturedThemes;
  ScrollableState? scrollable;
  AnimationController? _proxyAnimation;

  _DragInfo({
    required MotionAnimatedContentState item,
    Offset initialPosition = Offset.zero,
    required this.gridView,
    this.scrollDirection = Axis.vertical,
    this.onUpdate,
    this.onEnd,
    this.onCancel,
    this.onDragCompleted,
    this.proxyDecorator,
    required this.tickerProvider,
  }) {
    final RenderBox itemRenderBox =
        item.context.findRenderObject()! as RenderBox;
    listState = item.listState;
    index = item.index;
    child = item.widget.child;
    capturedThemes = item.widget.capturedThemes!;
    dragPosition = initialPosition;
    dragOffset = itemRenderBox.globalToLocal(initialPosition);
    itemSize = item.context.size!;
    itemExtent = _sizeExtent(itemSize, scrollDirection);
    scrollable = Scrollable.of(item.context);
  }

  void dispose() {
    _proxyAnimation?.dispose();
  }

  void startDrag() {
    _proxyAnimation = AnimationController(
        vsync: tickerProvider, duration: const Duration(milliseconds: 250))
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          _dropCompleted();
        }
      })
      ..forward();
  }

  @override
  void update(DragUpdateDetails details) {
    final Offset delta = !gridView
        ? _restrictAxis(details.delta, scrollDirection)
        : details.delta;
    dragPosition += delta;
    onUpdate?.call(this, dragPosition, details.delta);
  }

  @override
  void end(DragEndDetails details) {
    _proxyAnimation!.reverse();
    onEnd?.call(this);
  }

  @override
  void cancel() {
    _proxyAnimation?.dispose();
    _proxyAnimation = null;
    onCancel?.call(this);
  }

  void _dropCompleted() {
    _proxyAnimation?.dispose();
    _proxyAnimation = null;
    onDragCompleted?.call();
  }

  Widget createProxy(BuildContext context) {
    return capturedThemes.wrap(_DragItemProxy(
        listState: listState,
        index: index,
        position: dragPosition - dragOffset - _overlayOrigin(context),
        size: itemSize,
        animation: _proxyAnimation!,
        proxyDecorator: proxyDecorator,
        child: child));
  }
}

class _DragItemProxy extends StatelessWidget {
  final MotionBuilderState listState;
  final int index;
  final Widget child;
  final Offset position;
  final Size size;
  final AnimationController animation;
  final ReorderItemProxyDecorator? proxyDecorator;

  const _DragItemProxy(
      {required this.listState,
      required this.index,
      required this.child,
      required this.position,
      required this.size,
      required this.animation,
      required this.proxyDecorator});

  @override
  Widget build(BuildContext context) {
    final Widget proxyChild =
        proxyDecorator?.call(child, index, animation.view) ?? child;
    final Offset overlayOrigin = _overlayOrigin(context);
    return MediaQuery(
        data: MediaQuery.of(context).removePadding(removeTop: true),
        child: AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            Offset effectivePosition = position;
            final Offset? dropPosition = listState._finalDropPosition;
            if (dropPosition != null) {
              effectivePosition = Offset.lerp(
                  dropPosition - overlayOrigin,
                  effectivePosition,
                  Curves.easeOut.transform(animation.value))!;
            }
            return Positioned(
                left: effectivePosition.dx,
                top: effectivePosition.dy,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: child,
                ));
          },
          child: proxyChild,
        ));
  }
}

class ReorderableGridDragStartListener extends StatelessWidget {
  /// Creates a listener for a drag immediately following a pointer down
  /// event over the given child widget.
  ///
  /// This is most commonly used to wrap part of a grid item like a drag
  /// handle.
  const ReorderableGridDragStartListener({
    Key? key,
    required this.child,
    required this.index,
    this.enabled = true,
  }) : super(key: key);

  /// The widget for which the application would like to respond to a tap and
  /// drag gesture by starting a reordering drag on a reorderable grid.
  final Widget child;

  /// The index of the associated item that will be dragged in the grid.
  final int index;

  /// Whether the [child] item can be dragged and moved in the grid.
  ///
  /// If true, the item can be moved to another location in the grid when the
  /// user taps on the child. If false, tapping on the child will be ignored.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: enabled
          ? (PointerDownEvent event) => _startDragging(context, event)
          : null,
      child: child,
    );
  }

  /// Provides the gesture recognizer used to indicate the start of a reordering
  /// drag operation.
  ///
  /// By default this returns an [ImmediateMultiDragGestureRecognizer] but
  /// subclasses can use this to customize the drag start gesture.
  @protected
  MultiDragGestureRecognizer createRecognizer() {
    return ImmediateMultiDragGestureRecognizer(debugOwner: this);
  }

  void _startDragging(BuildContext context, PointerDownEvent event) {
    final MotionBuilderState? list = MotionBuilder.maybeOf(context);
    list?.startItemDragReorder(
      index: index,
      event: event,
      recognizer: createRecognizer(),
    );
  }
}

/// A wrapper widget that will recognize the start of a drag operation by
/// looking for a long press event. Once it is recognized, it will start
/// a drag operation on the wrapped item in the reorderable grid.
///
/// See also:
///
///  * [ReorderableGridDragStartListener], a similar wrapper that will
///    recognize the start of the drag immediately after a pointer down event.
///  * [ReorderableGrid], a widget grid that allows the user to reorder
///    its items.
///  * [SliverReorderableGrid], a sliver grid that allows the user to reorder
///    its items.
///  * [ReorderableGridView], a material design grid that allows the user to
///    reorder its items.
class ReorderableGridDelayedDragStartListener
    extends ReorderableGridDragStartListener {
  /// Creates a listener for an drag following a long press event over the
  /// given child widget.
  ///
  /// This is most commonly used to wrap an entire grid item in a reorderable
  /// grid.
  const ReorderableGridDelayedDragStartListener({
    Key? key,
    required Widget child,
    required int index,
    bool enabled = true,
  }) : super(key: key, child: child, index: index, enabled: enabled);

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(debugOwner: this);
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

double _sizeExtent(Size size, Axis scrollDirection) {
  switch (scrollDirection) {
    case Axis.horizontal:
      return size.width;
    case Axis.vertical:
      return size.height;
  }
}

Offset _restrictAxis(Offset offset, Axis scrollDirection) {
  switch (scrollDirection) {
    case Axis.horizontal:
      return Offset(offset.dx, 0.0);
    case Axis.vertical:
      return Offset(0.0, offset.dy);
  }
}

Offset _overlayOrigin(BuildContext context) {
  final OverlayState overlay =
      Overlay.of(context, debugRequiredFor: context.widget);
  final RenderBox overlayBox = overlay.context.findRenderObject()! as RenderBox;
  return overlayBox.localToGlobal(Offset.zero);
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
