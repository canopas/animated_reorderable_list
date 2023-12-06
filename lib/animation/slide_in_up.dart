import 'package:flutter/cupertino.dart';


class SlideInUp extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const SlideInUp(
      {Key? key, required this.child, required this.animation})
      :super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
          begin: const Offset(0, -1), end: const Offset(0, 0)).animate(
          animation),
      child: child,
    );
  }
}