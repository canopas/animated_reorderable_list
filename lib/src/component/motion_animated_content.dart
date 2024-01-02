import 'package:animated_reorderable_list/src/model/motion_data.dart';
import 'package:flutter/widgets.dart';

import '../builder/motion_animated_builder.dart';

class MotionAnimatedContent extends StatefulWidget {
  final int index;
  final MotionData motionData;
  final Widget? child;
  final Function(MotionData)? updateMotionData;

  const MotionAnimatedContent(
      {required Key key,
      required this.index,
      required this.motionData,
      required this.child,
      this.updateMotionData})
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
  bool visible = true;

  @override
  void initState() {
    _listState = MotionBuilderState.of(context);
    _listState.registerItem(this);

    _positionController =
        AnimationController(vsync: this, duration: widget.motionData.duration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.updateMotionData?.call(widget.motionData);
            }
          });

    _offsetAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_positionController)
      ..addListener(() {
        if (mounted) setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.updateMotionData?.call(widget.motionData);
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant MotionAnimatedContent oldWidget) {
    if (oldWidget.index != widget.index) {
      print("didUpdateWidget old ${oldWidget.index} index ${widget.index}");
      _listState.unregisterItem(oldWidget.index, this);
      _listState.registerItem(this);
     //  visible = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.updateMotionData?.call(widget.motionData);
      //if (mounted) setState(() => visible = true);
    });

    super.didUpdateWidget(oldWidget);
  }

  void move() {
    Offset endOffset = itemOffset();

    print(
        "_updateAnimationTranslation index $index endOffset $endOffset startOffset ${widget.motionData.startOffset}");
    Offset offsetDiff =
        (widget.motionData.startOffset + currentAnimatedOffset) - endOffset;

    if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
      _positionController.duration = widget.motionData.duration;

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
    return Visibility(
      visible: visible,
      child: Transform.translate(
          offset: _offsetAnimation.value,
          child: widget.child ?? const SizedBox.shrink()),
    );
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
