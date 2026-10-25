import 'package:image/image.dart' as img;

class ContaminationHeatmapResult {
  final img.Image heatmapImage; // High-contrast RGBA overlay
  final img.Image compositeImage; // Original blended with heatmap
  final double soilPercentage; // 0.0 - 100.0%
  final int soiledPixels;
  final int totalMaskPixels;

  ContaminationHeatmapResult({
    required this.heatmapImage,
    required this.compositeImage,
    required this.soilPercentage,
    required this.soiledPixels,
    required this.totalMaskPixels,
  });
}

class ContaminationHeatmapGenerator {
  /// Generates a visual RGBA contamination heatmap overlay.
  /// If [mask] is provided, only pixels inside the mask are evaluated.
  static ContaminationHeatmapResult generate(
    img.Image source, {
    List<List<bool>>? mask,
    double soilSensitivity = 1.0, // Multiplier for stain detection
  }) {
    final w = source.width;
    final h = source.height;

    final heatmap = img.Image(width: w, height: h, numChannels: 4);
    final composite = img.Image.from(source);

    int maskPixelCount = 0;
    int soilCount = 0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final isInside = (mask == null) || (y < mask.length && x < mask[0].length && mask[y][x]);
        if (!isInside) {
          // Transparent outside mask
          heatmap.setPixelRgba(x, y, 0, 0, 0, 0);
          continue;
        }

        maskPixelCount++;
        final p = source.getPixel(x, y);
        final r = p.r / 255.0;
        final g = p.g / 255.0;
        final b = p.b / 255.0;

        // Convert to HSV
        final maxC = [r, g, b].reduce((curr, next) => curr > next ? curr : next);
        final minC = [r, g, b].reduce((curr, next) => curr < next ? curr : next);
        final delta = maxC - minC;

        double hue = 0;
        if (delta > 0.0001) {
          if (maxC == r) {
            hue = 60 * (((g - b) / delta) % 6);
          } else if (maxC == g) {
            hue = 60 * (((b - r) / delta) + 2);
          } else {
            hue = 60 * (((r - g) / delta) + 4);
          }
        }
        if (hue < 0) hue += 360;

        final sat = maxC == 0 ? 0.0 : delta / maxC;
        final val = maxC;

        // Soil heuristics:
        // 1. Food / grease / sauce: Yellow-Orange-Brown hue (15 - 55), high saturation (> 0.28)
        // 2. Dirt / mold / dark residue: Low brightness (val < 0.22) on normally reflective objects
        final isGreaseSauce = (hue >= 12 && hue <= 58) && (sat >= 0.25 / soilSensitivity);
        final isDarkResidue = (val <= 0.22 * soilSensitivity) && (sat > 0.15);

        if (isGreaseSauce || isDarkResidue) {
          soilCount++;

          // Severity calculation
          final severity = isDarkResidue ? 0.9 : (sat.clamp(0.3, 1.0));
          int heatR = 255;
          int heatG = isDarkResidue ? 30 : (180 * (1.0 - severity)).toInt().clamp(0, 200);
          int heatB = 20;
          int heatA = (200 * severity).toInt().clamp(100, 240);

          heatmap.setPixelRgba(x, y, heatR, heatG, heatB, heatA);

          // Alpha blend into composite image
          final alphaF = heatA / 255.0;
          final blendedR = (p.r * (1.0 - alphaF) + heatR * alphaF).round().clamp(0, 255);
          final blendedG = (p.g * (1.0 - alphaF) + heatG * alphaF).round().clamp(0, 255);
          final blendedB = (p.b * (1.0 - alphaF) + heatB * alphaF).round().clamp(0, 255);
          composite.setPixelRgb(x, y, blendedR, blendedG, blendedB);
        } else {
          // Clean pixel - subtle green tinted indicator with low opacity
          heatmap.setPixelRgba(x, y, 40, 167, 69, 30);
        }
      }
    }

    final soilPercent = maskPixelCount > 0 ? (soilCount / maskPixelCount) * 100.0 : 0.0;

    return ContaminationHeatmapResult(
      heatmapImage: heatmap,
      compositeImage: composite,
      soilPercentage: soilPercent,
      soiledPixels: soilCount,
      totalMaskPixels: maskPixelCount,
    );
  }
}

