import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

class SliverGridWithCustomGeometryLayout extends SliverGridRegularTileLayout {
  final SliverGridGeometry Function(
      int index, SliverGridRegularTileLayout layout) geometryBuilder;

  const SliverGridWithCustomGeometryLayout({
    required this.geometryBuilder,
    required int crossAxisCount,
    required double mainAxisStride,
    required double crossAxisStride,
    required double childMainAxisExtent,
    required double childCrossAxisExtent,
    required bool reverseCrossAxis,
  })  : assert(crossAxisCount > 0),
        assert(mainAxisStride >= 0),
        assert(crossAxisStride >= 0),
        assert(childMainAxisExtent >= 0),
        assert(childCrossAxisExtent >= 0),
        super(
            crossAxisCount: crossAxisCount,
            mainAxisStride: mainAxisStride,
            crossAxisStride: crossAxisStride,
            childMainAxisExtent: childMainAxisExtent,
            childCrossAxisExtent: childCrossAxisExtent,
            reverseCrossAxis: reverseCrossAxis);

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
   //print("$index------ ${geometryBuilder(index, this)}");
    return geometryBuilder(index, this);
  }

  Offset getChildOffset(int index) {
    return Offset(
      crossAxisStride * (index % crossAxisCount),
      mainAxisStride * (index ~/ crossAxisCount),
    );
  }
}

class SliverReorderableGridDelegateWithFixedCrossAxisCount
    extends SliverGridDelegateWithFixedCrossAxisCount {
  final int itemCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
   double childCrossAxisExtent = 0.0;
   double childMainAxisExtent= 0.0;

   SliverReorderableGridDelegateWithFixedCrossAxisCount({
    required this.itemCount,
    required int crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
  })  : assert(itemCount >= 0),
        assert(crossAxisCount > 0),
        assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        assert(childAspectRatio > 0),
        super(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        );

  bool _debugAssertIsValid() {
    assert(itemCount >= 0);
    assert(crossAxisCount > 0);
    assert(mainAxisSpacing >= 0);
    assert(crossAxisSpacing >= 0);
    assert(childAspectRatio > 0);
    return true;
  }



  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    assert(_debugAssertIsValid());
    final usableCrossAxisCount = max(0.0,
        constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1));

     childCrossAxisExtent = usableCrossAxisCount / crossAxisCount;
     childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
    return  SliverGridWithCustomGeometryLayout(
        geometryBuilder: (index, layout) {
          return SliverGridGeometry(
              scrollOffset: (index ~/ crossAxisCount) * layout.mainAxisStride,
              crossAxisOffset: _getOffsetFromStartInCrossAxis(index, layout),
              mainAxisExtent: childMainAxisExtent,
              crossAxisExtent: childCrossAxisExtent);
        },
        crossAxisCount: crossAxisCount,
        mainAxisStride: childMainAxisExtent + mainAxisSpacing,
        crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
        childMainAxisExtent: childMainAxisExtent,
        childCrossAxisExtent: childCrossAxisExtent,
        reverseCrossAxis:
            axisDirectionIsReversed(constraints.crossAxisDirection));
  }

  Offset getChildOffset(int index, SliverGridRegularTileLayout layout) {
    final int row = index ~/ crossAxisCount;
    final int col = index % crossAxisCount;

    final double x = col * (layout.childCrossAxisExtent + crossAxisSpacing);
    final double y = row * (layout.childMainAxisExtent + mainAxisSpacing);

    return Offset(x, y);
  }



  double _getOffsetFromStartInCrossAxis(
      int index,
      SliverGridRegularTileLayout layout,
      ) {
    final crossAxisStart = (index % crossAxisCount) * layout.crossAxisStride;

    if (layout.reverseCrossAxis) {
      return crossAxisCount * layout.crossAxisStride -
          crossAxisStart -
          layout.childCrossAxisExtent -
          (layout.crossAxisStride - layout.childCrossAxisExtent);
    }
    return crossAxisStart;
  }

  @override
  bool shouldRelayout(SliverGridDelegateWithFixedCrossAxisCount oldDelegate) {
    return oldDelegate.crossAxisCount != crossAxisCount
        || oldDelegate.mainAxisSpacing != mainAxisSpacing
        || oldDelegate.crossAxisSpacing != crossAxisSpacing
        || oldDelegate.childAspectRatio != childAspectRatio
        || oldDelegate.mainAxisExtent != mainAxisExtent;
  }
}
