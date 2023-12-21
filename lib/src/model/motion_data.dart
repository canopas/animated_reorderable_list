import 'package:flutter/cupertino.dart';

class MotionData {
  final Offset target;

  // final Offset frontItemOffset;
  // final Offset nextItemOffset;
  final int index;
  final bool enter;
  final bool exit;

  MotionData(
      {required this.index,
      this.target = Offset.zero,
      // this.frontItemOffset = Offset.zero,
      // this.nextItemOffset = Offset.zero,
      this.enter = false,
      this.exit = false});

  MotionData copyWith(
      {Offset? offset,
      Offset? frontItemOffset,
      Offset? nextItemOffset,
      int? index,
      bool? enter,
      bool? exit}) {
    return MotionData(
        target: offset ?? this.target,
        // frontItemOffset: frontItemOffset ?? this.frontItemOffset,
        // nextItemOffset: nextItemOffset ?? this.nextItemOffset,
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
          target == other.target &&
          // frontItemOffset == other.frontItemOffset &&
          // nextItemOffset == other.nextItemOffset &&
          exit == other.exit &&
          enter == other.enter;

  @override
  String toString() {
    return "offset: $target, index: $index enter $enter exit $exit";
  }
}
