import 'package:flutter/widgets.dart';
import 'package:motion_list/src/model/motion_data.dart';

import '../builder/motion_animated_builder.dart';

class MotionAnimatedContent extends StatefulWidget {
  final Key key;
  final int index;
  final MotionData motionData;
  final Widget? child;
  final Function(MotionData)? updateMotionData;
  final Function(int)? onItemRemoved;

  const MotionAnimatedContent(
      {required this.key,
      required this.index,
      required this.motionData,
      required this.child,
      this.updateMotionData,
      this.onItemRemoved})
      : super(key: key);

  @override
  State<MotionAnimatedContent> createState() => MotionAnimatedContentState();
}

class MotionAnimatedContentState extends State<MotionAnimatedContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _positionController;
  late Animation<Offset> _offsetAnimation;

  late MotionBuilderState _listState;

  int get index => widget.index;

  Offset get currentAnimatedOffset =>
      _positionController.isAnimating ? _offsetAnimation.value : Offset.zero;

  @override
  void initState() {
    print("Initstate $index");
    _listState = MotionBuilderState.of(context);
    _listState.registerItem(this);

    _positionController =
        AnimationController(vsync: this, duration: widget.motionData.duration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
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
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MotionAnimatedContent oldWidget) {
    print("didUpdateWidget old ${oldWidget.index} new ${widget.index}");

    if (oldWidget.index != widget.index) {
      _listState.unregisterItem(oldWidget.index, this);
      _listState.registerItem(this);
    }

    // Offset endOffset = widget.motionData.endOffset;
    // if (endOffset != Offset.zero) {
    //  // _updateAnimationTranslation();
    // } else {
    //   print("${widget.index} no offset addPostFrameCallback");
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.updateMotionData?.call(widget.motionData);
      //_updateAnimationTranslation();
    });
    // }
    super.didUpdateWidget(oldWidget);
  }

  void moveForward(Offset endOffset) {
    // Offset endOffset = widget.motionData.endOffset;
    // endOffset = endOffset == Offset.zero ? itemOffset() : endOffset;
    //  print("currentAnimatedOffset $currentAnimatedOffset index $index");
    Offset offsetDiff =
        (widget.motionData.startOffset + currentAnimatedOffset) - endOffset;

    if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
      _positionController.duration = widget.motionData.duration;

      //_positionController.reset();

      _offsetAnimation = Tween<Offset>(begin: offsetDiff, end: Offset.zero)
          .animate(_positionController);
      _positionController.forward(from: 0);
    }
  }

  void moveBackward(Offset startOffset) {
    Offset endOffset = widget.motionData.endOffset;
    // endOffset = endOffset == Offset.zero ? itemOffset() : endOffset;
    //  print("currentAnimatedOffset $currentAnimatedOffset index $index");
    Offset offsetDiff = startOffset - endOffset;

    if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
      _positionController.duration = widget.motionData.duration;

      //_positionController.reset();

      _offsetAnimation = Tween<Offset>(begin: offsetDiff, end: Offset.zero)
          .animate(_positionController);
      _positionController.forward(from: 0);
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
