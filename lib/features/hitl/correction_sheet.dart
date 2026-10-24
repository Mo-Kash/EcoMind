import 'package:flutter/material.dart';
import '../../core/constants/taxonomy.dart';
import '../../data/local/app_database.dart';
import '../../data/models/detected_item.dart';

class CorrectionSheet extends StatelessWidget {
  final DetectedItem item;
  final VoidCallback onCorrected;

  const CorrectionSheet({
    super.key,
    required this.item,
    required this.onCorrected,
  });

  static void show(BuildContext context, DetectedItem item, VoidCallback onCorrected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CorrectionSheet(item: item, onCorrected: onCorrected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      ...Taxonomy.classes,
      'not_waste',
      'bad_detection',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Correct Classification',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current Prediction: ${Taxonomy.getDisplayName(item.predictedClass)} (${(item.confidence * 100).toStringAsFixed(0)}%)',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const Divider(height: 24),
          const Text(
            'Select the actual material:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (ctx, index) {
                final opt = options[index];
                String title;
                IconData icon;
                Color color;

                if (opt == 'not_waste') {
                  title = 'Not Waste / Keep Item';
                  icon = Icons.block;
                  color = Colors.red;
                } else if (opt == 'bad_detection') {
                  title = 'Bad Detection / Ghost Box';
                  icon = Icons.cancel;
                  color = Colors.orange;
                } else {
                  title = Taxonomy.getDisplayName(opt);
                  icon = Icons.recycling;
                  color = Taxonomy.getColor(opt);
                }

                final isCurrent = item.effectiveClass == opt;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                  trailing: isCurrent ? const Icon(Icons.check, color: Colors.green) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onTap: () async {
                    await AppDatabase.instance.recordCorrection(
                      itemId: item.id,
                      scanId: item.scanId,
                      originalClass: item.predictedClass,
                      correctedClass: opt,
                      detectorScore: item.detectorScore,
                    );
                    item.correctedClass = opt;
                    Navigator.pop(context);
                    onCorrected();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

