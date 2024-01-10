import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';

import 'motion_animated_builder.dart';

typedef ItemBuilder<W extends Widget, E> = Widget Function(
    BuildContext context, int index);

typedef EqualityChecker<E> = bool Function(E, E);

const Duration _kAnimationDuration = Duration(milliseconds: 300);

abstract class MotionListBase<W extends Widget, E extends Object>
    extends StatefulWidget {
  final ItemBuilder<W, E> itemBuilder;
  final List<E> items;
  final List<AnimationEffect>? enterTransition;
  final List<AnimationEffect>? exitTransition;
  final Duration? insertDuration;
  final Duration? removeDuration;
  final Axis? scrollDirection;
  final EqualityChecker<E>? areItemsTheSame;
  final SliverGridDelegate? sliverGridDelegate;

  const MotionListBase(
      {Key? key,
      required this.items,
      required this.itemBuilder,
      this.enterTransition,
      this.exitTransition,
      this.insertDuration,
      this.removeDuration,
      this.scrollDirection,
      this.sliverGridDelegate,
      this.areItemsTheSame})
      : super(key: key);
}

abstract class MotionListBaseState<
    W extends Widget,
    B extends MotionListBase<W, E>,
    E extends Object> extends State<B> with TickerProviderStateMixin {
  late List<E> oldList;

  Duration _enterDuration = _kAnimationDuration;
  Duration _exitDuration = _kAnimationDuration;

  List<EffectEntry> _enterAnimations = [];
  List<EffectEntry> _exitAnimations = [];

  Duration get enterDuration => _enterDuration;

  Duration get exitDuration => _exitDuration;

  @protected
  GlobalKey<MotionBuilderState> listKey = GlobalKey();

  @nonVirtual
  @protected
  MotionBuilderState get list => listKey.currentState!;

  @nonVirtual
  @protected
  ItemBuilder<W, E> get itemBuilder => widget.itemBuilder;

  @nonVirtual
  @protected
  SliverGridDelegate? get sliverGridDelegate => widget.sliverGridDelegate;

  @nonVirtual
  @protected
  Duration get insertDuration => widget.insertDuration ?? enterDuration;

  @nonVirtual
  @protected
  Duration get removeDuration => widget.removeDuration ?? exitDuration;

  @protected
  @nonVirtual
  Axis get scrollDirection => widget.scrollDirection ?? Axis.vertical;

  @nonVirtual
  @protected
  List<AnimationEffect> get enterTransition => widget.enterTransition ?? [];

  @nonVirtual
  @protected
  List<AnimationEffect> get exitTransition => widget.exitTransition ?? [];

  late final resizeAnimController = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    oldList = List.from(widget.items);
    addEffects(enterTransition, _enterAnimations, enter: true);
    addEffects(exitTransition, _exitAnimations, enter: false);
  }

  @override
  void didUpdateWidget(covariant B oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newList = widget.items;
    if (!listEquals(oldWidget.enterTransition, enterTransition)) {
      _enterAnimations = [];
      addEffects(enterTransition, _enterAnimations, enter: true);
    }
    if (!listEquals(oldWidget.exitTransition, exitTransition)) {
      _exitAnimations = [];
      addEffects(exitTransition, _exitAnimations, enter: false);
    }
    calculateDiff(oldList, newList);
    oldList = List.from(newList);
  }

  void addEffects(List<AnimationEffect> effects, List<EffectEntry> enteries,
      {required bool enter}) {
    if (effects.isNotEmpty) {
      for (AnimationEffect effect in effects) {
        addEffect(effect, enteries, enter: enter);
      }
    } else {
      addEffect(FadeIn(), enteries, enter: enter);
    }
  }

  void addEffect(AnimationEffect effect, List<EffectEntry> enteries,
      {required bool enter}) {
    Duration zero = Duration.zero;

    if (effect.duration != null) {
      if (enter) {
        _enterDuration = effect.duration! > _enterDuration
            ? effect.duration!
            : _enterDuration;
        assert(_enterDuration >= zero, "Duration can not be negative");
      } else {
        _exitDuration =
            effect.duration! > _exitDuration ? effect.duration! : _exitDuration;
        assert(_exitDuration >= zero, "Duration can not be negative");
      }
    }

    EffectEntry entry = EffectEntry(
        animationEffect: effect,
        delay: effect.delay ?? zero,
        duration: effect.duration ?? removeDuration,
        curve: effect.curve ?? Curves.linear);

    enteries.add(entry);
  }

  void calculateDiff(List oldList, List newList) {
    // Detect removed and updated items
    for (int i = oldList.length - 1; i >= 0; i--) {
      if (!newList.contains(oldList[i])) {
        listKey.currentState!.removeItem(i, removeItemDuration: removeDuration);
      }
    }
    // Detect added items
    for (int i = 0; i < newList.length; i++) {
      if (!oldList.contains(newList[i])) {
        listKey.currentState!.insertItem(i, insertDuration: insertDuration);
      }
    }
  }

  @nonVirtual
  @protected
  Widget insertItemBuilder(
      BuildContext context, Widget child, Animation<double> animation) {
    Widget animatedChild = child;
    for (EffectEntry entry in _enterAnimations) {
      animatedChild =
          entry.animationEffect.build(context, animatedChild, animation, entry);
    }
    return animatedChild;
  }

  @nonVirtual
  @protected
  Widget removeItemBuilder(
      BuildContext context, Widget child, Animation<double> animation) {
    Widget animatedChild = child;
    for (EffectEntry entry in _exitAnimations) {
      animatedChild =
          entry.animationEffect.build(context, animatedChild, animation, entry);
    }
    return animatedChild;
  }
}
