import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';



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
