
import 'package:flutter/cupertino.dart';

class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Animation<double> animation;

  const FadeInAnimation(
      {Key? key, required this.child, required this.animation})
      :super(key: key);

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this,duration: const Duration(milliseconds: 500));
    _animation= Tween(begin: 0.0,end: 1.0).animate(_animationController!);
    _animationController!.forward();
    _animationController!.addStatusListener((status) {
      // _animation= Animation.fromValueListenable(listenable)
      if(status == AnimationStatus.completed){
        widget.animation.drive(Tween<double>(begin: 0.0,end: 1.0).chain(CurveTween(curve: Curves.easeIn)));
      }
    });
    widget.animation.addStatusListener((status) {
      if(status == AnimationStatus.completed){
      _animation!.drive(Tween<double>(begin: 1.0,end: 0.0).chain(CurveTween(curve: Curves.easeIn)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:Animation.fromValueListenable(widget.animation,transformer: (value){
        return (value).clamp(0, 1);
      }),
      child: FadeTransition(
        opacity:widget.animation,
        child: widget.child,
      ),
    );
  }
}