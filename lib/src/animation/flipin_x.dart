import 'dart:math';

import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';

class FlipInX extends AnimationEffect<double> {
  static const double beginValue = pi / 2;
  static const double endValue = 0.0;

  FlipInX(
      {super.delay, super.duration, super.curve, double? begin, double? end})
      : super(begin: begin ?? beginValue, end: end ?? endValue);

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,
      EffectEntry entry) {
    final Animation<double> rotation = buildAnimation(entry).animate(animation);
    return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          return Transform(
            transform: Matrix4.rotationX(rotation.value),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: child);
  }
}

// class FlipInX extends StatelessWidget {
//   final Animation<double> animation;
//   final Widget child;
//
//   const FlipInX({Key? key, required this.animation, required this.child})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: animation,
//       builder: (BuildContext context, Widget? child) {
//         final rotateAnim = Tween(begin: pi / 2, end: 0.0).animate(animation);
//         return Transform(
//           transform: Matrix4.rotationX(rotateAnim.value),
//           alignment: Alignment.center,
//           child: child,
//         );
//       },
//       child: child,
//     );
//   }
// }
