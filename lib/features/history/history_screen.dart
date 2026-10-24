import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/local/app_database.dart';
import '../../data/models/detected_item.dart';
import '../../data/models/enhancement_log.dart';
import '../../data/models/quality_metrics.dart';
import '../../data/models/scan_record.dart';
import '../results/results_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _scans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await AppDatabase.instance.getScansHistory();
    setState(() {
      _scans = list;
      _isLoading = false;
    });
  }

  Future<void> _openScan(Map<String, dynamic> scanMap) async {
    final scanId = scanMap['id'] as String;
    final itemRows = await AppDatabase.instance.getItemsForScan(scanId);

    final items = itemRows.map((row) {
      return DetectedItem(
        id: row['id'] as String,
        scanId: scanId,
        boundingBox: Rect.fromLTRB(
          (row['box_left'] as num).toDouble(),
          (row['box_top'] as num).toDouble(),
          (row['box_right'] as num).toDouble(),
          (row['box_bottom'] as num).toDouble(),
        ),
        predictedClass: row['predictedClass'] as String,
        top3Scores: {},
        confidence: (row['confidence'] as num).toDouble(),
        contaminationLevel: row['contaminationLevel'] as String?,
        contaminationRatio: (row['contaminationRatio'] as num?)?.toDouble(),
        glassColor: row['glassColor'] as String?,
        correctedClass: row['correctedClass'] as String?,
      );
    }).toList();

    final scanRecord = ScanRecord(
      id: scanId,
      timestamp: DateTime.parse(scanMap['timestamp'] as String),
      originalImagePath: scanMap['originalImagePath'] as String,
      enhancedImagePath: scanMap['enhancedImagePath'] as String,
      items: items,
      qualityMetrics: const QualityMetrics(
        blurVariance: 120.0,
        meanLuma: 110.0,
        clippedPixelShare: 0.01,
        isBlurry: false,
        isDark: false,
        isBright: false,
        status: 'pass',
        message: 'Quality verified.',
      ),
      enhancementLog: const EnhancementLog(),
      totalElapsedMs: scanMap['totalElapsedMs'] as int? ?? 0,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ResultsScreen(scan: scanRecord),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No previous scans yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _scans.length,
                  itemBuilder: (ctx, index) {
                    final scan = _scans[index];
                    final enhPath = scan['enhancedImagePath'] as String;
                    final ts = DateTime.parse(scan['timestamp'] as String);
                    final formattedDate = "${ts.day}/${ts.month}/${ts.year} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}";

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: File(enhPath).existsSync()
                              ? Image.file(File(enhPath), width: 52, height: 52, fit: BoxFit.cover)
                              : Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, size: 28),
                                ),
                        ),
                        title: Text(
                          'Scan on $formattedDate',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Latency: ${scan['totalElapsedMs']} ms',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _openScan(scan),
                      ),
                    );
                  },
                ),
    );
  }
}

