import 'package:flutter/cupertino.dart';

import '../../animated_reorderable_list.dart';

class ScaleInTop extends AnimationEffect<double> {
  static const double beginValue = 0.0;
  static const double endValue = 1.0;

  ScaleInTop(
      {super.delay, super.duration, super.curve, double? begin, double? end})
      :super(begin: begin ?? beginValue, end: end ?? endValue);

  @override
  Widget build(BuildContext context, Widget child, Animation<double> animation,EffectEntry entry){
    final Animation<double> scale= buildAnimation(entry).animate(animation);
    return ScaleTransition(
      alignment: Alignment.topCenter,
      scale: scale,
      child: child,
    );
  }
}


