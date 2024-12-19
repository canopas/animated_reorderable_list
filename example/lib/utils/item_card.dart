import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final int index;

  const ItemCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        print('Tapped on item $index');
      },
      onLongPress: () {
        print('Long pressed on item $index');
      },
      child: SizedBox(
        height: 150.0,
        width: 150,
        child: Card(
          color: Colors.primaries[index % Colors.primaries.length],
          child: Center(
            child: Text(
              (index).toString(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
      ),
    );
  }
}
