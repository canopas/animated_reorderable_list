import 'package:flutter/cupertino.dart';

class MotionData {
  final Offset startOffset;
  final Offset endOffset;
  final Duration duration;

  MotionData(
      {this.startOffset = Offset.zero,
      this.endOffset = Offset.zero,
      this.duration = const Duration(milliseconds: 300)});

  MotionData copyWith(
      {Offset? startOffset,
      Offset? endOffset,
      Offset? frontItemOffset,
      Offset? nextItemOffset,
        Duration? duration,
      int? index,
      bool? enter,
      bool? exit}) {
    return MotionData(
        startOffset: startOffset ?? this.startOffset,
        endOffset: endOffset ?? this.endOffset,
      duration:duration?? this.duration
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MotionData &&
          runtimeType == other.runtimeType &&
          startOffset == other.startOffset &&
          endOffset == other.endOffset;

  @override
  String toString() {
    return "startOffset: $startOffset, endOffset $endOffset Duration: $duration";
  }
}
