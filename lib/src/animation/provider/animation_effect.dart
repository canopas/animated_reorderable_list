import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';

class AnimationTransition{

}


abstract class AnimationEffect<T>{
  final Duration? delay;
  final Duration? duration;
  final Curve? curve;
  final T? begin;
  final T? end;

  AnimationEffect({this.delay,this.duration,this.curve,this.begin,this.end});
  Widget build(BuildContext context, Widget child){
    return child;
  }
}