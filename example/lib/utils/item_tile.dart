import 'package:flutter/material.dart';

class ItemTile extends StatefulWidget {
  final VoidCallback? onTap;
  final int index;
  final bool selected;

  const ItemTile({
    super.key,
    this.onTap,
    required this.index,
    this.selected = false,
  });

  @override
  State<ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<ItemTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Column(
          children: [
            Container(
              height: 60,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.primaries[widget.index % Colors.primaries.length],
              ),
              child: Center(
                child: Text(
                  'Item ${widget.index}',
                  style: const TextStyle(fontSize: 25),
                ),
              ),
            ),
            const SizedBox(
              height: 5,
            )
          ],
        ),
      ),
    );
  }
}
