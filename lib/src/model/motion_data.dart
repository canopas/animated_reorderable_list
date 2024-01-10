import 'package:flutter/cupertino.dart';

class MotionData {
  final Offset startOffset;
  final Offset endOffset;

  MotionData(
      {this.startOffset = Offset.zero,
      this.endOffset = Offset.zero,
      });

  MotionData copyWith({
    Offset? startOffset,
    Offset? endOffset,
    int? index,
  }) {
    return MotionData(
        startOffset: startOffset ?? this.startOffset,
        endOffset: endOffset ?? this.endOffset,
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
  int get hashCode => startOffset.hashCode^endOffset.hashCode;

}
