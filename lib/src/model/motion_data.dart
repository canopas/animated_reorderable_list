import 'package:flutter/cupertino.dart';

class MotionData {
  final Offset startOffset;
  final Offset endOffset;

  final Offset frontItemOffset;
  final Offset nextItemOffset;
  final int index;
  final bool enter;
  final bool exit;

  MotionData(
      {required this.index,
      this.startOffset = Offset.zero,
      this.endOffset = Offset.zero,
      this.frontItemOffset = Offset.zero,
      this.nextItemOffset = Offset.zero,
      this.enter = false,
      this.exit = false});

  MotionData copyWith(
      {Offset? startOffset,
      Offset? endOffset,
      Offset? frontItemOffset,
      Offset? nextItemOffset,
      int? index,
      bool? enter,
      bool? exit}) {
    return MotionData(
        startOffset: startOffset ?? this.startOffset,
        endOffset: endOffset ?? this.endOffset,
        frontItemOffset: frontItemOffset ?? this.frontItemOffset,
        nextItemOffset: nextItemOffset ?? this.nextItemOffset,
        index: index ?? this.index,
        enter: enter ?? this.enter,
        exit: exit ?? this.exit);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MotionData &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          startOffset == other.startOffset &&
          endOffset == other.endOffset &&
          frontItemOffset == other.frontItemOffset &&
          nextItemOffset == other.nextItemOffset &&
          exit == other.exit &&
          enter == other.enter;

  @override
  String toString() {
    return "index: $index  offset: $startOffset, endOffset $endOffset, frontItemOffset: $frontItemOffset, nextItemOffset: $nextItemOffset";
  }
}
