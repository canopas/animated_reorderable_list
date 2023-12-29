import 'package:flutter/cupertino.dart';

class FadeInRight extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const FadeInRight({Key? key, required this.animation, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
              begin: const Offset(1.0, 0.0), end: const Offset(0.0, 0.0))
          .animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}
