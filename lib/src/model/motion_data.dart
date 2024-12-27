import 'package:flutter/cupertino.dart';

class MotionData {
  final Offset startOffset;
  final Offset endOffset;
  final bool visible;
  final bool animate;

  MotionData(
      {this.startOffset = Offset.zero,
      this.endOffset = Offset.zero,
      this.visible = true,
      this.animate = false});

  MotionData copyWith(
      {Offset? startOffset, Offset? endOffset, bool? visible, bool? animate}) {
    return MotionData(
        startOffset: startOffset ?? this.startOffset,
        endOffset: endOffset ?? this.endOffset,
        visible: visible ?? this.visible,
        animate: animate ?? this.animate);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MotionData &&
          runtimeType == other.runtimeType &&
          startOffset == other.startOffset &&
          endOffset == other.endOffset &&
          animate == other.animate;

  @override
  int get hashCode => Object.hash(startOffset, endOffset, visible, animate);
}
