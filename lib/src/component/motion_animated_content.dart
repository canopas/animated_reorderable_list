import 'package:flutter/widgets.dart';
import 'package:motion_list/src/model/motion_data.dart';

import '../builder/motion_animation_builder.dart';

const Duration _kDragDuration = Duration(milliseconds: 300);
const Duration _kEntryDuration = Duration(milliseconds: 300);
const Duration _kExitDuration = Duration(milliseconds: 300);

class MotionAnimatedContent extends StatefulWidget {
  final MotionData motionData;
  final bool enter;
  final bool exit;
  final AnimatedWidgetBuilder insertAnimationBuilder;
  final AnimatedWidgetBuilder removeAnimationBuilder;
  final Widget? child;
  final Function(MotionData)? updateMotionData;

  const MotionAnimatedContent(
      {Key? key,
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

  // late MotionAnimationBuilderState _listState;

  int get index => widget.motionData.index;

  @override
  void initState() {
    // _listState = MotionAnimationBuilder.of(context);
    //  _listState.registerItem(this);
    _visibilityController = AnimationController(
      value: 1.0,
      duration: _kEntryDuration,
      reverseDuration: _kExitDuration,
      vsync: this,
    );

    _positionController =
        AnimationController(vsync: this, duration: _kDragDuration)
          ..addStatusListener((status) {
            print("status $status");
            if (status == AnimationStatus.completed ||
                status == AnimationStatus.dismissed) {
              // widget.updateMotionData?.call(widget.motionData);
            }
          });

    _offsetAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_positionController)
      ..addListener(() {
        setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.updateMotionData?.call(widget.motionData);
      if (widget.motionData.enter) {
        _visibilityController.forward();
        print("forward visbility controller $index");
      }
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MotionAnimatedContent oldWidget) {
    final oldMotionData = oldWidget.motionData;
    final newMotionData = widget.motionData;
    print(
        "didUpdateWidget oldMotionData $oldMotionData newMotionData $newMotionData");
    // if (!oldMotionData.enter && newMotionData.enter) {
    //   _visibilityController.value = 0.0;
    //   _visibilityController.forward(); // TODO  should start after drag complete
    // } else if (!oldMotionData.exit && newMotionData.exit) {
    //   _visibilityController.reverse();
    // }

    if (oldMotionData.index != newMotionData.index) {
      final offsetToMove = oldMotionData.index < newMotionData.index
          ? newMotionData.nextItemOffset
          : newMotionData.frontItemOffset;

      final currentOffset = newMotionData.offset;
      Offset offsetDiff = currentOffset - offsetToMove;

      if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
        _positionController.reset();

        _offsetAnimation = Tween<Offset>(begin: offsetDiff, end: Offset.zero)
            .animate(_positionController);
        _positionController.forward();
      }
    }

    super.didUpdateWidget(oldWidget);
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
    // _listState.unregisterItem(index, this);
    _visibilityController.dispose();
    _positionController.dispose();
    super.dispose();
  }
}
