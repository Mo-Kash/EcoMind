import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';

class BinStreamInfo {
  final String name;
  final String colorName;
  final String hexColor;
  final String destination;

  BinStreamInfo({
    required this.name,
    required this.colorName,
    required this.hexColor,
    required this.destination,
  });

  factory BinStreamInfo.fromMap(Map<String, dynamic> map) {
    return BinStreamInfo(
      name: map['name'] as String? ?? 'General Stream',
      colorName: map['color_name'] as String? ?? 'Grey',
      hexColor: map['hex_color'] as String? ?? '#757575',
      destination: map['destination'] as String? ?? 'Municipal Facility',
    );
  }
}

class ItemDisposalGuidance {
  final String itemClass;
  final String displayName;
  final String binStreamKey;
  final BinStreamInfo binStream;
  final bool recyclable;
  final bool reusable;
  final List<String> prepSteps;
  final String tips;
  final String? contaminationAdvice;
  final String? colorAttributeNote;

  ItemDisposalGuidance({
    required this.itemClass,
    required this.displayName,
    required this.binStreamKey,
    required this.binStream,
    required this.recyclable,
    required this.reusable,
    required this.prepSteps,
    required this.tips,
    this.contaminationAdvice,
    this.colorAttributeNote,
  });
}

class DisposalRulesService {
  static final DisposalRulesService instance = DisposalRulesService._init();
  DisposalRulesService._init();

  Map<String, dynamic>? _rulesJson;
  Map<String, BinStreamInfo> _streams = {};

  Future<void> initialize() async {
    if (_rulesJson != null) return;
    try {
      final jsonString = await rootBundle.loadString(AppConfig.disposalRulesAssetPath);
      _rulesJson = jsonDecode(jsonString) as Map<String, dynamic>;

      final streamsMap = _rulesJson!['streams'] as Map<String, dynamic>? ?? {};
      _streams = streamsMap.map(
        (key, value) => MapEntry(key, BinStreamInfo.fromMap(value as Map<String, dynamic>)),
      );
    } catch (e) {
      // Default fallback streams if asset load fails
      _streams = {
        'dry_waste': BinStreamInfo(
          name: 'Dry Recyclable (Blue Bin)',
          colorName: 'Blue',
          hexColor: '#1565C0',
          destination: 'Material Recovery Facility',
        ),
        'wet_waste': BinStreamInfo(
          name: 'Wet Compostable (Green Bin)',
          colorName: 'Green',
          hexColor: '#2E7D32',
          destination: 'Composting Facility',
        ),
        'domestic_hazardous': BinStreamInfo(
          name: 'Hazardous (Red Bin)',
          colorName: 'Red',
          hexColor: '#C62828',
          destination: 'Hazardous Collection Point',
        ),
      };
    }
  }

  ItemDisposalGuidance getGuidance({
    required String itemClass,
    String? contaminationLevel,
    String? glassColor,
  }) {
    final rules = _rulesJson?['rules'] as Map<String, dynamic>? ?? {};
    final classRule = rules[itemClass] as Map<String, dynamic>?;

    if (classRule == null) {
      return ItemDisposalGuidance(
        itemClass: itemClass,
        displayName: itemClass,
        binStreamKey: 'general_reject',
        binStream: _streams['general_reject'] ??
            BinStreamInfo(
              name: 'General Reject',
              colorName: 'Black',
              hexColor: '#424242',
              destination: 'Landfill / WTE',
            ),
        recyclable: false,
        reusable: false,
        prepSteps: ['Check local municipality guidance.'],
        tips: 'Segregate at source to protect municipal sanitation workers.',
      );
    }

    String streamKey = classRule['bin_stream'] as String? ?? 'dry_waste';
    bool recyclable = classRule['recyclable'] as bool? ?? false;
    final reusable = classRule['reusable'] as bool? ?? false;
    final List<String> prepSteps = List<String>.from(classRule['prep_steps'] as List? ?? []);
    final tips = classRule['tips'] as String? ?? '';
    String? contaminationAdvice;
    String? colorNote;

    // Check contamination override
    if (contaminationLevel != null && contaminationLevel != 'clean') {
      final ifContam = classRule['if_contamination'] as Map<String, dynamic>?;
      if (ifContam != null && ifContam.containsKey(contaminationLevel)) {
        final override = ifContam[contaminationLevel] as Map<String, dynamic>;
        if (override.containsKey('bin_stream')) {
          streamKey = override['bin_stream'] as String;
        }
        if (override.containsKey('recyclable')) {
          recyclable = override['recyclable'] as bool;
        }
        contaminationAdvice = override['advice'] as String?;
      }
    }

    // Check glass color attribute note
    if (itemClass == 'glass' && glassColor != null) {
      final colorMap = classRule['attributes_by_color'] as Map<String, dynamic>?;
      if (colorMap != null && colorMap.containsKey(glassColor)) {
        colorNote = colorMap[glassColor] as String?;
      }
    }

    final streamInfo = _streams[streamKey] ??
        BinStreamInfo(
          name: 'Dry Recyclables',
          colorName: 'Blue',
          hexColor: '#1565C0',
          destination: 'Recycling Facility',
        );

    return ItemDisposalGuidance(
      itemClass: itemClass,
      displayName: classRule['display_name'] as String? ?? itemClass,
      binStreamKey: streamKey,
      binStream: streamInfo,
      recyclable: recyclable,
      reusable: reusable,
      prepSteps: prepSteps,
      tips: tips,
      contaminationAdvice: contaminationAdvice,
      colorAttributeNote: colorNote,
    );
  }
}

