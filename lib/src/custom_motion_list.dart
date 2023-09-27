import 'package:flutter/cupertino.dart';
import 'package:motion_list/motion_list.dart';

class CustomMotionList<E extends Object> extends MotionListBase<Widget, E> {
  const CustomMotionList({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
    Duration insertDuration = const Duration(milliseconds: 500),
    Duration removeDuration = const Duration(milliseconds: 500),
    Duration resizeDuration = const Duration(milliseconds: 500),
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
      insertAnimationType: insertAnimationType!,
      removeAnimationType: removeAnimationType!,
      // itemBuilder: (BuildContext context, int i) {
      //   return buildItem(context,i);
      // },
      animatedWidgetBuilder: (BuildContext context,
          Animation<double>? resizeAnimation,
          Animation<double> animation,
          int index) {
        return buildItem(context, resizeAnimation, index, animation);
      },
    );
  }
}
