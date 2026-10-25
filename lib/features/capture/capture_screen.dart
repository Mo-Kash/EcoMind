import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../core/utils/isolate_runner.dart';
import '../../data/local/app_database.dart';
import '../../data/models/detected_item.dart';
import '../../data/models/scan_record.dart';
import '../classification/mobilenet_classifier_service.dart';
import '../detection/yolo_detector_service.dart';
import '../dip/edge_texture_analyzer.dart';
import '../dip/hsv_contamination.dart';
import '../dip/kmeans_color.dart';
import '../results/results_screen.dart';

class CaptureScreen extends StatefulWidget {
  final ImageSource source;

  const CaptureScreen({super.key, required this.source});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  String _statusText = 'Capturing image...';
  int _currentStep = 0; // 0: Capture, 1: DIP Pre-processing, 2: Detection, 3: Classification & DIP Surface Analysis

  IsolateDIPResult? _dipResult;
  String? _originalImagePath;
  String? _enhancedImagePath;

  final YoloDetectorService _detector = YoloDetectorService();
  final MobileNetClassifierService _classifier = MobileNetClassifierService();

  @override
  void initState() {
    super.initState();
    _startPipeline();
  }

  Future<void> _startPipeline() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: widget.source);

      if (picked == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      setState(() {
        _currentStep = 1;
        _statusText = 'DIP Pre-Processing: Balancing color, boosting CLAHE contrast & edge sharpening...';
      });

      final bytes = await File(picked.path).readAsBytes();

      // 1. Run EXIF fix, Quality Gate, and Auto-Enhancement in background isolate
      final dipResult = await IsolateRunner.processImageBytes(bytes);

      // Save files to app directory
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final origPath = '${dir.path}/scan_orig_$ts.jpg';
      final enhPath = '${dir.path}/scan_enh_$ts.jpg';

      await File(origPath).writeAsBytes(dipResult.originalBytes);
      await File(enhPath).writeAsBytes(dipResult.enhancedBytes);

      setState(() {
        _dipResult = dipResult;
        _originalImagePath = origPath;
        _enhancedImagePath = enhPath;
      });

      // If quality gate warns or rejects, prompt user
      if (dipResult.qualityMetrics.status != 'pass' && mounted) {
        _showQualityDialog();
      } else {
        _runInferencePipeline();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing photo: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _showQualityDialog() {
    final qm = _dipResult!.qualityMetrics;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              qm.status == 'reject' ? Icons.error_outline : Icons.warning_amber_rounded,
              color: qm.status == 'reject' ? Colors.red : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(qm.status == 'reject' ? 'Quality Issue' : 'Quality Warning'),
          ],
        ),
        content: Text(qm.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Retake photo
            },
            child: const Text('Retake Photo'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _runInferencePipeline();
            },
            child: const Text('Proceed Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _runInferencePipeline() async {
    setState(() {
      _currentStep = 2;
      _statusText = 'Object Detection: Isolating waste instances on conditioned image...';
    });

    final stopwatch = Stopwatch()..start();

    // 1. Decode enhanced image
    final enhancedImage = img.decodeImage(_dipResult!.enhancedBytes)!;

    // 2. Initialize models
    await _detector.initialize();
    await _classifier.initialize();

    // 3. Segment waste items (YOLO11n-seg)
    final rawDetections = await _detector.detectAndSegment(enhancedImage);
    final refinedDetections = _detector.postProcessDetections(rawDetections);

    setState(() {
      _currentStep = 3;
      _statusText = 'Classification & DIP Surface Analysis: Assessing material, texture & contamination...';
    });

    // 4. Per-instance classification (MobileNetV3), Texture, Contamination, and Glass Color
    final items = <DetectedItem>[];
    final scanId = 'scan_${DateTime.now().millisecondsSinceEpoch}';

    for (int i = 0; i < refinedDetections.length; i++) {
      final det = refinedDetections[i];
      final itemId = '${scanId}_item_$i';

      // Crop instance with 10% padding
      final crop = _cropInstanceWithPadding(enhancedImage, det.box);

      // Classify instance
      final clsResult = await _classifier.classifyCrop(crop, enableTTA: true);

      // DIP Surface Texture & Roughness Analysis (Sobel Gradient)
      final texture = EdgeTextureAnalyzer.analyze(crop);

      // HSV contamination estimate inside mask
      final contam = HsvContamination.analyze(
        image: enhancedImage,
        mask: det.mask,
        itemClass: clsResult.topClass,
      );

      // Glass color detection if classified as glass
      String? glassColor;
      if (clsResult.topClass == 'glass') {
        glassColor = KMeansColor.extractDominantGlassColor(
          image: enhancedImage,
          mask: det.mask,
        );
      }

      items.add(
        DetectedItem(
          id: itemId,
          scanId: scanId,
          boundingBox: det.box,
          predictedClass: clsResult.topClass,
          top3Scores: clsResult.top3,
          confidence: clsResult.confidence,
          detectorScore: det.score,
          contaminationRatio: contam.ratio,
          contaminationLevel: contam.level,
          glassColor: glassColor,
          surfaceTexture: texture.surfaceTexture,
          edgeDensity: texture.edgeDensity,
        ),
      );
    }

    stopwatch.stop();

    // 5. Build ScanRecord and persist to SQLite
    final scanRecord = ScanRecord(
      id: scanId,
      timestamp: DateTime.now(),
      originalImagePath: _originalImagePath!,
      enhancedImagePath: _enhancedImagePath!,
      items: items,
      qualityMetrics: _dipResult!.qualityMetrics,
      enhancementLog: _dipResult!.enhancementLog,
      totalElapsedMs: stopwatch.elapsedMilliseconds,
    );

    await AppDatabase.instance.insertScan(scanRecord);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => ResultsScreen(scan: scanRecord),
        ),
      );
    }
  }

  img.Image _cropInstanceWithPadding(img.Image src, Rect normBox) {
    final padX = (normBox.width * src.width * 0.05); // 5% pad on each side = 10% total padding
    final padY = (normBox.height * src.height * 0.05);
    final x1 = ((normBox.left * src.width) - padX).clamp(0, src.width - 1).toInt();
    final y1 = ((normBox.top * src.height) - padY).clamp(0, src.height - 1).toInt();
    final x2 = ((normBox.right * src.width) + padX).clamp(x1 + 1, src.width).toInt();
    final y2 = ((normBox.bottom * src.height) + padY).clamp(y1 + 1, src.height).toInt();

    return img.copyCrop(src, x: x1, y: y1, width: x2 - x1, height: y2 - y1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing & Classifying'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(strokeWidth: 4, color: Colors.green),
              ),
              const SizedBox(height: 24),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              // Visual 3-Stage Pipeline Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildPipelineStep(
                      stepNum: 1,
                      title: 'DIP Image Conditioning',
                      subtitle: 'Gray-World WB, CLAHE contrast & unsharp sharpening',
                      isActive: _currentStep == 1,
                      isCompleted: _currentStep > 1,
                    ),
                    const Divider(height: 20),
                    _buildPipelineStep(
                      stepNum: 2,
                      title: 'Instance Segmentation',
                      subtitle: 'YOLO11n-seg bounding box & polygon mask isolation',
                      isActive: _currentStep == 2,
                      isCompleted: _currentStep > 2,
                    ),
                    const Divider(height: 20),
                    _buildPipelineStep(
                      stepNum: 3,
                      title: 'Material & Surface Analysis',
                      subtitle: 'MobileNetV3 classifier + Sobel texture & HSV soil metrics',
                      isActive: _currentStep == 3,
                      isCompleted: _currentStep > 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '100% on-device & private · Zero network latency',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineStep({
    required int stepNum,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color iconColor;
    IconData icon;
    if (isCompleted) {
      iconColor = Colors.green;
      icon = Icons.check_circle;
    } else if (isActive) {
      iconColor = Colors.teal;
      icon = Icons.hourglass_top;
    } else {
      iconColor = Colors.grey.shade400;
      icon = Icons.radio_button_unchecked;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isActive ? Colors.teal.shade900 : (isCompleted ? Colors.black87 : Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

