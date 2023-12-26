import 'package:example/utils/extension.dart';
import 'package:example/utils/item_card.dart';
import 'package:example/utils/item_tile.dart';
import 'package:flutter/material.dart';
import 'package:motion_list/motion_list.dart';

class User {
  final String name;
  final int index;

  User({required this.name, required this.index});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AnimationType appliedStyle = AnimationType.fadeIn;
  List<User> list =
      List.generate(3, (index) => User(name: "User $index", index: index));
  int addedNumber = 3;
  bool isGrid = false;

  void insert() {
    addedNumber += 1;
    setState(() {
      list.insert(1, User(name: "User $addedNumber", index: addedNumber));
    });
  }

  // void insert() {
  //   List<User> newList = List.generate(
  //       2,
  //       (index) => User(
  //           name: "User ${addedNumber + index}", index: index + addedNumber));
  //   setState(() {
  //     list.insertAll(1, newList);
  //     addedNumber += 2;
  //   });
  // }

  void remove() {
    setState(() {
      if (list.isNotEmpty && list.length > 1) list.removeAt(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Row(
          children: [
            const SizedBox(
              width: 10,
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<AnimationType>(
                  iconEnabledColor: Colors.black87,
                  value: appliedStyle,
                  items:
                      AnimationType.values.map((AnimationType animationType) {
                    return DropdownMenuItem<AnimationType>(
                      value: animationType,
                      child: Text(
                        animationType.name.capitalize(),
                        style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                  onChanged: (AnimationType? animationType) {
                    if (animationType == null) {
                      return;
                    }
                    setState(() {
                      appliedStyle = animationType;
                    });
                  }),
            )
          ],
        ),
        actions: [
          TextButton(
              onPressed: insert,
              child: const Text(
                'ADD',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
              )),
          TextButton(
              onPressed: remove,
              child: const Text(
                'DEL',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
              ))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isGrid != false) {
                          isGrid = false;
                        }
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'List',
                        style: TextStyle(fontSize: 25),
                      ),
                    )),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () {
                    setState(() {
                      if (isGrid != true) {
                        isGrid = true;
                      }
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Grid',
                      style: TextStyle(fontSize: 25),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: isGrid
                  ? MotionGridViewBuilder(
                      items: list,
                      scrollDirection: Axis.vertical,
                      itemBuilder: (BuildContext context, int index) {
                        // print("Key ${list[index].name}");
                        return ItemCard(
                            key: Key('${list[index].name}'),
                            index: list[index].index);
                      },
                      removedItemBuilder: (context, item) {
                        return ItemCard(
                            key: Key('${item.name}'), index: item.index);
                      },
                      insertAnimation: appliedStyle,
                      removeAnimation: appliedStyle,
                      insertDuration: const Duration(milliseconds: 3000),
                      removeDuration: const Duration(milliseconds: 3000),
                      sliverGridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4),
                    )
                  : MotionListViewBuilder(
                items: list,
                      itemBuilder: (BuildContext context, int index) {
                        return ItemTile(
                            key: Key('${list[index].name}'),
                            index: list[index].index);
                      },
                      removedItemBuilder: (context, item) {
                        return ItemTile(
                            key: Key('${item.name}'), index: item.index);
                      },
                      insertDuration: const Duration(milliseconds: 3000),
                      removeDuration: const Duration(milliseconds: 3000),
                      insertAnimation: appliedStyle,
                      removeAnimation: appliedStyle,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
