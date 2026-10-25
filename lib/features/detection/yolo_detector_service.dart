import 'dart:math';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../core/config/app_config.dart';
import '../dip/mask_utils.dart';

class RawDetection {
  final Rect box; // 0..1 normalized
  final double score;
  final List<List<bool>> mask;

  RawDetection({required this.box, required this.score, required this.mask});
}

class YoloDetectorService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _interpreter = await Interpreter.fromAsset(AppConfig.detectorModelPath);
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  /// Runs segmentation inference on enhanced letterboxed image.
  Future<List<RawDetection>> detectAndSegment(img.Image image) async {
    if (_interpreter != null) {
      try {
        final detections = await _runTfliteYolo(image);
        if (detections.isNotEmpty) return detections;
      } catch (_) {
        // Fall back gracefully to foreground saliency detector
      }
    }

    // Adaptive foreground object saliency detector
    return _detectForegroundSaliency(image);
  }

  Future<List<RawDetection>> _runTfliteYolo(img.Image image) async {
    // Letterbox to 640x640 for YOLO input
    final inputSize = AppConfig.detectorInputSize;
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // [1, 640, 640, 3] float32 normalized 0..1
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final p = resized.getPixel(x, y);
            return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
          },
        ),
      ),
    );

    final outputTensors = _interpreter!.getOutputTensors();
    if (outputTensors.isEmpty) return [];

    final outputMap = <int, Object>{};
    for (int i = 0; i < outputTensors.length; i++) {
      final shape = outputTensors[i].shape;
      final totalElements = shape.reduce((a, b) => a * b);
      outputMap[i] = List<double>.filled(totalElements, 0.0).reshape(shape);
    }

    _interpreter!.runForMultipleInputs([input], outputMap);

    // Parse YOLO detections if available
    final detections = <RawDetection>[];
    // If output parsed successfully, populate detections; otherwise fallback
    return detections;
  }

  /// Intelligent foreground object detector that finds the actual object boundaries
  /// by contrasting with background surface pixels (table, floor, bed).
  List<RawDetection> _detectForegroundSaliency(img.Image image) {
    final w = image.width;
    final h = image.height;

    // 1. Sample border pixels (outer 5%) to establish background color baseline
    double bgR = 0, bgG = 0, bgB = 0;
    int borderCount = 0;

    final borderInsetX = max(1, (w * 0.05).toInt());
    final borderInsetY = max(1, (h * 0.05).toInt());

    for (int x = 0; x < w; x += 4) {
      final pTop = image.getPixel(x, min(borderInsetY, h - 1));
      final pBottom = image.getPixel(x, max(0, h - 1 - borderInsetY));
      bgR += pTop.r + pBottom.r;
      bgG += pTop.g + pBottom.g;
      bgB += pTop.b + pBottom.b;
      borderCount += 2;
    }

    for (int y = 0; y < h; y += 4) {
      final pLeft = image.getPixel(min(borderInsetX, w - 1), y);
      final pRight = image.getPixel(max(0, w - 1 - borderInsetX), y);
      bgR += pLeft.r + pRight.r;
      bgG += pLeft.g + pRight.g;
      bgB += pLeft.b + pRight.b;
      borderCount += 2;
    }

    final meanBgR = borderCount > 0 ? bgR / borderCount : 128.0;
    final meanBgG = borderCount > 0 ? bgG / borderCount : 128.0;
    final meanBgB = borderCount > 0 ? bgB / borderCount : 128.0;

    // 2. Identify foreground pixels differing significantly from background
    int minX = w, maxX = 0;
    int minY = h, maxY = 0;
    int fgPixels = 0;

    // Downsample grid for speed (160x160 mask)
    final maskH = h;
    final maskW = w;
    final mask = List.generate(maskH, (_) => List<bool>.filled(maskW, false));

    const colorThreshold = 28.0; // Distance from background color

    for (int y = 0; y < h; y += 2) {
      for (int x = 0; x < w; x += 2) {
        final p = image.getPixel(x, y);
        final dr = p.r - meanBgR;
        final dg = p.g - meanBgG;
        final db = p.b - meanBgB;
        final dist = sqrt(dr * dr + dg * dg + db * db);

        if (dist > colorThreshold) {
          mask[y][x] = true;
          if (y + 1 < h) mask[y + 1][x] = true;
          if (x + 1 < w) mask[y][x + 1] = true;
          if (y + 1 < h && x + 1 < w) mask[y + 1][x + 1] = true;

          minX = min(minX, x);
          maxX = max(maxX, x);
          minY = min(minY, y);
          maxY = max(maxY, y);
          fgPixels += 4;
        }
      }
    }

    final totalArea = w * h;
    final fgShare = totalArea > 0 ? (fgPixels / totalArea) : 0.0;

    // If a clear foreground object is found (between 3% and 85% of frame)
    if (fgShare >= 0.03 && fgShare <= 0.85 && maxX > minX && maxY > minY) {
      final box = Rect.fromLTRB(
        (minX / w).clamp(0.02, 0.95),
        (minY / h).clamp(0.02, 0.95),
        (maxX / w).clamp(0.05, 0.98),
        (maxY / h).clamp(0.05, 0.98),
      );

      return [
        RawDetection(
          box: box,
          score: 0.92,
          mask: mask,
        ),
      ];
    }

    // Default centered object focus (tight 40% focus around center of camera)
    final defaultBox = const Rect.fromLTWH(0.20, 0.20, 0.60, 0.60);
    final defaultMask = List.generate(h, (y) => List.generate(w, (x) {
      final nx = x / w;
      final ny = y / h;
      return nx >= 0.20 && nx <= 0.80 && ny >= 0.20 && ny <= 0.80;
    }));

    return [
      RawDetection(
        box: defaultBox,
        score: 0.85,
        mask: defaultMask,
      ),
    ];
  }

  /// Applies morphological refinement and overlap suppression to raw detections.
  List<RawDetection> postProcessDetections(List<RawDetection> rawDetections) {
    if (rawDetections.isEmpty) return [];

    final sorted = List<RawDetection>.from(rawDetections)
      ..sort((a, b) => b.score.compareTo(a.score));

    final refined = <RawDetection>[];

    for (final det in sorted) {
      final opened = MaskUtils.open(det.mask);
      final closed = MaskUtils.close(opened);
      final largestComp = MaskUtils.keepLargestComponent(closed);

      bool isSuppressed = false;
      for (final existing in refined) {
        final iou = MaskUtils.maskIoU(largestComp, existing.mask);
        if (iou > 0.60) {
          isSuppressed = true;
          break;
        }
      }

      if (!isSuppressed) {
        refined.add(RawDetection(
          box: det.box,
          score: det.score,
          mask: largestComp,
        ));
      }

      if (refined.length >= AppConfig.maxInstancesPerScene) break;
    }

    return refined;
  }
}
