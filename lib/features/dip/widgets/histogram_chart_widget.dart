import 'dart:math';
import 'package:flutter/material.dart';
import '../histogram_analyzer.dart';

enum HistogramDisplayMode { luma, rgb }

class HistogramChartWidget extends StatefulWidget {
  final ImageHistogramData data;
  final double height;

  const HistogramChartWidget({
    super.key,
    required this.data,
    this.height = 140,
  });

  @override
  State<HistogramChartWidget> createState() => _HistogramChartWidgetState();
}

class _HistogramChartWidgetState extends State<HistogramChartWidget> {
  HistogramDisplayMode _mode = HistogramDisplayMode.luma;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Channel Selector
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Color & Luma Histogram',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SegmentedButton<HistogramDisplayMode>(
                segments: const [
                  ButtonSegment(
                    value: HistogramDisplayMode.luma,
                    label: Text('Luma', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: HistogramDisplayMode.rgb,
                    label: Text('RGB', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (val) => setState(() => _mode = val.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFF2B303C),
                  selectedBackgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white70,
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Paint Canvas for the Histogram Curves
          SizedBox(
            height: widget.height,
            child: CustomPaint(
              painter: _HistogramPainter(data: widget.data, mode: _mode),
            ),
          ),
          const SizedBox(height: 14),

          // Photometric Descriptors Grid
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildMetric('Mean Luma', widget.data.meanLuma.toStringAsFixed(1)),
              _buildMetric('RMS Contrast', '±${widget.data.rmsContrast.toStringAsFixed(1)}'),
              _buildMetric('Dyn Range', '${widget.data.dynamicRange}'),
              _buildMetric('Entropy', '${widget.data.entropy.toStringAsFixed(2)} bits'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSubMetric(
                'Shadow Clip (<10)',
                '${widget.data.shadowClippingPercent.toStringAsFixed(1)}%',
                widget.data.shadowClippingPercent > 10 ? Colors.orangeAccent : Colors.white70,
              ),
              _buildSubMetric(
                'Highlight Clip (>245)',
                '${widget.data.highlightClippingPercent.toStringAsFixed(1)}%',
                widget.data.highlightClippingPercent > 10 ? Colors.redAccent : Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSubMetric(String label, String value, Color valColor) {
    return Wrap(
      spacing: 4,
      children: [
        Text(
          '$label:',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(color: valColor, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _HistogramPainter extends CustomPainter {
  final ImageHistogramData data;
  final HistogramDisplayMode mode;

  _HistogramPainter({required this.data, required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF13171F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)),
      bgPaint,
    );

    // Grid lines at 25%, 50%, 75%
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final x = size.width * (i / 4.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (mode == HistogramDisplayMode.luma) {
      final maxLuma = data.luma.reduce(max);
      if (maxLuma > 0) {
        _drawChannel(
          canvas,
          size,
          data.luma,
          maxLuma,
          Colors.white70,
          Colors.white.withOpacity(0.2),
        );
      }
    } else {
      final maxR = data.red.reduce(max);
      final maxG = data.green.reduce(max);
      final maxB = data.blue.reduce(max);
      final maxOverall = [maxR, maxG, maxB].reduce(max);

      if (maxOverall > 0) {
        _drawChannel(
          canvas,
          size,
          data.red,
          maxOverall,
          Colors.redAccent,
          Colors.redAccent.withOpacity(0.15),
        );
        _drawChannel(
          canvas,
          size,
          data.green,
          maxOverall,
          Colors.greenAccent,
          Colors.greenAccent.withOpacity(0.15),
        );
        _drawChannel(
          canvas,
          size,
          data.blue,
          maxOverall,
          Colors.blueAccent,
          Colors.blueAccent.withOpacity(0.15),
        );
      }
    }
  }

  void _drawChannel(
    Canvas canvas,
    Size size,
    List<int> channel,
    int maxVal,
    Color strokeColor,
    Color fillColor,
  ) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (int i = 0; i < 256; i++) {
      final x = (i / 255.0) * size.width;
      final norm = channel[i] / maxVal.toDouble();
      final y = size.height - (norm * (size.height - 4));
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(_HistogramPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.mode != mode;
}
