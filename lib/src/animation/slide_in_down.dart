import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';

class SlideInDownEffect extends AnimationEffect {
  static const Offset beginValue = const Offset(0, 1);
  static const Offset endValue = const Offset(0, 0);

  SlideInDownEffect(
      {super.delay, super.duration, super.curve, double? begin, double? end})
      :super(begin: begin ?? beginValue, end: end ?? endValue);

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,EffectEntry entry){
    final Animation<Offset> position= buildAnimation(entry,animation) as Animation<Offset>;
    return SlideTransition(
      position: position,
      child: child,
    );
  }
}

class SlideInDown extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const SlideInDown({Key? key, required this.child, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: SlideTransition(
        position:
            Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0))
                .animate(animation),
        child: child,
      ),
    );
  }
}
