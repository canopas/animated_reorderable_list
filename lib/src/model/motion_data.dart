import 'package:flutter/cupertino.dart';

class MotionData {
  final Offset startOffset;
  final Offset endOffset;
  final Duration duration;
  final bool visible;

  MotionData(
      {this.startOffset = Offset.zero,
      this.endOffset = Offset.zero,
      });
      this.duration = const Duration(milliseconds: 300),
      this.visible = true});

  MotionData copyWith({
    Offset? startOffset,
    Offset? endOffset,
    int? index,
  }) {
  MotionData copyWith(
      {Offset? startOffset,
      Offset? endOffset,
      Duration? duration,
      bool? visible}) {
    return MotionData(
        startOffset: startOffset ?? this.startOffset,
        endOffset: endOffset ?? this.endOffset,
        duration: duration ?? this.duration,
        visible: visible ?? this.visible);
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
  int get hashCode => startOffset.hashCode ^ endOffset.hashCode;
}
