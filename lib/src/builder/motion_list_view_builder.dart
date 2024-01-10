import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';

import 'motion_list_impl.dart';

class MotionListViewBuilder<E extends Object> extends StatelessWidget {
  /// The current list of items that this[MotionListViewBuilder] should represent.
  final List<E> items;

  ///Called, as needed, to build list item widget
  final ItemBuilder itemBuilder;

  /// A callback used by [ReorderableList] to report that a list item has moved
  /// to a new position in the list.
  ///
  /// Implementations should remove the corresponding list item at [oldIndex]
  /// and reinsert it at [newIndex].
  final ReorderCallback? onReorder;

  /// A callback that is called when an item drag has started.
  ///
  /// The index parameter of the callback is the index of the selected item.
  final void Function(int)? onReorderStart;

  /// A callback that is called when the dragged item is dropped.
  ///
  /// The index parameter of the callback is the index where the item is
  /// dropped. Unlike [onReorder], this is called even when the list item is
  /// dropped in the same location.
  final void Function(int)? onReorderEnd;

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
  final Duration insertDuration;

  /// The duration of the animation when an item was removed from the list.
  final Duration removeDuration;

  /// {@template flutter.widgets.reorderable_list.proxyDecorator}
  /// A callback that allows the app to add an animated decoration around
  /// an item when it is being dragged.
  /// {@endtemplate}
  final ReorderItemProxyDecorator? proxyDecorator;

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
  ///
  ///  Must be null if [primary] is true.
  ///
  ///  It can be used to read the current
  //   scroll position (see [ScrollController.offset]), or change it (see
  //   [ScrollController.animateTo]).
  final ScrollController? controller;

  /// When this is true, the scroll view is scrollable even if it does not have
  /// sufficient content to actually scroll. Otherwise, by default the user can
  /// only scroll the view if it has sufficient content. See [physics].
  ///
  /// Cannot be true while a [ScrollController] is provided to `controller`,
  /// only one ScrollController can be associated with a ScrollView.
  ///
  /// Defaults to null.
  final bool? primary;

  /// {@template flutter.widgets.reorderable_list.padding}
  /// The amount of space by which to inset the list contents.
  ///
  /// It defaults to `EdgeInsets.all(0)`.
  /// {@endtemplate}
  final EdgeInsetsGeometry? padding;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions. Furthermore, if [primary] is
  /// false, then the user cannot scroll if there is insufficient content to
  /// scroll, while if [primary] is true, they can always attempt to scroll.
  final ScrollPhysics? physics;

  /// [ScrollBehavior]s also provide [ScrollPhysics]. If an explicit
  /// [ScrollPhysics] is provided in [physics], it will take precedence,
  /// followed by [scrollBehavior], and then the inherited ancestor
  /// [ScrollBehavior].
  final ScrollBehavior? scrollBehavior;

  /// Creates a ScrollView that creates custom scroll effects using slivers.
  /// See the ScrollView constructor for more details on these arguments.
  final String? restorationId;

  /// [ScrollViewKeyboardDismissBehavior] the defines how this [ScrollView] will
  /// dismiss the keyboard automatically.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Defaults to [Clip.hardEdge].
  ///
  /// Creates a ScrollView that creates custom scroll effects using slivers.
  /// See the ScrollView constructor for more details on these arguments.
  final Clip clipBehavior;

  /// Creates a ScrollView that creates custom scroll effects using slivers.
  /// See the ScrollView constructor for more details on these arguments.
  final DragStartBehavior dragStartBehavior;

  const MotionListViewBuilder(
      {Key? key,
      required this.items,
      required this.itemBuilder,
      this.onReorder,
      this.onReorderStart,
      this.onReorderEnd,
      this.proxyDecorator,
      this.insertAnimation = AnimationType.fadeIn,
      this.removeAnimation,
      this.insertDuration = const Duration(milliseconds: 300),
      this.removeDuration = const Duration(milliseconds: 300),
      this.scrollDirection = Axis.vertical,
      this.padding,
      this.reverse = false,
      this.controller,
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
          SliverPadding(
            padding: padding ?? EdgeInsets.zero,
            sliver: MotionListImpl(
              items: items,
              itemBuilder: itemBuilder,
              insertAnimationType: insertAnimation,
              removeAnimationType: removeAnimation ?? insertAnimation,
              onReorder: onReorder,
              onReorderStart: onReorderStart,
              onReorderEnd: onReorderEnd,
              proxyDecorator: proxyDecorator,
              insertDuration: insertDuration,
              removeDuration: removeDuration,
              scrollDirection: scrollDirection,
            ),
          ),
        ]);
  }
}
