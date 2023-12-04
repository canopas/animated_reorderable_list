import 'package:flutter/cupertino.dart';

class ReorderableEntity {
  final Key key;
  final Offset oldOffset;
  final Offset updatedOffset;
  final int oldIndex;
  final int updatedIndex;
  final Widget? child;

  ReorderableEntity(
      {required this.key,
      required this.oldOffset,
      required this.updatedOffset,
      required this.oldIndex,
      required this.updatedIndex,
       this.child});

  ReorderableEntity copywith(
      {Key? key,
        Offset? oldOffset,
      Offset? updatedOffset,
      int? oldIndex,
      int? updatedIndex,
      Widget? child}) {
    return ReorderableEntity(
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
