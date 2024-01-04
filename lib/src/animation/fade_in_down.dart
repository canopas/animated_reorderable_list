import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';



class FadeInDown extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  const FadeInDown({Key? key, required this.child, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
        position: Tween(begin: const Offset(0.0, -0.3), end: Offset.zero)
            .animate(animation),
        child: FadeTransition(opacity: animation, child: child));
  }
}
