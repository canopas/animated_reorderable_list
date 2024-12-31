import 'package:example/theme/colors.dart';
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
        color: !dragEnabled
            ? containerLowColor
            : Colors.primaries[id % Colors.primaries.length],
        child: Center(
          child: dragEnabled
              ? Text((id).toString(),
                  style: const TextStyle(fontSize: 22, color: Colors.black))
              : const Icon(Icons.lock, color: Colors.white),
        ),
      ),
    );
  }
}
