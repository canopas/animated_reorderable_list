import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';

import 'motion_animated_builder.dart';
import 'motion_list_base.dart';

class MotionListImpl<E extends Object> extends MotionListBase<Widget, E> {
  const MotionListImpl({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
    List<AnimationEffect>? enterTransition,
    List<AnimationEffect>? exitTransition,
    Duration? insertDuration,
    Duration? removeDuration,
    ReorderCallback? onReorder,
    void Function(int)? onReorderStart,
    void Function(int)? onReorderEnd,
    ReorderItemProxyDecorator? proxyDecorator,
    required Axis scrollDirection,
    AnimatedWidgetBuilder? insertItemBuilder,
    AnimatedWidgetBuilder? removeItemBuilder,
    bool? buildDefaultDragHandles,
    bool? longPressDraggable,
    bool Function(E a, E b)? isSameItem,
  }) : super(
            key: key,
            items: items,
            itemBuilder: itemBuilder,
            enterTransition: enterTransition,
            exitTransition: exitTransition,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            onReorder: onReorder,
            onReorderStart: onReorderStart,
            onReorderEnd: onReorderEnd,
            proxyDecorator: proxyDecorator,
            scrollDirection: scrollDirection,
            insertItemBuilder: insertItemBuilder,
            removeItemBuilder: removeItemBuilder,
            buildDefaultDragHandles: buildDefaultDragHandles,
            longPressDraggable: longPressDraggable,
            isSameItem: isSameItem);

  const MotionListImpl.grid(
      {Key? key,
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
      required Axis scrollDirection,
      AnimatedWidgetBuilder? insertItemBuilder,
      AnimatedWidgetBuilder? removeItemBuilder,
      bool? buildDefaultDragHandles,
      bool? longPressDraggable,
      bool Function(E a, E b)? isSameItem,
      })
      : super(
            key: key,
            items: items,
            itemBuilder: itemBuilder,
            sliverGridDelegate: sliverGridDelegate,
            enterTransition: enterTransition,
            exitTransition: exitTransition,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            onReorder: onReorder,
            onReorderStart: onReorderStart,
            onReorderEnd: onReorderEnd,
            proxyDecorator: proxyDecorator,
            scrollDirection: scrollDirection,
            insertItemBuilder: insertItemBuilder,
            removeItemBuilder: removeItemBuilder,
            buildDefaultDragHandles: buildDefaultDragHandles,
            longPressDraggable: longPressDraggable,
             isSameItem: isSameItem
  );

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
      insertAnimationBuilder: insertAnimationBuilder,
      removeAnimationBuilder: removeAnimationBuilder,
      itemBuilder: itemBuilder,
      scrollDirection: scrollDirection,
      delegateBuilder: sliverGridDelegate,
      buildDefaultDragHandles: buildDefaultDragHandles,
      longPressDraggable: longPressDraggable,
    );
  }
}
