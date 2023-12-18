import 'package:flutter/cupertino.dart';

class ReorderableItem {
  final Key key;
  final Offset oldOffset;
  final Offset updatedOffset;
  final int oldIndex;
  final int updatedIndex;
  bool visible;
  bool isNew;
  final Widget? child;

  ReorderableItem(
      {required this.key,
      required this.oldOffset,
      required this.updatedOffset,
      required this.oldIndex,
      required this.updatedIndex,
      this.visible = true,
      this.isNew = false,
      this.child});

  ReorderableItem copyWith(
      {Key? key,
      Offset? oldOffset,
      Offset? updatedOffset,
      int? oldIndex,
      int? updatedIndex,
      bool? visible,
      bool? isNew,
      Widget? child}) {
    return ReorderableItem(
        key: key ?? this.key,
        oldOffset: oldOffset ?? this.oldOffset,
        updatedOffset: updatedOffset ?? this.updatedOffset,
        oldIndex: oldIndex ?? this.oldIndex,
        updatedIndex: updatedIndex ?? this.updatedIndex,
        visible: visible ?? this.visible,
        isNew: isNew ?? this.isNew,
        child: child ?? this.child);
  }

  @override
  String toString() {
    return "Key: $key, oldOffset: $oldOffset, updatedOffset: $updatedOffset, oldIndex: $oldIndex, updatedIndex: $updatedIndex ";
  }
}
