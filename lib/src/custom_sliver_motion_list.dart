import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:motion_list/motion_list.dart';

const Duration _kDuration = Duration(milliseconds: 300);
const Duration _kResizeDuration = Duration(milliseconds: 1000);

typedef DelegateBuilder = SliverChildBuilderDelegate Function(
    NullableIndexedWidgetBuilder builder, int itemCount);

typedef AnimatedRemovedItemBuilder = Widget Function(
    BuildContext context, Animation<double> animation);

class CustomSliverMotionList<E> extends StatefulWidget {
  final AnimatedItemBuilder? animatedItemBuilder;
  final ItemBuilder itemBuilder;
  final AnimationType insertAnimationType;
  final AnimationType removeAnimationType;
  final int initialCount;
  final DelegateBuilder? delegateBuilder;

  const CustomSliverMotionList(
      {Key? key,
      this.animatedItemBuilder,
      required this.itemBuilder,
      required this.insertAnimationType,
        required this.removeAnimationType,
      this.initialCount = 0,
      this.delegateBuilder})
      : assert(initialCount >= 0),
        super(key: key);

  @override
  CustomSliverMotionListState createState() => CustomSliverMotionListState();

  static CustomSliverMotionListState of(BuildContext context) {
    final CustomSliverMotionListState? result =
        context.findAncestorStateOfType<CustomSliverMotionListState>();
    assert(() {
      if (result == null) {
        throw FlutterError(
          'SliverAnimatedList.of() called with a context that does not contain a SliverAnimatedList.\n'
          'No SliverAnimatedListState ancestor could be found starting from the '
          'context that was passed to SliverAnimatedListState.of(). This can '
          'happen when the context provided is from the same StatefulWidget that '
          'built the AnimatedList. Please see the SliverAnimatedList documentation '
          'for examples of how to refer to an AnimatedListState object: '
          'https://api.flutter.dev/flutter/widgets/SliverAnimatedListState-class.html\n'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return result!;
  }

  static CustomSliverMotionListState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<CustomSliverMotionListState>();
  }
}

class CustomSliverMotionListState extends State<CustomSliverMotionList>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<_ActiveItem> _incomingItems = <_ActiveItem>[];
  final List<_ActiveItem> _outgoingItems = <_ActiveItem>[];
  int _itemsCount = 0;

  @override
  void initState() {
    super.initState();
    _itemsCount = widget.initialCount;
  }

  @override
  void dispose() {
    for (final _ActiveItem item in _incomingItems.followedBy(_outgoingItems)) {
      item.controller!.dispose();
      item.resizeController?.dispose();
    }
    super.dispose();
  }

  _ActiveItem? _removeActiveItemAt(List<_ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, _ActiveItem.index(itemIndex));
    return i == -1 ? null : items.removeAt(i);
  }

  _ActiveItem? _activeItemAt(List<_ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, _ActiveItem.index(itemIndex));
    return i == -1 ? null : items[i];
  }

  int _indexToItemIndex(int index) {
    int itemIndex = index;

    for (final _ActiveItem item in _outgoingItems) {
      if (item.itemIndex <= itemIndex) {
        itemIndex += 1;
      } else {
        break;
      }
    }
    return itemIndex;
  }

  int _itemIndexToIndex(int itemIndex) {
    int index = itemIndex;
    for (final _ActiveItem item in _outgoingItems) {
      assert(item.itemIndex != itemIndex);
      if (item.itemIndex < itemIndex) {
        index -= 1;
      } else {
        break;
      }
    }
    return index;
  }

  void insertItem(int index, {Duration duration = _kDuration}) {
    assert(index >= 0);
    final int itemIndex = _indexToItemIndex(index);

    if (itemIndex < 0 || itemIndex > _itemsCount) {
      return;
    }
    for (final _ActiveItem item in _incomingItems) {
      if (item.itemIndex >= itemIndex) item.itemIndex += 1;
    }
    for (final _ActiveItem item in _outgoingItems) {
      if (item.itemIndex >= itemIndex) item.itemIndex += 1;
    }

    final AnimationController addResizeController =
        AnimationController(vsync: this, duration: _kResizeDuration);

    final AnimationController controller =
        AnimationController(vsync: this, duration: duration);
    final _ActiveItem incomingItem =
        _ActiveItem.builder(controller, itemIndex, addResizeController);
    addResizeController.forward();
    addResizeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.forward().then<void>((_) {
          final activeItem =
              _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)!;
          activeItem.controller!.dispose();
          activeItem.resizeController?.dispose();
        });
      }
    });
    setState(() {
      _incomingItems
        ..add(incomingItem)
        ..sort();
      _itemsCount += 1;
    });
  }

  void removeItem(int index, {Duration duration = _kDuration}) {
    assert(index >= 0);
    final int itemIndex = _indexToItemIndex(index);
    if (itemIndex < 0 || itemIndex >= _itemsCount) {
      return;
    }
    assert(_activeItemAt(_outgoingItems, itemIndex) == null);

    final _ActiveItem? incomingItem =
        _removeActiveItemAt(_incomingItems, itemIndex);
    final AnimationController controller = incomingItem?.controller ??
        AnimationController(vsync: this, value: 1.0, duration: duration);
    final AnimationController resizeController = incomingItem?.resizeController ??
        AnimationController(vsync: this, value: 1.0, duration: duration);
    controller.reverse();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        resizeController.reverse();
      }
    });
    final _ActiveItem outgoingItem = _ActiveItem.builder(controller, itemIndex,resizeController);
    setState(() {
      _outgoingItems
        ..add(outgoingItem)
        ..sort();
    });

    resizeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
      final _ActiveItem? activeItem=  _removeActiveItemAt(_outgoingItems, outgoingItem.itemIndex);

        for (final _ActiveItem item in _incomingItems) {
          if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
        }
        for (final _ActiveItem item in _outgoingItems) {
          if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
        }
        setState(() {
          _itemsCount -= 1;
        });
        activeItem?.controller?.dispose();
        activeItem?.resizeController?.dispose();
      }
    });
  }


  SliverChildDelegate _createDelegate() {
    return widget.delegateBuilder?.call(itemBuilderDelegate, _itemsCount) ??
        SliverChildBuilderDelegate(itemBuilderDelegate,
            childCount: _itemsCount);
  }

  Widget itemBuilder(AnimationType animationType, Widget child,
      Animation<double> animation, Animation<double>? resizeAnimation) {
    return SizeTransition(
        sizeFactor: resizeAnimation ?? kAlwaysCompleteAnimation,
        child:
            AnimationProvider.buildAnimation(animationType, child, animation));
  }

  Widget _removeItemBuilder(_ActiveItem outgoingItem, int itemIndex) {
    final Animation<double> animation =
        outgoingItem.controller?.view ?? kAlwaysCompleteAnimation;
    final Animation<double> resizeAnimation = outgoingItem.resizeController!.view;
    return itemBuilder(widget.removeAnimationType,
        widget.itemBuilder(context, itemIndex), animation, resizeAnimation);
  }

  Widget _insertItemBuilder(_ActiveItem? incomingItem, int itemIndex) {
    final Animation<double> animation =
        incomingItem?.controller?.view ?? kAlwaysCompleteAnimation;
    final Animation<double>? resizeAnimation =
        incomingItem?.resizeController?.view;
    return itemBuilder(
        widget.insertAnimationType,
        widget.itemBuilder(context, _itemIndexToIndex(itemIndex)),
        animation,
        resizeAnimation);
  }

  Widget itemBuilderDelegate(BuildContext context, int itemIndex) {
    final _ActiveItem? outgoingItem = _activeItemAt(_outgoingItems, itemIndex);
    if (outgoingItem != null) {
      return _removeItemBuilder(outgoingItem, itemIndex);
    }
    final _ActiveItem? incomingItem = _activeItemAt(_incomingItems, itemIndex);
    return _insertItemBuilder(incomingItem, itemIndex);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SliverList(delegate: _createDelegate());
  }

  @override
  bool get wantKeepAlive => false;
}

class _ActiveItem implements Comparable<_ActiveItem> {
  final AnimationController? controller;
  final AnimationController? resizeController;
  int itemIndex;

  _ActiveItem.builder(this.controller, this.itemIndex, this.resizeController);

  _ActiveItem.index(this.itemIndex)
      : controller = null,
        resizeController = null;

  @override
  int compareTo(_ActiveItem other) {
    return itemIndex - other.itemIndex;
  }
}
