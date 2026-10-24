import 'package:flutter/material.dart';

/// EcoMind 2.0 9-class material taxonomy.
class Taxonomy {
  static const String cardboard = 'cardboard';
  static const String paper = 'paper';
  static const String plastic = 'plastic';
  static const String glass = 'glass';
  static const String metal = 'metal';
  static const String organic = 'organic';
  static const String batteryEwaste = 'battery_ewaste';
  static const String textile = 'textile';
  static const String generalTrash = 'general_trash';

  static const List<String> classes = [
    cardboard,
    paper,
    plastic,
    glass,
    metal,
    organic,
    batteryEwaste,
    textile,
    generalTrash,
  ];

  static const Map<String, String> displayNames = {
    cardboard: 'Cardboard',
    paper: 'Paper',
    plastic: 'Plastic',
    glass: 'Glass',
    metal: 'Metal',
    organic: 'Organic / Food',
    batteryEwaste: 'Battery / E-Waste',
    textile: 'Textile / Clothes',
    generalTrash: 'General Trash',
  };

  /// Color-blind safe palette (Wong / Okabe-Ito inspired) with high distinctness
  static const Map<String, Color> classColors = {
    cardboard: Color(0xFFD55E00),     // Vermillion / Orange-brown
    paper: Color(0xFFF0E442),         // Soft Yellow
    plastic: Color(0xFF0072B2),       // Sky Blue
    glass: Color(0xFF009E73),         // Bluish Green
    metal: Color(0xFFCC79A7),         // Reddish Purple
    organic: Color(0xFF228B22),       // Forest Green
    batteryEwaste: Color(0xFFD32F2F), // Bright Red
    textile: Color(0xFF56B4E9),       // Light Cyan
    generalTrash: Color(0xFF757575),  // Neutral Gray
  };

  static Color getColor(String className) {
    return classColors[className] ?? const Color(0xFF9E9E9E);
  }

  static String getDisplayName(String className) {
    return displayNames[className] ?? className;
  }
}

