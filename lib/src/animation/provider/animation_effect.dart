import 'package:flutter/cupertino.dart';

extension AnimationPlusExtension on AnimationEffect {

}

class AnimationTransition {

  List<AnimationEffect> effects =[];
  AnimationTransition(this.effects);

  void addAnimation(AnimationEffect effect) {
    effects.add(effect);
  }

  Widget applyAnimation(BuildContext context, Widget child, Animation<double> animation) {
    Widget animatedChild= child;
    for (final effect in effects) {
     animatedChild= effect.build(context, child, animation);
    }
    return animatedChild;
  }
}

abstract class AnimationEffect<T> {
  final Duration? delay;
  final Duration? duration;
  final Curve? curve;
  final double? begin;
  final double? end;

  AnimationEffect({
    this.delay,
    this.duration,
    this.curve,
    this.begin,
    this.end,
  });

  Widget build(BuildContext context, Widget child, Animation<double> animation) {
    return child;
  }

  Animation<double> buildAnimation(Animation<double> animation) {
    return animation.drive(Tween<double>(begin: begin, end: end)
        .chain(CurveTween(curve: curve ?? Curves.linear)));
  }
}
