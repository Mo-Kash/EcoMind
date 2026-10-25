import 'dart:math';
import 'package:image/image.dart' as img;

class KMeansColor {
  /// Determines dominant color of glass from masked pixels ('clear', 'green', 'brown', 'other').
  static String extractDominantGlassColor({
    required img.Image image,
    required List<List<bool>> mask,
  }) {
    final List<(int, int, int)> pixels = [];
    final maskH = mask.length;
    if (maskH == 0) return 'clear';
    final maskW = mask[0].length;
    final height = min(image.height, maskH);
    final width = min(image.width, maskW);

    // Sample up to ~2,000 pixels inside the mask with adaptive stride for instant clustering
    final totalPixels = width * height;
    final int step = totalPixels > 100000 ? max(1, sqrt(totalPixels / 10000).ceil()) : 1;

    for (int y = 0; y < height; y += step) {
      for (int x = 0; x < width; x += step) {
        if (mask[y][x]) {
          final p = image.getPixel(x, y);
          pixels.add((p.r.toInt(), p.g.toInt(), p.b.toInt()));
          if (pixels.length >= 2000) break;
        }
      }
      if (pixels.length >= 2000) break;
    }

    if (pixels.length < 30) return 'clear';

    // Simple k-means with k=3
    final centroids = [
      pixels[0],
      pixels[pixels.length ~/ 2],
      pixels[pixels.length - 1],
    ];

    final counts = [0, 0, 0];
    final sumR = [0, 0, 0];
    final sumG = [0, 0, 0];
    final sumB = [0, 0, 0];

    for (final p in pixels) {
      int bestCluster = 0;
      double bestDist = double.infinity;
      for (int c = 0; c < 3; c++) {
        final dist = _colorDist(p, centroids[c]);
        if (dist < bestDist) {
          bestDist = dist;
          bestCluster = c;
        }
      }
      counts[bestCluster]++;
      sumR[bestCluster] += p.$1;
      sumG[bestCluster] += p.$2;
      sumB[bestCluster] += p.$3;
    }

    // Find largest cluster
    int maxIdx = 0;
    for (int i = 1; i < 3; i++) {
      if (counts[i] > counts[maxIdx]) maxIdx = i;
    }

    if (counts[maxIdx] == 0) return 'clear';

    final meanR = sumR[maxIdx] / counts[maxIdx];
    final meanG = sumG[maxIdx] / counts[maxIdx];
    final meanB = sumB[maxIdx] / counts[maxIdx];

    // Classification heuristics for glass
    if (meanG > (meanR * 1.15) && meanG > (meanB * 1.15)) {
      return 'green';
    } else if (meanR > (meanB * 1.4) && meanG < meanR && meanR > 60 && meanB < 80) {
      return 'brown';
    } else if ((meanR - meanG).abs() < 25 && (meanG - meanB).abs() < 25) {
      return 'clear';
    }

    return 'other';
  }

  static double _colorDist((int, int, int) p1, (int, int, int) p2) {
    final dr = p1.$1 - p2.$1;
    final dg = p1.$2 - p2.$2;
    final db = p1.$3 - p2.$3;
    return sqrt(dr * dr + dg * dg + db * db);
  }
}

