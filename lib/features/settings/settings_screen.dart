import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../data/local/app_database.dart';
import '../hitl/dataset_exporter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoEnhancement = true;
  bool _enableTTA = true;
  Map<String, dynamic> _stats = {};
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key') ?? AppConfig.defaultGeminiApiKey;
    _apiKeyController.text = savedKey;
  }

  Future<void> _saveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API key updated successfully!')),
      );
    }
  }

  Future<void> _loadStats() async {
    final s = await AppDatabase.instance.getStatistics();
    setState(() => _stats = s);
  }

  Future<void> _exportDataset() async {
    final path = await DatasetExporter.exportCorrectionDataset();
    if (mounted) {
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dataset exported and shared successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No corrections recorded yet to export.')),
        );
      }
    }
  }

  Future<void> _wipeData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Stored Data?'),
        content: const Text(
          'This will permanently delete all scan history, crop images, and corrections from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppDatabase.instance.clearAllData();
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All local data wiped.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Regional Profile
          _buildSectionHeader('Regional Waste System'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const ListTile(
              leading: Icon(Icons.location_on, color: Colors.green),
              title: Text('India SWM 3-Stream System'),
              subtitle: Text('Wet (Green) · Dry Recyclable (Blue) · Hazardous (Red/Black)'),
            ),
          ),
          const SizedBox(height: 16),

          // Processing Toggles
          _buildSectionHeader('Image Processing & ML'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('DIP Auto-Enhancement'),
                  subtitle: const Text('Applies white balance, CLAHE, and gamma in isolate'),
                  value: _autoEnhancement,
                  onChanged: (v) => setState(() => _autoEnhancement = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Test-Time Augmentation (TTA)'),
                  subtitle: const Text('Averages flip predictions for higher accuracy'),
                  value: _enableTTA,
                  onChanged: (v) => setState(() => _enableTTA = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // EcoBot & Gemini Cloud Inference
          _buildSectionHeader('EcoBot AI Configuration'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gemini API Key',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Required for live cloud responses with Gemini 1.5 Flash. If blank, EcoBot automatically falls back to offline municipal rules.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'AIzaSy...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _saveApiKey,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      child: const Text('Save Key'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // HITL & Data Management
          _buildSectionHeader('Human-in-the-Loop & Privacy'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('Total Scans', '${_stats['totalScans'] ?? 0}'),
                      _buildStatItem('Items Analyzed', '${_stats['totalItems'] ?? 0}'),
                      _buildStatItem('Corrections', '${_stats['totalCorrections'] ?? 0}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _exportDataset,
                    icon: const Icon(Icons.share),
                    label: const Text('Export Retraining Dataset (ZIP)'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _wipeData,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Delete All Local Data', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Attributions & Licenses
          _buildSectionHeader('Attributions & Open Source'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.gavel),
                  title: const Text('Open Source Licences'),
                  subtitle: const Text('Ultralytics (AGPL-3.0), TensorFlow, Flutter'),
                  onTap: () => showLicensePage(context: context),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.dataset),
                  title: Text('Datasets Used'),
                  subtitle: Text('TACO (Trash Annotations in Context), TrashNet, Kaggle Garbage Classification'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

