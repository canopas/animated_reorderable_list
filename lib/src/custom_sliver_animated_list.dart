import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:motion_list/motion_list.dart';

const Duration _kDuration = Duration(milliseconds: 300);

typedef DelegateBuilder = SliverChildBuilderDelegate Function(
    NullableIndexedWidgetBuilder builder, int itemCount);

typedef AnimatedRemovedItemBuilder = Widget Function(
    BuildContext context, Animation<double> animation);

class CustomSliverAnimatedList extends StatefulWidget {
  final AnimatedItemBuilder itemBuilder;
  final InsertItemBuilder insertItemBuilder;
  final int initialCount;
  final DelegateBuilder? delegateBuilder;

  const CustomSliverAnimatedList(
      {Key? key,
      required this.itemBuilder,
        required this.insertItemBuilder,
      this.initialCount = 0,
      this.delegateBuilder})
      : assert(initialCount >= 0),
        super(key: key);

  @override
  CustomSliverAnimatedListState createState() =>
      CustomSliverAnimatedListState();

  static CustomSliverAnimatedListState of(BuildContext context) {
    final CustomSliverAnimatedListState? result =
        context.findAncestorStateOfType<CustomSliverAnimatedListState>();
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

  static CustomSliverAnimatedListState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<CustomSliverAnimatedListState>();
  }
}

class CustomSliverAnimatedListState extends State<CustomSliverAnimatedList>
    with TickerProviderStateMixin {
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

  void insertItem(int index, {Duration duration = _kDuration}){
    assert(index>=0);
    final int itemIndex= _indexToItemIndex(index);
    if(itemIndex<0 || itemIndex>_itemsCount){
      return;
    }
    for(final _ActiveItem item in _incomingItems){
      if(item.itemIndex >= itemIndex) item.itemIndex +=1;
    }
    for(final _ActiveItem item in _outgoingItems){
      if(item.itemIndex >= itemIndex) item.itemIndex +=1;
    }

    final AnimationController controller= AnimationController(vsync: this,duration: duration);
    final _ActiveItem incomingItem= _ActiveItem.incoming(controller, itemIndex);

    setState(() {
      _incomingItems..add(incomingItem)..sort();
      _itemsCount +=1;
    });

    controller.forward().then<void>((_) {
      _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)!.controller!.dispose();
    });
  }

  void removeItem(int index, AnimatedRemovedItemBuilder builder, {Duration duration=_kDuration}){
    assert(index >=0);
    final int itemIndex= _indexToItemIndex(index);
    if(itemIndex<0 || itemIndex>=_itemsCount){
      return;
    }

    assert(_activeItemAt(_outgoingItems, itemIndex)==null);

    final _ActiveItem? incomingItem= _removeActiveItemAt(_incomingItems, itemIndex);
    final AnimationController controller= incomingItem?.controller?? AnimationController(vsync: this,duration: duration);
    final _ActiveItem outgoingItem= _ActiveItem.outgoing(controller, itemIndex,builder);

    setState(() {
      _outgoingItems..add(outgoingItem)..sort();
    });

    controller.reverse().then<void>((_) {
      _removeActiveItemAt(_outgoingItems, outgoingItem.itemIndex)!.controller!.dispose();

      for(final _ActiveItem item in _incomingItems){
        if(item.itemIndex > outgoingItem.itemIndex) item.itemIndex -=1;
      }
      for(final _ActiveItem item in _outgoingItems){
        if(item.itemIndex> outgoingItem.itemIndex)item.itemIndex -=1;
      }
      setState(() {
        _itemsCount -=1;
      });
    });
  }

  SliverChildDelegate _createDelegate() {
    return widget.delegateBuilder?.call(_itemBuilder, _itemsCount) ??
        SliverChildBuilderDelegate(_itemBuilder, childCount: _itemsCount);
  }

  Widget _itemBuilder(BuildContext context, int itemIndex) {
    final _ActiveItem? outgoingItem = _activeItemAt(_outgoingItems, itemIndex);
    if (outgoingItem != null) {
      return outgoingItem.removedItemBuilder!(
          context, outgoingItem.controller!.view);
    }
    final _ActiveItem? incomingItem = _activeItemAt(_incomingItems, itemIndex);
    final Animation<double> animation =
        incomingItem?.controller?.view ?? kAlwaysCompleteAnimation;
    return widget.itemBuilder(context, _itemIndexToIndex(itemIndex), animation);
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(delegate: _createDelegate());
  }
}

class _ActiveItem implements Comparable<_ActiveItem> {
  final AnimationController? controller;
  final AnimatedRemovedItemBuilder? removedItemBuilder;
  int itemIndex;

  _ActiveItem.incoming(this.controller, this.itemIndex)
      : removedItemBuilder = null;

  _ActiveItem.outgoing(
      this.controller, this.itemIndex, this.removedItemBuilder);

  _ActiveItem.index(this.itemIndex)
      : controller = null,
        removedItemBuilder = null;

  @override
  int compareTo(_ActiveItem other) {
    return itemIndex - other.itemIndex;
  }
}
