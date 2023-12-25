import 'package:flutter/widgets.dart';
import 'package:motion_list/src/model/motion_data.dart';

import '../builder/motion_builder.dart';

const int duration = 2000;
const Duration kDragDuration = Duration(milliseconds: duration);
const Duration _kEntryDuration = Duration(milliseconds: duration);
const Duration _kExitDuration = Duration(milliseconds: duration);

class MotionAnimatedContent extends StatefulWidget {
  final Key key;
  final int index;
  final MotionData motionData;

  // final bool enter;
//  final bool exit;
//  final AnimatedWidgetBuilder insertAnimationBuilder;
  // final AnimatedWidgetBuilder removeAnimationBuilder;
  final Widget? child;
  final Function(MotionData)? updateMotionData;
  final Function(int)? onItemRemoved;

  const MotionAnimatedContent(
      {required this.key,
      required this.index,
      required this.motionData,
      //  required this.enter,
      //   required this.exit,
      //   required this.insertAnimationBuilder,
      //   required this.removeAnimationBuilder,
      required this.child,
      this.updateMotionData,
      this.onItemRemoved})
      : super(key: key);

  @override
  State<MotionAnimatedContent> createState() => MotionAnimatedContentState();
}

class MotionAnimatedContentState extends State<MotionAnimatedContent>
    with SingleTickerProviderStateMixin {
// late AnimationController _visibilityController;
  late AnimationController _positionController;
  late Animation<Offset> _offsetAnimation;

  late MotionBuilderState _listState;

  int get index => widget.index;

  Offset? get currentAnimatedOffset =>
      _positionController.isAnimating ? _offsetAnimation.value : null;

  @override
  void initState() {
    print("initState ${widget.index}");
    _listState = MotionBuilderState.of(context);
    _listState.registerItem(this);
    // _visibilityController = AnimationController(
    //   value: 1.0,
    //   duration: _kEntryDuration,
    //   reverseDuration: _kExitDuration,
    //   vsync: this,
    // )..addStatusListener((status) {
    //     print("status $status index $index");
    //     if (status == AnimationStatus.dismissed) {
    //       widget.onItemRemoved?.call(widget.motionData.index);
    //     }
    //   });

    _positionController =
        AnimationController(vsync: this, duration: kDragDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.updateMotionData?.call(widget.motionData);
            }
          });

    _offsetAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_positionController)
      ..addListener(() {
        setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.updateMotionData?.call(widget.motionData);
    });

    // if (widget.motionData.enter) {
    //   _visibilityController.value = 0.0;
    //   Future.delayed(_kDragDuration, () {
    //     _visibilityController.forward();
    //   });
    // }
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
    //
    // if (!oldMotionData.exit && newMotionData.exit) {
    //   animateExit();
    // }

   // print("didUpdateWidget");
    // print("OLD - ${oldMotionData}   \n   NEW - ${newMotionData}");

    Offset endOffset = widget.motionData.endOffset;
    if (endOffset != Offset.zero) {
      _updateAnimationTranslation();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _updateAnimationTranslation();
        widget.updateMotionData?.call(widget.motionData);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  void _updateAnimationTranslation() {
    Offset endOffset = widget.motionData.endOffset;
    //   print("_updateAnimationTranslation $index endOffset $endOffset");
    endOffset = endOffset == Offset.zero ? itemOffset() : endOffset;
    Offset offsetDiff = widget.motionData.startOffset - endOffset;

    if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
      _positionController.reset();

      _offsetAnimation = Tween<Offset>(begin: offsetDiff, end: Offset.zero)
          .animate(_positionController);
      _positionController.forward();
    }
  }

  Offset itemOffset() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;

    return box.localToGlobal(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    _listState.registerItem(this);
    print("build $index ${widget.motionData.exit}");
    return Transform.translate(
        offset: _offsetAnimation.value,
        child: widget.child ?? const SizedBox.shrink());
  }

  @override
  void dispose() {
    _listState.unregisterItem(widget.index, this);
    _positionController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    _listState.unregisterItem(index, this);
    super.deactivate();
  }

}
