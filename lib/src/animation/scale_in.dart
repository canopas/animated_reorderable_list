import 'package:flutter/cupertino.dart';

class ScaleIn extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  const ScaleIn({Key? key, required this.child, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }
}
