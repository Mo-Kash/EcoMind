import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ecomind/features/dip/quality_gate.dart';
import 'package:ecomind/features/dip/auto_enhancement.dart';
import 'package:ecomind/features/dip/mask_utils.dart';
import 'package:ecomind/features/dip/hsv_contamination.dart';
import 'package:ecomind/features/dip/kmeans_color.dart';

void main() {
  group('DIP Quality Gate Tests', () {
    test('Flat image produces low Laplacian variance (blurry / untextured)', () {
      final flat = img.Image(width: 100, height: 100);
      img.fill(flat, color: img.ColorRgb8(120, 120, 120));

      final metrics = QualityGate.evaluate(flat);
      expect(metrics.blurVariance, equals(0.0));
      expect(metrics.isBlurry, isTrue);
    });

    test('Dark image produces underexposed warning', () {
      final dark = img.Image(width: 100, height: 100);
      img.fill(dark, color: img.ColorRgb8(20, 20, 20));

      final metrics = QualityGate.evaluate(dark);
      expect(metrics.meanLuma, lessThan(70.0));
      expect(metrics.isDark, isTrue);
    });

    test('High glare image triggers overexposed flag', () {
      final bright = img.Image(width: 100, height: 100);
      img.fill(bright, color: img.ColorRgb8(252, 252, 252));

      final metrics = QualityGate.evaluate(bright);
      expect(metrics.meanLuma, greaterThan(200.0));
      expect(metrics.isBright, isTrue);
    });
  });

  group('DIP Mask Utilities Tests', () {
    test('Morphological opening removes isolated speckle', () {
      final mask = List.generate(10, (_) => List<bool>.filled(10, false));
      // Single isolated speckle pixel
      mask[5][5] = true;

      final opened = MaskUtils.open(mask);
      expect(opened[5][5], isFalse);
    });

    test('Keep largest component isolates main object and discards noise', () {
      final mask = List.generate(20, (_) => List<bool>.filled(20, false));
      // Small component (2 pixels)
      mask[1][1] = true;
      mask[1][2] = true;

      // Large component (3x3 = 9 pixels)
      for (int y = 10; y <= 12; y++) {
        for (int x = 10; x <= 12; x++) {
          mask[y][x] = true;
        }
      }

      final largest = MaskUtils.keepLargestComponent(mask);
      expect(largest[1][1], isFalse);
      expect(largest[10][10], isTrue);
      expect(largest[12][12], isTrue);
    });
  });

  group('HSV Contamination Tests', () {
    test('Uniform clean surface returns clean tier (< 10%)', () {
      final cleanImg = img.Image(width: 50, height: 50);
      img.fill(cleanImg, color: img.ColorRgb8(220, 220, 220));
      final mask = List.generate(50, (_) => List<bool>.filled(50, true));

      final res = HsvContamination.analyze(
        image: cleanImg,
        mask: mask,
        itemClass: 'cardboard',
      );

      expect(res.level, equals('clean'));
      expect(res.ratio, lessThan(0.10));
    });
  });

  group('Glass Color Extraction Tests', () {
    test('Predominantly green pixels map to green glass', () {
      final greenImg = img.Image(width: 50, height: 50);
      img.fill(greenImg, color: img.ColorRgb8(30, 160, 40));
      final mask = List.generate(50, (_) => List<bool>.filled(50, true));

      final color = KMeansColor.extractDominantGlassColor(
        image: greenImg,
        mask: mask,
      );

      expect(color, equals('green'));
    });
  });
}

