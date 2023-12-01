import 'package:flutter/cupertino.dart';

class ReorderableEntity {
  final Key? key;
  final Offset oldOffset;
  final Offset updatedOffset;
  final int oldIndex;
  final int updatedIndex;

  ReorderableEntity(
      {this.key,
      required this.oldOffset,
      required this.updatedOffset,
      required this.oldIndex,
      required this.updatedIndex});

  ReorderableEntity copywith(
      {Offset? oldOffset,
      Offset? updatedOffset,
      int? oldIndex,
      int? updatedIndex}) {
    return ReorderableEntity(
        oldOffset: oldOffset ?? this.oldOffset,
        updatedOffset: updatedOffset ?? this.updatedOffset,
        oldIndex: oldIndex ?? this.oldIndex,
        updatedIndex: updatedIndex ?? this.updatedIndex);
  }
}
