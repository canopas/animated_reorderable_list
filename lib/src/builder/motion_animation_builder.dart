import 'package:flutter/cupertino.dart';
import 'package:motion_list/src/builder/motion_list_base.dart';
import 'package:motion_list/src/component/motion_animated_content.dart';
import 'package:motion_list/src/model/reorderable_entity.dart';

import '../component/reorderable_widget.dart';

typedef OnDragCompleteCallback = void Function(ReorderableItem reorderableItem);
typedef OnCreateCallback = ReorderableItem? Function(
    ReorderableItem reorderableItem);
typedef StartInsertAnimationCallback = void Function(
    ReorderableWidget reorderableItem);

enum Operation { add, remove }

const Duration _kDuration = Duration(milliseconds: 300);
const Duration _kResizeDuration = Duration(milliseconds: 1000);

typedef DelegateBuilder = SliverChildBuilderDelegate Function(
    NullableIndexedWidgetBuilder builder, int itemCount);

typedef AnimatedRemovedItemBuilder = Widget Function(
    BuildContext context, Animation<double> animation);

typedef AnimatedWidgetBuilder = Widget Function(
    BuildContext context, Widget child, Animation<double> animation);

class MotionAnimationBuilder<E> extends StatefulWidget {
  final AnimatedWidgetBuilder insertAnimationBuilder;
  final AnimatedWidgetBuilder removeAnimationBuilder;
  final int initialCount;
  final SliverGridDelegate? delegateBuilder;
  final ItemBuilder itemBuilder;

  const MotionAnimationBuilder(
      {Key? key,
      required this.insertAnimationBuilder,
      required this.removeAnimationBuilder,
      this.initialCount = 0,
      this.delegateBuilder,
      required this.itemBuilder})
      : assert(initialCount >= 0),
        super(key: key);

  @override
  MotionAnimationBuilderState createState() => MotionAnimationBuilderState();

  static MotionAnimationBuilderState of(BuildContext context) {
    final MotionAnimationBuilderState? result =
        context.findAncestorStateOfType<MotionAnimationBuilderState>();
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

  static MotionAnimationBuilderState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<MotionAnimationBuilderState>();
  }
}

class MotionAnimationBuilderState extends State<MotionAnimationBuilder>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<ReorderableWidget> _incomingItems = <ReorderableWidget>[];
  final List<ReorderableWidget> _outgoingItems = <ReorderableWidget>[];
  final Map<int, MotionAnimatedContentState> _items =
      <int, MotionAnimatedContentState>{};
  Map<int, ReorderableItem> childrenMap = <int, ReorderableItem>{};
  List<GlobalKey> globalKeys = [];

  int _itemsCount = 0;
  int changeIndex = 0;

  @override
  void initState() {
    super.initState();
    _itemsCount = widget.initialCount;
    for (int i = 0; i < _itemsCount; i++) {
      childrenMap[i] = ReorderableItem(
          oldOffset: Offset.zero,
          updatedOffset: Offset.zero,
          oldIndex: i,
          updatedIndex: i,
          key: ValueKey(i));
    }
    _updateGlobalKeys();

    setState(() {});
  }

  _updateGlobalKeys() {
    globalKeys = List.generate(
      _itemsCount,
      (index) => GlobalKey(debugLabel: index.toString()),
    );
  }

  @override
  void dispose() {
    for (final ReorderableWidget item
        in _incomingItems.followedBy(_outgoingItems)) {
      item.animationController!.dispose();
    }
    super.dispose();
  }

  ReorderableWidget? _removeActiveItemAt(
      List<ReorderableWidget> items, int itemIndex) {
    final i = items.indexWhere((element) => element.index == itemIndex);
    return i == -1 ? null : items.removeAt(i);
  }

  ReorderableWidget? _activeItemAt(
      List<ReorderableWidget> items, int itemIndex) {
    final i = items.indexWhere((element) => element.index == itemIndex);
    return i == -1 ? null : items[i];
  }

  int _indexToItemIndex(int index) {
    int itemIndex = index;

    for (final ReorderableWidget item in _outgoingItems) {
      if (item.index <= itemIndex) {
        itemIndex += 1;
      } else {
        break;
      }
    }
    return itemIndex;
  }

  int _itemIndexToIndex(int itemIndex) {
    int index = itemIndex;
    for (final ReorderableWidget item in _outgoingItems) {
      assert(item.index != itemIndex);
      if (item.index < itemIndex) {
        index -= 1;
      } else {
        break;
      }
    }
    return index;
  }

  void registerItem(MotionAnimatedContentState item) {
    _items[item.index] = item;
  }

  void unregisterItem(int index, MotionAnimatedContentState item) {
    final MotionAnimatedContentState? currentItem = _items[index];
    if (currentItem == item) {
      _items.remove(index);
    }
  }

  Offset? _itemOffsetAt(int index) {
    final box = _items[index]?.context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero);
  }

  Future<void> insertItem(int index,
      {Duration insertDuration = _kDuration}) async {
    assert(index >= 0);
    final int itemIndex = _indexToItemIndex(index);

    if (itemIndex < 0 || itemIndex > _itemsCount) {
      return;
    }
    for (final ReorderableWidget item in _incomingItems) {
      if (item.index >= itemIndex) item.index += 1;
    }
    for (final ReorderableWidget item in _outgoingItems) {
      if (item.index >= itemIndex) item.index += 1;
    }
    final AnimationController controller =
        AnimationController(vsync: this, duration: insertDuration);
    final ReorderableWidget incomingItem =
        ReorderableWidget.builder(itemIndex, controller);
    _incomingItems
      ..add(incomingItem)
      ..sort();
    addItem(incomingItem.index);

    //  print("XXXX ${_incomingItems.length}");
    if (mounted) {
      setState(() {
        _itemsCount++;
        _updateGlobalKeys();
      });
    }

    Future.delayed(const Duration(seconds: 2), () {
      final activeItem =
          _removeActiveItemAt(_incomingItems, incomingItem.index);
      activeItem?.animateEntry();
    });
  }

  void addItem(int itemIndex) {
    final updatedChildrenMap = <int, ReorderableItem>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key < itemIndex) {
          updatedChildrenMap[entry.key] = childrenMap[entry.key]!.copyWith(
            visible: false,
          );
        } else if (entry.key == itemIndex) {
          updatedChildrenMap[entry.key] = ReorderableItem(
            key: ValueKey(entry.key),
            oldOffset: Offset.zero,
            updatedOffset: _itemOffsetAt(entry.key) ?? Offset.zero,
            oldIndex: entry.key,
            updatedIndex: entry.key,
          );
          updatedChildrenMap[entry.key + 1] = childrenMap[entry.key]!.copyWith(
            key: ValueKey(entry.key + 1),
            oldOffset: _itemOffsetAt(entry.key),
            updatedOffset: _itemOffsetAt(entry.key + 1) ?? Offset.zero,
            updatedIndex: entry.key + 1,
          );
        } else {
          updatedChildrenMap[entry.key + 1] = childrenMap[entry.key]!.copyWith(
            key: ValueKey(entry.key + 1),
            updatedIndex: entry.key + 1,
            updatedOffset: _itemOffsetAt(entry.key + 1) ?? Offset.zero,
          );
        }
      }
    }
    childrenMap.clear();
    childrenMap.addAll(updatedChildrenMap);
  }

  void removeItem(int index, {Duration removeDuration = _kDuration}) {
    assert(index >= 0);
    final int itemIndex = _indexToItemIndex(index);
    if (itemIndex < 0 || itemIndex >= _itemsCount) {
      return;
    }
    assert(_activeItemAt(_outgoingItems, itemIndex) == null);

    final ReorderableWidget? incomingItem =
        _removeActiveItemAt(_incomingItems, itemIndex);
    final AnimationController controller = incomingItem?.animationController ??
        AnimationController(vsync: this, value: 1.0, duration: removeDuration);
    final ReorderableWidget outgoingItem =
        ReorderableWidget.builder(itemIndex, controller);

    controller.reverse();

    _outgoingItems
      ..add(outgoingItem)
      ..sort();

    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _itemsCount -= 1;
            _updateGlobalKeys();
          });
        }
        deleteItem(outgoingItem.index);

        final ReorderableWidget? activeItem =
            _removeActiveItemAt(_outgoingItems, outgoingItem.index);

        for (final ReorderableWidget item in _incomingItems) {
          if (item.index > outgoingItem.index) item.index -= 1;
        }
        for (final ReorderableWidget item in _outgoingItems) {
          if (item.index > outgoingItem.index) item.index -= 1;
        }
        activeItem?.animationController?.dispose();
      }
    });
  }

  void deleteItem(int itemIndex) {
    final updatedChildrenMap = <int, ReorderableItem>{};
    if (childrenMap.containsKey(itemIndex)) {
      for (final entry in childrenMap.entries) {
        if (entry.key < itemIndex) {
          updatedChildrenMap[entry.key] = childrenMap[entry.key]!;
        } else if (entry.key == itemIndex) {
          continue;
        } else {
          updatedChildrenMap[entry.key - 1] = childrenMap[entry.key]!.copyWith(
            key: ValueKey(entry.key - 1),
            updatedIndex: entry.key - 1,
          );
        }
      }
    }
    childrenMap.clear();
    childrenMap.addAll(updatedChildrenMap);
  }

  void onDragComplete(ReorderableItem reorderableItem) {
    final updatedOffset = _itemOffsetAt(reorderableItem.updatedIndex);
    if (updatedOffset != null) {
      childrenMap[reorderableItem.updatedIndex] = reorderableItem;
    }
  }

  ReorderableItem? _onCreated(ReorderableItem reorderableItem) {
    final offset = _itemOffsetAt(reorderableItem.updatedIndex);
    if (offset != null) {
      final updatedReorderableItem = reorderableItem.copyWith(
          oldOffset: _itemOffsetAt(reorderableItem.oldIndex),
          updatedOffset: _itemOffsetAt(reorderableItem.updatedIndex));
      childrenMap[reorderableItem.updatedIndex] = updatedReorderableItem;
      return updatedReorderableItem;
    }
    return null;
  }

  SliverChildDelegate _createDelegate() {
    return SliverChildBuilderDelegate((context, index) {
      final ReorderableWidget? outgoingItem =
          _activeItemAt(_outgoingItems, index);

      final ReorderableWidget? incomingItem =
          _activeItemAt(_incomingItems, index);

      final Widget child = outgoingItem != null
          ? _removeItemBuilder(outgoingItem, index)
          : _insertItemBuilder(incomingItem, index);

      return ReorderableWidget(
        key: childrenMap[index]!.key,
        index: index,
        reorderableItem: childrenMap[index],
        animationController: incomingItem?.animationController,
        onDragCompleteCallback: onDragComplete,
        onCreateCallback: _onCreated,
        child: child,
      );
    }, childCount: _itemsCount);
  }

  Widget _removeItemBuilder(ReorderableWidget outgoingItem, int itemIndex) {
    final Animation<double> animation =
        outgoingItem.animationController ?? kAlwaysCompleteAnimation;
    return widget.removeAnimationBuilder(
      context,
      widget.itemBuilder(context, itemIndex),
      animation,
    );
  }

  Widget _insertItemBuilder(ReorderableWidget? incomingItem, int itemIndex) {
    final Animation<double> animation =
        incomingItem?.animationController ?? kAlwaysCompleteAnimation;
    return widget.insertAnimationBuilder(
      context,
      widget.itemBuilder(context, _itemIndexToIndex(itemIndex)),
      animation,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.delegateBuilder != null
        ? SliverGrid(
            gridDelegate: widget.delegateBuilder!, delegate: _createDelegate())
        : SliverList(delegate: _createDelegate());
  }

  @override
  bool get wantKeepAlive => false;
}