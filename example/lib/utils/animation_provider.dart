import 'package:animated_reorderable_list/animated_reorderable_list.dart';

class AnimationProvider {
  static AnimationEffect buildAnimation(AnimationType animationType) {
    switch (animationType) {
      case (AnimationType.fadeIn):
        return FadeIn();
      case (AnimationType.flipInY):
        return FlipInY();
      case (AnimationType.flipInX):
        return FlipInX();
      case (AnimationType.landing):
        return Landing();
      case (AnimationType.size):
        return SizeAnimation();
      case (AnimationType.scaleIn):
        return ScaleIn();
      case (AnimationType.scaleInTop):
        return ScaleInTop();
      case (AnimationType.scaleInBottom):
        return ScaleInBottom();
      case (AnimationType.scaleInLeft):
        return ScaleInLeft();
      case (AnimationType.scaleInRight):
        return ScaleInRight();
      case (AnimationType.slideInLeft):
        return SlideInLeft();
      case (AnimationType.slideInRight):
        return SlideInRight();
      case (AnimationType.slideInUp):
        return SlideInUp();
      case (AnimationType.slideInDown):
        return SlideInDown();
    }
  }
}
