import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final int id;
  final bool dragEnabled;

  const ItemCard({super.key, required this.id, this.dragEnabled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150.0,
      width: 150,
      child: Card(
        color: dragEnabled
            ? Colors.primaries[id % Colors.primaries.length]
            : Colors.grey,
        child: Center(
          child: Text(
            (id).toString(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}
