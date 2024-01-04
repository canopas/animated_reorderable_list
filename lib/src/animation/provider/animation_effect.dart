import 'package:flutter/cupertino.dart';


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

  Animation<double> buildAnimation(EffectEntry entry,Animation<double> animation) {
    return animation.drive(Tween<double>(begin: begin, end: end).chain(entry.buildAnimation()));
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
  Duration get end => duration;

  /// Builds a sub-animation based on the properties of this entry.
  CurveTween buildAnimation({
    Curve? curve,
  }) {
    int ttlT = duration.inMicroseconds;
    int beginT = begin.inMicroseconds, endT = end.inMicroseconds;
    return CurveTween(
      curve: Interval(beginT / ttlT, endT / ttlT, curve: curve ?? this.curve),
    );
  }

  @override
  String toString() {
    return "delay: $delay, Duration: $duration, curve: $curve, begin: $begin, end: $end, Effect: $animationEffect";
  }
}

