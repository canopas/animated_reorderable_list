import 'package:flutter/cupertino.dart';
import 'package:animated_reorderable_list/src/animation/animation.dart';

class FadeInLeft extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const FadeInLeft({Key? key, required this.animation, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideInLeft(
      animation: animation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}
