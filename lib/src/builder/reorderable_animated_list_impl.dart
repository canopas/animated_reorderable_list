import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';

import 'reorderable_animated_builder.dart';
import 'reorderable_animated_list_base.dart';

class ReorderableAnimatedListImpl<E extends Object>
    extends ReorderableAnimatedListBase<Widget, E> {
  const ReorderableAnimatedListImpl({
    Key? key,
    required List<E> items,
    required ItemBuilder? itemBuilder,
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
    Duration? dragStartDelay,
    List<E> nonDraggableItems = const [],
    List<E> lockedItems = const [],
    bool enableSwap = true,
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
            isSameItem: isSameItem,
            dragStartDelay: dragStartDelay,
            nonDraggableItems: nonDraggableItems,
            lockedItems: lockedItems,
            enableSwap: enableSwap);

  const ReorderableAnimatedListImpl.grid({
    Key? key,
    required List<E> items,
    required SliverGridDelegate sliverGridDelegate,
    required ItemBuilder itemBuilder,
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
    Duration? dragStartDelay,
    List<E> nonDraggableItems = const [],
    List<E> lockedItems = const [],
    bool enableSwap = true,
  }) : super(
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
            isSameItem: isSameItem,
            dragStartDelay: dragStartDelay,
            nonDraggableItems: nonDraggableItems,
            lockedItems: lockedItems,
            enableSwap: enableSwap);

  @override
  ReorderableAnimatedListImplState<E> createState() =>
      ReorderableAnimatedListImplState<E>();
}

class ReorderableAnimatedListImplState<E extends Object>
    extends ReorderableAnimatedListBaseState<Widget,
        ReorderableAnimatedListImpl<E>, E> {
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasOverlay(context));
    return ReorderableAnimatedBuilder(
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
      dragStartDelay: dragStartDelay,
      nonDraggableIndices: nonDraggableItems,
      lockedIndices: lockedIndices,
    );
  }
}
