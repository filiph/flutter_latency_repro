import 'package:flutter/material.dart';

class MinimumLatencyROWidget extends LeafRenderObjectWidget {
  final int counter;

  const MinimumLatencyROWidget({required this.counter, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      MinimumLatencyRenderObject(counter: counter);

  @override
  void updateRenderObject(
    BuildContext context,
    MinimumLatencyRenderObject renderObject,
  ) {
    renderObject.counter = counter;
  }
}

class MinimumLatencyRenderObject extends RenderBox {
  // Private field to hold the counter value.
  int _counter;

  // Constructor to initialize the counter.
  MinimumLatencyRenderObject({required int counter}) : _counter = counter;

  // Public getter for the counter.
  int get counter => _counter;

  // Public setter for the counter.
  // When the value changes, we need to repaint.
  set counter(int value) {
    if (_counter == value) {
      return;
    }
    _counter = value;
    // markNeedsPaint() tells the framework that this RenderBox needs to be repainted.
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.smallest;
  }

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final paint = Paint()
      ..color = Color(0xFFFF0000)
      ..style = PaintingStyle.fill;

    // Determine the radius based on whether the counter is even or odd.
    final double radius = _counter.isEven ? 5.0 : 10.0;

    // Calculate the center of the available space.
    final center = offset + size.center(Offset.zero);

    // Draw the circle at the calculated center with the determined radius.
    context.canvas.drawCircle(center, radius, paint);
  }
}
