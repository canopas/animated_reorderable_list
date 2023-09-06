import 'package:flutter/cupertino.dart';
import 'package:motion_list/animation/fade_in.dart';
import 'package:motion_list/animation/size_in.dart';
import 'package:motion_list/animation/slide_in.dart';

import 'animation_type.dart';

class AnimationProvider{
  static Widget buildAnimation(AnimationType animationType,Widget child, Animation<double> animation){
    switch(animationType){
      case(AnimationType.fadeIn):
        return FadeInAnimation(animation: animation, child: child);
      case(AnimationType.slideIn):
      return  SlideInAnimation(animation: animation,child: child,);
      case (AnimationType.sizeIn):
        return SizeInAnimation(animation: animation, child: child);
    }
}
}