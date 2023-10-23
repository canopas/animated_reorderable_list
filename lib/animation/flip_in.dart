import 'dart:math';

import 'package:flutter/cupertino.dart';

class FlipIn extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  FlipIn({Key? key, required this.animation, required this.child})
      : super(key: key);
  var transform = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final rotateAnim = Tween(begin: pi / 2, end: 0.0).animate(animation);
        return Transform(
          transform: Matrix4.rotationY(rotateAnim.value),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }
}
