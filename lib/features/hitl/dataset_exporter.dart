import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/local/app_database.dart';

class DatasetExporter {
  /// Exports all locally recorded corrections and crops into a retrainable ZIP dataset.
  static Future<String?> exportCorrectionDataset() async {
    final db = await AppDatabase.instance.database;
    final corrections = await db.rawQuery('''
      SELECT c.*, i.cropImagePath, i.maskImagePath, i.box_left, i.box_top, i.box_right, i.box_bottom
      FROM corrections c
      JOIN items i ON c.itemId = i.id
    ''');

    if (corrections.isEmpty) {
      return null;
    }

    final archive = Archive();

    // 1. Build manifest.csv
    final csvRows = <String>['item_id,scan_id,original_class,corrected_class,detector_score,timestamp'];
    
    // 2. Build annotations.json (COCO format)
    final cocoImages = <Map<String, dynamic>>[];
    final cocoAnnotations = <Map<String, dynamic>>[];

    int imageId = 1;
    for (final row in corrections) {
      final itemId = row['itemId'] as String;
      final scanId = row['scanId'] as String;
      final origClass = row['originalClass'] as String;
      final corrClass = row['correctedClass'] as String;
      final score = row['detectorScore'] ?? 1.0;
      final ts = row['timestamp'] as String;

      csvRows.add('$itemId,$scanId,$origClass,$corrClass,$score,$ts');

      // Include crop image file if available
      final cropPath = row['cropImagePath'] as String?;
      if (cropPath != null && File(cropPath).existsSync()) {
        final imageBytes = await File(cropPath).readAsBytes();
        final internalPath = 'dataset/$corrClass/$itemId.png';
        archive.addFile(ArchiveFile(internalPath, imageBytes.length, imageBytes));

        cocoImages.add({
          'id': imageId,
          'file_name': internalPath,
          'width': 224,
          'height': 224,
        });

        cocoAnnotations.add({
          'id': imageId,
          'image_id': imageId,
          'category_id': corrClass,
          'score': score,
          'bbox': [
            row['box_left'],
            row['box_top'],
            (row['box_right'] as num) - (row['box_left'] as num),
            (row['box_bottom'] as num) - (row['box_top'] as num),
          ],
        });
        imageId++;
      }
    }

    // Add manifest.csv to archive
    final csvBytes = utf8.encode(csvRows.join('\n'));
    archive.addFile(ArchiveFile('manifest.csv', csvBytes.length, csvBytes));

    // Add annotations.json to archive
    final cocoJson = jsonEncode({
      'images': cocoImages,
      'annotations': cocoAnnotations,
    });
    final cocoBytes = utf8.encode(cocoJson);
    archive.addFile(ArchiveFile('annotations.json', cocoBytes.length, cocoBytes));

    // Compress archive to ZIP
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    if (zipBytes.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/ecomind_dataset_export_${DateTime.now().millisecondsSinceEpoch}.zip';
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipBytes);

    // Share through system share sheet
    await Share.shareXFiles([XFile(zipPath)], text: 'EcoMind 2.0 Retraining Dataset');
    return zipPath;
  }
}

