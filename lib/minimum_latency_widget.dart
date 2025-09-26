import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

class MinimumLatencyWidget extends StatefulWidget {
  final int counter;

  const MinimumLatencyWidget({required this.counter, super.key});

  @override
  State<MinimumLatencyWidget> createState() => _MinimumLatencyWidgetState();
}

class _MinimumLatencyWidgetState extends State<MinimumLatencyWidget>
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
    return CustomPaint(
      painter: _Painter(widget.counter, repaint: _controller),
      size: Size(20, 20),
      willChange: false /* does this matter? */,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _Painter extends CustomPainter {
  final int counter;

  const _Painter(this.counter, {required super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFFFF0000)
      ..style = PaintingStyle.fill;

    // final vertices = Vertices(VertexMode.triangles, [
    //   size.topLeft(Offset.zero),
    //   size.topRight(Offset.zero),
    //   if (counter.isEven)
    //     size.bottomLeft(Offset.zero)
    //   else
    //     size.bottomRight(Offset.zero),
    // ]);

    final vertices = Vertices.raw(
      VertexMode.triangles,
      Float32List.fromList([
        0,
        0,
        size.width,
        0,
        counter.isEven ? 0 : size.width,
        size.height,
      ]),
    );

    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) {
    return true;
  }
}
