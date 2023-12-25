import 'package:flutter/cupertino.dart';
import 'package:motion_list/src/animation/animation.dart';

import 'animation_type.dart';

class AnimationProvider {
  static Widget buildAnimation(
      AnimationType animationType, Widget child, Animation<double> animation) {
    switch (animationType) {
      case (AnimationType.fadeIn):
        return FadeInAnimation(animation: animation, child: child);
      case (AnimationType.fadeInLeft):
        return FadeInLeft(
          animation: animation,
          child: child,
        );
      case (AnimationType.fadeInRight):
        return FadeInRight(
          animation: animation,
          child: child,
        );
      case (AnimationType.fadeInDown):
        return FadeInDown(animation: animation, child: child);
      case (AnimationType.fadeInUp):
        return FadeInUp(animation: animation, child: child);
      case (AnimationType.flipInY):
        return FlipInY(animation: animation, child: child);
      case (AnimationType.flipInX):
        return FlipInX(animation: animation, child: child);
      case (AnimationType.landing):
        return Landing(animation: animation, child: child);
      case (AnimationType.scaleIn):
        return ScaleIn(animation: animation, child: child);
      case (AnimationType.scaleInTop):
        return ScaleInTop(animation: animation, child: child);
      case (AnimationType.scaleInBottom):
        return ScaleInBottom(animation: animation, child: child);
      case (AnimationType.scaleInLeft):
        return ScaleInLeft(animation: animation, child: child);
      case (AnimationType.scaleInRight):
        return ScaleInRight(animation: animation, child: child);
      case (AnimationType.slideInLeft):
        return SlideInLeft(animation: animation, child: child);
      case (AnimationType.slideInRight):
        return SlideInRight(animation: animation, child: child);
      case (AnimationType.slideInUp):
        return SlideInUp(animation: animation, child: child);
      case (AnimationType.slideInDown):
        return SlideInDown(animation: animation, child: child);
      case (AnimationType.sizeIn):
        return SizeIn(animation: animation, child: child);
    }
  }
}
