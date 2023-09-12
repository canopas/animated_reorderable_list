import 'package:flutter/cupertino.dart';
import 'package:motion_list/motion_list.dart';
import 'package:motion_list/src/custom_sliver_motion_list.dart';
import 'package:motion_list/src/motion_list_base.dart';

import '../provider/animation_type.dart';

class CustomMotionList<E extends Object> extends MotionListBase<Widget, E> {
  CustomMotionList({
    Key? key,
    required List<E> items,
    required ItemBuilder<E> itemBuilder,
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
          // animatedItemBuilder: (BuildContext context, int index, Animation<double> animation) {
          //   if(insertAnimationType!=null){
          //   return insertItemBuilder!(context, widget.insertAnimationType!,widget.builder(context, widget.items[index]), index );
          // },
          itemBuilder: (BuildContext context, int i) {
            return itemBuilder(context,i);
          },),
      ],
    );
  }
}
