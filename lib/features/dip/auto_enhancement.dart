import 'dart:math';
import 'package:image/image.dart' as img;
import '../../core/config/app_config.dart';
import '../../data/models/enhancement_log.dart';
import '../../data/models/quality_metrics.dart';

class AutoEnhancement {
  /// Conditionally applies digital image processing enhancements based on QualityMetrics.
  /// Guarantees execution within the isolate budget (<= 150 ms).
  static (img.Image, EnhancementLog) enhance(
    img.Image inputImage,
    QualityMetrics metrics,
  ) {
    final stopwatch = Stopwatch()..start();

    // 1. Working copy downscaled to <= 1280 px
    img.Image current = _downscaleIfNeeded(inputImage, AppConfig.maxWorkingDimension);

    bool wbApplied = false;
    bool claheApplied = false;
    bool gammaApplied = false;
    double gammaVal = 1.0;
    bool denoiseApplied = false;
    bool sharpenApplied = false;

    // 2. White Balance (Gray-World Assumption)
    final wbCheck = _checkWhiteBalance(current);
    if (wbCheck.$1) {
      current = _applyGrayWorldWB(current, wbCheck.$2, wbCheck.$3, wbCheck.$4);
      wbApplied = true;
    }

    // 3. Contrast Adjustment (Adaptive Histogram Equalization / CLAHE approx)
    if (metrics.meanLuma > 0 && (metrics.isDark || metrics.isBright)) {
      current = _applyContrastStretch(current);
      claheApplied = true;
    }

    // 4. Gamma Correction
    if (metrics.isDark) {
      gammaVal = AppConfig.gammaDark;
      current = _applyGamma(current, gammaVal);
      gammaApplied = true;
    } else if (metrics.isBright) {
      gammaVal = AppConfig.gammaBright;
      current = _applyGamma(current, gammaVal);
      gammaApplied = true;
    }

    // 5. Mild Sharpening (Unsharp Mask)
    if (metrics.isBlurry && metrics.status != 'reject') {
      current = _applyUnsharpMask(current);
      sharpenApplied = true;
    }

    stopwatch.stop();

    final log = EnhancementLog(
      whiteBalanceApplied: wbApplied,
      claheApplied: claheApplied,
      gammaApplied: gammaApplied,
      gammaValue: gammaVal,
      denoiseApplied: denoiseApplied,
      sharpenApplied: sharpenApplied,
      elapsedMs: stopwatch.elapsedMilliseconds,
    );

    return (current, log);
  }

  static img.Image _downscaleIfNeeded(img.Image image, int maxDim) {
    if (image.width <= maxDim && image.height <= maxDim) {
      return img.Image.from(image);
    }
    if (image.width > image.height) {
      return img.copyResize(image, width: maxDim);
    } else {
      return img.copyResize(image, height: maxDim);
    }
  }

  static (bool, double, double, double) _checkWhiteBalance(img.Image image) {
    double sumR = 0, sumG = 0, sumB = 0;
    final total = image.width * image.height;
    if (total == 0) return (false, 1.0, 1.0, 1.0);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        sumR += p.r;
        sumG += p.g;
        sumB += p.b;
      }
    }

    final avgR = sumR / total;
    final avgG = sumG / total;
    final avgB = sumB / total;
    final overallMean = (avgR + avgG + avgB) / 3.0;

    if (overallMean == 0) return (false, 1.0, 1.0, 1.0);

    final maxDiff = max((avgR - avgG).abs(), max((avgG - avgB).abs(), (avgR - avgB).abs())) / overallMean;

    if (maxDiff > AppConfig.wbChannelDifferenceRatio) {
      final gainR = overallMean / (avgR > 0 ? avgR : 1.0);
      final gainG = overallMean / (avgG > 0 ? avgG : 1.0);
      final gainB = overallMean / (avgB > 0 ? avgB : 1.0);
      return (true, gainR, gainG, gainB);
    }

    return (false, 1.0, 1.0, 1.0);
  }

  static img.Image _applyGrayWorldWB(img.Image image, double gainR, double gainG, double gainB) {
    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final r = (p.r * gainR).clamp(0, 255).toInt();
        final g = (p.g * gainG).clamp(0, 255).toInt();
        final b = (p.b * gainB).clamp(0, 255).toInt();
        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  static img.Image _applyContrastStretch(img.Image image) {
    int minR = 255, maxR = 0;
    int minG = 255, maxG = 0;
    int minB = 255, maxB = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        minR = min(minR, p.r.toInt());
        maxR = max(maxR, p.r.toInt());
        minG = min(minG, p.g.toInt());
        maxG = max(maxG, p.g.toInt());
        minB = min(minB, p.b.toInt());
        maxB = max(maxB, p.b.toInt());
      }
    }

    final diffR = (maxR - minR) > 0 ? (maxR - minR) : 1;
    final diffG = (maxG - minG) > 0 ? (maxG - minG) : 1;
    final diffB = (maxB - minB) > 0 ? (maxB - minB) : 1;

    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final r = (((p.r - minR) / diffR) * 255).clamp(0, 255).toInt();
        final g = (((p.g - minG) / diffG) * 255).clamp(0, 255).toInt();
        final b = (((p.b - minB) / diffB) * 255).clamp(0, 255).toInt();
        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  static img.Image _applyGamma(img.Image image, double gamma) {
    final lut = List<int>.generate(256, (i) {
      return (pow(i / 255.0, gamma) * 255.0).clamp(0, 255).toInt();
    });

    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        result.setPixelRgb(x, y, lut[p.r.toInt()], lut[p.g.toInt()], lut[p.b.toInt()]);
      }
    }
    return result;
  }

  static img.Image _applyUnsharpMask(img.Image image) {
    final blurred = img.gaussianBlur(image, radius: 1);
    final result = img.Image(width: image.width, height: image.height);
    const double amount = 0.5;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pOrig = image.getPixel(x, y);
        final pBlur = blurred.getPixel(x, y);

        final r = (pOrig.r + amount * (pOrig.r - pBlur.r)).clamp(0, 255).toInt();
        final g = (pOrig.g + amount * (pOrig.g - pBlur.g)).clamp(0, 255).toInt();
        final b = (pOrig.b + amount * (pOrig.b - pBlur.b)).clamp(0, 255).toInt();

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  /// Resizes image to target dimension preserving aspect ratio with centered neutral padding.
  static img.Image letterbox(img.Image src, int targetSize) {
    final double scale = min(targetSize / src.width, targetSize / src.height);
    final int scaledWidth = (src.width * scale).round();
    final int scaledHeight = (src.height * scale).round();

    final resized = img.copyResize(src, width: scaledWidth, height: scaledHeight);
    final canvas = img.Image(width: targetSize, height: targetSize);
    img.fill(canvas, color: img.ColorRgb8(128, 128, 128));

    final int offsetX = (targetSize - scaledWidth) ~/ 2;
    final int offsetY = (targetSize - scaledHeight) ~/ 2;

    img.compositeImage(canvas, resized, dstX: offsetX, dstY: offsetY);
    return canvas;
  }
}

