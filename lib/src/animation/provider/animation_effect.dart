import 'package:flutter/cupertino.dart';

extension AnimationPlusExtension on AnimationEffect {
  void operator +(EffectEntry entry) {
    AnimationTransition()
      ..effects
      ..addAnimation(entry);
  }
}

class AnimationTransition {
  List<EffectEntry> effects = [];

  void addAnimation(EffectEntry entry) {
    effects.add(entry);
  }

  void applyAnimation(BuildContext context, Widget child) {
    for (final entry in effects) {
      entry.effect.build(context, child);
    }
  }
}

abstract class AnimationEffect<T> {
  final Duration? delay;
  final Duration? duration;
  final Curve? curve;
  final T? begin;
  final T? end;

  AnimationEffect(
      {this.delay, this.duration, this.curve, this.begin, this.end});

  Widget build(BuildContext context, Widget child) {
    return child;
  }

  Animation<T> buildAnimation(
      AnimationController controller, EffectEntry entry) {
    return entry
        .buildAnimation(controller)
        .drive(Tween<T>(begin: begin, end: end));
  }
}

class EffectEntry {
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final AnimationEffect effect;

  EffectEntry(
      {required this.effect,
      required this.duration,
      required this.curve,
      required this.delay});

  Animation<double> buildAnimation(AnimationController controller,
      {Curve? curve}) {
    return CurvedAnimation(parent: controller, curve: curve ?? this.curve);
  }
}
