import 'package:flutter/cupertino.dart';


class SlideInDown extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const SlideInDown(
      {Key? key, required this.child, required this.animation})
      :super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
          begin: const Offset(0, 1), end: const Offset(0, 0)).animate(
          animation),
      child: child,
    );
  }
}