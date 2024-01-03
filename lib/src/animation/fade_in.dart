import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';


class FadeEffect extends AnimationEffect {
  static const double beginValue = 0.0;
  static const double endValue = 1.0;

  FadeEffect(
      {super.delay, super.duration, super.curve, double? begin, double? end})
      :super(begin: begin ?? beginValue, end: end ?? endValue);
  
  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation){
    return FadeInAnimation(animation: buildAnimation(animation), child: child);
  }
}


class FadeInAnimation extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const FadeInAnimation(
      {Key? key, required this.child, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
