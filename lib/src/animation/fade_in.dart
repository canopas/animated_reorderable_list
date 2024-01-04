import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';

class FadeIn extends AnimationEffect<double> {
  static const double beginValue = 0.0;
  static const double endValue = 1.0;

  FadeIn(
      {super.delay, super.duration, super.curve, double? begin, double? end})
      : super(
            begin: begin ?? beginValue,
            end: end ?? endValue);

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,
      EffectEntry entry) {
    final Animation<double> opacity = buildAnimation(entry).animate(animation);
    return FadeTransition(opacity: opacity, child: child);
  }
}

