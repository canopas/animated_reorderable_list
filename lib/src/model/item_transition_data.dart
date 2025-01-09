import 'package:flutter/cupertino.dart';

class ItemTransitionData {
  final Offset startOffset;
  final Offset endOffset;
  final bool visible;
  final bool animate;

  ItemTransitionData(
      {this.startOffset = Offset.zero,
      this.endOffset = Offset.zero,
      this.visible = true,
      this.animate = false});

  ItemTransitionData copyWith(
      {Offset? startOffset, Offset? endOffset, bool? visible, bool? animate}) {
    return ItemTransitionData(
        startOffset: startOffset ?? this.startOffset,
        endOffset: endOffset ?? this.endOffset,
        visible: visible ?? this.visible,
        animate: animate ?? this.animate);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemTransitionData &&
          runtimeType == other.runtimeType &&
          startOffset == other.startOffset &&
          endOffset == other.endOffset &&
          animate == other.animate;

  @override
  int get hashCode => Object.hash(startOffset, endOffset, visible, animate);

  @override
  String toString() {
    return 'ItemTransitionData{startOffset: $startOffset, endOffset: $endOffset, visible: $visible, animate: $animate}';
  }
}
