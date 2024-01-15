import 'dart:math';

import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';

class FlipInY extends AnimationEffect<double> {
  static const double beginValue = pi / 2;
  static const double endValue = 0.0;
  final double? begin;
  final double? end;

  FlipInY({super.delay, super.duration, super.curve, this.begin, this.end});

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,
      EffectEntry entry) {
    final Animation<double> rotation =
        buildAnimation(entry, begin: begin ?? beginValue, end: endValue)
            .animate(animation);
    return AnimatedBuilder(
      animation: rotation,
      builder: (BuildContext context, Widget? child) {
        return Transform(
          transform: Matrix4.rotationY(rotation.value),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }
}
