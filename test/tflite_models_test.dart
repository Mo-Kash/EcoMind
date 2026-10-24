import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  test('Verify TFLite model files exist and have valid sizes', () {
    final mobilenetFile = File('assets/models/mobilenetv3_large.tflite');
    final yoloFile = File('assets/models/yolo11n-seg.tflite');
    final labelsFile = File('assets/models/labels.txt');

    expect(mobilenetFile.existsSync(), isTrue, reason: 'mobilenetv3_large.tflite must exist');
    expect(yoloFile.existsSync(), isTrue, reason: 'yolo11n-seg.tflite must exist');
    expect(labelsFile.existsSync(), isTrue, reason: 'labels.txt must exist');

    final mobilenetSizeMb = mobilenetFile.lengthSync() / (1024 * 1024);
    final yoloSizeMb = yoloFile.lengthSync() / (1024 * 1024);

    expect(mobilenetSizeMb, lessThanOrEqualTo(12.0), reason: 'MobileNetV3 must be <= 12MB');
    expect(yoloSizeMb, lessThanOrEqualTo(15.0), reason: 'YOLO11n-seg must be <= 15MB');

    final labels = labelsFile.readAsLinesSync();
    expect(labels.length, equals(9));
  });

  test('Inspect TFLite interpreter if native library is available', () {
    try {
      final interp = Interpreter.fromFile(File('assets/models/mobilenetv3_large.tflite'));
      print('MobileNetV3 Inputs: ${interp.getInputTensors().map((t) => "${t.name}: ${t.shape} ${t.type}")}');
      print('MobileNetV3 Outputs: ${interp.getOutputTensors().map((t) => "${t.name}: ${t.shape} ${t.type}")}');
      interp.close();
    } catch (e) {
      print('Native tflite runtime on Windows host test: $e (Normal if dll not bundled for host runner)');
    }
  });
}

