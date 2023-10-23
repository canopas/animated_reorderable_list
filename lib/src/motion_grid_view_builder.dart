import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

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
  final Axis scrollDirection;

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

  /// {@template flutter.widgets.scroll_view.reverse}
  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the scroll view scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the scroll view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  /// {@endtemplate}
  final bool reverse;

  /// [ScrollController] to get the current scroll position.
  final ScrollController? controller;

  /// When this is true, the scroll view is scrollable even if it does not have
  /// sufficient content to actually scroll. Otherwise, by default the user can
  /// only scroll the view if it has sufficient content. See [physics].
  final bool? primary;
  final ScrollPhysics? physics;
  final ScrollBehavior? scrollBehavior;
  final String? restorationId;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final Clip clipBehavior;
  final DragStartBehavior dragStartBehavior;

  const MotionGridViewBuilder(
      {Key? key,
      required this.items,
      required this.itemBuilder,
      this.insertAnimation = AnimationType.fadeIn,
      this.removeAnimation,
      this.insertDuration = const Duration(milliseconds: 300),
      this.removeDuration = const Duration(milliseconds: 300),
      this.resizeDuration = const Duration(milliseconds: 300),
      required this.sliverGridDelegate,
      this.scrollDirection = Axis.vertical,
        this.controller,
        this.reverse=false,
      this.areItemsTheSame,
      this.primary,
      this.physics,
      this.scrollBehavior,
      this.restorationId,
      this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
      this.dragStartBehavior = DragStartBehavior.start,
      this.clipBehavior = Clip.hardEdge})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
        scrollDirection: scrollDirection,
        reverse: reverse,
        controller: controller,
        primary: primary,
        physics: physics,
        scrollBehavior: scrollBehavior,
        restorationId: restorationId,
        keyboardDismissBehavior: keyboardDismissBehavior,
        dragStartBehavior: dragStartBehavior,
        clipBehavior: clipBehavior,
        slivers: [
      MotionListImpl.grid(
        items: items,
        itemBuilder: itemBuilder,
        insertAnimationType: insertAnimation,
        removeAnimationType: removeAnimation ?? insertAnimation,
        insertDuration: insertDuration!,
        removeDuration: removeDuration!,
        resizeDuration: resizeDuration!,
        areItemsTheSame: areItemsTheSame,
        scrollDirection: scrollDirection,
        sliverGridDelegate: sliverGridDelegate,
      ),
    ]);
  }
}
