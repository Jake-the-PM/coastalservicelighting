import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_specs.dart';
import '../../data/repositories/lighting_repository.dart';

class PresetsScreen extends StatelessWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presets & Effects')),
      body: SafeArea(
        child: Column(
          children: [
            // Global Dimmer (Invariant: Always Visible)
            _buildStickyDimmer(context),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader(context, 'Favorites'),
                  _buildPresetItem(context, 'Warm White', 1, Colors.orangeAccent),
                  _buildPresetItem(context, 'Party Mode', 2, Colors.purpleAccent),
                  _buildPresetItem(context, 'Soft Night', 3, Colors.indigoAccent),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'Categories'),
                  _buildCategoryTile(context, 'Solid Colors', Icons.color_lens),
                  _buildCategoryTile(context, 'Dynamic Effects', Icons.auto_awesome),
                  _buildCategoryTile(context, 'Playlists', Icons.format_list_bulleted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyDimmer(BuildContext context) {
    final repo = context.watch<LightingRepository>();
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.brightness_medium, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Slider(
              value: repo.globalBrightness.toDouble(),
              min: 0,
              max: 255,
              onChanged: (val) => repo.setGlobalBrightness(val.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title, 
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
      ),
    );
  }

  Widget _buildPresetItem(BuildContext context, String label, int presetId, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, radius: 12),
        title: Text(label),
        trailing: const Icon(Icons.play_arrow_rounded),
        onTap: () {
          // Apply Preset (Default to ALL zones for simple browser)
          context.read<LightingRepository>().applyPreset(presetId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Applied $label'), duration: const Duration(milliseconds: 500)),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00BFA6)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to detail list (Placeholder)
      },
    );
  }
}
