import 'package:animated_reorderable_list/src/component/Handle.dart';
import 'package:flutter/material.dart';

import '../builder/motion_animated_reorderable_list.dart';

typedef ReorderableBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  bool inDrag,
);

class Reorderable extends StatefulWidget {
  final ReorderableBuilder? builder;
  final Widget? child;

  const Reorderable({required Key key, this.builder, this.child})
      : assert(builder != null || child != null),
        super(key: key);

  @override
  State<Reorderable> createState() => ReorderableState();

  static ReorderableState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ReorderableState>();
  }
}

class ReorderableState extends State<Reorderable>
    with SingleTickerProviderStateMixin {
  late Key key = widget.key ?? UniqueKey();

  late final _dragController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  late final _dragAnimation = CurvedAnimation(
    parent: _dragController,
    curve: Curves.linear,
  );

  Animation<double>? _translation;

  bool _isVertical = true;

  bool _inDrag = false;

  bool get inDrag => _inDrag;

  set inDrag(bool value) {
    if (value != inDrag) {
      _inDrag = value;
      value ? _dragController.animateTo(1.0) : _dragController.animateBack(0.0);
    }
  }

  // ignore: avoid_setters_without_getters
  set duration(Duration value) => _dragController.duration = value;

  void setTranslation(Animation<double>? animation) {
    if (mounted) {
      setState(() {
        _translation = animation;
      });
    }
  }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  void _registerItem() {
    final list = AnimatedReorderableList.maybeOf(context)!;

    list.registerItem(this);
    _dragController.duration = list.widget.reorderDuration;

    inDrag = list.dragItem?.key == key && list.inDrag;
    _isVertical = list.isVertical;
  }

  @override
  Widget build(BuildContext context) {
    _registerItem();

    final child = () {
      if (widget.child != null) {
        return widget.child;
      } else {
        return widget.builder!(context, _dragAnimation, _inDrag);
      }
    }();

    return AnimatedBuilder(
      animation: _translation ?? const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        final offset = _translation?.value ?? 0.0;

        return Transform.translate(
          offset: Offset(
            _isVertical ? 0.0 : offset,
            _isVertical ? offset : 0.0,
          ),
          child: child,
        );
      },
      child: Handle(child: child!),
    );
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }
}
