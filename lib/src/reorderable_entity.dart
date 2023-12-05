import 'package:flutter/cupertino.dart';

class ReorderableItem {
  final Key key;
  final Offset oldOffset;
  final Offset updatedOffset;
  final int oldIndex;
  final int updatedIndex;
  final Widget? child;

  ReorderableItem(
      {required this.key,
      required this.oldOffset,
      required this.updatedOffset,
      required this.oldIndex,
      required this.updatedIndex,
       this.child});

  ReorderableItem copywith(
      {Key? key,
        Offset? oldOffset,
      Offset? updatedOffset,
      int? oldIndex,
      int? updatedIndex,
      Widget? child}) {
    return ReorderableItem(
      key: key??this.key,
        oldOffset: oldOffset ?? this.oldOffset,
        updatedOffset: updatedOffset ?? this.updatedOffset,
        oldIndex: oldIndex ?? this.oldIndex,
        updatedIndex: updatedIndex ?? this.updatedIndex,
        child: child ?? this.child);
  }

  @override
 String toString(){
    return "Key: $key, oldOffset: $oldOffset, updatedOffset: $updatedOffset, oldIndex: $oldIndex, updatedIndex: $updatedIndex ";
  }
}
