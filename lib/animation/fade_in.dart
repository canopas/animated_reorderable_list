
import 'package:flutter/cupertino.dart';

class FadeInAnimation extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const FadeInAnimation(
      {Key? key, required this.child, required this.animation})
      :super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: Tween<double>(begin: 0.0,end: 1.0).evaluate(animation),
      duration: const Duration(milliseconds:500),
      child: child,
    );
  }
}