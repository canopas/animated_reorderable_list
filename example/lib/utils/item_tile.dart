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
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
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
          ),
          const SizedBox(
            height: 5,
          )
        ],
      ),
    );
  }
}
