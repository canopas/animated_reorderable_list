import 'dart:ui';

import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:example/theme/colors.dart';
import 'package:example/utils/animation_provider.dart';
import 'package:example/utils/extension.dart';
import 'package:example/utils/item_card.dart';
import 'package:example/utils/item_tile.dart';
import 'package:flutter/material.dart';

import 'model/user_model.dart';

void main() {
  runApp(
      const MaterialApp(title: 'Animated Reorderable List', home: HomePage()));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AnimationType appliedStyle = AnimationType.fadeIn;
  List<User> list = [];

  int addedNumber = 9;
  bool isGrid = true;

  List<User> nonDraggableItems = [];
  List<User> lockedItems = [];

  List<AnimationEffect> animations = [];

  @override
  void initState() {
    super.initState();
    list = List.generate(8, (index) => User(name: "User $index", id: index));
    nonDraggableItems = list.where((user) => user.id == 1).toList();
    lockedItems = list.where((user) => user.id == 0).toList();
  }

  void insert() {
    addedNumber += 1;
    setState(() {
      list.insert(1, User(name: "User $addedNumber", id: addedNumber));
    });
  }

  void remove() {
    setState(() {
      if (list.isNotEmpty && list.length > 1) list.removeAt(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: surfaceColor,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          title: _listType(),
          actions: [
            IconButton(
                onPressed: () {
                  final child1 = list[2];
                  final child2 = list[7];
                  list[2] = child2;
                  list[7] = child1;
                  setState(() {});
                },
                icon: const Icon(
                  Icons.swap_horiz,
                  color: primaryColor,
                )),
            IconButton(
                onPressed: insert,
                icon: const Icon(
                  Icons.add,
                  color: primaryColor,
                )),
            IconButton(
                onPressed: remove,
                icon: const Icon(
                  Icons.remove,
                  color: primaryColor,
                )),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimationControlPanel(),
              Expanded(
                child: isGrid
                    ? AnimatedReorderableGridView(
                        items: list,
                        itemBuilder: (BuildContext context, int index) {
                          final user = list[index];
                          return ItemCard(
                            key: ValueKey(user.id),
                            id: user.id,
                            dragEnabled: !nonDraggableItems.contains(user),
                            isLocked: lockedItems.contains(user),
                          );
                        },
                        sliverGridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4),
                        enterTransition: animations,
                        exitTransition: animations,
                        insertDuration: const Duration(milliseconds: 300),
                        removeDuration: const Duration(milliseconds: 300),
                        onReorder: (int oldIndex, int newIndex) {
                          final Map<User, int> lockedItemPositions = {
                            for (int i = 0; i < list.length; i++)
                              if (lockedItems.contains(list[i])) list[i]: i
                          };
                          setState(() {
                            final User user = list.removeAt(oldIndex);
                            list.insert(newIndex, user);
                            for (var entry in lockedItemPositions.entries) {
                              list.remove(entry.key);
                              list.insert(
                                  entry.value,
                                  entry
                                      .key); // Insert based on original position (id in this case)
                            }
                          });
                        },
                        nonDraggableItems: nonDraggableItems,
                        lockedItems: lockedItems,
                        onReorderEnd: (int index) {
                          //  print(" End index :  $index");
                        },
                        onReorderStart: (int index) {
                          // print(" Start index :  $index");
                        },
                        proxyDecorator: proxyDecorator,
                        isSameItem: (a, b) => a.id == b.id,

                        /*  A custom builder that is for inserting items with animations.

                              insertItemBuilder: (Widget child, Animation<double> animation){
                                 return ScaleTransition(
                                       scale: animation,
                                       child: child,
                                     );
                                    },


                      */
                        /*  A custom builder that is for removing items with animations.

                                  removeItemBuilder: (Widget child, Animation<double> animation){
                                     return ScaleTransition(
                                       scale: animation,
                                       child: child,
                                     );
                                    },
                      */
                      )
                    : AnimatedReorderableListView(
                        items: list,
                        itemBuilder: (BuildContext context, int index) {
                          final user = list[index];
                          return ItemTile(
                            key: ValueKey(user.id),
                            id: user.id,
                            dragEnabled: !nonDraggableItems.contains(user),
                            isLocked: lockedItems.contains(user),
                          );
                        },
                        enterTransition: animations,
                        exitTransition: animations,
                        insertDuration: const Duration(milliseconds: 300),
                        removeDuration: const Duration(milliseconds: 300),
                        nonDraggableItems: nonDraggableItems,
                        lockedItems: lockedItems,
                        buildDefaultDragHandles: true,
                        onReorder: (int oldIndex, int newIndex) {
                          final Map<User, int> lockedItemPositions = {
                            for (int i = 0; i < list.length; i++)
                              if (lockedItems.contains(list[i])) list[i]: i
                          };
                          setState(() {
                            final User user = list.removeAt(oldIndex);
                            list.insert(newIndex, user);
                            for (var entry in lockedItemPositions.entries) {
                              list.remove(entry.key);
                              list.insert(
                                  entry.value,
                                  entry
                                      .key); // Insert based on original position (id in this case)
                            }
                          });
                        },
                        proxyDecorator: proxyDecorator,
                        isSameItem: (a, b) => a.id == b.id

                        /*  A custom builder that is for inserting items with animations.

                                insertItemBuilder: (Widget child, Animation<double> animation){
                                   return ScaleTransition(
                                         scale: animation,
                                         child: child,
                                       );
                                      },


                        */
                        /*  A custom builder that is for removing items with animations.

                                    removeItemBuilder: (Widget child, Animation<double> animation){
                                       return ScaleTransition(
                                         scale: animation,
                                         child: child,
                                       );
                                      },
                        */
                        ),
              ),
            ],
          ),
        ));
  }

  Widget _buildAnimationControlPanel() {
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: containerLowColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AnimationType>(
                dropdownColor: containerLowColor,
                borderRadius: BorderRadius.circular(10),
                alignment: Alignment.center,
                iconEnabledColor: primaryColor,
                value: appliedStyle,
                items: AnimationType.values.map((AnimationType animationType) {
                  return DropdownMenuItem<AnimationType>(
                    value: animationType,
                    child: Text(
                      animationType.name.capitalize(),
                      style: const TextStyle(
                          fontSize: 20,
                          color: primaryColor,
                          fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
                onChanged: (AnimationType? animationType) {
                  if (animationType == null) {
                    return;
                  }
                  animations = [];
                  AnimationEffect animation =
                      AnimationProvider.buildAnimation(animationType);
                  animations.add(animation);
                  setState(() {
                    appliedStyle = animationType;
                  });
                }),
          ),
        ));
  }

  Widget _listType() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: containerLowColor,
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                onPressed: () {
                  if (isGrid) return;
                  setState(() {
                    isGrid = !isGrid;
                  });
                },
                icon: Icon(
                  Icons.grid_view_rounded,
                  color: isGrid ? primaryColor : textSecondaryDarkColor,
                )),
            const VerticalDivider(
              indent: 12,
              endIndent: 12,
              width: 1,
              color: textSecondaryLightColor,
            ),
            IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (!isGrid) return;

                  setState(() {
                    isGrid = !isGrid;
                  });
                },
                icon: Icon(
                  Icons.list,
                  color: !isGrid ? primaryColor : textSecondaryDarkColor,
                ))
          ],
        ),
      ),
    );
  }
}

Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget? child) {
      final double animValue = Curves.easeInOut.transform(animation.value);
      final double elevation = lerpDouble(0, 6, animValue)!;
      return Material(
        elevation: elevation,
        color: const Color(0x00000000),
        shadowColor: primaryColor.withValues(alpha: 0.9),
        child: child,
      );
    },
    child: child,
  );
}
