import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import '../../animated_reorderable_list.dart';
import 'builder/motion_list_base.dart';
import 'builder/motion_list_impl.dart';

///  enterTransition: [FadeEffect(), ScaleEffect()],
///
/// Effects are always run in parallel (ie. the fade and scale effects in the
/// example above would be run simultaneously), but you can apply delays to
/// offset them or run them in sequence.
///
/// A Flutter AnimatedGridView that animates insertion and removal of the item.
class AnimatedGridView<E extends Object> extends StatelessWidget {
  /// The current list of items that this[MotionGridViewBuilder] should represent.
  final List<E> items;

  ///Called, as needed, to build list item widget
  final ItemBuilder<Widget, E> itemBuilder;

  /// Controls the layout of tiles in a grid.
  /// Given the current constraints on the grid,
  /// a SliverGridDelegate computes the layout for the tiles in the grid.
  /// The tiles can be placed arbitrarily,
  /// but it is more efficient to place tiles in roughly in order by scroll offset because grids reify a contiguous sequence of children.
  final SliverGridDelegate sliverGridDelegate;

  /// A list of [AnimationEffect](s) used for the appearing animation when an item is added to the list.
  ///
  /// This property controls how newly added items animate into view. The animations in this list
  /// will run sequentially, meaning each effect will be applied one after another in the order
  /// specified. By default, this property uses a single [Fade()] effect.
  ///
  /// ### Default Value
  /// If not explicitly provided, the default animation applied is:
  /// ```dart
  /// [Fade()]
  /// ```
  ///
  /// ### Supported Animations
  /// The following animation effects are supported by the library and can be combined as desired:
  /// - `FadeIn()`: A smooth fade-in animation.
  /// - `FlipInY()`: An animation that flips the item along the Y-axis.
  /// - `FlipInX()`: An animation that flips the item along the X-axis.
  /// - `Landing()`: An animation that mimics a landing effect.
  /// - `SizeAnimation()`: Gradually animates the size of the item.
  /// - `ScaleIn()`: A scaling animation where the item grows into view.
  /// - `ScaleInTop()`: A scaling effect originating from the top.
  /// - `ScaleInBottom()`: A scaling effect originating from the bottom.
  /// - `ScaleInLeft()`: A scaling effect originating from the left.
  /// - `ScaleInRight()`: A scaling effect originating from the right.
  /// - `SlideInLeft()`: A sliding animation from the left.
  /// - `SlideInRight()`: A sliding animation from the right.
  /// - `SlideInUp()`: A sliding animation from the bottom to the top.
  /// - `SlideInDown()`: A sliding animation from the top to the bottom.
  ///
  /// ### Custom Animations
  /// In addition to the predefined animations listed above, you can create custom configurations
  /// for each animation to suit your specific needs. For example, you can adjust the duration,
  /// curve, or other parameters for finer control:
  /// ```dart
  /// enterTransition: [
  ///   FadeIn(duration: Duration(milliseconds: 500), curve: Curves.easeIn),
  ///   SlideInLeft(delay: Duration(milliseconds: 200)),
  /// ],
  /// ```
  ///
  final List<AnimationEffect>? enterTransition;

  ///List of [AnimationEffect] used for the disappearing animation when item is removed from list.
  ///
  ///Defaults to [FadeAnimation()]
  final List<AnimationEffect>? exitTransition;

  /// The duration of the animation when an item was inserted into the list.
  ///
  /// If you provide a specific duration for each AnimationEffect, it will override this [insertDuration].
  final Duration? insertDuration;

  /// The duration of the animation when an item was removed from the list.
  ///
  /// If you provide a specific duration for each AnimationEffect, it will override this [removeDuration].
  final Duration? removeDuration;

  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// {@template flutter.widgets.reorderable_list.padding}
  /// The amount of space by which to inset the list contents.
  ///
  /// It defaults to `EdgeInsets.all(0)`.
  /// {@endtemplate}
  final EdgeInsetsGeometry? padding;

  /// {@macro flutter.widgets.scroll_view.reverse}
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

  /// A custom builder that is for adding items with animations.
  ///
  /// The child argument is the widget that is returned by [itemBuilder],
  ///  and the `animation` is an [Animation] that should be used to animate an exit
  /// transition for the widget that is built.
  final AnimatedWidgetBuilder? insertItemBuilder;

  /// A custom builder that is for removing items with animations.
  ///
  /// The child argument is the widget that is returned by [itemBuilder],
  ///  and the `animation` is an [Animation] that should be used to animate an exit
  /// transition for the widget that is built.
  final AnimatedWidgetBuilder? removeItemBuilder;

  /// Whether the extent of the scroll view in the scrollDirection should be determined by the contents being viewed.
  final bool shrinkWrap;

  /// A callback function to determine if two items in the list are considered the same.
  ///
  /// This function is important to prevent unnecessary animations when editing or updating items.
  /// For example, if your items have a unique `id`, you can use this function to compare them
  /// and return `true`, indicating they represent the same item.
  ///
  ///
  /// **Why is this important?**
  ///
  /// If `isSameItem` is not defined and you are working with immutable objects (e.g., creating new
  /// instances on every update), the library may interpret these as different items. This will
  /// trigger animations unnecessarily. Additionally, if you are generating `Key` values directly
  /// from these instances, it can result in the following exception:
  ///
  /// `Multiple widgets used the same GlobalKey.`
  ///
  /// To avoid this exception, you must implement the `isSameItem` callback to accurately compare
  /// the identity of the items in your list.
  ///
  /// Example:
  /// ```dart
  /// isSameItem: (a, b) => a.id == b.id,
  /// ```
  final bool Function(E a, E b) isSameItem;

  /// Whether to enable swap animation when changing the order of the items.
  ///
  /// Defaults to true.
  final bool enableSwap;

  /// Creates a [AnimatedGridView] that animates insertion and removal of the item.
  const AnimatedGridView(
      {Key? key,
      required this.items,
      required this.itemBuilder,
      required this.sliverGridDelegate,
      this.enterTransition,
      this.exitTransition,
      this.insertDuration,
      this.removeDuration,
      this.padding,
      this.scrollDirection = Axis.vertical,
      this.reverse = false,
      this.controller,
      this.primary,
      this.physics,
      this.scrollBehavior,
      this.restorationId,
      this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
      this.dragStartBehavior = DragStartBehavior.start,
      this.clipBehavior = Clip.hardEdge,
      this.insertItemBuilder,
      this.removeItemBuilder,
      this.shrinkWrap = false,
      required this.isSameItem,
      this.enableSwap = true})
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
        shrinkWrap: shrinkWrap,
        slivers: [
          SliverPadding(
            padding: padding ?? EdgeInsets.zero,
            sliver: MotionListImpl.grid(
                items: items,
                itemBuilder: itemBuilder,
                sliverGridDelegate: sliverGridDelegate,
                insertDuration: insertDuration,
                removeDuration: removeDuration,
                enterTransition: enterTransition,
                exitTransition: exitTransition,
                scrollDirection: scrollDirection,
                insertItemBuilder: insertItemBuilder,
                removeItemBuilder: removeItemBuilder,
                isSameItem: isSameItem,
                enableSwap: enableSwap),
          ),
        ]);
  }
}
