import 'package:flutter/material.dart';

class ItemListCard extends StatelessWidget {
  final VoidCallback? onTap;
  final int index;
  final bool selected;
  const ItemListCard({super.key,
    this.onTap,
    required this.index,
    this.selected=false,
  });

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:onTap,
        child: Column(
          children: [
            Container(
              width: 50,
              height: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.primaries[index % Colors.primaries.length],
              ),
              child:    Center(
                child: Text('Item $index',style: const TextStyle(
                    fontSize: 25
                ),),
              ),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}