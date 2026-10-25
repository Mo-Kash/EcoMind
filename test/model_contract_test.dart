import 'package:flutter_test/flutter_test.dart';
import 'package:ecomind/core/constants/taxonomy.dart';
import 'package:ecomind/core/config/app_config.dart';

void main() {
  group('Model Contract & Taxonomy Tests', () {
    test('Official 9 classes match PRD specifications exactly', () {
      expect(Taxonomy.classes.length, equals(9));
      expect(Taxonomy.classes, equals([
        'cardboard',
        'paper',
        'plastic',
        'glass',
        'metal',
        'organic',
        'battery_ewaste',
        'textile',
        'general_trash',
      ]));
    });

    test('Every class has an assigned display name and color', () {
      for (final cls in Taxonomy.classes) {
        expect(Taxonomy.displayNames.containsKey(cls), isTrue);
        expect(Taxonomy.classColors.containsKey(cls), isTrue);
      }
    });

    test('Confidence threshold policy invariants', () {
      expect(AppConfig.confidentThreshold, greaterThan(AppConfig.likelyThreshold));
      expect(AppConfig.confidentThreshold, equals(0.70));
      expect(AppConfig.likelyThreshold, equals(0.45));
    });

    test('DIP configuration invariants', () {
      expect(AppConfig.sobelEdgeThreshold, equals(45.0));
      expect(AppConfig.textureRoughnessThreshold, equals(0.15));
      expect(AppConfig.histogramBins, equals(256));
    });
  });
}

