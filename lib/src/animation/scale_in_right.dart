import 'package:flutter/cupertino.dart';

class ScaleInRight extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  const ScaleInRight({Key? key, required this.child, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      alignment: Alignment.centerRight,
      scale: animation,
      child: child,
    );
  }
}
