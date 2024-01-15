import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';

import 'motion_animated_builder.dart';


class MotionListImpl<E extends Object> extends MotionListBase<Widget, E> {
  const MotionListImpl({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
    ReorderCallback? onReorder,
    void Function(int)? onReorderStart,
    void Function(int)? onReorderEnd,
    ReorderItemProxyDecorator? proxyDecorator,
    List<AnimationEffect>? enterTransition,
    List<AnimationEffect>? exitTransition,
    Duration? insertDuration,
    Duration? removeDuration,
    Axis? scrollDirection,
    EqualityChecker<E>? areItemsTheSame,
  }) : super(
          key: key,
          items: items,
          itemBuilder: itemBuilder,
          insertDuration: insertDuration,
          removeDuration: removeDuration,
          enterTransition: enterTransition,
          exitTransition: exitTransition,
          scrollDirection: scrollDirection,
          areItemsTheSame: areItemsTheSame,
        );
            key: key,
            items: items,
            itemBuilder: itemBuilder,
            onReorder: onReorder,
            onReorderStart: onReorderStart,
            onReorderEnd: onReorderEnd,
            proxyDecorator: proxyDecorator,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            scrollDirection: scrollDirection,
            areItemsTheSame: areItemsTheSame,
            insertAnimationType: insertAnimationType,
            removeAnimationType: removeAnimationType);

  const MotionListImpl.grid({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
    required SliverGridDelegate sliverGridDelegate,
    List<AnimationEffect>? enterTransition,
    List<AnimationEffect>? exitTransition,
    ReorderCallback? onReorder,
    void Function(int)? onReorderStart,
    void Function(int)? onReorderEnd,
    ReorderItemProxyDecorator? proxyDecorator,

    Duration? insertDuration,
    Duration? removeDuration,
    Axis? scrollDirection,
  }) : super(
          key: key,
          items: items,
          itemBuilder: itemBuilder,
          sliverGridDelegate: sliverGridDelegate,
          enterTransition: enterTransition,
          exitTransition: exitTransition,
          insertDuration: insertDuration,
          removeDuration: removeDuration,
          scrollDirection: scrollDirection,
        );
            key: key,
            items: items,
            itemBuilder: itemBuilder,
            onReorder: onReorder,
            onReorderStart: onReorderStart,
            onReorderEnd: onReorderEnd,
            proxyDecorator: proxyDecorator,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            scrollDirection: scrollDirection,
            sliverGridDelegate: sliverGridDelegate,
            insertAnimationType: insertAnimationType,
            removeAnimationType: removeAnimationType);

  @override
  MotionListImplState<E> createState() => MotionListImplState<E>();
}

class MotionListImplState<E extends Object>
    extends MotionListBaseState<Widget, MotionListImpl<E>, E> {

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasOverlay(context));
    return MotionBuilder(
      key: listKey,
      initialCount: oldList.length,
      onReorder: onReorder,
      onReorderStart: onReorderStart,
      onReorderEnd: onReorderEnd,
      proxyDecorator: proxyDecorator,
      insertAnimationBuilder: insertItemBuilder,
      removeAnimationBuilder: removeItemBuilder,
      itemBuilder: itemBuilder,
      scrollDirection: scrollDirection,
      delegateBuilder: sliverGridDelegate,
    );
  }
}
