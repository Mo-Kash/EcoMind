import 'detected_item.dart';
import 'quality_metrics.dart';
import 'enhancement_log.dart';

class ScanRecord {
  final String id;
  final DateTime timestamp;
  final String originalImagePath;
  final String enhancedImagePath;
  final List<DetectedItem> items;
  final QualityMetrics qualityMetrics;
  final EnhancementLog enhancementLog;
  final String detectorVersion;
  final String classifierVersion;
  final int totalElapsedMs;

  ScanRecord({
    required this.id,
    required this.timestamp,
    required this.originalImagePath,
    required this.enhancedImagePath,
    required this.items,
    required this.qualityMetrics,
    required this.enhancementLog,
    this.detectorVersion = 'yolo11n-seg-v1.0',
    this.classifierVersion = 'mobilenetv3-large-v1.0',
    this.totalElapsedMs = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'originalImagePath': originalImagePath,
      'enhancedImagePath': enhancedImagePath,
      'detectorVersion': detectorVersion,
      'classifierVersion': classifierVersion,
      'totalElapsedMs': totalElapsedMs,
    };
  }
}

