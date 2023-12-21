import 'package:flutter/cupertino.dart';

class MotionData {
  final Offset offset;
  final Offset frontItemOffset;
  final Offset nextItemOffset;
  final int index;
  final bool enter;
  final bool exit;

  MotionData(
      {required this.index,
      this.offset = Offset.zero,
      this.frontItemOffset = Offset.zero,
      this.nextItemOffset = Offset.zero,
      this.enter = false,
      this.exit = false});

  MotionData copyWith({
    Offset? offset,
    Offset? frontItemOffset,
    Offset? nextItemOffset,
    int? index,
  }) {
    return MotionData(
        offset: offset ?? this.offset,
        frontItemOffset: frontItemOffset ?? this.frontItemOffset,
        nextItemOffset: nextItemOffset ?? this.nextItemOffset,
        index: index ?? this.index);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MotionData &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          offset == other.offset &&
          frontItemOffset == other.frontItemOffset &&
          nextItemOffset == other.nextItemOffset &&
          exit == other.exit &&
          enter == other.enter;

  @override
  String toString() {
    return "offset: $offset, frontItemOffset: $frontItemOffset, nextItemOffset: $nextItemOffset, index: $index ";
  }
}
