import 'package:flutter/cupertino.dart';
import 'package:motion_list/animation/animation.dart';

class FadeInRight extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const FadeInRight({Key? key,required this.animation,required this.child}):super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:Animation.fromValueListenable(animation,transformer: (value){
        return (value).clamp(0, 1);
      }),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(1.0,0.0),end:Offset(0.0,0.0)).animate(animation),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }
}
