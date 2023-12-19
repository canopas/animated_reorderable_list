import 'package:flutter/material.dart';

import '../builder/motion_animation_builder.dart';
import '../model/reorderable_entity.dart';

class ReorderableWidget extends StatefulWidget
    implements Comparable<ReorderableWidget> {
  int index;
  final Widget? child;
  final ReorderableItem? reorderableItem;
  final AnimationController? animationController;
  final OnDragCompleteCallback? onDragCompleteCallback;
  final OnCreateCallback? onCreateCallback;

  ReorderableWidget({
    Key? key,
    required this.index,
    required this.reorderableItem,
    required this.child,
    required this.animationController,
    required this.onDragCompleteCallback,
    required this.onCreateCallback,
  }) : super(key: key);

  ReorderableWidget.builder(this.index, this.animationController)
      : child = null,
        reorderableItem = null,
        onDragCompleteCallback = null,
        onCreateCallback = null;

  @override
  State<ReorderableWidget> createState() => ReorderableWidgetState();

  @override
  int compareTo(ReorderableWidget other) {
    return index - other.index;
  }

  void animateEntry() {
    animationController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController?.dispose();
      }
    });
    animationController?.forward();
  }
}

class ReorderableWidgetState extends State<ReorderableWidget>
    with SingleTickerProviderStateMixin {
  late MotionAnimationBuilderState _listState;

  late AnimationController _offsetAnimationController;
  late Animation<Offset> _animationOffset;
  late ReorderableItem reorderableItem;

  int get index => widget.index;

  @override
  void initState() {
    _listState = MotionAnimationBuilder.of(context);
    _listState.registerItem(this);
    reorderableItem = widget.reorderableItem!;
    _handleCreated();
    _offsetAnimationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _animationOffset = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_offsetAnimationController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          final updatedOffset = itemOffset();
          reorderableItem = reorderableItem.copyWith(
              oldOffset: updatedOffset,
              updatedOffset: updatedOffset,
              oldIndex: index);
          widget.onDragCompleteCallback?.call(reorderableItem);
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _updateAnimationTranslation();
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant ReorderableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    reorderableItem = widget.reorderableItem!;
    _updateAnimationTranslation();

    if (oldWidget.index != index) {
      _listState.unregisterItem(index, this);
      _listState.registerItem(this);
      rebuild();
    }
  }

  void _handleCreated() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final updatedReorderableItem = widget.onCreateCallback!(reorderableItem);
      if (updatedReorderableItem != null) {
        setState(() {
          reorderableItem = updatedReorderableItem;
        });
      }
    });
  }

  void _updateAnimationTranslation() {
    final originalOffset = reorderableItem.oldOffset;
    final updatedOffset = itemOffset();
    Offset offsetDiff = originalOffset - updatedOffset;

    if (offsetDiff.dx != 0 || offsetDiff.dy != 0) {
      if (_offsetAnimationController.isAnimating) {
        final currentAnimationOffset = _animationOffset.value;
        final newOriginalOffset = currentAnimationOffset - offsetDiff;
        offsetDiff = offsetDiff + newOriginalOffset;
      }
      _offsetAnimationController.reset();

      _animationOffset = Tween<Offset>(begin: offsetDiff, end: Offset.zero)
          .animate(_offsetAnimationController);
      _offsetAnimationController.forward();
    }
  }

  Offset itemOffset() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(Offset.zero);
  }

  @override
  void dispose() {
    _listState.unregisterItem(index, this);
    _offsetAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.translationValues(
          _animationOffset.value.dx, _animationOffset.value.dy, 0.0),
      child: widget.child,
    );
  }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }
}
