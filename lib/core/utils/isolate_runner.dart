import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../config/app_config.dart';
import '../../data/models/enhancement_log.dart';
import '../../data/models/quality_metrics.dart';
import '../../features/dip/auto_enhancement.dart';
import '../../features/dip/quality_gate.dart';

class IsolateDIPResult {
  final Uint8List originalBytes;
  final Uint8List enhancedBytes;
  final QualityMetrics qualityMetrics;
  final EnhancementLog enhancementLog;

  IsolateDIPResult({
    required this.originalBytes,
    required this.enhancedBytes,
    required this.qualityMetrics,
    required this.enhancementLog,
  });
}

class IsolateRunner {
  /// Runs EXIF correction, Quality Gate, and Auto-Enhancement in a background isolate.
  static Future<IsolateDIPResult> processImageBytes(Uint8List rawBytes) async {
    return await compute(_backgroundDIPTask, rawBytes);
  }

  static IsolateDIPResult _backgroundDIPTask(Uint8List rawBytes) {
    // 1. Decode raw bytes
    img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw Exception('Failed to decode image bytes.');
    }

    // 2. EXIF orientation correction
    decoded = img.bakeOrientation(decoded);

    // 3. Quality Gate evaluation on downscaled working image
    final workingCopy = AutoEnhancement.letterbox(
      decoded,
      AppConfig.detectorInputSize,
    );
    final qualityMetrics = QualityGate.evaluate(workingCopy);

    // 4. Conditional auto-enhancement
    final (enhanced, log) = AutoEnhancement.enhance(decoded, qualityMetrics);

    // 5. Encode output images to JPEG bytes for safe isolate transfer
    final originalJpg = Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
    final enhancedJpg = Uint8List.fromList(img.encodeJpg(enhanced, quality: 90));

    return IsolateDIPResult(
      originalBytes: originalJpg,
      enhancedBytes: enhancedJpg,
      qualityMetrics: qualityMetrics,
      enhancementLog: log,
    );
  }
}

