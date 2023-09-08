import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:motion_list/src/animation_provider.dart';
import 'package:motion_list/src/animation_type.dart';

typedef WidgetBuilder<E>= Widget Function(BuildContext context, E item);
typedef InsertItemBuilder<E> = Widget Function(
    BuildContext context, Animation<double> animation,Widget child);
typedef RemoveItemBuilder<E> = Widget Function(
    BuildContext context, Animation<double> animation,Widget child);
typedef EqualityChecker<E> = bool Function(E, E);

class SliverMotionList<E> extends StatefulWidget {
  final List<E> items;
  final WidgetBuilder builder;
  final InsertItemBuilder insertItemBuilder;
  final RemoveItemBuilder removeItemBuilder;
  final EqualityChecker<E>? areItemsTheSame;
  final AnimationType insertAnimation;
  final AnimationType? removeAnimation;

  const SliverMotionList(
      {Key? key,
        required this.builder,
      required this.items,
      required this.removeItemBuilder,
      required this.insertItemBuilder,
        required this.insertAnimation,
        this.removeAnimation,
      this.areItemsTheSame})
      : super(key: key);

  static SliverMotionList<Widget> fromKeyedWidgetList(
      {required List<Widget> children,
        required WidgetBuilder builder,
      required InsertItemBuilder insertItemBuilder,
      required RemoveItemBuilder removeItemBuilder,
        required AnimationType insertAnimation,
        AnimationType removeAnimation= AnimationType.sizeIn,
      Duration insertDuration = const Duration(milliseconds: 300),
      Duration removeDuration = const Duration(milliseconds: 300)}) {
    if (kDebugMode) {
      final keys = <Key?>{};
      for (final child in children) {
        if (!keys.add(child.key)) {
          throw FlutterError(
            'DiffUtilSliverList.fromKeyedWidgetList called with widgets that do not contain unique keys! '
            'This is an error as changed is this list cannot be animated reliably. Use unique keys or the default constructor'
            ' This duplicate key was ${child.key} in widget $child. ',
          );
        }
      }

    }
    return SliverMotionList<Widget>(
      items: children,
      builder: builder,
      removeItemBuilder: removeItemBuilder,
      insertItemBuilder: insertItemBuilder,
      insertAnimation: insertAnimation,
      areItemsTheSame: (a, b) => a.key == b.key,
    );
  }

  @override
  SliverMotionListState<E> createState() => SliverMotionListState<E>();
}

class SliverMotionListState<E> extends State<SliverMotionList<E>> {
  late GlobalKey<SliverAnimatedListState> listkey;
  late List<E> oldList;
  late InsertItemBuilder insertItemBuilder;
  late  RemoveItemBuilder removeItemBuilder;

  @override
  void initState() {
    super.initState();
    listkey = GlobalKey<SliverAnimatedListState>();
    oldList = List.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant SliverMotionList<E> oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAnimatedList(
          key: listkey,
          initialItemCount: widget.items.length,
          itemBuilder:
              (BuildContext context, int index, Animation<double> animation) =>
              AnimationProvider.buildAnimation(widget.insertAnimation, widget.builder(context,widget.items[index]),
                  animation)
        ),
      ],

    );
  }

  void _onChanged(int position, Object? payLoad, final List<E?> tmpList) {
    listkey.currentState!.removeItem(
        position, (context, animation) => const SizedBox.shrink(),
        duration: const Duration(milliseconds: 1000));
    _onInserted(position, 1, tmpList);
  }

  void _onInserted(
      final int position, final int count, final List<E?> tmpList) {
    for (var loopCount = 0; loopCount < count; loopCount++) {
      listkey.currentState!.insertItem(position + loopCount,duration: const Duration(milliseconds: 1000));
    }
    tmpList.insertAll(position, List<E?>.filled(count, null));
  }

  void _onRemoved(final int position, final int count, final List<E?> tmpList) {
    for (var loopcount = 0; loopcount < count; loopcount++) {
      final oldItem = tmpList[position + loopcount];
      listkey.currentState?.removeItem(
          position,
          (context, animation) =>
              AnimationProvider.buildAnimation(widget.removeAnimation??AnimationType.sizeIn, widget.builder(context,oldItem),
                  animation) ,duration: const Duration(milliseconds: 1000));   }
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
}
