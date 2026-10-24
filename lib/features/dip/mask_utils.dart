import 'dart:math';

class MaskUtils {
  /// Applies morphological opening (erosion followed by dilation) to remove speckle.
  static List<List<bool>> open(List<List<bool>> mask) {
    return dilate(erode(mask));
  }

  /// Applies morphological closing (dilation followed by erosion) to fill thin gaps.
  static List<List<bool>> close(List<List<bool>> mask) {
    return erode(dilate(mask));
  }

  /// 3x3 Binary erosion.
  static List<List<bool>> erode(List<List<bool>> mask) {
    final h = mask.length;
    if (h == 0) return mask;
    final w = mask[0].length;
    final output = List.generate(h, (_) => List<bool>.filled(w, false));

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        if (mask[y][x] &&
            mask[y - 1][x] &&
            mask[y + 1][x] &&
            mask[y][x - 1] &&
            mask[y][x + 1]) {
          output[y][x] = true;
        }
      }
    }
    return output;
  }

  /// 3x3 Binary dilation.
  static List<List<bool>> dilate(List<List<bool>> mask) {
    final h = mask.length;
    if (h == 0) return mask;
    final w = mask[0].length;
    final output = List.generate(h, (_) => List<bool>.filled(w, false));

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        if (mask[y][x]) {
          output[y][x] = true;
          output[y - 1][x] = true;
          output[y + 1][x] = true;
          output[y][x - 1] = true;
          output[y][x + 1] = true;
        }
      }
    }
    return output;
  }

  /// Retains only the largest connected component in the mask.
  static List<List<bool>> keepLargestComponent(List<List<bool>> mask) {
    final h = mask.length;
    if (h == 0) return mask;
    final w = mask[0].length;

    final visited = List.generate(h, (_) => List<bool>.filled(w, false));
    List<Point<int>> bestComponent = [];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (mask[y][x] && !visited[y][x]) {
          final comp = <Point<int>>[];
          final queue = <Point<int>>[Point(x, y)];
          visited[y][x] = true;

          while (queue.isNotEmpty) {
            final pt = queue.removeLast();
            comp.add(pt);

            const dx = [0, 0, 1, -1];
            const dy = [1, -1, 0, 0];

            for (int k = 0; k < 4; k++) {
              final nx = pt.x + dx[k];
              final ny = pt.y + dy[k];

              if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
                if (mask[ny][nx] && !visited[ny][nx]) {
                  visited[ny][nx] = true;
                  queue.add(Point(nx, ny));
                }
              }
            }
          }

          if (comp.length > bestComponent.length) {
            bestComponent = comp;
          }
        }
      }
    }

    final output = List.generate(h, (_) => List<bool>.filled(w, false));
    for (final pt in bestComponent) {
      output[pt.y][pt.x] = true;
    }
    return output;
  }

  /// Calculates intersection over union (IoU) between two boolean masks.
  static double maskIoU(List<List<bool>> m1, List<List<bool>> m2) {
    int intersection = 0;
    int union = 0;
    final h = min(m1.length, m2.length);
    if (h == 0) return 0;
    final w = min(m1[0].length, m2[0].length);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final b1 = m1[y][x];
        final b2 = m2[y][x];
        if (b1 && b2) intersection++;
        if (b1 || b2) union++;
      }
    }
    return union > 0 ? (intersection / union) : 0.0;
  }
}

