import 'package:flutter/cupertino.dart';
import 'package:motion_list/motion_list.dart';

class SliverMotionList<E extends Object> extends StatelessWidget {
  final List<E> items;
  final ItemBuilder itemBuilder;
  final AnimationType insertAnimation;
  final AnimationType? removeAnimation;
  final Axis scrollDirection;
  final Duration insertDuration;
  final Duration removeDuration;
  final Duration resizeDuration;
  final EqualityChecker? areItemsTheSame;

  const SliverMotionList({Key? key,
    required this.items,
    required this.itemBuilder,
    this.insertAnimation = AnimationType.fadeIn,
    this.removeAnimation,
    this.insertDuration = const Duration(milliseconds: 300),
    this.removeDuration = const Duration(milliseconds: 300),
    this.resizeDuration = const Duration(milliseconds: 300),
    this.scrollDirection = Axis.vertical,
    this.areItemsTheSame}):super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
        scrollDirection: scrollDirection,
        slivers: [
          CustomMotionList(
            items: items,
            itemBuilder: itemBuilder,
            insertAnimationType: insertAnimation,
            removeAnimationType: removeAnimation ?? insertAnimation,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            resizeDuration: resizeDuration,
            areItemsTheSame: areItemsTheSame,
            scrollDirection: scrollDirection,
          ),
        ]
    );
  }
}
