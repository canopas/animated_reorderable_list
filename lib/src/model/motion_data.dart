import 'package:flutter/cupertino.dart';

class MotionData {
  final Offset startOffset;
  final Offset endOffset;
  final Duration duration;
  final Key? key;

  MotionData(
      {this.key,
      this.startOffset = Offset.zero,
      this.endOffset = Offset.zero,
      this.duration = const Duration(milliseconds: 300)});

  MotionData copyWith({
    Key? key,
    Offset? startOffset,
    Offset? endOffset,
    Duration? duration,
  }) {
    return MotionData(
        key: key ?? this.key,
        startOffset: startOffset ?? this.startOffset,
        endOffset: endOffset ?? this.endOffset,
        duration: duration ?? this.duration);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MotionData &&
          runtimeType == other.runtimeType &&
          startOffset == other.startOffset &&
          key == other.key &&
          endOffset == other.endOffset;

  @override
  String toString() {
    return "startOffset: $startOffset, endOffset $endOffset";
  }
}
