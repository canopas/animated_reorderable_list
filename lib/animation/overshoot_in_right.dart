import 'package:flutter/cupertino.dart';


class OverShootInRight extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const OverShootInRight(
      {Key? key, required this.child, required this.animation})
      :super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
          begin: const Offset(1, 0), end: const Offset(0, 0)).animate(
          CurvedAnimation(parent: animation, curve: Curves.bounceOut)),
      child: child,
    );
  }
}
