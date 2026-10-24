import 'dart:io';
import 'dart:typed_data';
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
  bool _isProcessing = true;
  String _statusText = 'Capturing image...';
  bool _showEnhanced = true;

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

      setState(() => _statusText = 'Analyzing image quality & auto-enhancing in background isolate...');

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
        _isProcessing = false;
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
      _isProcessing = true;
      _statusText = 'Running instance segmentation & waste classification...';
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

    // 4. Per-instance classification (MobileNetV3), Contamination, and Glass Color
    final items = <DetectedItem>[];
    final scanId = 'scan_${DateTime.now().millisecondsSinceEpoch}';

    for (int i = 0; i < refinedDetections.length; i++) {
      final det = refinedDetections[i];
      final itemId = '${scanId}_item_$i';

      // Crop instance with 10% padding
      final crop = _cropInstanceWithPadding(enhancedImage, det.box);

      // Classify instance
      final clsResult = await _classifier.classifyCrop(crop, enableTTA: true);

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
    final x1 = (normBox.left * src.width).clamp(0, src.width).toInt();
    final y1 = (normBox.top * src.height).clamp(0, src.height).toInt();
    final w = ((normBox.width * src.width) * 1.1).clamp(1, src.width - x1).toInt();
    final h = ((normBox.height * src.height) * 1.1).clamp(1, src.height - y1).toInt();

    return img.copyCrop(src, x: x1, y: y1, width: w, height: h);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyzing Waste'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(strokeWidth: 4, color: Colors.green),
              ),
              const SizedBox(height: 24),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Running fully on-device & offline',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

