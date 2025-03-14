import 'package:flutter/cupertino.dart';

import '../../animated_reorderable_list.dart';

class ScaleInTop extends AnimationEffect<double> {
  static const double beginValue = 0.0;
  static const double endValue = 1.0;
  final double? begin;
  final double? end;

  /// A scaling effect originating from the top.
  ScaleInTop({super.delay, super.duration, super.curve, this.begin, this.end});

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,
      EffectEntry entry, Duration totalDuration) {
    final Animation<double> scale = buildAnimation(entry, totalDuration,
            begin: begin ?? beginValue, end: endValue)
        .animate(animation);
    return ScaleTransition(
      alignment: Alignment.topCenter,
      scale: scale,
      child: child,
    );
  }
}
