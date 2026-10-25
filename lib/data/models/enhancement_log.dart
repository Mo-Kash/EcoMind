class EnhancementLog {
  final bool whiteBalanceApplied;
  final bool claheApplied;
  final bool gammaApplied;
  final double gammaValue;
  final bool denoiseApplied;
  final bool sharpenApplied;
  final int elapsedMs;

  const EnhancementLog({
    this.whiteBalanceApplied = false,
    this.claheApplied = false,
    this.gammaApplied = false,
    this.gammaValue = 1.0,
    this.denoiseApplied = false,
    this.sharpenApplied = false,
    this.elapsedMs = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'whiteBalanceApplied': whiteBalanceApplied ? 1 : 0,
      'claheApplied': claheApplied ? 1 : 0,
      'gammaApplied': gammaApplied ? 1 : 0,
      'gammaValue': gammaValue,
      'denoiseApplied': denoiseApplied ? 1 : 0,
      'sharpenApplied': sharpenApplied ? 1 : 0,
      'elapsedMs': elapsedMs,
    };
  }

  factory EnhancementLog.fromMap(Map<String, dynamic> map) {
    return EnhancementLog(
      whiteBalanceApplied: map['whiteBalanceApplied'] == 1,
      claheApplied: map['claheApplied'] == 1,
      gammaApplied: map['gammaApplied'] == 1,
      gammaValue: (map['gammaValue'] as num?)?.toDouble() ?? 1.0,
      denoiseApplied: map['denoiseApplied'] == 1,
      sharpenApplied: map['sharpenApplied'] == 1,
      elapsedMs: map['elapsedMs'] as int? ?? 0,
    );
  }
}

