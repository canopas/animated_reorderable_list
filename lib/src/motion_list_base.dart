import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:motion_list/motion_list.dart';

typedef InsertItemBuilder<W extends Widget, E> = W Function(
    BuildContext context, AnimationType animationType, E item, int i);

typedef RemoveItemBuilder<W extends Widget, E> = W Function(
    BuildContext context, AnimationType animationType, E item);

typedef UpdateItemBuilder<W extends Widget, E> = W Function(
    BuildContext context, AnimationType animationType, int i);

typedef ItemBuilder<W extends Widget, E> = Widget Function(
    BuildContext context, int index);

typedef EqualityChecker<E> = bool Function(E, E);

abstract class MotionListBase<W extends Widget, E extends Object>
    extends StatefulWidget {
  final ItemBuilder<W, E> itemBuilder;
  final InsertItemBuilder<W, E>? insertItemBuilder;
  final RemoveItemBuilder<W, E>? removeItemBuilder;
  final List<E> items;
  final Duration resizeDuration;
  final Duration insertDuration;
  final Duration removeDuration;
  final Axis scrollDirection;
  final AnimationType? insertAnimationType;
  final AnimationType? removeAnimationType;
  final EqualityChecker<E>? areItemsTheSame;
  final SliverGridDelegate? sliverGridDelegate;

  const MotionListBase(
      {Key? key,
      required this.items,
      required this.itemBuilder,
      this.insertItemBuilder,
      this.removeItemBuilder,
      required this.resizeDuration,
      required this.insertDuration,
      required this.removeDuration,
      this.insertAnimationType,
      required this.scrollDirection,
      this.sliverGridDelegate,
      this.removeAnimationType,
      this.areItemsTheSame})
      : super(key: key);
}

abstract class MotionListBaseState<
    W extends Widget,
    B extends MotionListBase<W, E>,
    E extends Object> extends State<B> with TickerProviderStateMixin {
  late List<E> oldList;

  @protected
  GlobalKey<CustomSliverMotionListState> listKey = GlobalKey();

  @nonVirtual
  @protected
  CustomSliverMotionListState get list => listKey.currentState!;

  @nonVirtual
  @protected
  ItemBuilder<W, E> get itemBuilder => widget.itemBuilder;

  // @nonVirtual
  // @protected
  // InsertItemBuilder<W, E>? get insertItemBuilder => widget.insertItemBuilder;
  //
  // @nonVirtual
  // @protected
  // RemoveItemBuilder<W, E>? get removeItemBuilder => widget.removeItemBuilder;

  @nonVirtual
  @protected
  SliverGridDelegate? get sliverGridDelegate => widget.sliverGridDelegate;

  @nonVirtual
  @protected
  Duration get resizeDuration => widget.resizeDuration;

  @nonVirtual
  @protected
  Duration get insertDuration => widget.insertDuration;

  @nonVirtual
  @protected
  Duration get removeDuration => widget.removeDuration;

  @protected
  @nonVirtual
  Axis get scrollDirection => widget.scrollDirection;

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
    final diff = calculateListDiff(oldList, newList,
            detectMoves: false, equalityChecker: widget.areItemsTheSame)
        .getUpdates();
    final tempList = List<E?>.from(oldList);
    for (final update in diff) {
      _onDiffUpdate(update, tempList);
    }
    oldList = List.from(newList);
  }

  void _onChanged(int position, Object? payLoad, final List<E?> tmpList) {
    listKey.currentState!.removeItem(position, removeDuration: removeDuration);
    _onInserted(position, 1, tmpList);
  }

  void _onInserted(
      final int position, final int count, final List<E?> tmpList) {
    for (var loopCount = 0; loopCount < count; loopCount++) {
      listKey.currentState!.insertItem(position,
          insertDuration: insertDuration, resizeDuration: resizeDuration);
    }
    tmpList.insertAll(position, List<E?>.filled(count, null));
  }

  void _onRemoved(final int position, final int count, final List<E?> tmpList) {
    for (var loopcount = 0; loopcount < count; loopcount++) {
      listKey.currentState!.removeItem(position + loopcount,
          removeDuration: removeDuration, resizeDuration: resizeDuration);
    }
    tmpList.removeRange(position, position + count);
  }

  void _onDiffUpdate(DiffUpdate update, List<E?> tmpList) {
    update.when(
        insert: (pos, count) => _onInserted(pos, count, tmpList),
        remove: (pos, count) => _onRemoved(pos, count, tmpList),
        change: (pos, payload) => _onChanged(pos, payload, tmpList),
        move: (_, __) =>
            throw UnimplementedError('Moves are currently not supported'));
  }

  @nonVirtual
  @protected
  Widget insertItemBuilder(BuildContext context,
      Animation<double>? resizeAnimation, int index, Animation<double> animation) {
    return SizeTransition(
      axis: scrollDirection,
      sizeFactor: resizeAnimation ?? kAlwaysCompleteAnimation,
      child: AnimationProvider.buildAnimation(
          insertAnimationType!, itemBuilder(context, index), animation),);
  }

  @nonVirtual
  @protected
  Widget removeItemBuilder(BuildContext context,
      Animation<double>? resizeAnimation, int index, Animation<double> animation) {
    return SizeTransition(
      axis: scrollDirection,
      sizeFactor: resizeAnimation ?? kAlwaysCompleteAnimation,
      child: AnimationProvider.buildAnimation(
          removeAnimationType!, itemBuilder(context, index), animation),);
  }
}
