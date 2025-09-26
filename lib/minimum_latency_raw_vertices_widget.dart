import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

class MinimumLatencyRawVerticesWidget extends StatefulWidget {
  final Float32List verticesPositions;

  const MinimumLatencyRawVerticesWidget({
    required this.verticesPositions,
    super.key,
  });

  @override
  State<MinimumLatencyRawVerticesWidget> createState() =>
      _MinimumLatencyRawVerticesWidgetState();
}

class _MinimumLatencyRawVerticesWidgetState
    extends State<MinimumLatencyRawVerticesWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();

    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _Painter(widget.verticesPositions, repaint: _controller),
        size: Size(20, 20),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _Painter extends CustomPainter {
  final Float32List verticesPositions;

  const _Painter(this.verticesPositions, {required super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF009900)
      ..style = PaintingStyle.fill;

    final vertices = Vertices.raw(VertexMode.triangles, verticesPositions);

    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) {
    return oldDelegate.verticesPositions != verticesPositions;
  }
}
