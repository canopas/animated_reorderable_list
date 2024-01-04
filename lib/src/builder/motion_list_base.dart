import 'package:animated_reorderable_list/src/animation/provider/animation_effect.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';

import 'motion_animated_builder.dart';

typedef ItemBuilder<W extends Widget, E> = Widget Function(
    BuildContext context, int index);

typedef EqualityChecker<E> = bool Function(E, E);

const Duration _kInsertItemDuration = Duration(milliseconds: 300);

const Duration _kRemoveItemDuration = Duration(milliseconds: 300);

abstract class MotionListBase<W extends Widget, E extends Object>
    extends StatefulWidget{
  final ItemBuilder<W, E> itemBuilder;
  final List<E> items;
  final Duration? resizeDuration;
  final Duration? insertDuration;
  final Duration? removeDuration;
  final Axis? scrollDirection;
  final List<AnimationEffect>? onEnter;
  final AnimationType? insertAnimationType;
  final AnimationType? removeAnimationType;
  final EqualityChecker<E>? areItemsTheSame;
  final SliverGridDelegate? sliverGridDelegate;

  MotionListBase(
      {Key? key,
      required this.items,
      required this.itemBuilder,
      this.resizeDuration,
      this.insertDuration,
      this.removeDuration,
      this.insertAnimationType,
      this.scrollDirection,
      this.onEnter,
      this.sliverGridDelegate,
      this.removeAnimationType,
      this.areItemsTheSame})
      : super(key: key);
}

abstract class MotionListBaseState<
    W extends Widget,
    B extends MotionListBase<W, E>,
    E extends Object> extends State<B> with TickerProviderStateMixin {
  late List<E> oldList;
  Duration _duration = const Duration(milliseconds: 300);
  List<EffectEntry> _enteries = [];
  EffectEntry? _lastEntry;

  Duration get duration => _duration;

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
  Duration get insertDuration => widget.insertDuration ?? _duration;

  @nonVirtual
  @protected
  Duration get removeDuration => widget.removeDuration ?? _kRemoveItemDuration;

  @protected
  @nonVirtual
  Axis get scrollDirection => widget.scrollDirection ?? Axis.vertical;

  @nonVirtual
  @protected
  AnimationType? get insertAnimationType => widget.insertAnimationType;

  @nonVirtual
  @protected
  List<AnimationEffect> get onEnter => widget.onEnter ?? [];

  @nonVirtual
  @protected
  AnimationType? get removeAnimationType => widget.removeAnimationType;

  late final resizeAnimController = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    oldList = List.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant B oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newList = widget.items;
    if(!listEquals(oldWidget.onEnter, onEnter)){
      addEffects(onEnter);
    }
    calculateDiff(oldList, newList);
    oldList = List.from(newList);
  }

  void addEffects(List<AnimationEffect> effects) {
    _enteries = [];
    if(effects.isNotEmpty){
      for (AnimationEffect effect in effects) {
        addEffect(effect);
      }
    }else{
      addEffect(FadeEffect());
    }
  }

  void addEffect(AnimationEffect effect) {
    EffectEntry? prior = _lastEntry;
    Duration zero = Duration.zero, delay = zero;
    assert(delay >= zero, "calculared delay can not be negative");

    if (effect.duration != null) {
      _duration = effect.duration! > _duration ? effect.duration! : _duration;
    }

    EffectEntry entry = EffectEntry(
        animationEffect: effect,
        delay: effect.delay ?? zero,
        duration: effect.duration ?? prior?.duration ?? _kInsertItemDuration,
        curve: effect.curve ?? prior?.curve ?? Curves.linear);

    _enteries.add(entry);
    _lastEntry = entry;
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
        listKey.currentState!.insertItem(i, insertDuration: _duration);
      }
    }
  }

  @nonVirtual
  @protected
  Widget insertItemBuilder(
      BuildContext context, Widget child, Animation<double> animation) {
    Widget animatedChild= child;
    for(EffectEntry entry in _enteries){
      animatedChild = entry.animationEffect.build(context, animatedChild, animation, entry);
    }
    return animatedChild;
  }

  @nonVirtual
  @protected
  Widget removeItemBuilder(
      BuildContext context, Widget child, Animation<double> animation) {
    return AnimationProvider.buildAnimation(
        removeAnimationType!, child, animation);
  }
}
