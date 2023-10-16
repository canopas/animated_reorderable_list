import 'package:flutter/cupertino.dart';

import '../motion_list.dart';

/// A Flutter AnimatedGridView that animates insertion and removal of the item.
class MotionGridViewBuilder<E extends Object> extends StatelessWidget {
  /// The current list of items that this[MotionGridViewBuilder] should represent.
  final List<E> items;

  ///Called, as needed, to build list item widget
  final ItemBuilder<Widget, E> itemBuilder;

  /// AnimationStyle when item is added in the list.
  final AnimationType insertAnimation;

  /// AnimationStyle when item is removed from the list.
  ///
  /// If not specified, it is same as insertAnimation.
  final AnimationType? removeAnimation;

  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis? scrollDirection;

  /// The duration of the animation when an item was inserted into the list.
  final Duration? insertDuration;

  /// The duration of the animation when an item was removed from the list.
  final Duration? removeDuration;

  /// The duration of the list update its position.
  final Duration? resizeDuration;

  /// Controls the layout of tiles in a grid.
  /// Given the current constraints on the grid,
  /// a SliverGridDelegate computes the layout for the tiles in the grid.
  /// The tiles can be placed arbitrarily,
  /// but it is more efficient to place tiles in roughly in order by scroll offset because grids reify a contiguous sequence of children.
  final SliverGridDelegate sliverGridDelegate;

  ///
  ///Called by the DiffUtil to decide whether two object represent the same Item.
  ///<p>
  ///For example, if your items have unique ids, this method should check their id equality.
  ///
  ///@param oldItemPosition The position of the item in the old list
  ///@param newItemPosition The position of the item in the new list
  ///@return True if the two items represent the same object or false if they are different.
  ///
  final EqualityChecker? areItemsTheSame;

  const MotionGridViewBuilder(
      {Key? key,
      required this.items,
      required this.itemBuilder,
      this.insertAnimation = AnimationType.fadeIn,
      this.removeAnimation,
      this.insertDuration,
      this.removeDuration,
      this.resizeDuration,
      required this.sliverGridDelegate,
      this.scrollDirection = Axis.vertical,
      this.areItemsTheSame})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
        scrollDirection: scrollDirection ?? Axis.vertical,
        slivers: [
          MotionListImpl.grid(
            items: items,
            itemBuilder: itemBuilder,
            insertAnimationType: insertAnimation,
            removeAnimationType: removeAnimation ?? insertAnimation,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            resizeDuration: resizeDuration,
            areItemsTheSame: areItemsTheSame,
            scrollDirection: scrollDirection,
            sliverGridDelegate: sliverGridDelegate,
          ),
        ]);
  }
}
