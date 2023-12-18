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
