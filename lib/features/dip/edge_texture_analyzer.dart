import 'dart:math';
import 'package:image/image.dart' as img;
import '../../core/config/app_config.dart';

class EdgeTextureResult {
  final img.Image edgeMap;
  final double edgeDensity; // 0.0 - 1.0 fraction of edge pixels
  final double meanGradient;
  final double maxGradient;
  final String surfaceTexture; // 'Smooth', 'Semi-Smooth', 'Textured / Rough'

  EdgeTextureResult({
    required this.edgeMap,
    required this.edgeDensity,
    required this.meanGradient,
    required this.maxGradient,
    required this.surfaceTexture,
  });
}

class EdgeTextureAnalyzer {
  /// Computes Sobel edge gradient magnitude map and surface texture roughness.
  static EdgeTextureResult analyze(
    img.Image src, {
    double threshold = AppConfig.sobelEdgeThreshold,
  }) {
    final w = src.width;
    final h = src.height;
    final edgeMap = img.Image(width: w, height: h);

    if (w < 3 || h < 3) {
      return EdgeTextureResult(
        edgeMap: edgeMap,
        edgeDensity: 0.0,
        meanGradient: 0.0,
        maxGradient: 0.0,
        surfaceTexture: 'Smooth',
      );
    }

    // Convert src to grayscale 2D luminance array for fast convolution
    final luma = List<List<int>>.generate(
      h,
      (y) => List<int>.generate(w, (x) {
        final p = src.getPixel(x, y);
        return (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
      }),
    );

    double totalGrad = 0;
    double maxGrad = 0;
    int edgePixelCount = 0;
    final innerPixels = (w - 2) * (h - 2);

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        // Sobel kernels
        // Gx = [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]]
        final gx = (luma[y - 1][x + 1] + 2 * luma[y][x + 1] + luma[y + 1][x + 1]) -
                   (luma[y - 1][x - 1] + 2 * luma[y][x - 1] + luma[y + 1][x - 1]);

        // Gy = [[-1, -2, -1], [0, 0, 0], [1, 2, 1]]
        final gy = (luma[y + 1][x - 1] + 2 * luma[y + 1][x] + luma[y + 1][x + 1]) -
                   (luma[y - 1][x - 1] + 2 * luma[y - 1][x] + luma[y - 1][x + 1]);

        final mag = sqrt(gx * gx + gy * gy);
        totalGrad += mag;
        if (mag > maxGrad) maxGrad = mag;

        if (mag >= threshold) {
          edgePixelCount++;
        }

        final int byteVal = (mag.clamp(0.0, 255.0)).toInt();
        edgeMap.setPixelRgb(x, y, byteVal, byteVal, byteVal);
      }
    }

    final edgeDensity = innerPixels > 0 ? (edgePixelCount / innerPixels) : 0.0;
    final meanGrad = innerPixels > 0 ? (totalGrad / innerPixels) : 0.0;

    String texture;
    if (edgeDensity < 0.08) {
      texture = 'Smooth';
    } else if (edgeDensity < 0.20) {
      texture = 'Semi-Smooth';
    } else {
      texture = 'Textured / Rough';
    }

    return EdgeTextureResult(
      edgeMap: edgeMap,
      edgeDensity: edgeDensity,
      meanGradient: meanGrad,
      maxGradient: maxGrad,
      surfaceTexture: texture,
    );
  }
}

