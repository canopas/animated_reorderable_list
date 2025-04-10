import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that captures sliver constraints and notifies through a callback.
///
/// This widget can be used to intercept the constraints passed to a sliver
/// without introducing a new build step, making it more efficient than using
/// [SliverLayoutBuilder].
///
/// Example:
/// ```dart
/// SliverConstraintsCapture(
///   onConstraintsChanged: (constraints) {
///     print('Sliver constraints: $constraints');
///   },
///   child: SliverList(...),
/// )
/// ```
class SliverConstraintsCapture extends SingleChildRenderObjectWidget {
  /// Creates a widget that captures sliver constraints.
  ///
  /// The [onConstraintsChanged] callback will be called during layout
  /// when the constraints are available.
  ///
  /// The [child] parameter is required and will be laid out normally.
  const SliverConstraintsCapture({
    super.key,
    required this.onConstraintsChanged,
    required Widget child,
  }) : super(child: child);

  /// Called during layout when sliver constraints are available.
  ///
  /// This callback can be used to read the constraints without triggering
  /// an additional build.
  final void Function(SliverConstraints constraints) onConstraintsChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSliverConstraintsCapture(
      onConstraintsChanged: onConstraintsChanged,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverConstraintsCapture renderObject) {
    renderObject.onConstraintsChanged = onConstraintsChanged;
  }
}

/// Render object that captures sliver constraints during layout.
///
/// This render object acts as a transparent proxy, passing through all
/// layout operations to its child while also notifying through a callback
/// when constraints are available.
class RenderSliverConstraintsCapture extends RenderProxySliver {
  /// Creates a render object that captures sliver constraints.
  ///
  /// The [onConstraintsChanged] callback will be called during layout
  /// when the constraints are available.
  RenderSliverConstraintsCapture({
    required this.onConstraintsChanged,
  });

  /// Called during layout when sliver constraints are available.
  void Function(SliverConstraints constraints) onConstraintsChanged;

  @override
  void performLayout() {
    onConstraintsChanged(constraints);
    super.performLayout();
  }
}
