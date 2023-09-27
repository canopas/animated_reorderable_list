import 'package:example/item_card.dart';
import 'package:example/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:motion_list/motion_list.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AnimationType appliedStyle = AnimationType.fadeIn;
  //
  // List<String> list = ['sunny', 'family', "student"];
  // String nextItem = 'Added item';
  List<int> list= [1,2,3];
  int addedNumber=10;


  void insert() {
    addedNumber +=1;

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
        padding: const EdgeInsets.all(10),
        child: SliverMotionList(
          items: list,
          itemBuilder: (BuildContext context, index) {
            //final item= list[index];
            return ItemListCard(index: index);
        },
          insertAnimation: appliedStyle,
          removeAnimation:  appliedStyle,

        ),
      ),
    );
  }
}
