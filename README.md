# motion_list

A Flutter Animated Listview with simple implementation with animation and smooth transition.

## Features
- Smooth animations when adding and removing items from the list.
- List and Grid support.
- Easily customize animation styles and duration to Flutter list.

## Demo

### List Animations
<img src="gif/demo.gif" width="32%"> <img src="gif/demo1.gif" width="32%"> 

### Grid Animations
<img src="gif/demo2.gif" width="32%"> <img src="gif/demo3.gif" width="32%">

### How to use it?
[Sample](https://github.com/cp-sneha-s/flutter_motion_list/tree/main/example) app demonstrates how simple the usage of the library actually is.

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
For bugs, questions and discussions please use the [Github Issues](https://github.com/cp-sneha-s/flutter_motion_list/issues).

## Credits
**motion_list** is owned and maintained by the [Canopas team](https://canopas.com/). You can follow them on Twitter at [@canopassoftware](https://twitter.com/canopassoftware) for project updates and releases.

Inspired by [recyclerview-animators](https://github.com/wasabeef/recyclerview-animators) in Android.

## Licence

```
Copyright 2022 Canopas Software LLP

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

