<a href="https://canopas.com/contact"><img src="https://github.com/user-attachments/assets/35d53858-0b59-49dd-84ee-8ca4fb6817a9"></a></p>

# animated_reorderable_list

This library is a powerful and easy-to-use solution for implementing animated list and grid with
drag-and-drop functionality in Flutter.

## Features

- [x] Smooth transition during item insertion and removal from the list with animations.
- [x] Drag and Drop support (ReorderableList) for both ListView and GridView with Animation.
- [x] It can be both animated and reordered at the same time
- [x] Animating items is as simple as updating the list.
- [x] Pre-built animation like fade,scale, slide, flip etc for Flutter list.
- [x] Provides support for both lists and grids
- [x] Supports large lists and creates items on demand as they come into the viewport.

## Demo

### Reorderable List

| ![Image 1](https://github.com/user-attachments/assets/b3f9b177-995a-4e23-a245-82db9462c548?raw=true) | ![Image 2](https://github.com/user-attachments/assets/262c1cb6-e5f0-445f-b710-75eca84e2df8?raw=true) | ![Image 3](https://github.com/user-attachments/assets/90b6a151-d341-4dd9-ba85-66051743f8a8?raw=true) |
|                  :---:                             |                     :---:                          |                            :---:                   |
|                ReorderableGridView                 |                   ReorderableListView              |              Swap Animation                        | 

## How to use it?

#### 1. Add dependency

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  animated_reorderable_list: <latest_version>
```

#### 2. Install it

You can install packages from the command line:

with `pub`:

```
$ pub get
```

with `Flutter`:

```
$ flutter pub get
```

#### 3. Import it

Now in your `Dart` code, you can use:

```dart
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
```

### 4. Use it

[Sample](https://github.com/canopas/animated_reorderable_list/tree/main/example) app demonstrates
how simple the usage of the library actually is.

## Basic usage

#### AnimatedReorderableGridView

A `AnimatedGridView` with built-in support for drag and drop functionality.

```dart
AnimatedReorderableGridView(
  items: list,
  itemBuilder: (BuildContext context, int index) {
    final user = list[index];
    return ItemCard(
      key: ValueKey(user.id),
      id: user.id,
    );
  },
  sliverGridDelegate:
      SliverReorderableGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4),
  enterTransition: [FlipInX(), ScaleIn()],
  exitTransition: [SlideInLeft()],
  insertDuration: const Duration(milliseconds: 300),
  removeDuration: const Duration(milliseconds: 300),
  onReorder: (int oldIndex, int newIndex) {
    setState(() {
      final User user = list.removeAt(oldIndex);
      list.insert(newIndex, user);
    });
  },
  dragStartDelay: const Duration(milliseconds: 300),
  isSameItem: (a, b) => a.id == b.id,
)
```

### AnimatedReorderableListView

A `AnimatedListView` with built-in support for drag-and-drop functionality.

```dart
 AnimatedReorderableListView(
  items: list,
  itemBuilder: (BuildContext context, int index) {
    final user = list[index];
    return ItemTile(
      key: ValueKey(user.id),
      id: user.id,
    );
  },
  enterTransition: [SlideInDown()],
  exitTransition: [SlideInUp()],
  insertDuration: const Duration(milliseconds: 300),
  removeDuration: const Duration(milliseconds: 300),
  dragStartDelay: const Duration(milliseconds: 300),
  onReorder: (int oldIndex, int newIndex) {
    setState(() {
      final User user = list.removeAt(oldIndex);
      list.insert(newIndex, user);
    });
  },
  isSameItem: (a, b) => a.id == b.id
)

```

### AnimatedListView

A `AnimatedListView` that animates insertion and removal of the item. Use this widget when you don't
need drag-and-drop functionality.

```dart
AnimatedListView(
  items: list,
  itemBuilder: (context, index) {
    final user = list[index];
    return ItemTile(
      key: ValueKey(user.id),
      id: user.id,
    );
  },
  enterTransition: [FadeIn(), ScaleIn()]
  exitTransition: [SlideInUp()],
  isSameItem: (a, b) => a.id == b.id,
)
```

### AnimatedGridView

A `AnimatedGridView` that animates insertion and removal of the item. Use this widget when you don't
need drag-and-drop functionality.

```dart
AnimatedGridView(
  items: list,
  itemBuilder: (context, index) {
    final user = list[index];
    return ItemCard(
      key: ValueKey(user.id),
      id: user.id,
    );
  },
  sliverGridDelegate:
      SliverReorderableGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4),
  enterTransition: [FadeIn(), ScaleIn()],
  exitTransition: [SlideInDown()],
  isSameItem: (a, b) => a.id == b.id),
```

Duration for animation
----------------------------------------

```dart
//optional
insertDuration: const Duration(milliseconds: 300),
removeDuration: const Duration(milliseconds:300),
```

The duration for item insertion and removal animation. If not specified, the default duration is
`Duration(milliseconds: 300)`.

Enter and exit Animation
----------------------------------------

To apply animation, while inserting or removing item, specify a list of animation:

``` dart
//optional
    enterTransition: [FadeIn(), ScaleIn()],
    exitTransition:  [SlideIn()],
```

If not specified, then default `FadeIn()` animation will be applied.

Delay, duration, curve
----------------------------------------

Animation have optional `delay`, `duration`, `begin`, `end` and `curve` parameters. Animations run
in parallel, but you can use a `delay` to run them sequentially:

``` dart
//optional
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
However, if `insertDuration` or `removeDuration` are specified, it will override specific item
duration.

Custom AnimationBuilder
----------------------------------------

``` dart
//optional
insertItemBuilder: (Widget child, Animation<double> animation){
      return ScaleTransition(
         scale: animation,
         child: child,
     );
  }
                                    
removeItemBuilder: (Widget child, Animation<double> animation){
       return ScaleTransition(
          scale: animation,
          child: child,
      );
    }
```

You can use custom `insertItemBuilder` or `removeItemBuilder` if you wish to implement your own
customized animations instead of relying on the built-in animations provided by the library.
In these custom builder functions, the child parameter represents the widget returned by the
`itemBuilder` callback, and the `animation` parameter provides the animation control.

If a custom `insertItemBuilder` is provided, it will override the `enterTransition`. Similarly, if
`removeItemBuilder` is provided, then it will override `exitTransition`.

## Animations

The library provides a set of pre-built animations that can be used for item insertion and removal.
You can use multiple animations at the same time by providing a list of animations.


The following animations are available:

| Animation Type   | ListView Example              | GridView Example              |
|------------------|-------------------------------|-------------------------------|
| **FadeIn**       | <img src="https://github.com/user-attachments/assets/c1e0737e-ed06-4978-826d-8d6891a954eb?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/90dd1449-9771-436a-be04-83d10a9929f3?raw=true" width="250"/>  |
| **FlipInY**      | <img src="https://github.com/user-attachments/assets/7d9e1398-c1ae-4fc0-8767-e7d86d0cdbe1?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/54c302f0-4d88-4152-8628-33f6baf077a0?raw=true" width="250"/>  |
| **FlipInX**      | <img src="https://github.com/user-attachments/assets/5cdb949b-80c9-4d9b-808e-cd07a928321f?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/a638a7ca-1d5c-403e-b78b-c370a260a5d4?raw=true" width="250"/>  |
| **Landing**      | <img src="https://github.com/user-attachments/assets/4d856723-d204-4571-bbd4-54edc4037141?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/46ebffb7-a983-4930-995c-4ea735f25810?raw=true" width="250"/>  |
| **ScaleIn**      | <img src="https://github.com/user-attachments/assets/3b6977bf-e0f9-4162-a44d-073869c8a225?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/9945da15-10eb-4eb8-8d0b-894635702808?raw=true" width="250"/>  |
| **ScaleInTop**   | <img src="https://github.com/user-attachments/assets/f7b5d6f9-8baa-4425-a9b1-dae3ce12d378?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/83a81b69-204f-4eff-9e52-6559065097f7?raw=true" width="250"/>  |
| **ScaleInBottom**| <img src="https://github.com/user-attachments/assets/5cb5cc5b-df22-44c3-9368-3520b94cdc6a?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/7a0a33e1-2f9f-42bf-ab30-bf925df56651?raw=true" width="250"/>  |
| **ScaleInLeft**  | <img src="https://github.com/user-attachments/assets/a5c3dac6-9889-4658-996a-5694c79fcb5d?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/b2c8ac50-98ed-46d3-932b-c312dd81c5d1?raw=true" width="250"/>  |
| **ScaleInRight** | <img src="https://github.com/user-attachments/assets/c245eaa0-3b92-437f-b7d6-73e6c7539d6b?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/a46c2cd0-039d-440e-89a2-94f0496928c9?raw=true" width="250"/>  |
| **Size**         | <img src="https://github.com/user-attachments/assets/a3aa9cf2-136d-4a66-abb9-25742528111e?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/63b2f1ff-08a0-4b54-8a9d-d5136af41ce9?raw=true" width="250"/>  |
| **SlideInDown**  | <img src="https://github.com/user-attachments/assets/57c4e863-5d3e-47fd-b786-ec760a2f0c52?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/0a8611b2-1b68-4a37-9e50-fe81ac1ff22c?raw=true" width="250"/>  |
| **SlideInUp**    | <img src="https://github.com/user-attachments/assets/7a11b8e5-7bff-462b-8fa2-816967fe5887?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/4d38d646-a485-4871-8373-20ea987f4214?raw=true" width="250"/>  |



## Bugs and Feedback

We welcome and appreciate any suggestions you may have for improvement.
For bugs, questions, and discussions please use
the [Github Issues](https://github.com/canopas/animated_reorderable_list/issues).

<a href="https://canopas.com/contact"><img src="https://github.com/user-attachments/assets/b2688b52-5ef8-4e93-ad4d-1ea97e1bf8c6" width=300></a>

## Acknowledgments

This library builds upon the foundation laid by the incredible work of the Flutter team.
The core logic for animated list and drag-and-drop functionality are derived from Flutter's native
widgets, specifically `AnimatedList` and `ReorderableListView`.

## Contribution

The Canopas team enthusiastically welcomes contributions and project participation! There are a
bunch of things you can do if you want to contribute! The [Contributor Guide](CONTRIBUTING.md) has
all the information you need for everything from reporting bugs to contributing entire new features.
Please don't hesitate to jump in if you'd like to, or even ask us questions if something isn't
clear.

## Credits

**animated_reorderable_list** is owned and maintained by the [Canopas team](https://canopas.com/).
You can follow them on Twitter at [@canopassoftware](https://x.com/canopassoftware) for
project updates and releases.

Inspired by [recyclerview-animators](https://github.com/wasabeef/recyclerview-animators) in Android.
