import 'package:flutter/cupertino.dart';
import 'package:motion_list/motion_list.dart';

class MotionListImpl<E extends Object> extends MotionListBase<Widget, E> {
  const MotionListImpl({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
    required Duration insertDuration,
    required Duration removeDuration,
    required Duration resizeDuration,
    Axis? scrollDirection,
    AnimationType? insertAnimationType,
    AnimationType? removeAnimationType,
    EqualityChecker<E>? areItemsTheSame,
  }) : super(
            key: key,
            items: items,
            itemBuilder: itemBuilder,
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
    required Duration insertDuration,
    required  Duration removeDuration,
   required Duration resizeDuration,
    Axis? scrollDirection,
    AnimationType? insertAnimationType,
    AnimationType? removeAnimationType,
    EqualityChecker<E>? areItemsTheSame,
  }) : super(
            key: key,
            items: items,
            itemBuilder: itemBuilder,
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
    return MotionAnimationBuilder(
      key: listKey,
      initialCount: oldList.length,
      insertAnimationBuilder: insertItemBuilder,
      removeAnimationBuilder: removeItemBuilder,
      delegateBuilder: sliverGridDelegate,
      isGriView: sliverGridDelegate != null ? true : false,
    );
  }
}
