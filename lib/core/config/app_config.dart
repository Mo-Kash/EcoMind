/// Central configuration parameters for EcoMind 2.0.
class AppConfig {
  // Image sizing
  static const int maxWorkingDimension = 1280;
  static const int detectorInputSize = 640;
  static const int classifierInputSize = 224;

  // Quality gate thresholds
  static const double blurVarianceThreshold = 100.0;
  static const double underexposedLumaThreshold = 70.0;
  static const double overexposedLumaThreshold = 200.0;
  static const double overexposedSaturatedPixelShare = 0.05;

  // Auto-enhancement triggers
  static const double wbChannelDifferenceRatio = 0.15;
  static const double claheLumaStdDevThreshold = 40.0;
  static const double gammaDark = 0.8;
  static const double gammaBright = 1.2;
  static const int maxEnhancementBudgetMs = 150;

  // Classifier confidence policy
  static const double confidentThreshold = 0.70;
  static const double likelyThreshold = 0.45;

  // Detection settings
  static const double defaultConfidenceThreshold = 0.35;
  static const double defaultIouThreshold = 0.50;
  static const int maxInstancesPerScene = 20;
  static const double minInstanceMaskShare = 0.005; // 0.5% min area
  static const int minBoundingBoxPx = 32;

  // Model asset paths
  static const String detectorModelPath = 'assets/models/yolo11n-seg.tflite';
  static const String classifierModelPath = 'assets/models/mobilenetv3_large.tflite';
  static const String legacyClassifierPath = 'assets/mobilenetv2_trash_classifier.tflite';
  static const String labelsAssetPath = 'assets/models/labels.txt';
  static const String disposalRulesAssetPath = 'assets/rules/disposal_rules.json';
  static const String contaminationConfigAssetPath = 'assets/rules/contamination_config.json';

  // Storage
  static const int maxStorageMb = 500;

  // Gemini & EcoBot
  // Build-time values are extractable from client apps; use only for local testing.
  static const String defaultGeminiModel = 'gemini-1.5-flash';
  static const String defaultGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
}
