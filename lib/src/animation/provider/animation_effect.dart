import 'package:flutter/cupertino.dart';

extension AnimationPlusExtension on AnimationEffect {}

class AnimationTransition {
  List<EffectEntry> effects = [];

  AnimationTransition(this.effects);


  Widget applyAnimation(
      BuildContext context, Widget child, Animation<double> animation) {
    Widget animatedChild= child;;
    for(EffectEntry entry in effects){
      animatedChild = entry.animationEffect.build(context, animatedChild, animation, entry);
    }
    return animatedChild;
  }
}

abstract class AnimationEffect<T> {
  final Duration? delay;
  final Duration? duration;
  final Curve? curve;
  final double? begin;
  final double? end;

  AnimationEffect({
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.curve,
    this.begin,
    this.end,
  });

  Widget build(BuildContext context, Widget child, Animation<double> animation,
      EffectEntry entry) {
    return child;
  }

  Animatable<double> buildAnimation(
       EffectEntry entry) {
    return Tween<double>(begin: begin, end: end).chain(entry.buildAnimation());
  }
}

@immutable
class EffectEntry {
  const EffectEntry({
    required this.animationEffect,
    required this.delay,
    required this.duration,
    required this.curve,
  });

  /// The delay for this entry.
  final Duration delay;

  /// The duration for this entry.
  final Duration duration;

  /// The curve used by this entry.
  final Curve curve;

  /// The effect associated with this entry.
  final AnimationEffect animationEffect;

  /// The begin time for this entry.
  Duration get begin => delay;

  /// The end time for this entry.
  Duration get end => duration ;

  /// Builds a sub-animation based on the properties of this entry.
  CurveTween buildAnimation({
    Curve? curve,
  }) {
    int ttlT = duration.inMicroseconds;
    int beginT = begin.inMicroseconds,
        endT = end.inMicroseconds;
    print("begin: ${beginT / ttlT} end: ${endT / ttlT}");

    return CurveTween(
      curve: Interval(beginT / ttlT, endT / ttlT, curve: curve ?? this.curve),
    );
  }
}


mixin AnimateManager<T> {
  T addEffect(AnimationEffect effect) => throw (UnimplementedError());
  T addEffects(List<AnimationEffect> effects) {
    for (AnimationEffect o in effects) {
      addEffect(o);
    }
    return this as T;
  }
}