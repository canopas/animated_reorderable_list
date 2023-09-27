import 'package:flutter/cupertino.dart';
import 'package:motion_list/motion_list.dart';

class CustomMotionList<E extends Object> extends MotionListBase<Widget, E> {
  const CustomMotionList({
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

  @override
  CustomMotionListState<E> createState() => CustomMotionListState<E>();
}

class CustomMotionListState<E extends Object>
    extends MotionListBaseState<Widget, CustomMotionList<E>, E> {
  @override
  Widget build(BuildContext context) {
    return CustomSliverMotionList(
      key: listKey,
      initialCount: oldList.length,
      insertAnimationBuilder: insertItemBuilder,
      removeAnimationBuilder: removeItemBuilder,
    );
  }
}
