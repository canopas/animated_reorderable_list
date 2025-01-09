part of '../builder/reorderable_animated_builder.dart';

class ReorderableAnimatedContent extends StatefulWidget {
  final int index;
  final ItemTransitionData transitionData;
  final Widget child;
  final Function()? updateItemPosition;
  final CapturedThemes? capturedThemes;

  const ReorderableAnimatedContent({
    Key? key,
    required this.index,
    required this.transitionData,
    required this.child,
    this.updateItemPosition,
    required this.capturedThemes,
  }) : super(key: key);

  @override
  State<ReorderableAnimatedContent> createState() =>
      ReorderableAnimatedContentState();
}

class ReorderableAnimatedContentState extends State<ReorderableAnimatedContent>
    with SingleTickerProviderStateMixin {
  late ReorderableAnimatedBuilderState listState;

  Offset _targetOffset = Offset.zero;
  Offset _startOffset = Offset.zero;
  AnimationController? _offsetAnimation;

  bool _dragging = false;

  bool get dragging => _dragging;

  set dragging(bool dragging) {
    if (mounted) {
      setState(() {
        _dragging = dragging;
      });
    }
  }

  Size _dragSize = Size.zero;

  set dragSize(Size itemSize) {
    if (mounted) {
      setState(() {
        _dragSize = itemSize;
      });
    }
  }

  int get index => widget.index;
  bool visible = true;

  @override
  void initState() {
    listState = ReorderableAnimatedBuilder.of(context);
    listState.registerItem(this);
    visible = widget.transitionData.visible;

    _updateItemPosition();

    Future.delayed(kAnimationDuration).then((value) {
      visible = true;
      rebuild();
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ReorderableAnimatedContent oldWidget) {
    if (oldWidget.index != widget.index) {
      listState.unregisterItem(oldWidget.index, this);
      listState.registerItem(this);
    }
    if (oldWidget.index != widget.index && !_dragging) {
      // Reset this flag to false after the drag is completed and items are reordered
      listState._isDragging = false;
      _updateAnimationTranslation();
    } else {
      _updateItemPosition();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _updateAnimationTranslation() {
    if (widget.transitionData.animate) {
      Offset offsetDiff = (widget.transitionData.startOffset + offset) -
          widget.transitionData.endOffset;
      _startOffset = offsetDiff;
      if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
        if (_offsetAnimation == null) {
          _offsetAnimation = AnimationController(
            vsync: listState,
            duration: kAnimationDuration,
          )
            ..addListener(rebuild)
            ..addStatusListener((AnimationStatus status) {
              if (status == AnimationStatus.completed) {
                widget.updateItemPosition?.call();
                _startOffset = _targetOffset;
                _offsetAnimation!.dispose();
                _offsetAnimation = null;
              }
            })
            ..forward();
        } else {
          _startOffset = offsetDiff;
          _offsetAnimation!.forward(from: 0.0);
        }
      }
    }
  }

  Offset get offset {
    if (_offsetAnimation != null) {
      final Offset offset =
          Offset.lerp(_startOffset, _targetOffset, _offsetAnimation!.value)!;
      return offset;
    }
    return _targetOffset;
  }

  void updateForGap(bool animate) {
    if (!mounted) return;
    final Offset newTargetOffset = listState.calculateNextDragOffset(index);
    if (newTargetOffset == _targetOffset) return;
    _targetOffset = newTargetOffset;

    if (animate) {
      if (_offsetAnimation == null) {
        _offsetAnimation = AnimationController(
          vsync: listState,
          duration: const Duration(milliseconds: 250),
        )
          ..addListener(rebuild)
          ..addStatusListener((AnimationStatus status) {
            if (status == AnimationStatus.completed) {
              _startOffset = _targetOffset;
              _offsetAnimation!.dispose();
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
        _offsetAnimation!.dispose();
        _offsetAnimation = null;
      }
      _startOffset = _targetOffset;
    }
    rebuild();
  }

  void _updateItemPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.updateItemPosition?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    listState.registerItem(this);
    return Visibility(
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      visible: visible && !_dragging,
      child: Transform.translate(
          offset: offset,
          child:
              !_dragging ? widget.child : SizedBox.fromSize(size: _dragSize)),
    );
  }

  void resetGap() {
    if (_offsetAnimation != null) {
      _offsetAnimation!.dispose();
      _offsetAnimation = null;
    }
    _startOffset = Offset.zero;
    _targetOffset = Offset.zero;
    rebuild();
  }

  Rect targetGeometryNonOffset() {
    final RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
    final Offset itemPosition = itemRenderBox.localToGlobal(Offset.zero);
    return itemPosition & itemRenderBox.size;
  }

  Rect targetGeometry() {
    final RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
    final Offset itemPosition =
        itemRenderBox.localToGlobal(Offset.zero) + _targetOffset;
    return itemPosition & itemRenderBox.size;
  }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    listState.unregisterItem(index, this);
    _offsetAnimation?.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    listState.unregisterItem(index, this);
    super.deactivate();
  }
}
