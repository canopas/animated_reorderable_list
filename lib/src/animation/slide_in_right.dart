import 'package:flutter/cupertino.dart';

class SlideInRight extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const SlideInRight({Key? key, required this.child, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: SlideTransition(
        position:
            Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0, 0))
                .animate(animation),
        child: child,
      ),
    );
  }
}
