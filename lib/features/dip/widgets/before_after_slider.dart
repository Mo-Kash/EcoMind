import 'dart:io';
import 'package:flutter/material.dart';

/// An interactive split-view widget that allows users to drag a divider
/// to compare "Before" (left) and "After" (right) images.
class BeforeAfterSlider extends StatefulWidget {
  final Widget beforeWidget;
  final Widget afterWidget;
  final String beforeLabel;
  final String afterLabel;
  final double initialPosition; // 0.0 - 1.0 (default 0.5)

  const BeforeAfterSlider({
    super.key,
    required this.beforeWidget,
    required this.afterWidget,
    this.beforeLabel = 'ORIGINAL',
    this.afterLabel = 'ENHANCED',
    this.initialPosition = 0.5,
  });

  factory BeforeAfterSlider.files({
    Key? key,
    required File beforeFile,
    required File afterFile,
    String beforeLabel = 'ORIGINAL',
    String afterLabel = 'ENHANCED',
    double initialPosition = 0.5,
    BoxFit fit = BoxFit.cover,
  }) {
    return BeforeAfterSlider(
      key: key,
      beforeWidget: Image.file(beforeFile, fit: fit),
      afterWidget: Image.file(afterFile, fit: fit),
      beforeLabel: beforeLabel,
      afterLabel: afterLabel,
      initialPosition: initialPosition,
    );
  }

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  late double _dividerPosition;

  @override
  void initState() {
    super.initState();
    _dividerPosition = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final splitX = width * _dividerPosition;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dividerPosition = (details.localPosition.dx / width).clamp(0.02, 0.98);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Right / After Image (Full background)
              widget.afterWidget,

              // 2. Left / Before Image (Clipped to splitX)
              ClipRect(
                clipper: _HorizontalSplitClipper(splitX: splitX),
                child: widget.beforeWidget,
              ),

              // 3. Divider Line & Handle
              Positioned(
                left: splitX - 1.5,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: Colors.white,
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.swap_horiz,
                        size: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Floating Labels
              Positioned(
                left: 12,
                top: 12,
                child: _buildLabel(widget.beforeLabel, Colors.black54),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: _buildLabel(widget.afterLabel, Colors.green.shade800),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
          )
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _HorizontalSplitClipper extends CustomClipper<Rect> {
  final double splitX;

  _HorizontalSplitClipper({required this.splitX});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, splitX, size.height);
  }

  @override
  bool shouldReclip(_HorizontalSplitClipper oldClipper) => oldClipper.splitX != splitX;
}
