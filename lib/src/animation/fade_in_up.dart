import 'package:flutter/cupertino.dart';

class FadeInUp extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  const FadeInUp({ Key? key,required this.child,required this.animation}):super (key:key);

  @override
  Widget build(BuildContext context) {
    return  SlideTransition(
        position: Tween(begin: const Offset(0.0,0.3),end: Offset.zero).animate(animation),
        child:FadeTransition(
            opacity: animation,
            child: child));
  }
}
