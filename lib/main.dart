import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_latency_repro/metal_screen.dart';
import 'package:flutter_latency_repro/minimum_latency_render_object.dart';
import 'package:flutter_latency_repro/minimum_latency_widget.dart';
import 'package:torch_light/torch_light.dart';

import 'minimum_latency_raw_vertices_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Latency Repro',
      theme: ThemeData.light(),
      showPerformanceOverlay: true,
      home: Scaffold(body: const TickingWidget()),
    );
  }
}

class TickingWidget extends StatefulWidget {
  const TickingWidget({super.key});

  @override
  State<TickingWidget> createState() => _TickingWidgetState();
}

class _TickingWidgetState extends State<TickingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Timer? _metalUpdateTimer;
  int _metalCounter = 0;

  bool torchLightAvailable = false;

  int loopCount = 0;
  int frameCount = 0;

  bool blinkedThisLoop = false;
  String currentTime = '';
  double? averageFramesPerLoop;

  dev.Flow? flow;
  Stopwatch stopwatch = Stopwatch();

  /// Attempt to directly change vertices.
  Float32List verticesPositions = Float32List.fromList([0, 0, 20, 0, 20, 20]);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MinimumLatencyRawVerticesWidget(verticesPositions: verticesPositions),
          MinimumLatencyWidget(counter: loopCount),
          SizedBox(
            width: 20,
            height: 20,
            child: MinimumLatencyROWidget(counter: loopCount),
          ),
          SizedBox(height: 20),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (flow != null) {
                final flowEnd = dev.Flow.end(flow!.id);
                flow = null;
                dev.Timeline.startSync(
                  'BENCH builder callback executed',
                  flow: flowEnd,
                );
                dev.Timeline.finishSync();
              }

              // This is _not_ the most performant way to do this
              // but build times are not the issue here.
              // In fact we're way below the frame budget even for 120 fps.
              return Column(
                children: [
                  _FrameIndicator(frame: frameCount),
                  Text('Frame number: $frameCount'),
                  Text('Time code: $currentTime'),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 100,
                    child: Transform.rotate(
                      angle: _controller.value * 2 * pi,
                      child: child,
                    ),
                  ),
                ],
              );
            },
            child: Container(width: 10, height: 100, color: Colors.blue),
          ),
          SizedBox(height: 20),
          Text(
            ' Loop count: $loopCount ',
            // Blink so that it's easier to spot the change.
            style: loopCount.isEven
                ? TextStyle(
                    fontWeight: FontWeight.bold,
                    backgroundColor: Color(0xFFFFFFFF),
                    color: Color(0xFF000000),
                  )
                : TextStyle(
                    fontWeight: FontWeight.bold,
                    backgroundColor: Color(0xFF000000),
                    color: Color(0xFFFFFFFF),
                  ),
          ),
          SizedBox(height: 20),
          Text('AFPL: ${averageFramesPerLoop?.toStringAsFixed(2)}'),
          SizedBox(height: 20),
          TextButton(
            onPressed: () async {
              _controller.stop();
              await MetalScreen.pushMetalRenderer(const {});

              _metalUpdateTimer?.cancel();
              _metalUpdateTimer = Timer.periodic(const Duration(seconds: 1), (
                t,
              ) {
                MetalScreen.updateScreenData({'counter': _metalCounter++});
              });
            },
            child: Text('OPEN METAL'),
          ),
          TextButton(
            onPressed: () async {
              _controller.repeat();
              await MetalScreen.popMetalRenderer();

              _metalUpdateTimer?.cancel();
              _metalUpdateTimer = null;
            },
            child: Text('DISPOSE METAL'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    TorchLight.isTorchAvailable()
        .then((isAvailable) {
          torchLightAvailable = isAvailable;
        })
        .onError<EnableTorchException>((e, s) {
          debugPrint("Couldn't determine torchlight availability: $e");
          torchLightAvailable = false;
        })
        .onError<MissingPluginException>((e, s) {
          debugPrint("Couldn't determine torchlight availability: $e");
          torchLightAvailable = false;
        })
        .whenComplete(() {
          if (mounted && !torchLightAvailable) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No torchlight on this device')),
            );
          }
        });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _controller.addListener(_update);

    // Start repeating animation after a short delay.
    if (const bool.fromEnvironment('autostart', defaultValue: false)) {
      Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        _controller.repeat();
        stopwatch.start();
      });
    }
  }

  /// We're doing it this way because [AnimationController.addStatusListener]
  /// doesn't fire when the animation is on repeat, and restarting an animation
  /// manually introduces at least a frame of distracting visual "jank"
  /// (instead of continuity, one animation run ends at 100%, then the following
  /// animation run start on next frame at 0%, which is the same position).
  void _update() {
    if (loopCount > 0) {
      frameCount++;
    }

    currentTime = stopwatch.elapsed.toString();

    if (blinkedThisLoop && _controller.value < 0.5) {
      // We're back at the start.
      blinkedThisLoop = false;
      return;
    }

    if (!blinkedThisLoop && _controller.value >= 0.5) {
      flow = dev.Flow.begin();
      dev.Timeline.startSync('BENCH new loop started', flow: flow);
      maybeBlink();

      // Vertices
      verticesPositions[4] = loopCount.isOdd ? 0 : 20;

      // New loop started
      setState(() {
        if (loopCount > 0) {
          averageFramesPerLoop = frameCount / loopCount;
        }
        loopCount++;
      });

      blinkedThisLoop = true;
      dev.Timeline.finishSync();
    }
  }

  Future<void> maybeBlink() async {
    if (!torchLightAvailable) return;

    await TorchLight.enableTorch();
    await Future.delayed(const Duration(milliseconds: 100));
    await TorchLight.disableTorch();
  }
}

class _FrameIndicator extends StatelessWidget {
  static const boxCount = 20;

  final int frame;

  const _FrameIndicator({required this.frame});

  @override
  Widget build(BuildContext context) {
    final remainder = frame % boxCount;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          for (var i = 0; i < boxCount; i++)
            SizedBox(
              width: 10,
              height: 20,
              child: ColoredBox(
                color: i == remainder ? Color(0xFF000000) : Color(0xFFEEEEEE),
              ),
            ),
        ],
      ),
    );
  }
}
