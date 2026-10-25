import 'dart:math';
import 'package:image/image.dart' as img;

/// Holds complete 256-bin histogram arrays and photometric descriptors.
class ImageHistogramData {
  final List<int> red;
  final List<int> green;
  final List<int> blue;
  final List<int> luma;

  final double meanLuma;
  final double rmsContrast; // Standard deviation of luma
  final int minLuma;
  final int maxLuma;
  final int dynamicRange; // maxLuma - minLuma
  final double entropy; // Shannon entropy in bits
  final double shadowClippingPercent; // % pixels < 10
  final double highlightClippingPercent; // % pixels > 245
  final int totalPixels;

  ImageHistogramData({
    required this.red,
    required this.green,
    required this.blue,
    required this.luma,
    required this.meanLuma,
    required this.rmsContrast,
    required this.minLuma,
    required this.maxLuma,
    required this.dynamicRange,
    required this.entropy,
    required this.shadowClippingPercent,
    required this.highlightClippingPercent,
    required this.totalPixels,
  });

  /// Normalizes histogram arrays to 0.0 - 1.0 range based on the maximum frequency bin.
  List<double> normalizedLuma() {
    final maxFreq = luma.reduce(max);
    if (maxFreq == 0) return List.filled(256, 0.0);
    return luma.map((c) => c / maxFreq).toList();
  }
}

class HistogramAnalyzer {
  /// Computes full photometric histogram analysis from an Image.
  static ImageHistogramData compute(img.Image image) {
    final rHist = List<int>.filled(256, 0);
    final gHist = List<int>.filled(256, 0);
    final bHist = List<int>.filled(256, 0);
    final yHist = List<int>.filled(256, 0);

    final totalPixels = image.width * image.height;
    if (totalPixels == 0) {
      return ImageHistogramData(
        red: rHist,
        green: gHist,
        blue: bHist,
        luma: yHist,
        meanLuma: 0,
        rmsContrast: 0,
        minLuma: 0,
        maxLuma: 0,
        dynamicRange: 0,
        entropy: 0,
        shadowClippingPercent: 0,
        highlightClippingPercent: 0,
        totalPixels: 0,
      );
    }

    double sumLuma = 0;
    int shadowCount = 0;
    int highlightCount = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final r = p.r.toInt().clamp(0, 255);
        final g = p.g.toInt().clamp(0, 255);
        final b = p.b.toInt().clamp(0, 255);

        // ITU-R BT.601 Luma formula
        final yVal = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);

        rHist[r]++;
        gHist[g]++;
        bHist[b]++;
        yHist[yVal]++;

        sumLuma += yVal;
        if (yVal < 10) shadowCount++;
        if (yVal > 245) highlightCount++;
      }
    }

    final meanLuma = sumLuma / totalPixels;

    // RMS Contrast (Standard Deviation) & Shannon Entropy
    double varianceSum = 0;
    double entropy = 0;

    int minLuma = 255;
    int maxLuma = 0;

    for (int i = 0; i < 256; i++) {
      final count = yHist[i];
      if (count > 0) {
        if (i < minLuma) minLuma = i;
        if (i > maxLuma) maxLuma = i;

        final prob = count / totalPixels;
        entropy -= prob * (log(prob) / ln2);

        final diff = i - meanLuma;
        varianceSum += count * (diff * diff);
      }
    }

    if (minLuma > maxLuma) {
      minLuma = 0;
      maxLuma = 0;
    }

    final rmsContrast = sqrt(varianceSum / totalPixels);

    return ImageHistogramData(
      red: rHist,
      green: gHist,
      blue: bHist,
      luma: yHist,
      meanLuma: meanLuma,
      rmsContrast: rmsContrast,
      minLuma: minLuma,
      maxLuma: maxLuma,
      dynamicRange: maxLuma - minLuma,
      entropy: entropy,
      shadowClippingPercent: (shadowCount / totalPixels) * 100.0,
      highlightClippingPercent: (highlightCount / totalPixels) * 100.0,
      totalPixels: totalPixels,
    );
  }
}

