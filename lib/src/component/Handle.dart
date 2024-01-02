import 'package:animated_reorderable_list/src/component/reorderable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../builder/motion_animated_reorderable_list.dart';
import '../util/handler.dart';

class Handle extends StatefulWidget {
  final Widget child;

  final Duration delay;

  final bool vibrate;

  final bool capturePointer;

  final bool enabled;

  const Handle({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.capturePointer = true,
    this.vibrate = true,
    this.enabled = true,
  }) : super(key: key);

  @override
  _HandleState createState() => _HandleState();
}

class _HandleState extends State<Handle> {
  ScrollableState? _parent;
  Handler? _handler;

  // The parent Reorderable item.
  ReorderableState? _reorderable;

  // The parent list.
  AnimatedReorderableListState? _list;

  // Whether the ImplicitlyAnimatedReorderableList has a
  // scrollDirection of Axis.vertical.
  bool get _isVertical => _list?.isVertical ?? true;

  Offset? _pointer;
  late double _downOffset;
  double? _startOffset;
  double? _currentOffset;

  double get _delta => (_currentOffset ?? 0) - (_startOffset ?? 0);

  // Use flags from the list as this State object is being
  // recreated between dragged and normal state.
  bool get _inDrag => _list!.inDrag;

  bool get _inReorder => _list!.inReorder;

  // The pixel offset of a possible parent Scrollable
  // used to capture it.
  double _parentPixels = 0.0;

  void _onDragStarted() {
    // If the list is already in drag we dont want to
    // initiate a new reorder.
    if (_inReorder) return;

    final moveDelta = (_downOffset - _currentOffset!).abs();
    if (moveDelta > 10.0) {
      return;
    }

    _parentPixels = _parent?.position.pixels ?? 0.0;

    _captureParentList();
    _startOffset = _currentOffset;

    _list?.onDragStarted(_reorderable?.key);
    _reorderable!.rebuild();

    _vibrate();
  }

  void _onDragUpdated(Offset pointer) {
    _list?.onDragUpdated(_delta);
    _captureParentList();
  }

  void _onDragEnded() {
    _handler?.cancel();
    _list?.onDragEnded();
    _captureParentList();
  }

  void _vibrate() {
    if (widget.vibrate) HapticFeedback.mediumImpact();
  }

  void _captureParentList() {
    // Listener does not capture the drag of this Handle
    // however we also cannot use GestureDetector to capture
    // the drag on the Handle, as this might make the whole
    // list unscrollable (e.g. when the Handle wraps a whole ListTile).
    //
    // This seems to be the only working solution to this problem.
    _parent?.position.jumpTo(_parentPixels);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    _list = AnimatedReorderableList.maybeOf(context);
    assert(_list != null,
        'No ancestor ImplicitlyAnimatedReorderableList was found in the hierarchy!');
    _reorderable = Reorderable.maybeOf(context);
    assert(_reorderable != null,
        'No ancestor Reorderable was found in the hierarchy!');
    _parent = Scrollable.maybeOf(_list!.context);

    // Sometimes the cancel callbacks of the GestureDetector
    // are erroneously invoked. Use a plain Listener instead
    // for now.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _onDown(event.localPosition),
      onPointerMove: (event) => _onUpdate(event.localPosition),
      onPointerUp: (_) => _onUp(),
      onPointerCancel: (_) => _onUp(),
      child: widget.child,
    );
  }

  void _onDown(Offset pointer) {
    _pointer = pointer;
    _currentOffset = _offset(_pointer);
    _downOffset = _offset(_pointer);

    // Ensure the list is not already in a reordering
    // state when initiating a new reorder operation.
    if (!_inDrag) {
      _onUp();

      _handler = postDuration(
        widget.delay,
        _onDragStarted,
      );
    }
  }

  void _onUpdate(Offset pointer) {
    _pointer = pointer;
    _currentOffset = _offset(_pointer);

    if (_inDrag && _inReorder) {
      _onDragUpdated(pointer);
    }
  }

  void _onUp() {
    _handler?.cancel();
    if (_inDrag) _onDragEnded();
  }

  double _offset(Offset? offset) => _isVertical ? offset!.dy : offset!.dx;
}
