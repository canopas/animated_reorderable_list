import 'package:flutter/cupertino.dart';
import 'package:motion_list/motion_list.dart';

import 'motion_builder.dart';

class MotionListImpl<E extends Object> extends MotionListBase<Widget, E> {
  const MotionListImpl({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
    RemovedItemBuilder? removedItemBuilder,
    Duration? insertDuration,
    Duration? removeDuration,
    Duration? resizeDuration,
    Axis? scrollDirection,
    AnimationType? insertAnimationType,
    AnimationType? removeAnimationType,
    EqualityChecker<E>? areItemsTheSame,
  }) : super(
      key: key,
            items: items,
            itemBuilder: itemBuilder,
            removedItemBuilder: removedItemBuilder,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            resizeDuration: resizeDuration,
            scrollDirection: scrollDirection,
            areItemsTheSame: areItemsTheSame,
            insertAnimationType: insertAnimationType,
            removeAnimationType: removeAnimationType);

  const MotionListImpl.grid({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
    required SliverGridDelegate sliverGridDelegate,
    RemovedItemBuilder? removedItemBuilder,
    Duration? insertDuration,
    Duration? removeDuration,
    Duration? resizeDuration,
    Axis? scrollDirection,
    AnimationType? insertAnimationType,
    AnimationType? removeAnimationType,
    EqualityChecker<E>? areItemsTheSame,
  }) : super(
      key: key,
            items: items,
            itemBuilder: itemBuilder,
            removedItemBuilder: removedItemBuilder,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            resizeDuration: resizeDuration,
            scrollDirection: scrollDirection,
            areItemsTheSame: areItemsTheSame,
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
      insertAnimationBuilder: insertItemBuilder,
      removeAnimationBuilder: removeItemBuilder,
      itemBuilder: itemBuilder,
      delegateBuilder: sliverGridDelegate,
      //isGriView: sliverGridDelegate != null ? true : false,
    );
  }
}
