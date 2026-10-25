import 'dart:math';
import 'package:image/image.dart' as img;

class ContaminationResult {
  final double ratio;
  final String level; // 'clean', 'light', 'heavy'
  final int flaggedPixels;
  final int totalMaskPixels;
  final img.Image? heatmapImage;

  const ContaminationResult({
    required this.ratio,
    required this.level,
    required this.flaggedPixels,
    required this.totalMaskPixels,
    this.heatmapImage,
  });
}

class HsvContamination {
  static const List<String> applicableClasses = [
    'paper',
    'cardboard',
    'plastic',
    'glass',
    'metal',
  ];

  /// Estimates contamination ratio and severity tier inside an object's mask.
  static ContaminationResult analyze({
    required img.Image image,
    required List<List<bool>> mask, // 2D boolean mask matching image dimensions
    required String itemClass,
  }) {
    if (!applicableClasses.contains(itemClass)) {
      return const ContaminationResult(
        ratio: 0.0,
        level: 'clean',
        flaggedPixels: 0,
        totalMaskPixels: 0,
      );
    }

    final maskH = mask.length;
    if (maskH == 0) {
      return const ContaminationResult(
        ratio: 0.0,
        level: 'clean',
        flaggedPixels: 0,
        totalMaskPixels: 0,
      );
    }
    final maskW = mask[0].length;
    final height = min(image.height, maskH);
    final width = min(image.width, maskW);

    // Adaptive sampling stride to ensure instantaneous real-time execution (~1-2 ms)
    // even on high-resolution (12-48 megapixel) camera frames without memory spikes.
    final totalPixels = width * height;
    final int step = totalPixels > 250000 ? max(1, sqrt(totalPixels / 25000).ceil()) : 1;

    // 1. Collect masked pixels and calculate H, S, V
    final List<double> hues = [];
    final List<double> saturations = [];
    final List<double> values = [];

    for (int y = 0; y < height; y += step) {
      for (int x = 0; x < width; x += step) {
        if (mask[y][x]) {
          final pixel = image.getPixel(x, y);
          final (h, s, v) = _rgbToHsv(pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
          hues.add(h);
          saturations.add(s);
          values.add(v);
        }
      }
    }

    final totalMaskPixels = hues.length;
    if (totalMaskPixels < 20) {
      return const ContaminationResult(
        ratio: 0.0,
        level: 'clean',
        flaggedPixels: 0,
        totalMaskPixels: 0,
      );
    }

    // 2. Compute baseline median
    final baselineH = _circularMedian(hues);
    final baselineS = _median(saturations);
    final baselineV = _median(values);

    // 3. Flag contaminated pixels based on Residue and Stain rules
    int flaggedCount = 0;

    for (int i = 0; i < totalMaskPixels; i++) {
      final h = hues[i];
      final s = saturations[i];
      final v = values[i];

      final hueDiff = _circularHueDistance(h, baselineH);

      // Residue rule: hue differs by > 15 deg, saturation > 90, value > 60
      final isResidue = hueDiff > 15.0 && s > 90.0 && v > 60.0;

      // Stain rule: value < 60% of baseline with saturation >= baseline
      final isStain = v < (0.60 * baselineV) && s >= baselineS;

      if (isResidue || isStain) {
        flaggedCount++;
      }
    }

    // 4. Calculate ratio and categorize
    final ratio = totalMaskPixels > 0 ? (flaggedCount / totalMaskPixels) : 0.0;

    String level = 'clean';
    if (ratio >= 0.30) {
      level = 'heavy';
    } else if (ratio >= 0.10) {
      level = 'light';
    }

    return ContaminationResult(
      ratio: ratio,
      level: level,
      flaggedPixels: flaggedCount,
      totalMaskPixels: totalMaskPixels,
    );
  }

  static (double, double, double) _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;

    final maxVal = max(rf, max(gf, bf));
    final minVal = min(rf, min(gf, bf));
    final delta = maxVal - minVal;

    double h = 0;
    if (delta > 0) {
      if (maxVal == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (maxVal == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else {
        h = 60 * (((rf - gf) / delta) + 4);
      }
    }
    if (h < 0) h += 360;

    final s = maxVal == 0 ? 0.0 : (delta / maxVal) * 255.0;
    final v = maxVal * 255.0;

    return (h, s, v);
  }

  static double _circularHueDistance(double h1, double h2) {
    final diff = (h1 - h2).abs() % 360;
    return diff > 180 ? (360 - diff) : diff;
  }

  static double _circularMedian(List<double> angles) {
    if (angles.isEmpty) return 0;
    double sinSum = 0;
    double cosSum = 0;
    for (final a in angles) {
      final rad = a * pi / 180.0;
      sinSum += sin(rad);
      cosSum += cos(rad);
    }
    double meanAngle = atan2(sinSum, cosSum) * 180.0 / pi;
    if (meanAngle < 0) meanAngle += 360;
    return meanAngle;
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[mid];
    } else {
      return (sorted[mid - 1] + sorted[mid]) / 2.0;
    }
  }
}
