
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ItemListCard extends StatelessWidget {
  final  String? item;
  final VoidCallback? onTap;
  final bool selected;
  const ItemListCard({super.key,
    this.item,
    this.onTap,
    this.selected=false,
  });

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:onTap,
        child: SizedBox(
          // height: 80,
          child: Column(
            children: [
              Container(
                height: 50,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.green,
                ),
                child:    Center(
                  child: Text('Item $item',style: const TextStyle(
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
      ),
    );
  }
}