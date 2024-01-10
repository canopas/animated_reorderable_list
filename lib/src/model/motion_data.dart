import 'package:flutter/cupertino.dart';

class MotionData {
  final Offset startOffset;
  final Offset endOffset;
  final Duration duration;

  MotionData(
      {this.startOffset = Offset.zero,
      this.endOffset = Offset.zero,
      this.duration = const Duration(milliseconds: 300)});

  MotionData copyWith({
    Offset? startOffset,
    Offset? endOffset,
    Duration? duration,
    int? index,
  }) {
    return MotionData(
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
          endOffset == other.endOffset;

  @override
  int get hashCode => startOffset.hashCode ^ endOffset.hashCode;
}
