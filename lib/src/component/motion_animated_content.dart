import 'package:flutter/widgets.dart';
import 'package:motion_list/src/model/motion_data.dart';

import '../builder/motion_animation_builder.dart';
import '../builder/motion_builder.dart';

const Duration _kDragDuration = Duration(milliseconds: 1000);
const Duration _kEntryDuration = Duration(milliseconds: 1000);
const Duration _kExitDuration = Duration(milliseconds: 1000);

class MotionAnimatedContent extends StatefulWidget {
  final int index;
  final MotionData motionData;
  final bool enter;
  final bool exit;
  final AnimatedWidgetBuilder insertAnimationBuilder;
  final AnimatedWidgetBuilder removeAnimationBuilder;
  final Widget? child;
  final Function(MotionData)? updateMotionData;

  const MotionAnimatedContent(
      {Key? key,
      required this.index,
      required this.motionData,
      required this.enter,
      required this.exit,
      required this.insertAnimationBuilder,
      required this.removeAnimationBuilder,
      required this.child,
      this.updateMotionData})
      : super(key: key);

  @override
  State<MotionAnimatedContent> createState() => MotionAnimatedContentState();
}

class MotionAnimatedContentState extends State<MotionAnimatedContent>
    with TickerProviderStateMixin {
  late AnimationController _visibilityController;
  late AnimationController _positionController;
  late Animation<Offset> _offsetAnimation;

  late MotionBuilderState _listState;

  int get index => widget.index;

  @override
  void initState() {
    print("initState ${widget.index}");
    _listState = MotionBuilderState.of(context);
    _listState.registerItem(this);
    _visibilityController = AnimationController(
      value: 1.0,
      duration: _kEntryDuration,
      reverseDuration: _kExitDuration,
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          widget.updateMotionData?.call(widget.motionData);
        }
      });

    _positionController =
        AnimationController(vsync: this, duration: _kDragDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed ||
                status == AnimationStatus.dismissed) {
              widget.updateMotionData?.call(widget.motionData);
            }
          });

    _offsetAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_positionController)
      ..addListener(() {
        setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _updateAnimationTranslation();
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MotionAnimatedContent oldWidget) {
    final oldMotionData = oldWidget.motionData;
    final newMotionData = widget.motionData;

    if (oldWidget.index != widget.index) {
      _listState.unregisterItem(oldWidget.index, this);
      _listState.registerItem(this);
    }
    final currentOffset = itemOffset();

    //  print("current $currentOffset");
    print("OLD - ${oldMotionData.enter}   \n   NEW - ${newMotionData.enter}");
    if (newMotionData.enter) {
      _visibilityController.reset();
      _visibilityController.value = 0.0;
      print(" ------ object enter animation----- $index");
      Future.delayed(_kDragDuration, () {
        _visibilityController.forward();
      });
    } else if (!oldMotionData.exit && newMotionData.exit) {
      Future.delayed(_kDragDuration, () {
        _visibilityController.reset();
        _visibilityController.value = 1.0;
        _visibilityController.reverse();
      });
    }

    // if (oldMotionData.target != newMotionData.target &&
    //     newMotionData.target != currentOffset) {
    // final offsetToMove = oldMotionData.offset < newMotionData.offset
    //     ? newMotionData.nextItemOffset
    //     : newMotionData.frontItemOffset;

    // final currentOffset = newMotionData.offset;

    _updateAnimationTranslation();
    super.didUpdateWidget(oldWidget);
  }

  void _updateAnimationTranslation() {
    final currentOffset = itemOffset();

    Offset offsetDiff = widget.motionData.target - currentOffset;
    print("offsetDiff $offsetDiff");
    if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
      _positionController.reset();

      _offsetAnimation = Tween<Offset>(begin: offsetDiff, end: Offset.zero)
          .animate(_positionController);
      _positionController.forward();
      //}
    }

    // final originalOffset = widget.reorderableItem!.oldOffset;
    // final updatedOffset = itemOffset();
    // Offset offsetDiff = originalOffset - updatedOffset;
    //
    // if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
    //   // if (_offsetAnimationController.isAnimating) {
    //   //   final currentAnimationOffset = _animationOffset.value;
    //   //   final newOriginalOffset = currentAnimationOffset - offsetDiff;
    //   //   offsetDiff = offsetDiff + newOriginalOffset;
    //   // }
    //   _offsetAnimationController.reset();
    //
    //   _animationOffset = Tween<Offset>(begin: offsetDiff, end: Offset.zero)
    //       .animate(_offsetAnimationController);
    //   _offsetAnimationController.forward();
    // }
  }

  Offset itemOffset() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    //  print("index $index, visibility controller ${_visibilityController.value}");
    return Transform(
        transform: Matrix4.translationValues(
            _offsetAnimation.value.dx, _offsetAnimation.value.dy, 0.0),
        child: widget.motionData.exit
            ? widget.removeAnimationBuilder(context,
                widget.child ?? const SizedBox.shrink(), _visibilityController)
            : widget.insertAnimationBuilder(
                context,
                widget.child ?? const SizedBox.shrink(),
                _visibilityController));

    return DualTransitionBuilder(
      animation: _visibilityController,
      forwardBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return widget.insertAnimationBuilder(
            context, child ?? const SizedBox.shrink(), animation);
      },
      reverseBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return widget.removeAnimationBuilder(
            context, child ?? const SizedBox.shrink(), animation);
      },
      child: Transform(
          transform: Matrix4.translationValues(
              _offsetAnimation.value.dx, _offsetAnimation.value.dy, 0.0),
          child: widget.child),
    );
  }

  @override
  void dispose() {
    _listState.unregisterItem(widget.index, this);
    _visibilityController.dispose();
    _positionController.dispose();
    super.dispose();
  }
}
