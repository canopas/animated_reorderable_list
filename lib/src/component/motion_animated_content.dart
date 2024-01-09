import 'package:flutter/widgets.dart';
import 'package:animated_reorderable_list/src/model/motion_data.dart';

import '../builder/motion_animated_builder.dart';

class MotionAnimatedContent extends StatefulWidget {
  final int index;
  final MotionData motionData;
  final Widget child;
  final Function(MotionData)? updateMotionData;
  final CapturedThemes? capturedThemes;

  const MotionAnimatedContent(
      { Key? key,
      required this.index,
      required this.motionData,
      required this.child,
      this.updateMotionData,
      required this.capturedThemes})
      : super(key: key);

  @override
  State<MotionAnimatedContent> createState() => MotionAnimatedContentState();
}

class MotionAnimatedContentState extends State<MotionAnimatedContent>
    with SingleTickerProviderStateMixin {
  late MotionBuilderState listState;

  Offset _targetOffset = Offset.zero;
  Offset _startOffset = Offset.zero;
  AnimationController? _offsetAnimation;

  bool _dragging = false;

  bool get dragging=> _dragging;

  set dragging(bool dragging){
    if(mounted){
      setState(() {
        _dragging = dragging;
      });
    }
  }

  Size _dragSize= Size.zero;

  set dragSize(Size itemSize){
    if(mounted){
      setState(() {
        _dragSize= itemSize;
      });
    }
  }

  int get index => widget.index;
  bool visible = true;

  @override
  void initState() {
    listState = MotionBuilder.of(context);
    listState.registerItem(this);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.updateMotionData?.call(widget.motionData);
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MotionAnimatedContent oldWidget) {
    if (oldWidget.index != widget.index) {
      listState.unregisterItem(oldWidget.index, this);
      listState.registerItem(this);
    }
    if (oldWidget.index != widget.index) {
      visible = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        visible = true;
      });
     if (oldWidget.index != widget.index) _updateAnimationTranslation();
      widget.updateMotionData?.call(widget.motionData);
    });
    super.didUpdateWidget(oldWidget);
  }

  void _updateAnimationTranslation() {
    Offset endOffset = itemOffset();
    Offset offsetDiff = (widget.motionData.startOffset + offset) - endOffset;
    _startOffset =offsetDiff;

    if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
      if (_offsetAnimation == null) {
        _offsetAnimation = AnimationController(
          vsync: listState,
          duration: const Duration(seconds: 3),
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
        _offsetAnimation!.forward();
      }
    }
  }

  Offset get offset {
    if (_offsetAnimation != null) {
      final Offset offset= Offset.lerp(_startOffset, _targetOffset, _offsetAnimation!.value)!;
      return offset;
    }
    return _targetOffset;
  }

  void updateForGap(int gapIndex, bool animate) {
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

  @override
  Widget build(BuildContext context) {
    // if (_dragging) {
    //   return const SizedBox.shrink();
    // }
    listState.registerItem(this);
    print("$index --Dragging: $_dragging");
    return Visibility(
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      visible: visible && !_dragging ,
      child: Transform(
         transform: Matrix4.translationValues(offset.dx, offset.dy, 0.0),
          child:!_dragging ? widget.child:SizedBox.fromSize(size:_dragSize)),
    );
  }


  Offset itemOffset() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(Offset.zero);
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

  Rect targetGeometry() {
    final RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
    final Offset itemPosition =
        itemRenderBox.localToGlobal(Offset.zero) + _targetOffset;
    return itemPosition & itemRenderBox.size;
  }


  Rect targetGeometryNonOffset() {
    final RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
    final Offset itemPosition = itemRenderBox.localToGlobal(Offset.zero);
    return itemPosition & itemRenderBox.size;
  }



  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    listState.unregisterItem(widget.index, this);
    _offsetAnimation?.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    listState.unregisterItem(index, this);
    super.deactivate();
  }
}

