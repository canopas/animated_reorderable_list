import 'package:flutter/cupertino.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'builder/reorderable_animated_list_base.dart';
import 'builder/reorderable_animated_list_impl.dart';

/// A Flutter SliverAnimatedListView that animates insertion and removal of the item.
///
///  ```dart
///  enterTransition: [FadeIn(), ScaleIn()],
///  ```
///
/// Effects are always run in parallel (ie. the fade and scale effects in the
/// example above would be run simultaneously), but you can apply delays to
/// offset them or run them in sequence.
///
/// /// All list items must have a key.
class SliverAnimatedListView<E extends Object> extends StatefulWidget {
  /// The current list of items that this[SliverAnimatedListView] should represent.
  final List<E> items;

  /// Called, as needed, to build list item widgets.
  ///
  /// List items are only built when they're scrolled into view.
  ///
  /// The [ItemBuilder] index parameter indicates the item's
  /// position in the list. The value of the index parameter will be between
  /// zero and one less than [items]. All items in the list must have a
  /// unique [Key].
  final ItemBuilder itemBuilder;

  /// A list of [AnimationEffect](s) used for the appearing animation when an item is added to the list.
  ///
  /// This property controls how newly added items animate into view. The animations in this list
  /// will run sequentially, meaning each effect will be applied one after another in the order
  /// specified. By default, this property uses a single [FadeIn()] effect.
  ///
  /// ### Default Value
  /// If not explicitly provided, the default animation applied is:
  /// ```dart
  /// [FadeIn()]
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
  final List<AnimationEffect>? enterTransition;

  /// A list of [AnimationEffect](s) used for the disappearing animation when an item was removed from the list.
  ///
  /// This property controls how item will be removed from the view. The animations in this list
  /// will run sequentially, meaning each effect will be applied one after another in the order
  /// specified. By default, this property uses a single [FadeIn()] effect.
  ///
  /// ### Default Value
  /// If not explicitly provided, the default animation applied is:
  /// ```dart
  /// [FadeIn()]
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
  /// exitTransition: [
  ///   FadeIn(duration: Duration(milliseconds: 500), curve: Curves.easeIn),
  ///   SlideInLeft(delay: Duration(milliseconds: 200)),
  /// ],
  /// ```
  final List<AnimationEffect>? exitTransition;

  /// The duration of the animation when an item is inserted into the list.
  ///
  /// This property defines the default duration for all animations applied to items
  /// when they are added to the list. If you provide a specific duration for each
  /// [AnimationEffect] in the `enterTransition` list, the [insertDuration]
  /// override the durations of all animations in the [enterTransition].
  ///
  /// **Usage:**
  /// - If `insertDuration` is provided, it will override all durations specified
  ///   in the [enterTransition] list.
  /// - If `insertDuration` is not provided, the individual durations defined
  ///   in [enterTransition] will be used instead.
  /// - If neither `insertDuration` nor individual durations are specified, a default
  ///   duration (e.g., `const Duration(milliseconds: 300)`) will be used.
  ///
  /// **Example:**
  /// ```dart
  /// SliverAnimatedListView(
  ///   insertDuration: Duration(milliseconds: 500), // Default duration for item insertions.
  ///   enterTransition: [
  ///     FadeIn(duration: Duration(milliseconds: 300)), // Overrides the default for this effect.
  ///     SlideInLeft(), // Will use the default duration from `insertDuration`.
  ///   ],
  /// );
  /// ```
  /// insertDuration
  final Duration? insertDuration;

  /// The duration of the animation when an item is removed from the list.
  ///
  /// This property defines the default duration for all animations applied to items
  /// when they are removed from the list. If you provide a specific duration for each
  /// [AnimationEffect] in the `exitTransition` list, the [removeDuration]
  /// override the durations of all animations in the [exitTransition].
  ///
  /// **Usage:**
  /// - If `removeDuration` is specified, it will be applied as the default duration
  ///   for the removal animation of items.
  /// - If specific durations are provided for individual `AnimationEffect`s, they take precedence.
  /// - If neither `removeDuration` nor individual durations are specified, a default
  ///   duration (e.g., `const Duration(milliseconds: 300)`) may be used.
  ///
  /// **Example:**
  /// ```dart
  /// SliverAnimatedListView(
  ///   removeDuration: Duration(milliseconds: 400), // Default duration for item removals.
  ///   exitTransition: [
  ///     FadeOut(duration: Duration(milliseconds: 200)), // Overrides the default for this effect.
  ///     SlideOutRight(), // Will use the default duration from `removeDuration`.
  ///   ],
  /// );
  /// ```
  /// `removeDuration` is overridden by the duration specified in the `exitTransition`.
  final Duration? removeDuration;

  /// {@template flutter.widgets.reorderable_list.padding}
  /// The amount of space by which to inset the list contents.
  ///
  /// It defaults to `EdgeInsets.all(0)`.
  /// {@endtemplate}
  final EdgeInsetsGeometry? padding;

  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// A custom builder that is for adding items with animations.
  ///
  /// The `context` argument is the build context where the widget will be
  /// created, the `index` is the index of the item to be built, and the
  /// `animation` is an [Animation] that should be used to animate an entry
  /// transition for the widget that is built.
  final AnimatedWidgetBuilder? insertItemBuilder;

  /// A custom builder that is for removing items with animations.
  ///
  /// The `context` argument is the build context where the widget will be
  /// created, the `index` is the index of the item to be built, and the
  /// `animation` is an [Animation] that should be used to animate an exit
  /// transition for the widget that is built.
  final AnimatedWidgetBuilder? removeItemBuilder;

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
  final bool Function(E a, E b)? isSameItem;

  /// Whether to enable swap animation when changing the order of the items.
  ///
  /// Defaults to true.
  final bool enableSwap;

  /// Creates a [SliverAnimatedListView] that animates insertion and removal of the item.
  const SliverAnimatedListView({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.enterTransition,
    this.exitTransition,
    this.insertDuration,
    this.removeDuration,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.insertItemBuilder,
    this.removeItemBuilder,
    required this.isSameItem,
    this.enableSwap = true,
  }) : super(key: key);

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// If no [SliverAnimatedListViewState] surrounds the given context, then this function
  /// will assert in debug mode and throw an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  static SliverAnimatedListViewState of(BuildContext context) {
    final SliverAnimatedListViewState? result =
        context.findAncestorStateOfType<SliverAnimatedListViewState>();
    assert(() {
      if (result == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'SliverAnimatedListViewState.of() called with a context that does not contain a SliverAnimatedListViewState.'),
          ErrorDescription(
            'No SliverAnimatedListViewState ancestor could be found starting from the context that was passed to SliverAnimatedListViewState.of().',
          ),
          ErrorHint(
              'This can happen when the context provided is from the same StatefulWidget that '
              'built the SliverAnimatedListViewState. '),
          context.describeElement('The context used was'),
        ]);
      }
      return true;
    }());
    return result!;
  }

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// This method is typically used by [SliverAnimatedListViewState] item widgets that insert
  /// or remove items in response to user input.
  ///
  /// If no [SliverAnimatedListViewState] surrounds the context given, then this function will
  /// return null.
  ///
  /// This method can be expensive (it walks the element tree).
  static SliverAnimatedListViewState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<SliverAnimatedListViewState>();
  }

  @override
  State<SliverAnimatedListView<E>> createState() => SliverAnimatedListViewState();
}

class SliverAnimatedListViewState<E extends Object>
    extends State<SliverAnimatedListView<E>> {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: widget.padding ?? EdgeInsets.zero,
      sliver: ReorderableAnimatedListImpl(
        items: widget.items,
        itemBuilder: widget.itemBuilder,
        enterTransition: widget.enterTransition,
        exitTransition: widget.exitTransition,
        insertDuration: widget.insertDuration,
        removeDuration: widget.removeDuration,
        scrollDirection: widget.scrollDirection,
        insertItemBuilder: widget.insertItemBuilder,
        removeItemBuilder: widget.removeItemBuilder,
        isSameItem: widget.isSameItem,
        enableSwap: widget.enableSwap,
      ),
    );
  }
}
