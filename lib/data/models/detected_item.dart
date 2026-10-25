import 'dart:ui';

class DetectedItem {
  final String id;
  final String scanId;
  final Rect boundingBox; // [left, top, right, bottom] normalized 0..1
  final List<Offset> maskPolygon; // Polygon contour points normalized 0..1
  final String predictedClass;
  final Map<String, double> top3Scores;
  final double confidence;
  final double detectorScore;
  final double? contaminationRatio;
  final String? contaminationLevel; // 'clean', 'light', 'heavy'
  final String? glassColor; // 'clear', 'green', 'brown', 'other'
  final String? surfaceTexture; // 'Smooth', 'Semi-Smooth', 'Textured / Rough'
  final double? edgeDensity;
  final String? cropImagePath;
  final String? maskImagePath;
  String? correctedClass; // HITL correction

  DetectedItem({
    required this.id,
    required this.scanId,
    required this.boundingBox,
    this.maskPolygon = const [],
    required this.predictedClass,
    required this.top3Scores,
    required this.confidence,
    this.detectorScore = 1.0,
    this.contaminationRatio,
    this.contaminationLevel,
    this.glassColor,
    this.surfaceTexture,
    this.edgeDensity,
    this.cropImagePath,
    this.maskImagePath,
    this.correctedClass,
  });

  String get effectiveClass => correctedClass ?? predictedClass;
  bool get isCorrected => correctedClass != null && correctedClass != predictedClass;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scanId': scanId,
      'box_left': boundingBox.left,
      'box_top': boundingBox.top,
      'box_right': boundingBox.right,
      'box_bottom': boundingBox.bottom,
      'predictedClass': predictedClass,
      'confidence': confidence,
      'detectorScore': detectorScore,
      'contaminationRatio': contaminationRatio,
      'contaminationLevel': contaminationLevel,
      'glassColor': glassColor,
      'surfaceTexture': surfaceTexture,
      'edgeDensity': edgeDensity,
      'cropImagePath': cropImagePath,
      'maskImagePath': maskImagePath,
      'correctedClass': correctedClass,
    };
  }
}

