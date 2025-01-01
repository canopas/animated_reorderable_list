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
- [x] Enable/disable drag and drop functionality.
- [x] Control reordering of item / locked an item.

## Demo

### Reorderable List

| ![Image 1](https://github.com/user-attachments/assets/7a31a2c0-f49b-4280-ac8c-b4bc35e5a3db?raw=true) | ![Image 2](https://github.com/user-attachments/assets/3a7d34ec-eb2f-491c-af8f-43b569607d91?raw=true) | ![Image 3](https://github.com/user-attachments/assets/68c1b0f7-481e-4e6e-b995-e1b754354d1f?raw=true) |
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

| Animation Type   | ListView Example                                                                                                  | GridView Example              |
|------------------|-------------------------------------------------------------------------------------------------------------------|-------------------------------|
| **FadeIn**       | <img src="gif/animations/list/fade-in.gif?raw=true" width="250"/>                                                 | <img src="https://github.com/user-attachments/assets/38376923-8aa6-4803-a09c-a301db98c939?raw=true" width="250"/>  |
| **FlipInY**      | <img src="https://github.com/user-attachments/assets/e7ed69dc-c038-4c14-ad82-59dec5075b10?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/cb8c0be3-9178-41e4-991b-4d652bde7ed1?raw=true" width="250"/>  |
| **FlipInX**      | <img src="https://github.com/user-attachments/assets/08a7753f-95f7-48c8-881f-3e746798b3ca?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/f67f2463-459e-4e97-ac3f-4cb410eacf00?raw=true" width="250"/>  |
| **Landing**      | <img src="https://github.com/user-attachments/assets/1c8ab183-1bce-4cf9-9a3d-7b4132083583?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/363f34d1-45b5-4260-a2ce-ec927b67ec02?raw=true" width="250"/>  |
| **ScaleIn**      | <img src="https://github.com/user-attachments/assets/a3bdbeb9-7b6e-4ee7-a822-274df2f84954?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/69c06e86-e43a-4e71-ad2e-78f4c370c0de?raw=true" width="250"/>  |
| **ScaleInTop**   | <img src="https://github.com/user-attachments/assets/2548ebdb-b873-44b7-b01a-fe1910fc5386?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/b1d63684-f934-4971-97b9-f0bce6358860?raw=true" width="250"/>  |
| **ScaleInBottom**| <img src="https://github.com/user-attachments/assets/f175da62-6a3b-4f8b-947f-a8ee9c6b656f?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/52f824ee-e437-464f-a462-3474a63e4306?raw=true" width="250"/>  |
| **ScaleInLeft**  | <img src="https://github.com/user-attachments/assets/010917bb-4e04-4455-951e-f9460f9c64a3?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/844e785a-c364-462e-9e9b-37d523bdda08?raw=true" width="250"/>  |
| **ScaleInRight** | <img src="https://github.com/user-attachments/assets/728c3886-f2eb-4a08-b87e-9ba68867e527?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/cbbe1462-a24b-4a75-96ba-56c028b53818?raw=true" width="250"/>  |
| **Size**         | <img src="https://github.com/user-attachments/assets/8bdb4cf7-c824-4a61-8cd2-a6902b64013e?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/9729cf06-d63d-4208-b964-30042520c8d7?raw=true" width="250"/>  |
| **SlideInLeft**  | <img src="https://github.com/user-attachments/assets/6f8d943f-bc39-4e79-a387-976b10220a52?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/1496315f-907d-465b-b537-4fa76ff7d4ea?raw=true" width="250"/>  |
| **SlideInRight**  | <img src="https://github.com/user-attachments/assets/6197c7b4-9060-4da4-a367-1a4570176916?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/353b2074-707d-4f76-a499-14caac021941?raw=true" width="250"/>  |
| **SlideInDown**  | <img src="https://github.com/user-attachments/assets/64c4c6cc-fbd6-4955-b5d8-4726e1e9b271?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/b6f8bb96-f395-4378-90bf-c8b0d5a17808?raw=true" width="250"/>  |
| **SlideInUp**    | <img src="https://github.com/user-attachments/assets/d8da449a-9d65-48c8-b9d5-b27f193b79c3?raw=true" width="250"/> | <img src="https://github.com/user-attachments/assets/ee7640c3-b1ea-443c-ba1a-b0a65f5b13af?raw=true" width="250"/>  |



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
