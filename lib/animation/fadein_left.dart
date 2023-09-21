import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:motion_list/animation/animation.dart';

class FadeInLeft extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const FadeInLeft({Key? key,required this.animation,required this.child}):super(key: key);

  @override
  Widget build(BuildContext context) {
    return   SlideIn(
      animation: animation,
      child: FadeTransition(
        opacity:animation,
        child: child,
      ),
    );
  }
}
