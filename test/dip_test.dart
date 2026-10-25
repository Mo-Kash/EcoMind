import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ecomind/features/dip/quality_gate.dart';
import 'package:ecomind/features/dip/mask_utils.dart';
import 'package:ecomind/features/dip/hsv_contamination.dart';
import 'package:ecomind/features/dip/kmeans_color.dart';
import 'package:ecomind/features/dip/histogram_analyzer.dart';
import 'package:ecomind/features/dip/edge_texture_analyzer.dart';
import 'package:ecomind/features/dip/contamination_heatmap.dart';

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

  group('Histogram & Photometric Analyzer Tests', () {
    test('Calculates 256 bins and correct dynamic range', () {
      final image = img.Image(width: 50, height: 50);
      img.fill(image, color: img.ColorRgb8(100, 100, 100));

      final hist = HistogramAnalyzer.compute(image);
      expect(hist.luma.length, equals(256));
      expect(hist.totalPixels, equals(2500));
      expect(hist.meanLuma, closeTo(100.0, 1.0));
      expect(hist.rmsContrast, closeTo(0.0, 0.1));
      expect(hist.entropy, closeTo(0.0, 0.01)); // Pure single tone = 0 entropy
    });

    test('Bimodal image produces non-zero entropy and dynamic range', () {
      final image = img.Image(width: 20, height: 20);
      for (int y = 0; y < 20; y++) {
        for (int x = 0; x < 20; x++) {
          final val = (x < 10) ? 50 : 200;
          image.setPixelRgb(x, y, val, val, val);
        }
      }

      final hist = HistogramAnalyzer.compute(image);
      expect(hist.entropy, greaterThan(0.9)); // Half/half = ~1 bit entropy
      expect(hist.dynamicRange, equals(150));
      expect(hist.rmsContrast, greaterThan(50.0));
    });
  });

  group('Sobel Edge & Texture Roughness Tests', () {
    test('Flat image produces 0 edge density (Smooth surface)', () {
      final flat = img.Image(width: 30, height: 30);
      img.fill(flat, color: img.ColorRgb8(128, 128, 128));

      final res = EdgeTextureAnalyzer.analyze(flat);
      expect(res.edgeDensity, equals(0.0));
      expect(res.surfaceTexture, equals('Smooth'));
    });

    test('High-contrast striped image produces high edge density (Textured/Rough)', () {
      final striped = img.Image(width: 30, height: 30);
      for (int y = 0; y < 30; y++) {
        for (int x = 0; x < 30; x++) {
          final v = ((x ~/ 3) % 2 == 0) ? 0 : 255;
          striped.setPixelRgb(x, y, v, v, v);
        }
      }

      final res = EdgeTextureAnalyzer.analyze(striped);
      expect(res.edgeDensity, greaterThan(0.20));
      expect(res.surfaceTexture, equals('Textured / Rough'));
    });
  });

  group('Contamination Heatmap Tests', () {
    test('Generates 4-channel RGBA heatmap with correct dimensions', () {
      final image = img.Image(width: 40, height: 40);
      img.fill(image, color: img.ColorRgb8(240, 240, 240));

      final res = ContaminationHeatmapGenerator.generate(image);
      expect(res.heatmapImage.width, equals(40));
      expect(res.heatmapImage.height, equals(40));
      expect(res.compositeImage.width, equals(40));
      expect(res.soilPercentage, lessThan(5.0)); // Clean image
    });
  });
}

