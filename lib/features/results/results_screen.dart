import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/detected_item.dart';
import '../../data/models/scan_record.dart';
import '../chat/ecobot_chat_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.scan.enhancedImagePath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorting Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Pipeline Inspector',
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
            // 1. Annotated Image Preview with Segmentation Mask Overlays
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: imageFile.existsSync()
                      ? Image.file(imageFile, fit: BoxFit.cover)
                      : Container(
                          color: Colors.black12,
                          child: const Center(child: Icon(Icons.broken_image, size: 64)),
                        ),
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // 2. Composition Donut Chart
                  CompositionDonutChart(items: widget.scan.items),
                  const SizedBox(height: 12),
                  // 3. Item Cards
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
                      onAskEcoBot: (selected) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => EcoBotChatScreen(
                              initialItem: selected,
                              sceneSummary: "Scene contains ${widget.scan.items.length} items.",
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => EcoBotChatScreen(
                sceneSummary: "Scene summary: ${widget.scan.items.length} items analyzed.",
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat),
        label: const Text('Ask EcoBot'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}

