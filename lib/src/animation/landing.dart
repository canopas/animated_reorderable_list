import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';

class Landing extends AnimationEffect<double> {
  static const double beginValue = 1.5;
  static const double endValue = 1.0;

  Landing(
      {super.delay, super.duration, super.curve, double? begin, double? end})
      :super(begin: begin ?? beginValue, end: end ?? endValue);

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,EffectEntry entry){
    final Animation<double> scale= buildAnimation(entry).animate(animation);
    return ScaleTransition(
      scale: scale,
      child: child,
    );
  }
}

// class Landing extends StatelessWidget {
//   final Widget child;
//   final Animation<double> animation;
//   const Landing({Key? key, required this.child, required this.animation})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ScaleTransition(
//       scale: Tween<double>(begin: 1.5, end: 1.0).animate(animation),
//       child: FadeTransition(opacity: animation, child: child),
//     );
//   }
// }
