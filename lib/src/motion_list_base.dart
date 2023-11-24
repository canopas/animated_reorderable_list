import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:motion_list/motion_list.dart';

typedef ItemBuilder<W extends Widget, E> = Widget Function(
    BuildContext context, int index);

typedef EqualityChecker<E> = bool Function(E, E);

const Duration _kInsertItemDuration = Duration(milliseconds: 300);

const Duration _kRemoveItemDuration = Duration(milliseconds: 300);

const Duration _kResizeDuration = Duration(milliseconds: 300);

abstract class MotionListBase<W extends Widget, E extends Object>
    extends StatefulWidget {
  final ItemBuilder<W, E> itemBuilder;
  final List<E> items;
  final Duration? resizeDuration;
  final Duration? insertDuration;
  final Duration? removeDuration;
  final Axis? scrollDirection;
  final AnimationType? insertAnimationType;
  final AnimationType? removeAnimationType;
  final EqualityChecker<E>? areItemsTheSame;
  final SliverGridDelegate? sliverGridDelegate;

  const MotionListBase(
      {Key? key,
      required this.items,
      required this.itemBuilder,
      this.resizeDuration,
      this.insertDuration,
      this.removeDuration,
      this.insertAnimationType,
      this.scrollDirection,
      this.sliverGridDelegate,
      this.removeAnimationType,
      this.areItemsTheSame})
      : super(key: key);

  static MotionListBaseState of(BuildContext context) {
    final MotionListBaseState? result =
        context.findAncestorStateOfType<MotionListBaseState>();
    assert(() {
      if (result == null) {
        throw FlutterError(
          'MotionAnimationBuilderState.of() called with a context that does not contain a MotionAnimationBuilderState.\n'
          'No MotionAnimationBuilderState ancestor could be found starting from the '
          'context that was passed to MotionAnimationBuilderState.of(). This can '
          'happen when the context provided is from the same StatefulWidget that '
          'built the AnimatedList.'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return result!;
  }
}

abstract class MotionListBaseState<
    W extends Widget,
    B extends MotionListBase<W, E>,
    E extends Object> extends State<B> with TickerProviderStateMixin {
  late List<E> oldList;

  @protected
  GlobalKey<MotionAnimationBuilderState> listKey = GlobalKey();

  @nonVirtual
  @protected
  MotionAnimationBuilderState get list => listKey.currentState!;

  @nonVirtual
  @protected
  ItemBuilder<W, E> get itemBuilder => widget.itemBuilder;

  @nonVirtual
  @protected
  SliverGridDelegate? get sliverGridDelegate => widget.sliverGridDelegate;

  @nonVirtual
  @protected
  Duration get resizeDuration => widget.resizeDuration ?? _kResizeDuration;

  @nonVirtual
  @protected
  Duration get insertDuration => widget.insertDuration ?? _kInsertItemDuration;

  @nonVirtual
  @protected
  Duration get removeDuration => widget.removeDuration ?? _kRemoveItemDuration;

  @protected
  @nonVirtual
  Axis get scrollDirection => widget.scrollDirection ?? Axis.vertical;

  @nonVirtual
  @protected
  AnimationType? get insertAnimationType => widget.insertAnimationType;

  @nonVirtual
  @protected
  AnimationType? get removeAnimationType => widget.removeAnimationType;

  late final resizeAnimController = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    oldList = List.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant B oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newList = widget.items;
    _calcDiff(oldList, newList);
  }

  void _calcDiff(List<E> oldList, List<E> newList) {
    for (int i = 0; i < oldList.length; i++) {
      if (!newList.contains(oldList[i])) {
        listKey.currentState!.removeItem(i,
            removeDuration: removeDuration, resizeDuration: resizeDuration);
        oldList.removeAt(i);
      }
    }
    for (int i = 0; i < newList.length; i++) {
      if (!oldList.contains(newList[i])) {
        listKey.currentState!.insertItem(i,
            insertDuration: insertDuration, resizeDuration: resizeDuration);
        oldList.insert(i, newList[i]);
      }
    }
  }

  @nonVirtual
  @protected
  Widget insertItemBuilder(
      BuildContext context,
      Animation<double>? resizeAnimation,
      int index,
      Animation<double> animation) {
    return SizeTransition(
      key: ValueKey(index),
      axis: scrollDirection,
      sizeFactor: resizeAnimation ?? kAlwaysCompleteAnimation,
      child: AnimationProvider.buildAnimation(
          insertAnimationType!, itemBuilder(context, index), animation),
    );
  }

  @nonVirtual
  @protected
  Widget removeItemBuilder(
      BuildContext context,
      Animation<double>? resizeAnimation,
      int index,
      Animation<double> animation) {
    return SizeTransition(
      key: ValueKey(index),
      axis: scrollDirection,
      sizeFactor: resizeAnimation ?? kAlwaysCompleteAnimation,
      child: AnimationProvider.buildAnimation(
          removeAnimationType!, itemBuilder(context, index), animation),
    );
  }
}
