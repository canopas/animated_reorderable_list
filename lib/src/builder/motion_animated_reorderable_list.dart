import 'dart:async';
import 'dart:math';

import 'package:animated_reorderable_list/src/util/key_extensions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../animated_reorderable_list.dart';

typedef ReorderStartedCallback<E> = void Function(E item, int index);

typedef ReorderFinishedCallback<E> = void Function(
    E item, int from, int to, List<E> newItems);

typedef AnimatedItemBuilder<W extends Widget, E> = W Function(
    BuildContext context, Animation<double> animation, E item, int i);

class AnimatedReorderableList<E extends Object>
    extends MotionListBase<Widget, E> {
  final List<E> items;
  final ItemBuilder<Reorderable, E> itemBuilder;
  final ReorderFinishedCallback<E> onReorderFinished;
  final bool reverse;
  final Axis scrollDirection;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ReorderStartedCallback<E>? onReorderStarted;
  final bool? shrinkWrap;
  final Duration removeDuration;
  final Duration insertDuration;
  final Duration reorderDuration;
  final AnimationType? removeAnimation;
  final AnimationType insertAnimation;
  final String? restorationId;

  /// [ScrollViewKeyboardDismissBehavior] the defines how this [ScrollView] will
  /// dismiss the keyboard automatically.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Defaults to [Clip.hardEdge].
  ///
  /// Creates a ScrollView that creates custom scroll effects using slivers.
  /// See the ScrollView constructor for more details on these arguments.
  final Clip clipBehavior;

  /// Creates a ScrollView that creates custom scroll effects using slivers.
  /// See the ScrollView constructor for more details on these arguments.
  final DragStartBehavior dragStartBehavior;

  /// Defaults to null.
  final bool? primary;
  final ScrollBehavior? scrollBehavior;

  const AnimatedReorderableList({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.insertAnimation = AnimationType.fadeIn,
    this.removeAnimation,
    this.insertDuration = const Duration(milliseconds: 300),
    this.removeDuration = const Duration(milliseconds: 300),
    this.reorderDuration = const Duration(milliseconds: 300),
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onReorderStarted,
    required this.onReorderFinished,
    this.clipBehavior = Clip.hardEdge,
    this.primary,
    this.scrollBehavior,
  }) : super(
            key: key,
            items: items,
            itemBuilder: itemBuilder,
            scrollDirection: scrollDirection,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            insertAnimationType: insertAnimation,
            removeAnimationType: removeAnimation);

  @override
  State<StatefulWidget> createState() => AnimatedReorderableListState<E>();

  static AnimatedReorderableListState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<AnimatedReorderableListState>();
  }
}

class AnimatedReorderableListState<E extends Object>
    extends MotionListBaseState<Widget, AnimatedReorderableList<E>, E> {
  final GlobalKey _listKey = GlobalKey(debugLabel: 'list_key');

  final GlobalKey _dragKey = GlobalKey(debugLabel: 'drag_key');
  Timer? _scrollAdjuster;
  ScrollController? _controller;

  ScrollController? get scrollController => _controller;
  double _headerHeight = 0.0;

  _Item? dragItem;
  Widget? _dragWidget;
  VoidCallback? _onDragEnd;

  late List<E> _data = List<E>.from(widget.items);

  List<E> get data => _data;

  bool get isVertical => widget.scrollDirection != Axis.horizontal;

  double _listSize = 0.0;

  double get scrollOffset => _canScroll ? _controller!.offset : 0.0;

  double get _maxScrollOffset => _controller?.position.maxScrollExtent ?? 0.0;

  double get _scrollDelta => scrollOffset - _dragStartScrollOffset;

  bool get _canScroll => _maxScrollOffset > 0.0;

  bool get _up => _dragDelta.isNegative;

  bool _inDrag = false;

  bool get inDrag => _inDrag;

  // Whether there is an item in the list that is currently being
  // reordered or moving towards its destination position.
  bool _inReorder = false;

  bool get inReorder => _inReorder;

  double _dragStartOffset = 0.0;
  double _dragStartScrollOffset = 0.0;

  Key? get dragKey => dragItem?.key;

  int? get _dragIndex => dragItem?.index;

  double get _dragStart => dragItem!.start + _dragDelta;

  double get _dragEnd => dragItem!.end + _dragDelta;

  // double get _dragCenter => dragItem.middle + _dragDelta;
  double get _dragSize => isVertical ? dragItem!.height : dragItem!.width;

  final ValueNotifier<double> _dragDeltaNotifier = ValueNotifier(0.0);

  double get _dragDelta => _dragDeltaNotifier.value;

  set _dragDelta(double value) => _dragDeltaNotifier.value = value;

  final ValueNotifier<double> _pointerDeltaNotifier = ValueNotifier(0.0);

  double get _pointerDelta => _pointerDeltaNotifier.value;

  set _pointerDelta(double value) => _pointerDeltaNotifier.value = value;

  final Map<Key?, GlobalKey> _keys = {};
  final Map<Key?, ReorderableState> _items = {};
  final Map<Key?, AnimationController> _itemTranslations = {};
  final Map<Key?, _Item> _itemBoxes = {};

  void registerItem(ReorderableState item) {
    _items[item.key] = item;
  }

  @override
  void initState() {
    super.initState();
    // The list must have a ScrollController in order to adjust the
    // scroll position when the user drags an item outside the
    // current viewport.
    _controller = widget.controller ?? ScrollController();
  }

  @override
  void didUpdateWidget(AnimatedReorderableList<E> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != null && widget.controller != _controller) {
      _controller = widget.controller;
    }
  }

  void onDragStarted(Key? key) {
    _onDragEnd?.call();

    _measureChild(key);
    dragItem = _itemBoxes[key];

    if (_dragIndex != null) {
      final offset = _itemOffset(key);
      _dragStartOffset = isVertical ? offset!.dy : offset!.dx;
      _dragStartScrollOffset = scrollOffset;

      _items[key]?.duration = widget.reorderDuration;

      setState(() {
        _inDrag = true;
        _inReorder = true;
      });

      widget.onReorderStarted?.call(oldList[_dragIndex!], _dragIndex!);

      _adjustScrollPositionWhenNecessary();
    }
  }

  void _measureChild(Key? key, [int? index]) {
    final item = _items[key];
    if (item == null || !mounted || !item.mounted) {
      return;
    }

    final box = item.context.renderBox;
    final offset = _itemOffset(key)?.translate(
      isVertical ? 0 : scrollOffset,
      isVertical ? scrollOffset : 0,
    );

    if (box != null && offset != null) {
      final i = index ?? _itemBoxes[key]?.index;
      _itemBoxes[key] = _Item(key, box, i, offset, isVertical);
    }
  }

  void _adjustScrollPositionWhenNecessary() {
    if (!_canScroll) return;

    _scrollAdjuster?.cancel();
    _scrollAdjuster = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final start = _headerHeight;
      final end = _maxScrollOffset;
      final isAtStart = _up && scrollOffset < start;
      final isAtEnd = !_up && scrollOffset > end;
      if (isAtStart || isAtEnd) {
        return;
      }

      final dragBox = _dragKey.renderBox;
      if (dragBox == null) return;

      final dragOffset =
          dragBox.localToGlobal(Offset.zero, ancestor: context.renderBox);
      final dragItemStart = isVertical ? dragOffset.dy : dragOffset.dx;
      final dragItemEnd = dragItemStart + _dragSize;

      double? delta;
      if (dragItemStart <= 0) {
        delta = dragItemStart;
      } else if (dragItemEnd >= _listSize) {
        delta = dragItemEnd - _listSize;
      }

      if (delta != null) {
        final atLowerBound = dragItemStart <= 0;
        delta = (delta.abs() / _dragSize).clamp(0.1, 1.0);

        const maxSpeed = 20;
        final max = atLowerBound ? -maxSpeed : maxSpeed;
        var newOffset = scrollOffset + (max * delta);

        if (!(scrollOffset < start) && !(scrollOffset > end)) {
          newOffset = newOffset.clamp(start, end);
        }

        _controller!.jumpTo(newOffset);
        onDragUpdated(_pointerDelta);
      }
    });
  }

  void onDragUpdated(double delta) {
    if (dragKey == null || dragItem == null) return;

    // Allow the dragged item to be overscrolled to allow for
    // continuous scrolling while in drag.
    final overscrollBound = _canScroll ? _dragSize : 0;
    // Constrain the dragged item to the bounds of the list.
    const epsilon = 2.0;
    final minDelta = (_headerHeight - (dragItem!.start + overscrollBound)) -
        _scrollDelta -
        epsilon;
    final maxDelta = ((_maxScrollOffset + _listSize + overscrollBound) -
            (dragItem!.bottom)) -
        _scrollDelta +
        epsilon;

    _pointerDelta = delta.clamp(minDelta, maxDelta);
    _dragDelta = _pointerDelta + _scrollDelta;

    _adjustItemTranslations();
  }

  void _adjustItemTranslations() {
    for (final item in _itemBoxes.values) {
      if (item == dragItem) continue;

      final key = item.key;
      if (_itemTranslations[key]?.isAnimating == true) continue;

      final translation = getTranslation(key);

      final index = item.index!;
      final itemStart = item.start + translation;
      final itemEnd = item.end + translation;

      if (index < _dragIndex!) {
        if (itemStart >= _dragStart && translation == 0) {
          _dispatchMove(key, _dragSize);
        } else if (itemEnd <= _dragEnd && translation != 0) {
          _dispatchMove(key, 0);
        }
      } else if (index > _dragIndex!) {
        if (itemStart >= _dragStart && translation != 0) {
          _dispatchMove(key, 0);
        } else if (itemEnd <= _dragEnd && translation == 0) {
          _dispatchMove(key, -_dragSize);
        }
      }
    }
  }

  double getTranslation(Key? key) =>
      key == dragKey ? _dragDelta : _itemTranslations[key]?.value ?? 0.0;

  Offset? _itemOffset(Key? key) {
    return _items[key]?.context.renderBox?.localToGlobal(
          Offset.zero,
          ancestor: context.renderBox,
        );
  }

  void _dispatchMove(Key? key, double delta,
      {VoidCallback? onEnd, Duration? duration}) {
    double value = 0.0;

    // Remove and stop the old controller if there was one
    // and start from the value where it left off.
    final oldController = _itemTranslations.remove(key);
    if (oldController != null) {
      value = oldController.value;

      oldController
        ..stop()
        ..dispose();
    }

    final start = min(value, delta);
    final end = max(value, delta);

    final controller = AnimationController(
      vsync: this,
      value: value,
      lowerBound: start,
      upperBound: end,
      duration: duration ?? widget.reorderDuration,
    );

    if (controller.upperBound == controller.lowerBound) {
      onEnd?.call();
      return;
    }

    _items[key]?.setTranslation(controller);
    _itemTranslations[key] = controller;

    // ignore: avoid_single_cascade_in_expression_statements
    controller.animateTo(
      delta,
      curve: Curves.easeInOut,
    )..whenCompleteOrCancel(
        () => onEnd?.call(),
      );
  }

  void onDragEnded() {
    if (dragKey == null) return;

    final target = findDropTargetItem();

    _onDragEnd = () {
      if (_dragIndex != null) {
        if (!_itemBoxes.containsKey(target!.key)) {
          _measureChild(target.key);
        }

        final toIndex = _itemBoxes[target.key]?.index;
        if (toIndex != null) {
          final E item = data.removeAt(_dragIndex!);
          data.insert(toIndex, item);

          widget.onReorderFinished(
            item,
            _dragIndex!,
            toIndex,
            List<E>.from(data),
          );
        }
      }

      _cancelReorder();
    };

    _items[dragKey]?.duration = widget.reorderDuration;

    final delta = () {
      if (target == dragItem) {
        return -_pointerDelta;
      } else if (_up) {
        return target!.start - _dragStart;
      } else {
        return target!.end - _dragEnd;
      }
    }();

    _dispatchMove(
      dragKey,
      // Make sure not to pass a zero delta (i.e. the item didn't move)
      // as this would lead to the same upper and lower bound on the animation
      // controller, which is not allowed.
      delta != 0.0 ? delta : 0.5,
      onEnd: _onDragEnd,
      duration: widget.reorderDuration,
    );

    avoidConflictingMoves(target);

    _scrollAdjuster?.cancel();

    setState(() => _inDrag = false);
  }

  void avoidConflictingMoves(_Item? target) {
    _itemTranslations.forEach((key, controller) {
      final item = _itemBoxes[key];

      if (item != dragItem && item != target) {
        if (item!.index! < target!.index!) {
          controller.reverse();
        } else {
          controller.forward();
        }
      }
    });
  }

  _Item? findDropTargetItem() {
    _Item? target = dragItem;

    // Boxes are in the order in which they are build, not
    // necessarily index based.
    final boxes = _itemBoxes.values.toList()
      ..sort((a, b) => a.index!.compareTo(b.index!));

    for (final box in boxes) {
      // Dont apply any translation to the currently dragged
      // item (#56)
      final t = box == dragItem ? 0.0 : getTranslation(box.key);

      if (_up) {
        if (_dragStart <= (box.start + t)) {
          return box;
        }
      } else {
        if (_dragEnd >= (box.end + t)) {
          target = box;
        }
      }
    }

    return target;
  }

  bool _prevInDrag = false;

  void _onRebuild() {
    _itemBoxes.clear();

    final needsRebuild = _listSize == 0 || inDrag != _prevInDrag;
    _prevInDrag = inDrag;

    double getSizeOfKey(GlobalKey key) =>
        (isVertical ? key.height : key.width) ?? 0.0;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _listSize = getSizeOfKey(_listKey);
      _headerHeight = 0.0;

      if (needsRebuild && mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _onRebuild();
    final scrollView = CustomScrollView(
        key: _listKey,
        controller: _controller,
        scrollDirection: scrollDirection,
        reverse: widget.reverse,
        primary: widget.primary,
        physics: widget.physics,
        scrollBehavior: widget.scrollBehavior,
        restorationId: widget.restorationId,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
        dragStartBehavior: widget.dragStartBehavior,
        clipBehavior: widget.clipBehavior,
        slivers: [
          MotionListImpl(
            items: widget.items,
            itemBuilder: (context, index) {
              final Reorderable reorderable =
                  itemBuilder(context, index) as Reorderable;

              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                _measureChild(reorderable.key, index);
              });

              if (!_keys.containsKey(reorderable.key)) {
                _keys[reorderable.key] = GlobalKey(
                  debugLabel: reorderable.key.toString(),
                );
              }

              final child = KeyedSubtree(
                key: _keys[reorderable.key],
                child: reorderable,
              );

              if (dragKey != null && index == _dragIndex) {
                final size = dragItem?.size;

                // Determine if the dragged widget should be hidden
                // immediately, or with on frame delay in order to
                // avoid item flash.
                final mustRebuild = _dragWidget == null;

                _dragWidget = child;
                if (mustRebuild) {
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    setState(() {});
                  });
                }

                // The placeholder of the dragged item.
                //
                // Make sure not to use the actual widget but only its size
                // when they have been determined, as a widget is only allowed
                // to be laid out once.
                return Visibility(
                  key: ValueKey(reorderable.key),
                  visible: mustRebuild,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: mustRebuild ? child : SizedBox.fromSize(size: size),
                );
              } else {
                return child;
              }
            },
            insertAnimationType: widget.insertAnimation,
            removeAnimationType:
                widget.removeAnimation ?? widget.insertAnimation,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            areItemsTheSame: widget.areItemsTheSame,
            scrollDirection: scrollDirection,
          ),
        ]);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        scrollView,
        if (_dragWidget != null) _buildDraggedItem(),
      ],
    );
  }

  Widget _buildDraggedItem() {
    final EdgeInsets listPadding =
        widget.padding as EdgeInsets? ?? EdgeInsets.zero;

    return ValueListenableBuilder<double>(
      // ignore: sort_child_properties_last
      child: _dragWidget,
      valueListenable: _pointerDeltaNotifier,
      builder: (context, pointer, dragWidget) {
        final delta = _dragStartOffset + pointer;
        final dx = isVertical ? 0.0 : delta;
        final dy = isVertical ? delta : 0.0;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Container(
            key: _dragKey,
            // Set a fixed width on the dragged item in horizontal
            // lists to prevent it from expanding.
            width: !isVertical ? dragItem?.width : null,
            // Add the horizontal padding in a vertical list as
            // a padding, to prevent the item from filling the lists insets.
            padding: EdgeInsets.only(
              left: isVertical ? listPadding.left : 0.0,
              right: isVertical ? listPadding.right : 0.0,
            ),
            // In horizontal lists, add the top padding as a margin
            // to offset the item from the top edge.
            margin: EdgeInsets.only(top: !isVertical ? listPadding.top : 0.0),
            child: dragWidget,
          ),
        );
      },
    );
  }

  void _cancelReorder() {
    setState(() {
      _inDrag = false;
      _inReorder = false;
      dragItem = null;
      _onDragEnd = null;
      _dragWidget = null;
      _dragDelta = 0.0;
      _pointerDelta = 0.0;
      _scrollAdjuster?.cancel();

      for (final key in _itemTranslations.keys) {
        _items[key]?.setTranslation(null);
      }

      _itemTranslations.clear();
      _disposeDrag();
    });
  }

  void _disposeDrag() {
    _controller!.jumpTo(_controller!.position.pixels);
  }

  @override
  void dispose() {
    _scrollAdjuster?.cancel();

    if (widget.controller == null) {
      _controller?.dispose();
    }

    super.dispose();
  }
}

class _Item extends Rect implements Comparable<_Item> {
  final RenderBox box;
  final Key? key;
  final int? index;
  final Offset offset;
  final bool _isVertical;

  _Item(
    this.key,
    this.box,
    this.index,
    this.offset,
    // ignore: avoid_positional_boolean_parameters
    this._isVertical,
  ) : super.fromLTWH(
          offset.dx,
          offset.dy,
          box.size.width,
          box.size.height,
        );

  double get start => _isVertical ? top : left;

  double get end => _isVertical ? bottom : right;

  double get middle => _isVertical ? center.dy : center.dx;

  double? distance;

  @override
  int compareTo(_Item other) => distance != null && other.distance != null
      ? distance!.compareTo(other.distance!)
      : -1;

  @override
  String toString() => '_Item key: $key, index: $index';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is _Item && o.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}
