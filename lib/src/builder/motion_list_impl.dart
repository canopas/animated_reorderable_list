import 'package:flutter/cupertino.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'motion_animated_builder.dart';


class MotionListImpl<E extends Object> extends MotionListBase<Widget, E> {
  const MotionListImpl({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
   required ReorderCallback onReorder,
   void Function(int)? onReorderStart,
   void Function(int)? onReorderEnd,
    Duration? insertDuration,
    Duration? removeDuration,
    Axis? scrollDirection,
    AnimationType? insertAnimationType,
    AnimationType? removeAnimationType,
    EqualityChecker<E>? areItemsTheSame,
  }) : super(
            key: key,

            items: items,
            itemBuilder: itemBuilder,
            onReorder: onReorder,
            onReorderStart: onReorderStart,
            onReorderEnd: onReorderEnd,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            scrollDirection: scrollDirection,
            areItemsTheSame: areItemsTheSame,
            insertAnimationType: insertAnimationType,
            removeAnimationType: removeAnimationType);

  const MotionListImpl.grid({
    Key? key,
    required List<E> items,
    required ItemBuilder itemBuilder,
    required SliverGridDelegate sliverGridDelegate,
    required ReorderCallback onReorder,
    void Function(int)? onReorderStart,
    void Function(int)? onReorderEnd,
    Duration? insertDuration,
    Duration? removeDuration,
    Axis? scrollDirection,
    AnimationType? insertAnimationType,
    AnimationType? removeAnimationType,
  }) : super(
            key: key,
            items: items,
            itemBuilder: itemBuilder,
            onReorder: onReorder,
            onReorderStart: onReorderStart,
            onReorderEnd: onReorderEnd,
            insertDuration: insertDuration,
            removeDuration: removeDuration,
            scrollDirection: scrollDirection,
            sliverGridDelegate: sliverGridDelegate,
            insertAnimationType: insertAnimationType,
            removeAnimationType: removeAnimationType);

  @override
  MotionListImplState<E> createState() => MotionListImplState<E>();
}

class MotionListImplState<E extends Object>
    extends MotionListBaseState<Widget, MotionListImpl<E>, E> {

  void startItemDragReorder({required int index, required PointerDownEvent event, required MultiDragGestureRecognizer recognizer}){
    listKey.currentState!.startItemDragReorder(index: index, event: event, recognizer: recognizer);
  }
  Widget _wrapWithSemantics(Widget child, int index) {
    void reorder(int startIndex, int endIndex) {
      if (startIndex != endIndex) {
        widget.onReorder(startIndex, endIndex);
      }
    }

    // First, determine which semantics actions apply.
    final Map<CustomSemanticsAction, VoidCallback> semanticsActions =
    <CustomSemanticsAction, VoidCallback>{};

    // Create the appropriate semantics actions.
    void moveToStart() => reorder(index, 0);
    void moveToEnd() => reorder(index, widget.items.length);
    void moveBefore() => reorder(index, index - 1);
    // To move after, we go to index+2 because we are moving it to the space
    // before index+2, which is after the space at index+1.
    void moveAfter() => reorder(index, index + 2);

    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);

    // If the item can move to before its current position in the grid.
    if (index > 0) {
      semanticsActions[
      CustomSemanticsAction(label: localizations.reorderItemToStart)] =
          moveToStart;
      String reorderItemBefore = localizations.reorderItemUp;
      if (widget.scrollDirection == Axis.horizontal) {
        reorderItemBefore = Directionality.of(context) == TextDirection.ltr
            ? localizations.reorderItemLeft
            : localizations.reorderItemRight;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemBefore)] =
          moveBefore;
    }

    // If the item can move to after its current position in the grid.
    if (index < widget.items.length - 1) {
      String reorderItemAfter = localizations.reorderItemDown;
      if (widget.scrollDirection == Axis.horizontal) {
        reorderItemAfter = Directionality.of(context) == TextDirection.ltr
            ? localizations.reorderItemRight
            : localizations.reorderItemLeft;
      }
      semanticsActions[CustomSemanticsAction(label: reorderItemAfter)] =
          moveAfter;
      semanticsActions[
      CustomSemanticsAction(label: localizations.reorderItemToEnd)] =
          moveToEnd;
    }

    // We pass toWrap with a GlobalKey into the item so that when it
    // gets dragged, the accessibility framework can preserve the selected
    // state of the dragging item.
    //
    // We also apply the relevant custom accessibility actions for moving the item
    // up, down, to the start, and to the end of the grid.
    return MergeSemantics(
      child: Semantics(
        customSemanticsActions: semanticsActions,
        child: child,
      ),
    );
  }


  Widget _itemBuilder(BuildContext context, int index) {
    final Widget item = widget.itemBuilder(context, index);
    assert(() {
      if (item.key == null) {
        throw FlutterError(
          'Every item of ReorderableListView must have a key.',
        );
      }
      return true;
    }());

    final Widget itemWithSemantics = _wrapWithSemantics(item, index);
    final Key itemGlobalKey =_ReorderableGridViewChildGlobalKey(item.key!, this);
    // final bool enable = widget.itemDragEnable(index);
    const bool enable = true;
    return ReorderableGridDelayedDragStartListener(
      key: itemGlobalKey,
      index: index,
      enabled: enable,
      child: itemWithSemantics,
    );
  }
  @override
  Widget build(BuildContext context) {
    return MotionBuilder(
      key: listKey,
      initialCount: oldList.length,
      onRerder: onReorder,
      onReorderStart: onReorderStart,
      onReorderEnd: onReorderEnd,
      insertAnimationBuilder: insertItemBuilder,
      removeAnimationBuilder: removeItemBuilder,
      itemBuilder: _itemBuilder,
      scrollDirection: scrollDirection,
      delegateBuilder: sliverGridDelegate,
    );
  }
}
@optionalTypeArgs
class _ReorderableGridViewChildGlobalKey extends GlobalObjectKey {
  const _ReorderableGridViewChildGlobalKey(this.subKey, this.state)
      : super(subKey);

  final Key subKey;
  final State state;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _ReorderableGridViewChildGlobalKey &&
        other.subKey == subKey &&
        other.state == state;
  }

  @override
  int get hashCode => Object.hash(subKey, state);
}