import 'package:flutter/cupertino.dart';

class ScaleInBottom extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  const ScaleInBottom({Key? key, required this.child, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      alignment: Alignment.bottomCenter,
      scale: animation,
      child: child,
    );
  }
}
