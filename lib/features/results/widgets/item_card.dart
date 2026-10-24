import 'package:flutter/material.dart';
import '../../../core/constants/taxonomy.dart';
import '../../../data/models/detected_item.dart';
import '../../hitl/correction_sheet.dart';
import '../../rules/disposal_rules_service.dart';

class ItemCard extends StatelessWidget {
  final DetectedItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCorrected;
  final Function(DetectedItem) onAskEcoBot;

  const ItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onCorrected,
    required this.onAskEcoBot,
  });

  @override
  Widget build(BuildContext context) {
    final guidance = DisposalRulesService.instance.getGuidance(
      itemClass: item.effectiveClass,
      contaminationLevel: item.contaminationLevel,
      glassColor: item.glassColor,
    );

    final color = Taxonomy.getColor(item.effectiveClass);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  radius: 20,
                  child: Icon(Icons.recycling, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            guidance.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item.isCorrected) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: const Text(
                                'Corrected',
                                style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Confidence: ${(item.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Bin Stream Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(int.parse(guidance.binStream.hexColor.replaceFirst('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    guidance.binStream.name.split('(')[0].trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Contamination & Attributes Badges
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (item.contaminationLevel != null)
                  _buildBadge(
                    item.contaminationLevel == 'heavy'
                        ? 'Contaminated (Heavy)'
                        : item.contaminationLevel == 'light'
                            ? 'Slightly Soiled'
                            : 'Clean',
                    item.contaminationLevel == 'heavy'
                        ? Colors.red
                        : item.contaminationLevel == 'light'
                            ? Colors.orange
                            : Colors.green,
                  ),
                if (item.glassColor != null)
                  _buildBadge('Color: ${item.glassColor}', Colors.teal),
                _buildBadge(
                  guidance.recyclable ? 'Recyclable' : 'Non-Recyclable',
                  guidance.recyclable ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              guidance.prepSteps.isNotEmpty ? guidance.prepSteps.first : guidance.tips,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => CorrectionSheet.show(context, item, onCorrected),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Wrong?'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => onAskEcoBot(item),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Ask EcoBot'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

