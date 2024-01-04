import 'dart:math';

import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';

class FlipInY extends AnimationEffect<double> {
  static const double beginValue = pi/2;
  static const double endValue = 0.0;

  FlipInY(
      {super.delay, super.duration, super.curve, double? begin, double? end})
      :super(begin: begin ?? beginValue, end: end ?? endValue);

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,EffectEntry entry){
    final Animation<double> rotation= buildAnimation(entry).animate(animation);
    return Transform(
      transform: Matrix4.rotationY(rotation.value),
      alignment: Alignment.center,
      child: child,
    );
  }
}

// class FlipInY extends StatelessWidget {
//   final Animation<double> animation;
//   final Widget child;
//
//   const FlipInY({Key? key, required this.animation, required this.child})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: animation,
//       builder: (BuildContext context, Widget? child) {
//         final rotateAnim = Tween(begin: pi / 2, end: 0.0).animate(animation);
//         return Transform(
//           transform: Matrix4.rotationY(rotateAnim.value),
//           alignment: Alignment.center,
//           child: child,
//         );
//       },
//       child: child,
//     );
//   }
// }
