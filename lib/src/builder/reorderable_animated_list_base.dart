import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'reorderable_animated_builder.dart';

typedef ItemBuilder<W extends Widget, E> = Widget Function(
    BuildContext context, int index);

typedef AnimatedWidgetBuilder<W extends Widget, E> = Widget Function(
    Widget child, Animation<double> animation);

typedef EqualityChecker<E> = bool Function(E, E);

const Duration kAnimationDuration = Duration(milliseconds: 300);
const Duration kDefaultDragStartDelay = Duration(milliseconds: 500);

abstract class ReorderableAnimatedListBase<W extends Widget, E extends Object>
    extends StatefulWidget {
  final ItemBuilder<W, E>? itemBuilder;
  final List<E> items;
  final ReorderCallback? onReorder;
  final void Function(int)? onReorderStart;
  final void Function(int)? onReorderEnd;
  final ReorderItemProxyDecorator? proxyDecorator;
  final List<AnimationEffect>? enterTransition;
  final List<AnimationEffect>? exitTransition;
  final Duration? insertDuration;
  final Duration? removeDuration;
  final Axis scrollDirection;
  final SliverGridDelegate? sliverGridDelegate;
  final AnimatedWidgetBuilder? insertItemBuilder;
  final AnimatedWidgetBuilder? removeItemBuilder;
  final bool? buildDefaultDragHandles;
  final bool? longPressDraggable;
  final bool Function(E a, E b)? isSameItem;
  final Duration? dragStartDelay;
  final List<E> nonDraggableItems;
  final List<E> lockedItems;
  final bool enableSwap;

  const ReorderableAnimatedListBase(
      {Key? key,
      required this.items,
      this.itemBuilder,
      this.onReorder,
      this.onReorderEnd,
      this.onReorderStart,
      this.proxyDecorator,
      this.enterTransition,
      this.exitTransition,
      this.insertDuration,
      this.removeDuration,
      required this.scrollDirection,
      this.sliverGridDelegate,
      this.insertItemBuilder,
      this.removeItemBuilder,
      this.buildDefaultDragHandles,
      this.longPressDraggable,
      this.isSameItem,
      this.dragStartDelay,
      this.enableSwap = true,
      required this.nonDraggableItems,
      required this.lockedItems})
      : assert(itemBuilder != null),
        super(key: key);
}

abstract class ReorderableAnimatedListBaseState<
    W extends Widget,
    B extends ReorderableAnimatedListBase<W, E>,
    E extends Object> extends State<B> with TickerProviderStateMixin {
  late List<E> oldList;

  Duration _enterDuration = kAnimationDuration;
  Duration _exitDuration = kAnimationDuration;

  List<EffectEntry> _enterAnimations = [];
  List<EffectEntry> _exitAnimations = [];

  Duration get enterDuration => _enterDuration;

  Duration get exitDuration => _exitDuration;

  @protected
  GlobalKey<ReorderableAnimatedBuilderState> listKey = GlobalKey();

  @nonVirtual
  @protected
  ReorderableAnimatedBuilderState get list => listKey.currentState!;

  @nonVirtual
  @protected
  ItemBuilder<W, E> get itemBuilder {
    return widget.itemBuilder!;
  }

  @nonVirtual
  @protected
  SliverGridDelegate? get sliverGridDelegate => widget.sliverGridDelegate;

  @nonVirtual
  @protected
  ReorderCallback? get onReorder => widget.onReorder;

  @nonVirtual
  @protected
  void Function(int)? get onReorderStart => widget.onReorderStart;

  @nonVirtual
  @protected
  void Function(int)? get onReorderEnd => widget.onReorderEnd;

  @nonVirtual
  @protected
  ReorderItemProxyDecorator? get proxyDecorator => widget.proxyDecorator;

  @nonVirtual
  @protected
  Duration get insertDuration => widget.insertDuration ?? enterDuration;

  @nonVirtual
  @protected
  Duration get removeDuration => widget.removeDuration ?? exitDuration;

  @protected
  @nonVirtual
  Axis get scrollDirection => widget.scrollDirection;

  @nonVirtual
  @protected
  List<AnimationEffect> get enterTransition => widget.enterTransition ?? [];

  @nonVirtual
  @protected
  List<AnimationEffect> get exitTransition => widget.exitTransition ?? [];

  @nonVirtual
  @protected
  bool get buildDefaultDragHandles => widget.buildDefaultDragHandles ?? false;

  @nonVirtual
  @protected
  bool get longPressDraggable => widget.longPressDraggable ?? false;

  @nonVirtual
  @protected
  bool Function(E a, E b) get isSameItem =>
      widget.isSameItem ?? (a, b) => a == b;

  @nonVirtual
  @protected
  Duration get dragStartDelay =>
      widget.dragStartDelay ?? kDefaultDragStartDelay;

  @nonVirtual
  @protected
  List<int> get nonDraggableItems => widget.items
      .asMap()
      .entries
      .where((entry) {
        final found =
            widget.nonDraggableItems.where((e) => isSameItem(e, entry.value));
        return found.isNotEmpty;
      })
      .map((entry) => entry.key)
      .toList();

  @nonVirtual
  @protected
  List<int> get lockedIndices => widget.items
      .asMap()
      .entries
      .where((entry) {
        final items =
            widget.lockedItems.where((e) => isSameItem(e, entry.value));
        return items.isNotEmpty;
      })
      .map((entry) => entry.key)
      .toList();

  @override
  void initState() {
    super.initState();
    oldList = List.from(widget.items);

    addEffects(enterTransition, _enterAnimations, enter: true);
    addEffects(exitTransition, _exitAnimations, enter: false);
  }

  @override
  void didUpdateWidget(covariant B oldWidget) {
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
    super.didUpdateWidget(oldWidget);
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
    final timeForAnimation =
        (effect.delay ?? zero) + (effect.duration ?? kAnimationDuration);
    if (enter) {
      _enterDuration =
          timeForAnimation > _enterDuration ? timeForAnimation : _enterDuration;
      assert(_enterDuration >= zero, "Duration can not be negative");
    } else {
      _exitDuration =
          timeForAnimation > _exitDuration ? timeForAnimation : _exitDuration;
      assert(_exitDuration >= zero, "Duration can not be negative");
    }

    EffectEntry entry = EffectEntry(
        animationEffect: effect,
        delay: effect.delay ?? zero,
        duration: effect.duration ?? kAnimationDuration,
        curve: effect.curve ?? Curves.linear);

    enteries.add(entry);
  }

  void calculateDiff(List oldList, List newList) {
    final swappedPairs = [];

    if (oldList.length == newList.length && widget.enableSwap) {
      for (int i = 0; i < newList.length; i++) {
        if (!isSameItem(oldList[i], newList[i])) {
          final oldIndex =
              oldList.indexWhere((oldItem) => isSameItem(oldItem, newList[i]));

          if (oldIndex != -1) {
            if (isSameItem(newList[oldIndex], oldList[i])) {
              swappedPairs.add([i, oldIndex]);
            }
          }
        }
      }
      if (swappedPairs.isEmpty) {
        return;
      }
      // Handle swapped Items
      for (List<int> pair in swappedPairs) {
        listKey.currentState!.moveItem(pair[0], pair[1]);
      }
      return;
    }

    // Detect removed and updated items
    for (int i = oldList.length - 1; i >= 0; i--) {
      if (newList.indexWhere((element) => isSameItem(oldList[i], element)) ==
          -1) {
        listKey.currentState!.removeItem(i, removeItemDuration: removeDuration);
      }
    }
    // Detect added items
    for (int i = 0; i < newList.length; i++) {
      if (oldList.indexWhere((element) => isSameItem(newList[i], element)) ==
          -1) {
        listKey.currentState!.insertItem(i, insertDuration: insertDuration);
      }
    }
  }

  @nonVirtual
  @protected
  Widget insertAnimationBuilder(
      BuildContext context, Widget child, Animation<double> animation) {
    if (widget.insertItemBuilder != null) {
      return widget.insertItemBuilder!(child, animation);
    } else {
      Widget animatedChild = child;
      for (EffectEntry entry in _enterAnimations) {
        animatedChild = entry.animationEffect
            .build(context, animatedChild, animation, entry, insertDuration);
      }
      return animatedChild;
    }
  }

  @nonVirtual
  @protected
  Widget removeAnimationBuilder(
      BuildContext context, Widget child, Animation<double> animation) {
    if (widget.removeItemBuilder != null) {
      return widget.removeItemBuilder!(child, animation);
    } else {
      Widget animatedChild = child;
      for (EffectEntry entry in _exitAnimations) {
        animatedChild = entry.animationEffect
            .build(context, animatedChild, animation, entry, removeDuration);
      }
      return animatedChild;
    }
  }
}
