import 'dart:math';
import 'package:image/image.dart' as img;
import '../../core/config/app_config.dart';
import '../../data/models/quality_metrics.dart';

class QualityGate {
  /// Evaluates image for blur (Laplacian variance) and exposure (mean luma, clipping).
  static QualityMetrics evaluate(img.Image image) {
    final width = image.width;
    final height = image.height;
    final totalPixels = width * height;

    if (totalPixels == 0) {
      return const QualityMetrics(
        blurVariance: 0,
        meanLuma: 0,
        clippedPixelShare: 0,
        isBlurry: true,
        isDark: false,
        isBright: false,
        status: 'reject',
        message: 'Empty or corrupt image.',
      );
    }

    // 1. Exposure & Luminance Calculation
    double sumLuma = 0;
    int saturatedPixels = 0;
    
    // Grayscale representation for Laplacian
    final List<double> gray = List<double>.filled(totalPixels, 0.0);

    int idx = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        // ITU-R BT.601 standard luma formula
        final luma = 0.299 * r + 0.587 * g + 0.114 * b;
        gray[idx++] = luma;
        sumLuma += luma;

        if (luma >= 250) {
          saturatedPixels++;
        }
      }
    }

    final meanLuma = sumLuma / totalPixels;
    final clippedPixelShare = saturatedPixels / totalPixels;

    // 2. Blur Estimation via 3x3 Laplacian Variance
    // Kernel:
    //  0  1  0
    //  1 -4  1
    //  0  1  0
    double sumLap = 0;
    double sumLapSq = 0;
    int lapCount = 0;

    for (int y = 1; y < height - 1; y++) {
      final rowOffset = y * width;
      final upOffset = (y - 1) * width;
      final downOffset = (y + 1) * width;

      for (int x = 1; x < width - 1; x++) {
        final center = gray[rowOffset + x];
        final up = gray[upOffset + x];
        final down = gray[downOffset + x];
        final left = gray[rowOffset + x - 1];
        final right = gray[rowOffset + x + 1];

        final lap = up + down + left + right - (4.0 * center);
        sumLap += lap;
        sumLapSq += lap * lap;
        lapCount++;
      }
    }

    final double blurVariance = lapCount > 0
        ? (sumLapSq / lapCount) - pow(sumLap / lapCount, 2)
        : 0.0;

    final isBlurry = blurVariance < AppConfig.blurVarianceThreshold;
    final isDark = meanLuma < AppConfig.underexposedLumaThreshold;
    final isBright = meanLuma > AppConfig.overexposedLumaThreshold ||
        clippedPixelShare > AppConfig.overexposedSaturatedPixelShare;

    // Decision Logic
    String status = 'pass';
    String message = 'Image quality is good.';

    if (blurVariance < (AppConfig.blurVarianceThreshold * 0.4)) {
      status = 'reject';
      message = 'Image is too blurry for reliable waste identification. Please hold steady and capture again.';
    } else if (isBlurry) {
      status = 'warn';
      message = 'Image appears slightly blurry. Auto-sharpening will be applied.';
    } else if (isDark) {
      status = 'warn';
      message = 'Image is dimly lit. Auto-exposure boost will be applied.';
    } else if (isBright) {
      status = 'warn';
      message = 'Image has high glare or overexposure. Contrast adjustment will be applied.';
    }

    return QualityMetrics(
      blurVariance: blurVariance,
      meanLuma: meanLuma,
      clippedPixelShare: clippedPixelShare,
      isBlurry: isBlurry,
      isDark: isDark,
      isBright: isBright,
      status: status,
      message: message,
    );
  }
}

