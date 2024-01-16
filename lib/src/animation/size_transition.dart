import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../animated_reorderable_list.dart';

class SizeInAnimation extends AnimationEffect<double> {
  static const double beginValue = 0.0;
  static const double endValue = 1.0;
  final double? begin;
  final double? end;
  final Axis axis;
  final double axisAlignment;

  SizeInAnimation({super.delay, super.duration, super.curve, this.begin, this.end,required this.axis,required this.axisAlignment});

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,
      EffectEntry entry) {
    final AlignmentDirectional alignment;
    if (axis == Axis.vertical) {
      alignment = AlignmentDirectional(-1.0, axisAlignment);
    } else {
      alignment = AlignmentDirectional(axisAlignment, -1.0);
    }
    final Animation<double> sizeFactor =
    buildAnimation(entry, begin: begin ?? beginValue, end: end ?? endValue)
        .animate(animation);
   return  ClipRect(
     child: Align(
        alignment: alignment,
        heightFactor: axis == Axis.vertical ? max(sizeFactor.value, 0.0) : null,
        widthFactor: axis == Axis.horizontal ? max(sizeFactor.value, 0.0) : null,
        child: child,
      ),
   );
  //  return FadeTransition(opacity: opacity, child: child);
  }
}
