import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:motion_list/motion_list.dart';

import 'motion_animated_builder.dart';

typedef ItemBuilder<W extends Widget, E> = Widget Function(
    BuildContext context, int index);

typedef RemovedItemBuilder<W extends Widget, E> = Widget Function(
    BuildContext context, E item);

typedef EqualityChecker<E> = bool Function(E, E);

const Duration _kInsertItemDuration = Duration(milliseconds: 300);

const Duration _kRemoveItemDuration = Duration(milliseconds: 300);

abstract class MotionListBase<W extends Widget, E extends Object>
    extends StatefulWidget {
  final ItemBuilder<W, E> itemBuilder;
  final RemovedItemBuilder<W, E>? removedItemBuilder;
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
      this.removedItemBuilder,
      this.resizeDuration,
      this.insertDuration,
      this.removeDuration,
      this.insertAnimationType,
      this.scrollDirection,
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
  GlobalKey<MotionBuilderState> listKey = GlobalKey();

  @nonVirtual
  @protected
  MotionBuilderState get list => listKey.currentState!;

  @nonVirtual
  @protected
  ItemBuilder<W, E> get itemBuilder => widget.itemBuilder;

  @nonVirtual
  @protected
  RemovedItemBuilder<W, E>? get removedItemBuilder => widget.removedItemBuilder;

  @nonVirtual
  @protected
  SliverGridDelegate? get sliverGridDelegate => widget.sliverGridDelegate;

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

  // @override
  // void didUpdateWidget(covariant B oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   final newList = widget.items;
  //   _calcDiff(oldList, newList);
  //
  //  // oldList = List.from(newList);
  // }
  @override
  void didUpdateWidget(covariant B oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newList = widget.items;
    calculateDiff(oldList, newList);
    oldList = List.from(newList);
  }

  void calculateDiff<E>(List oldList, List newList) {
    // Detect removed and updated items
    for (int i = 0; i < oldList.length; i++) {
      if (!newList.contains(oldList[i])) {
        listKey.currentState!.removeItem(i, (context, animation) {
          final item = oldList[i];
          return removedItemBuilder?.call(context, item) ??
              itemBuilder(context, i);
        }, removeItemDuration: removeDuration);
      }
      // else if (i < newList.length && oldList[i] != newList[i]) {
      //     updatedIndices.add(UpdateIndex(oldIndex: i, newIndex: newList.indexOf(oldList[i])));
      //   }
    }
    // Detect added items
    for (int i = 0; i < newList.length; i++) {
      if (!oldList.contains(newList[i])) {
        listKey.currentState!.insertItem(i, insertDuration: insertDuration);
      }
    }
  }

  void _onChanged(int position, Object? payLoad) {
    _onInserted(position, 1);
  }

  void _onInserted(final int position, final int count) {
    for (var i = 0; i < count; i++) {
      listKey.currentState!
          .insertItem(position, insertDuration: insertDuration);
    }
  }

  void _onRemoved(final int position, final int count) {
    for (var i = 0; i < count; i++) {
      final index = position + i;
      final item = oldList[index];
      listKey.currentState!.removeItem(index, (context, animation) {
        return removedItemBuilder?.call(context, item) ??
            itemBuilder(context, index);
      }, removeItemDuration: removeDuration);
    }
  }

  void _onDiffUpdate(DiffUpdate update) {
    update.when(
        insert: (pos, count) => _onInserted(pos, count),
        remove: (pos, count) => _onRemoved(pos, count),
        change: (pos, payload) => _onChanged(pos, payload),
        move: (_, __) =>
            throw UnimplementedError('Moves are currently not supported'));
  }

  @nonVirtual
  @protected
  Widget insertItemBuilder(
      BuildContext context, Widget child, Animation<double> animation) {
    return AnimationProvider.buildAnimation(
        insertAnimationType!, child, animation);
  }

  @nonVirtual
  @protected
  Widget removeItemBuilder(
      BuildContext context, Widget child, Animation<double> animation) {
    return AnimationProvider.buildAnimation(
        removeAnimationType!, child, animation);
  }
}
