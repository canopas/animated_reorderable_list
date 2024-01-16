import 'package:flutter/cupertino.dart';
import '../../animated_reorderable_list.dart';

class SizeAnimation extends AnimationEffect<double> {
  static const double beginValue = 0.0;
  static const double endValue = 1.0;
  static const double alignmentValue = 0.0;
  final double? begin;
  final double? end;
  final Axis? axis;
  final double? axisAlignment;

  SizeAnimation(
      {super.delay,
      super.duration,
      super.curve,
      this.begin,
      this.end,
      this.axis,
      this.axisAlignment});

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,
      EffectEntry entry) {
    final Animation<double> sizeFactor =
        buildAnimation(entry, begin: begin ?? beginValue, end: end ?? endValue)
            .animate(animation);
    return Align(
      child: SizeTransition(
        sizeFactor: sizeFactor,
        axis: axis ?? Axis.horizontal,
        axisAlignment: axisAlignment ?? alignmentValue,
        child: child,
      ),
    );
  }
}
