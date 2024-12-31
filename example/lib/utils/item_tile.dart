import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ItemTile extends StatelessWidget {
  final int id;
  final bool dragEnabled;
  final bool isLocked;

  const ItemTile({
    super.key,
    required this.id,
    this.dragEnabled = true,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isLocked
              ? containerLowColor
              : Colors.primaries[id % Colors.primaries.length]
                  .withValues(alpha: dragEnabled ? 1 : 0.3)),
      child: Center(
        child: !isLocked
            ? Text(
                'Item $id',
                style: const TextStyle(fontSize: 25),
              )
            : const Icon(Icons.lock, color: Colors.white),
      ),
    );
  }
}
