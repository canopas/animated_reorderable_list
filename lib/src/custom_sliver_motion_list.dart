import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:motion_list/motion_list.dart';

const Curve _kResizeTimeCurve = Interval(0.0, 1.0, curve: Curves.linear);
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
  final int initialCount;
  final DelegateBuilder? delegateBuilder;

  const CustomSliverMotionList(
      {Key? key,
      this.animatedItemBuilder,
      required this.itemBuilder,
      required this.insertAnimationType,
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

  AnimationController? _resizeController;
  Animation<double>? _resizeAnimation;

  Size? _sizePriorToCollapse;

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
    _resizeController?.dispose();
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
    print('insert item index: $index');

    final int itemIndex = _indexToItemIndex(index);
    print('insert item index from _indexToItemIndex method: $itemIndex');
    print('incoming item list length: ${_incomingItems.length}');

    if (itemIndex < 0 || itemIndex > _itemsCount) {
      return;
    }
    for (final _ActiveItem item in _incomingItems) {
      if (item.itemIndex >= itemIndex) item.itemIndex += 1;
    }
    for (final _ActiveItem item in _outgoingItems) {
      if (item.itemIndex >= itemIndex) item.itemIndex += 1;
    }

    final AnimationController controller =
        AnimationController(vsync: this, duration: duration);
    final _ActiveItem incomingItem = _ActiveItem.builder(controller, itemIndex);

    setState(() {
      _incomingItems
        ..add(incomingItem)
        ..sort();
      _itemsCount += 1;
    });
    print('incoming item list length after setstate: ${_incomingItems.length}');

    controller.forward().then<void>((_) {
      _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)!
          .controller!
          .dispose();
    });
  }

  void removeItem(int index, {Duration duration = _kDuration}) {
    assert(index >= 0);
    print('remove item index: $index');
    final int itemIndex = _indexToItemIndex(index);
    print('remove item index from _indexToItemIndex method: $itemIndex');
    if (itemIndex < 0 || itemIndex >= _itemsCount) {
      return;
    }

    assert(_activeItemAt(_outgoingItems, itemIndex) == null);

    final _ActiveItem? incomingItem =
        _removeActiveItemAt(_incomingItems, itemIndex);
    final AnimationController controller = incomingItem?.controller ??
        AnimationController(vsync: this, value: 1.0, duration: duration);

    print('Animationstatus is dismissed');
    _resizeController =
        AnimationController(vsync: this, duration: _kResizeDuration);
   // setState(() {
      _resizeAnimation = _resizeController!
          .drive(Tween<double>(begin: 1.0, end: 0.0))
          .drive(CurveTween(curve: _kResizeTimeCurve));
  //  });
    controller.addListener(() {
      //print("animation value ${controller.value}");
    });
    controller.addStatusListener((status) {
      print(status);

      if (status == AnimationStatus.dismissed) {
        _resizeController!.forward();
      }

    });
    final _ActiveItem outgoingItem = _ActiveItem.builder(controller, itemIndex);
    setState(() {
      _outgoingItems
        ..add(outgoingItem)
        ..sort();
    });
    _resizeController!.addStatusListener((status) {
      if(status==AnimationStatus.completed){
        _removeActiveItemAt(_outgoingItems, outgoingItem.itemIndex);

        for (final _ActiveItem item in _incomingItems) {
          if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
        }
        for (final _ActiveItem item in _outgoingItems) {
          if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
        }
        setState(() {
          _itemsCount -= 1;
        });
      }
    });



    controller.reverse().then<void>((void value) {

    });
   // print(controller.status);
    // _startResizeAnimation(controller);
  }

  void _startResizeAnimation() {

    //  }else{
    // print('Animationstatus is  $status');
    //
    // _resizeController =
    //    AnimationController(vsync: this, duration: _kResizeDuration)
    //      ..addStatusListener((status) {
    //        updateKeepAlive();
    //      });
    //    _resizeController!.forward();
    //    setState(() {
    //      //_sizePriorToCollapse = context.size;
    //      _resizeAnimation = kAlwaysCompleteAnimation;
    //      _resizeController!
    //          .drive(Tween<double>(begin: 1.0, end: 1.0))
    //          ;
    //    });
    //  }
  }

//   void _startResizeAnimation() {
// //   assert(_resizeController == null);
//     _resizeController =
//         AnimationController(vsync: this, duration: _kResizeDuration)..addStatusListener((status) {updateKeepAlive();});
//     _resizeController!.forward();
//     setState(() {
//       //_sizePriorToCollapse = context.size;
//       _resizeAnimation = _resizeController!
//           .drive(CurveTween(curve: _kResizeTimeCurve))
//           .drive(Tween<double>(begin: 1.0, end: 0.0));
//     });
//   }

  SliverChildDelegate _createDelegate() {
    return widget.delegateBuilder?.call(insertItemBuilderInList, _itemsCount) ??
        SliverChildBuilderDelegate(insertItemBuilderInList,
            childCount: _itemsCount);
  }

  Widget _removeAnimProvider(
      AnimationType animationType, Widget child, Animation<double> animation) {
    // _sizePriorToCollapse=context.size;
    print('resize animation value: ${_resizeAnimation!.value}');
    return SizeTransition(
        sizeFactor: _resizeAnimation!,
        child:
            AnimationProvider.buildAnimation(animationType, child, animation));
  }

  Widget insertItemBuilderInList(BuildContext context, int itemIndex) {
    final _ActiveItem? outgoingItem = _activeItemAt(_outgoingItems, itemIndex);
    if (outgoingItem != null) {
      final Animation<double> animation =
          outgoingItem.controller?.view ?? kAlwaysCompleteAnimation;
      return _removeAnimProvider(widget.insertAnimationType,
          widget.itemBuilder(context, itemIndex), animation);
      return AnimationProvider.buildAnimation(widget.insertAnimationType,
          widget.itemBuilder(context, itemIndex), animation);
    }
    final _ActiveItem? incomingItem = _activeItemAt(_incomingItems, itemIndex);
    final Animation<double> animation =
        incomingItem?.controller?.view ?? kAlwaysCompleteAnimation;
    return AnimationProvider.buildAnimation(widget.insertAnimationType,
        widget.itemBuilder(context, _itemIndexToIndex(itemIndex)), animation);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SliverList(delegate: _createDelegate());
  }

  @override
  bool get wantKeepAlive => _resizeController?.isAnimating ?? false;
}

class _ActiveItem implements Comparable<_ActiveItem> {
  final AnimationController? controller;
  int itemIndex;

  _ActiveItem.builder(this.controller, this.itemIndex);

  _ActiveItem.index(this.itemIndex) : controller = null;

  @override
  int compareTo(_ActiveItem other) {
    return itemIndex - other.itemIndex;
  }
}
