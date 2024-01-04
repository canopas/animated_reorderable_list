import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';

class SlideInDown extends AnimationEffect<Offset> {
  static const Offset beginValue = const Offset(0, 1);
  static const Offset endValue = const Offset(0, 0);

  SlideInDown(
      {super.delay, super.duration, super.curve, Offset? begin, Offset? end})
      :super(begin: begin ?? beginValue, end: end ?? endValue);

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,EffectEntry entry){
    final Animation<Offset> position= buildAnimation(entry).animate(animation);
    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: SlideTransition(
        position: position,
        child: child,
      ),
    );
  }
}

// class SlideInDown extends StatelessWidget {
//   final Widget child;
//   final Animation<double> animation;
//
//   const SlideInDown({Key? key, required this.child, required this.animation})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ClipRect(
//       clipBehavior: Clip.hardEdge,
//       child: SlideTransition(
//         position:
//             Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0))
//                 .animate(animation),
//         child: child,
//       ),
//     );
//   }
// }
