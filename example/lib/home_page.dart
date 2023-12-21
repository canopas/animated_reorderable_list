import 'package:example/utils/extension.dart';
import 'package:example/utils/item_card.dart';
import 'package:example/utils/item_tile.dart';
import 'package:flutter/material.dart';
import 'package:motion_list/motion_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AnimationType appliedStyle = AnimationType.fadeIn;
  List<int> list = List.generate(3, (index) => index);
  int addedNumber = 3;
  bool isGrid = true;

  void insert() {
    addedNumber += 1;
    setState(() {
      list.insert(1, addedNumber);
    });
  }

  void remove() {
    setState(() {
      list.removeAt(1);
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
                        return ItemCard(index: index);
                      },
                      insertDuration: const Duration(milliseconds: 200),
                      insertAnimation: appliedStyle,
                      removeAnimation: appliedStyle,
                      sliverGridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4),
                    )
                  : MotionListViewBuilder(
                      items: list,
                      itemBuilder: (BuildContext context, int index) {
                        return ItemTile(index: index);
                      },
                      insertDuration: const Duration(milliseconds: 200),
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
