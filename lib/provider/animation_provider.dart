import 'package:flutter/cupertino.dart';
import 'package:motion_list/animation/animation.dart';
import 'package:motion_list/animation/fade_in.dart';
import 'package:motion_list/animation/fadein_left.dart';
import 'package:motion_list/animation/fadein_right.dart';
import 'package:motion_list/animation/landing.dart';
import 'package:motion_list/animation/scale_in.dart';
import 'package:motion_list/animation/size_in.dart';
import 'package:motion_list/animation/slide_in.dart';

import 'animation_type.dart';

class AnimationProvider {
  static Widget buildAnimation(
      AnimationType animationType, Widget child, Animation<double> animation) {
    switch (animationType) {
      case (AnimationType.fadeIn):
        return FadeInAnimation(animation: animation, child: child);
      case (AnimationType.fadeInLeft):
        return FadeInLeft(animation: animation,child: child,);
      case (AnimationType.fadeInRight):
        return FadeInRight(animation: animation,child: child,);
      case(AnimationType.fadeInDown):
        return FadeInDown(animation: animation, child: child);
      case(AnimationType.fadeInUp):
        return FadeInUp(animation: animation, child: child);
      case(AnimationType.landing):
        return Landing(animation: animation, child: child);
      case(AnimationType.scaleIn):
        return ScaleIn(animation: animation, child: child);
      case(AnimationType.scaleInTop):
        return ScaleInTop(animation: animation, child: child);
      case(AnimationType.scaleInBottom):
        return ScaleInBottom(animation: animation, child: child);
      case(AnimationType.scaleInLeft):
        return ScaleInLeft(animation: animation, child: child);
      case(AnimationType.scaleInRight):
        return ScaleInRight(animation: animation, child: child);
      case (AnimationType.slideIn):
        return SlideIn(animation: animation, child: child);
      case (AnimationType.sizeIn):
        return SizeIn(animation: animation, child: child);

    }
  }
}
