import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';

class ScaleEffect extends AnimationEffect {
  static const double beginValue = 0.0;
  static const double endValue = 1.0;

  ScaleEffect(
      {super.delay, super.duration, super.curve, double? begin, double? end})
      :super(begin: begin ?? beginValue, end: end ?? endValue);

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,EffectEntry entry){
    final Animation<double> scale= buildAnimation(entry,animation) as Animation<double>;
    return ScaleTransition(
      scale: scale,
      child: child,
    );
  }
}

class ScaleIn extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  const ScaleIn({Key? key, required this.child, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }
}
