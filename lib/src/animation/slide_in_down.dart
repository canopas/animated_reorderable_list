import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';

class SlideInDown extends AnimationEffect<Offset> {
  static const Offset beginValue = Offset(0, 1);
  static const Offset endValue = Offset(0, 0);
  final Offset? begin;
  final Offset? end;

  /// A sliding animation from the top to the bottom.
  SlideInDown({super.delay, super.duration, super.curve, this.begin, this.end});

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,
      EffectEntry entry, Duration totalDuration) {
    final Animation<Offset> position = buildAnimation(entry, totalDuration,
            begin: begin ?? beginValue, end: endValue)
        .animate(animation);
    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: SlideTransition(
        position: position,
        child: child,
      ),
    );
  }
}
