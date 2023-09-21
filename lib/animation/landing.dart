import 'package:flutter/cupertino.dart';

class Landing extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  const Landing({Key? key,required this.child, required this.animation}):super(key: key);

  @override
  Widget build(BuildContext context) {
    return  ScaleTransition(
        scale: Tween<double>(begin: 1.5,end: 1.0).animate(animation),
      child: FadeTransition(
        opacity: animation,
          child: child),);
  }
}
