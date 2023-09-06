import 'package:flutter/cupertino.dart';

class SizeInAnimation extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const SizeInAnimation(
      {Key? key, required this.child, required this.animation})
      :super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: child,
    );
  }
}