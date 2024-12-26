import 'package:flutter/material.dart';

class ItemTile extends StatelessWidget {
  final int id;
  final bool dragEnabled;

  const ItemTile({
    super.key,
    required this.id,
    this.dragEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(dragEnabled ? 10 : 0),
        color: dragEnabled
            ? Colors.primaries[id % Colors.primaries.length]
            : Colors.grey,
      ),
      child: Center(
        child: Text(
          'Item $id',
          style: const TextStyle(fontSize: 25),
        ),
      ),
    );
  }
}
