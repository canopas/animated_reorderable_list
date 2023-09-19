import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:motion_list/animation/animation.dart';

class FadeInLeftWithSize extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const FadeInLeftWithSize({Key? key,required this.animation,required this.child}):super(key: key);

  @override
  Widget build(BuildContext context) {
    return   SizeTransition(
      sizeFactor:Animation.fromValueListenable(animation,transformer: (value){
        return (value).clamp(0, 1);
      }),
      child: SlideInAnimation(
        animation: animation,
        child: FadeTransition(
          opacity:animation,
          child: child,
        ),
      ),
    );
  }
}
