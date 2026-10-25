import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/taxonomy.dart';
import '../../data/models/detected_item.dart';
import '../../data/models/scan_record.dart';
import '../dip/widgets/before_after_slider.dart';
import '../hitl/correction_sheet.dart';
import '../inspector/pipeline_inspector_screen.dart';
import 'widgets/composition_donut_chart.dart';
import 'widgets/item_card.dart';
import 'widgets/mask_overlay_painter.dart';

class ResultsScreen extends StatefulWidget {
  final ScanRecord scan;

  const ResultsScreen({super.key, required this.scan});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String? _selectedItemId;
  bool _activeLearningDismissed = false;
  bool _showDIPWipe = false;

  void _showDIPDiagnosticsSheet(BuildContext context, DetectedItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Taxonomy.getColor(item.effectiveClass).withValues(alpha: 0.2),
                      child: Icon(Icons.analytics_outlined, color: Taxonomy.getColor(item.effectiveClass)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Taxonomy.getDisplayName(item.effectiveClass)} DIP Surface Profile',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Classification Confidence: ${(item.confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Diagnostic Badges
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDiagItem(
                        'Contamination',
                        '${((item.contaminationRatio ?? 0.0) * 100).toStringAsFixed(1)}%',
                        item.contaminationLevel == 'heavy' ? Colors.red : Colors.green,
                      ),
                      _buildDiagItem(
                        'Surface Status',
                        (item.contaminationLevel ?? 'clean').toUpperCase(),
                        Colors.black87,
                      ),
                      _buildDiagItem(
                        'Surface Texture',
                        item.surfaceTexture ?? 'Unknown',
                        item.surfaceTexture == 'Smooth' ? Colors.blueGrey : Colors.brown.shade700,
                      ),
                    ],
                  ),
                  if (item.edgeDensity != null || item.glassColor != null) ...[
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (item.edgeDensity != null)
                          _buildDiagItem(
                            'Sobel Edge Density',
                            '${(item.edgeDensity! * 100).toStringAsFixed(1)}%',
                            Colors.teal.shade800,
                          ),
                        if (item.glassColor != null)
                          _buildDiagItem(
                            'Glass Tint',
                            item.glassColor!.toUpperCase(),
                            Colors.teal,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Crop image preview if exists
            if (item.cropImagePath != null && File(item.cropImagePath!).existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 160,
                  child: Image.file(File(item.cropImagePath!), fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              'DIP features directly adjust image lighting and contrast before classification, '
              'while HSV residue and Sobel edge density determine recyclability and bin routing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        const SizedBox(height: 2),
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final origFile = File(widget.scan.originalImagePath);
    final enhFile = File(widget.scan.enhancedImagePath);

    final uncertainItem = _activeLearningDismissed
        ? null
        : widget.scan.items.cast<DetectedItem?>().firstWhere(
              (item) =>
                  item != null && !item.isCorrected && item.confidence < 0.60,
              orElse: () => null,
            );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorting Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'DIP Pipeline Inspector',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => PipelineInspectorScreen(scan: widget.scan),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image Viewer: Toggle between Segmentation Overlays and DIP Split Wipe
            AspectRatio(
              aspectRatio: 1.0,
              child: _showDIPWipe && origFile.existsSync() && enhFile.existsSync()
                  ? BeforeAfterSlider.files(
                      beforeFile: origFile,
                      afterFile: enhFile,
                      beforeLabel: 'RAW CAPTURE',
                      afterLabel: 'DIP CONDITIONED',
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: enhFile.existsSync()
                              ? Image.file(enhFile, fit: BoxFit.cover)
                              : Container(color: Colors.black12),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: MaskOverlayPainter(
                              items: widget.scan.items,
                              selectedItemId: _selectedItemId,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // DIP Mode Selector Bar
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _showDIPWipe
                          ? 'Wipe: Raw Capture vs DIP Conditioned Input'
                          : 'Tap an item to highlight segmentation mask',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _showDIPWipe = !_showDIPWipe),
                    icon: Icon(_showDIPWipe ? Icons.layers : Icons.swap_horiz, size: 16),
                    label: Text(_showDIPWipe ? 'Show Masks' : 'DIP Wipe View'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.teal.shade800,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Active Learning Prompt
                  if (uncertainItem != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.help_outline, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Help improve EcoMind',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'Uncertain about ${Taxonomy.getDisplayName(uncertainItem.predictedClass)}. Tap to confirm actual material.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              CorrectionSheet.show(context, uncertainItem, () {
                                setState(() {
                                  _activeLearningDismissed = true;
                                });
                              });
                            },
                            child: const Text('Confirm'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() => _activeLearningDismissed = true),
                          ),
                        ],
                      ),
                    ),

                  // 2. Composition Donut Chart
                  CompositionDonutChart(items: widget.scan.items),
                  const SizedBox(height: 12),

                  // 3. Item Cards with DIP Surface Diagnostics
                  ...widget.scan.items.map((item) {
                    return ItemCard(
                      item: item,
                      isSelected: item.id == _selectedItemId,
                      onTap: () {
                        setState(() {
                          _selectedItemId = _selectedItemId == item.id ? null : item.id;
                        });
                      },
                      onCorrected: () => setState(() {}),
                      onInspectDIP: (selected) => _showDIPDiagnosticsSheet(context, selected),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
