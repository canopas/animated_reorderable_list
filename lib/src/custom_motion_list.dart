import 'package:flutter/cupertino.dart';
import 'package:motion_list/motion_list.dart';


class CustomMotionList<E extends Object> extends MotionListBase<Widget, E> {
  const CustomMotionList({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
    InsertItemBuilder<Widget, E>? insertItemBuilder,
    RemoveItemBuilder<Widget, E>? removeItemBuilder,
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
      insertItemBuilder: insertItemBuilder,
      removeItemBuilder: removeItemBuilder,
      insertDuration: insertDuration,
      removeDuration: removeDuration,
      resizeDuration: resizeDuration,
      areItemsTheSame: areItemsTheSame,
      insertAnimationType: insertAnimationType,
      removeAnimationType: removeAnimationType);

  @override
  _CustomMotionListState<E> createState() => _CustomMotionListState<E>();
}

class _CustomMotionListState<E extends Object>
    extends MotionListBaseState<Widget, CustomMotionList<E>, E> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CustomSliverMotionList(
          key: listKey,
          initialCount: oldList.length,
          insertAnimationType:  insertAnimationType!,
          itemBuilder: (BuildContext context, int i) {
            return itemBuilder(context,i);
          },
        ),
      ],
    );
  }
}
