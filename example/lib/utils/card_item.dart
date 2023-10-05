import 'package:flutter/material.dart';

class CardItem extends StatelessWidget {
  final int index;
  const CardItem({super.key,required this.index});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80.0,
      width: 80,
      child: Card(
        color: Colors.primaries[index % Colors.primaries.length],
        child: Center(
          child: Text(
            (index + 1).toString(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}
