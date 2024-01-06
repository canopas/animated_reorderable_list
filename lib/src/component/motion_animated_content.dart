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

  late AnimationController _positionController;
  late Animation<Offset> _offsetAnimation;
  Offset _targetOffset = Offset.zero;
  Offset _startOffset = Offset.zero;

  bool _dragging = false;

  bool get dragging=> _dragging;

  set dragging(bool dragging){
    if(mounted){
      setState(() {
        _dragging = dragging;
      });
    }
  }

  int get index => widget.index;

  Offset get currentAnimatedOffset =>
      _positionController.isAnimating ? _offsetAnimation.value : Offset.zero;
  bool visible = true;

  @override
  void initState() {
    listState = MotionBuilder.of(context);
    listState.registerItem(this);

    _positionController =
        AnimationController(vsync: this, duration: widget.motionData.duration);

    _offsetAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_positionController)
      ..addListener(() {
        setState(() {});
      });

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

    Offset offsetDiff =
        (widget.motionData.startOffset + currentAnimatedOffset) - endOffset;
    _targetOffset = offsetDiff;

    if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
      _positionController.duration = widget.motionData.duration;

      _offsetAnimation = Tween<Offset>(begin: offsetDiff, end: Offset.zero)
          .animate(_positionController);
      _positionController.forward(from: 0);
    }
  }

  void updateForGap(
      int gapIndex, double gapExtent, bool animate, bool reverse) {
    // final Offset newTargetOffset = (gapIndex <= index)
    //     ? _extentOffset(
    //         reverse ? -gapExtent : gapExtent, listState.scrollDirection)
    //     : Offset.zero;
    final Offset newTargetOffset= listState.calculateNextDragOffset(index);
    print(newTargetOffset);
    if (newTargetOffset != _targetOffset) {
      _targetOffset = newTargetOffset;
      if (animate) {
        _offsetAnimation =
            Tween<Offset>(begin: _startOffset, end: _targetOffset)
                .animate(_positionController);
        _positionController.forward();
      }
    }
    rebuild();
  }

  void resetGap() {
    _startOffset = Offset.zero;
    _targetOffset = Offset.zero;
  }

  Offset itemOffset() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;

    return box.localToGlobal(Offset.zero);
  }
  Rect targetGeometryNonOffset() {
    final RenderBox itemRenderBox = context.findRenderObject()! as RenderBox;
    final Offset itemPosition = itemRenderBox.localToGlobal(Offset.zero);
    return itemPosition & itemRenderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    if (_dragging) {
      return const SizedBox.shrink();
    }
    listState.registerItem(this);
    return Visibility(
      visible: visible,
      child: Transform.translate(
          offset: _offsetAnimation.value, child: widget.child),
    );
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
    listState.unregisterItem(widget.index, this);
    _positionController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    listState.unregisterItem(index, this);
    super.deactivate();
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
