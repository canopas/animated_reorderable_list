import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';

class FadeIn extends AnimationEffect<double> {
  static const double beginValue = 0.0;
  static const double endValue = 1.0;
  final double? begin;
  final double? end;

  FadeIn({super.delay, super.duration, super.curve, this.begin, this.end});

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,
      EffectEntry entry) {
    final Animation<double> opacity =
        buildAnimation(entry, begin: begin ?? beginValue, end: end ?? endValue)
            .animate(animation);
    return FadeTransition(opacity: opacity, child: child);
  }
}
