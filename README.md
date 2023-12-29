# animated_reorderable_list

A Flutter Reorderable Animated List with simple implementation and smooth transition.

## Features
- [x] Smooth animations when adding and removing items from the list.
- [x] List and Grid support.
- [x] Easily customize animation styles and duration to Flutter list.
- [ ] Drag and Drop support

## Demo

### List Animations
<img src="gif/demo.gif" width="32%"> <img src="gif/demo1.gif" width="32%"> 

### Grid Animations
<img src="gif/demo2.gif" width="32%"> <img src="gif/demo3.gif" width="32%">

### How to use it?
[Sample](https://github.com/canopas/animated_reorderable_list/tree/main/example) app demonstrates how simple the usage of the library actually is.

```
SliverGridMotionList(
          items: list,
          scrollDirection: Axis.vertical,
          itemBuilder: (BuildContext context, int index) {
            return ItemCard(index: index);
          },
          insertDuration: Duration(milliseconds: 200),
          insertAnimation: AnimationType.scaleInTop,
          removeAnimation: AnimationType.fadeInDown,
          sliverGridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5),
        ),

```


## Bugs and Feedback
For bugs, questions and discussions please use the [Github Issues](https://github.com/canopas/animated_reorderable_list/issues).

## Credits
**animated_reorderable_list** is owned and maintained by the [Canopas team](https://canopas.com/). You can follow them on Twitter at [@canopassoftware](https://twitter.com/canopassoftware) for project updates and releases.

Inspired by [recyclerview-animators](https://github.com/wasabeef/recyclerview-animators) in Android.



