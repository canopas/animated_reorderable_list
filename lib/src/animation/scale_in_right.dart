import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';

class ScaleInRight extends AnimationEffect<double> {
  static const double beginValue = 0.0;
  static const double endValue = 1.0;

  ScaleInRight(
      {super.delay, super.duration, super.curve, double? begin, double? end})
      :super(begin: begin ?? beginValue, end: end ?? endValue);

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,EffectEntry entry){
    final Animation<double> scale= buildAnimation(entry).animate(animation);
    return ScaleTransition(
      alignment: Alignment.centerRight,
      scale: scale,
      child: child,
    );
  }
}

// class ScaleInRight extends StatelessWidget {
//   final Widget child;
//   final Animation<double> animation;
//   const ScaleInRight({Key? key, required this.child, required this.animation})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ScaleTransition(
//       alignment: Alignment.centerRight,
//       scale: animation,
//       child: child,
//     );
//   }
// }
