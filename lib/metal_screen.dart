import 'package:flutter/services.dart';

class MetalScreen {
  static const MethodChannel _channel = MethodChannel('metal_renderer');

  static Future<void> pushMetalRenderer(
    Map<String, dynamic> initialData,
  ) async {
    await _channel.invokeMethod('pushMetalRenderer', initialData);
  }

  static Future<void> updateScreenData(Map<String, dynamic> screenData) async {
    await _channel.invokeMethod('updateScreenData', screenData);
  }

  static Future<void> popMetalRenderer() async {
    await _channel.invokeMethod('popMetalRenderer');
  }
}
