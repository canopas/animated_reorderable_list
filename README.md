# animated_reorderable_list

This library is a powerful and easy-to-use solution for implementing animated lists and grids with drag-and-drop functionality in Flutter.

## Features

- [x] Smooth transition during item insertion and removal from the list with animations.
- [x] Drag and Drop support (ReorderableList) for both ListView and GridView with Animation.
- [x] Pre-built animation like fade,scale, slide, flip etc for Flutter list.
- [x] Provides support for both lists and grids
- [x] Supports large lists  and creates items on demand as they come into the viewport.
- [x] Animating items is as simple as updating the list.


## Demo

### Reorderable List

<img src="gif/reorderable-grid.gif" width="32%"> <img src="gif/reorderable-list.gif" width="32%">

### List Animations

<img src="gif/demo.gif" width="32%"> <img src="gif/demo1.gif" width="32%"> 

### Grid Animations

<img src="gif/demo2.gif" width="32%"> <img src="gif/demo3.gif" width="32%">


## How to use it?

In the pubspec.yaml, add the dependency:

```
dependencies:
  animated_reorderable_list: <latest_version>
```


In your library, add the import:

```
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
```
[Sample](https://github.com/canopas/animated_reorderable_list/tree/main/example) app demonstrates
how simple the usage of the library actually is.

## Basic usage

### AnimatedReorderableGridView
A `GridView` that enables users to interactively reorder items through dragging, with animated insertion and removal of items.

```dart
AnimatedReorderableGridView(
   items: list, 
   scrollDirection: Axis.vertical,
   itemBuilder: (BuildContext context, int index) {
      return ItemCard(
      key: Key(list[index].name),
      index: list[index].index);
      },
   sliverGridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4),
   enterTransition: [FadeIn(), ScaleIn()],
   exitTransition:  [SlideIn()],
   insertDuration: const Duration(milliseconds: 300),
   removeDuration: const Duration(milliseconds: 300),
   onReorder: (int oldIndex, int newIndex) {
      setState(() {
        final User user = list.removeAt(oldIndex);
          list.insert(newIndex, user);
        });
      },
  )

```

### AnimatedReorderableListView
A `ListView` that enables users to interactively reorder items through dragging, with animated insertion and removal of items.

```dart
 AnimatedReorderableListView(
    items: list,
    itemBuilder: (BuildContext context, int index) {
        return ItemTile(
        key: Key(list[index].name),
        index: list[index].index);
        },
    enterTransition: [FlipInX(), ScaleIn()],,
    exitTransition: [SlideInLeft()]
    insertDuration: const Duration(milliseconds: 300),
    removeDuration: const Duration(milliseconds: 300),
    onReorder: (int oldIndex, int newIndex) {
      setState(() {
        final User user = list.removeAt(oldIndex);
         list.insert(newIndex, user);
       });
      },
  )

```

### AnimatedListView
 A `AnimatedListView` that animates insertion and removal of the item.

```dart
AnimatedListView(
    items: list,
    itemBuilder: (BuildContext context, int index) {
       return ItemTile(
       key: Key(list[index].name),
       index: list[index].index);
       },
    enterTransition: [FadeIn(), ScaleIn()],
    exitTransition:  [SlideIn()],
    insertDuration: const Duration(milliseconds: 300),
    removeDuration: const Duration(milliseconds: 300),
  ),

```

### AnimatedGridView
A Flutter `AnimatedGridView` that animates insertion and removal of the item.

```dart
AnimatedGridView(
   items: list,
   scrollDirection: Axis.vertical,
   itemBuilder: (BuildContext context, int index) {
      return ItemCard(
      key: Key(list[index].name),
      index: list[index].index);
      },
   sliverGridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4),
   enterTransition: [FadeIn(), ScaleIn()],
   exitTransition:  [SlideIn()],
   insertDuration: const Duration(milliseconds: 300),
   removeDuration: const Duration(milliseconds: 300),
 )
```
Duration for animation
----------------------------------------
```dart
//optional
insertDuration: const Duration(milliseconds: 300),
removeDuration: const Duration(milliseconds: 300),
```
The duration for item insertion and removal animation. If not specified, the default duration is `Duration(milliseconds: 300)`. 

Enter and exit Animation
----------------------------------------

To apply animation, while inserting or removing item, specify a list of animation:

``` dart
    enterTransition: [FadeIn(), ScaleIn()],
    exitTransition:  [SlideIn()],
```
If not specified, then default `FadeIn()` animation will be applied.

Delay, duration, curve
----------------------------------------

Animation have optional `delay`, `duration`, `begin`, `end` and `curve` parameters. Animations run
in parallel, but you can use a `delay` to run them sequentially:

``` dart
                    enterTransition: [
                       FadeIn(
                              duration: const Duration(milliseconds: 300),
                              delay: const Duration(milliseconds: 100)),
                          ScaleIn(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.bounceInOut)
                        ],
```

If a specific duration is provided for the animation, it will run for that specified duration.
However, if `insertDuration` or `removeDuration` are specified, it will override specific item duration. 

Custom AnimationBuilder
----------------------------------------
``` dart
                        insertItemBuilder: (Widget child, Animation<double> animation){
                                 return ScaleTransition(
                                       scale: animation,
                                       child: child,
                                     );
                                    },
                                    
                        removeItemBuilder: (Widget child, Animation<double> animation){
                                     return ScaleTransition(
                                       scale: animation,
                                       child: child,
                                     );
                                    },
```
You have the flexibility to use custom insertItemBuilder or removeItemBuilder if you wish to implement your own customized animations instead of relying on the built-in animations provided by the library. In these custom builder functions, the child parameter represents the widget returned by the itemBuilder callback, and the animation parameter provides the animation control.
If a custom `insertItemBuilder` is provided, it will override the `enterTransition`. Similarly, if `removeItemBuilder` is provided, then it will override `exitTransition`.


## Bugs and Feedback

For bugs, questions and discussions please use
the [Github Issues](https://github.com/canopas/animated_reorderable_list/issues).

## Credits

**animated_reorderable_list** is owned and maintained by the [Canopas team](https://canopas.com/).
You can follow them on Twitter at [@canopassoftware](https://twitter.com/canopassoftware) for
project updates and releases.

Inspired by [recyclerview-animators](https://github.com/wasabeef/recyclerview-animators) in Android.



