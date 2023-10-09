import 'package:flutter/cupertino.dart';
import 'package:motion_list/motion_list.dart';

class MotionListImpl<E extends Object> extends MotionListBase<Widget, E> {
  const MotionListImpl({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
    Duration insertDuration = const Duration(milliseconds: 300),
    Duration removeDuration = const Duration(milliseconds: 300),
    Duration resizeDuration = const Duration(milliseconds: 300),
    Axis scrollDirection= Axis.vertical,
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
    Duration insertDuration = const Duration(milliseconds: 300),
    Duration removeDuration = const Duration(milliseconds: 300),
    Duration resizeDuration = const Duration(milliseconds: 300),
    required SliverGridDelegate sliverGridDelegate,
    Axis scrollDirection= Axis.vertical,
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
      isGriView: sliverGridDelegate!=null?true:false,
    );
  }
}
