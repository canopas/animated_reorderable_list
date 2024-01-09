import 'package:flutter/cupertino.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'motion_animated_builder.dart';


class MotionListImpl<E extends Object> extends MotionListBase<Widget, E> {
  const MotionListImpl({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
   required ReorderCallback onReorder,
   void Function(int)? onReorderStart,
   void Function(int)? onReorderEnd,
    Duration? insertDuration,
    Duration? removeDuration,
    Axis? scrollDirection,
    AnimationType? insertAnimationType,
    AnimationType? removeAnimationType,
    EqualityChecker<E>? areItemsTheSame,
  }) : super(
            key: key,

            items: items,
            itemBuilder: itemBuilder,
            onReorder: onReorder,
            onReorderStart: onReorderStart,
            onReorderEnd: onReorderEnd,
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
    required ReorderCallback onReorder,
    void Function(int)? onReorderStart,
    void Function(int)? onReorderEnd,
    Duration? insertDuration,
    Duration? removeDuration,
    Axis? scrollDirection,
    AnimationType? insertAnimationType,
    AnimationType? removeAnimationType,
  }) : super(
            key: key,
            items: items,
            itemBuilder: itemBuilder,
            onReorder: onReorder,
            onReorderStart: onReorderStart,
            onReorderEnd: onReorderEnd,
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
    return MotionBuilder(
      key: listKey,
      initialCount: oldList.length,
      onReorder: onReorder,
      onReorderStart: onReorderStart,
      onReorderEnd: onReorderEnd,
      insertAnimationBuilder: insertItemBuilder,
      removeAnimationBuilder: removeItemBuilder,
      itemBuilder: itemBuilder,
      scrollDirection: scrollDirection,
      delegateBuilder: sliverGridDelegate,
    );
  }
}
