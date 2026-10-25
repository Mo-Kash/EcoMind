class QualityMetrics {
  final double blurVariance;
  final double meanLuma;
  final double clippedPixelShare;
  final bool isBlurry;
  final bool isDark;
  final bool isBright;
  final String status; // 'pass', 'warn', 'reject'
  final String message;

  const QualityMetrics({
    required this.blurVariance,
    required this.meanLuma,
    required this.clippedPixelShare,
    required this.isBlurry,
    required this.isDark,
    required this.isBright,
    required this.status,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'blurVariance': blurVariance,
      'meanLuma': meanLuma,
      'clippedPixelShare': clippedPixelShare,
      'isBlurry': isBlurry ? 1 : 0,
      'isDark': isDark ? 1 : 0,
      'isBright': isBright ? 1 : 0,
      'status': status,
      'message': message,
    };
  }

  factory QualityMetrics.fromMap(Map<String, dynamic> map) {
    return QualityMetrics(
      blurVariance: (map['blurVariance'] as num).toDouble(),
      meanLuma: (map['meanLuma'] as num).toDouble(),
      clippedPixelShare: (map['clippedPixelShare'] as num).toDouble(),
      isBlurry: map['isBlurry'] == 1,
      isDark: map['isDark'] == 1,
      isBright: map['isBright'] == 1,
      status: map['status'] as String,
      message: map['message'] as String,
    );
  }
}

