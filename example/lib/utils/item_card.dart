import 'package:example/theme/colors.dart';
import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final int id;
  final bool dragEnabled;
  final bool isLocked;

  const ItemCard(
      {super.key,
      required this.id,
      this.dragEnabled = true,
      this.isLocked = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150.0,
      width: 150,
      child: Card(
        color: isLocked
            ? containerLowColor
            : Colors.primaries[id % Colors.primaries.length]
                .withValues(alpha: dragEnabled ? 1 : 0.3),
        child: Center(
          child: !isLocked
              ? Text((id).toString(),
                  style: const TextStyle(fontSize: 22, color: Colors.black))
              : const Icon(Icons.lock, color: Colors.white),
        ),
      ),
    );
  }
}
