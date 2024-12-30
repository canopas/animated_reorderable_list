import 'package:flutter/material.dart';
import '../theme/colors.dart';

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
        borderRadius: BorderRadius.circular(10),
        color: !dragEnabled ? containerLowColor : Colors.primaries[id % Colors.primaries.length],
      ),
      child: Center(
        child: dragEnabled
            ? Text(
                'Item $id',
                style: const TextStyle(fontSize: 25),
              )
            : const Icon(Icons.lock, color: Colors.white),
      ),
    );
  }
}
