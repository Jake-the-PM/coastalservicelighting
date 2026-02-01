import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/lighting_repository.dart';
import '../widgets/liquid_container.dart';
import '../widgets/spectrum_picker.dart';
import '../widgets/effect_preview.dart';
import 'palette_browser.dart';

class ZoneDetailSheet extends StatefulWidget {
  final String controllerIp;
  final int zoneId;
  final String label;
  final bool isDialog;

  const ZoneDetailSheet({
    super.key,
    required this.controllerIp,
    required this.zoneId,
    required this.label,
    this.isDialog = false,
  });

  @override
  State<ZoneDetailSheet> createState() => _ZoneDetailSheetState();
}

class _ZoneDetailSheetState extends State<ZoneDetailSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Local state for UI feedback
  Color _currentColor = Colors.white;
  int _currentEffectId = 0;
  int _currentPaletteId = 0;
  double _speed = 128;
  double _intensity = 128;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Defer state init to access provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialState();
    });
  }
  
  void _loadInitialState() {
    final repo = context.read<LightingRepository>();
    final segment = repo.getSegment(widget.controllerIp, widget.zoneId);

    if (segment != null) {
      setState(() {
        // Hydrate Color
        if (segment.colors.isNotEmpty && segment.colors[0].length >= 3) {
          _currentColor = Color.fromARGB(
            255, 
            segment.colors[0][0], 
            segment.colors[0][1], 
            segment.colors[0][2]
          );
        }

        // Hydrate FX/Palette
        _currentEffectId = segment.effectId;
        _currentPaletteId = segment.paletteId;
        _speed = segment.speed.toDouble();
        _intensity = segment.intensity.toDouble();

        // Smart Tab Selection
        if (_currentEffectId > 0 && _tabController.length >= 2) {
          _tabController.animateTo(1); // Go to FX tab if FX is active
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<LightingRepository>();
    final size = MediaQuery.of(context).size;
    
    // Dialog mode sizing vs Sheet mode sizing
    final height = widget.isDialog 
        ? 700.0 // Fixed max height for dialog
        : size.height * 0.85;

    // Constrain height if in dialog to fit screen
    final effectiveHeight = widget.isDialog 
        ? (height > size.height - 80 ? size.height - 80 : height) 
        : height;

    return Container(
      height: effectiveHeight,
      width: widget.isDialog ? 500 : double.infinity, // Constrain width in dialog
      decoration: BoxDecoration(
        color: const Color(0xFF050E1C).withOpacity(0.95), // Deep Navy Glass
        borderRadius: widget.isDialog 
            ? BorderRadius.circular(24) // All corners for dialog
            : const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            spreadRadius: 10,
          )
        ]
      ),
      child: SafeArea(
        top: false, // Handle is fine at top, bottom needs protection
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Icon(Icons.tune, color: const Color(0xFFD4AF37), size: 28),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          letterSpacing: 2.0,
                          color: Colors.white54,
                        ),
                      ),
                      Text(
                        "Pro Control",
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  )
                ],
              ),
            ),
            
            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "COLOR"),
                    Tab(text: "EFFECT"),
                    Tab(text: "PALETTE"),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. COLOR TAB
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        SpectrumPicker(
                          currentColor: _currentColor,
                          size: 300,
                          onChanged: (color) {
                            setState(() => _currentColor = color);
                            repo.setZoneColor(widget.controllerIp, widget.zoneId, [color.red, color.green, color.blue]);
                          },
                        ),
                        const SizedBox(height: 40),
                        // Swatches
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSwatch(Colors.white, repo),
                              _buildSwatch(const Color(0xFFD4AF37), repo), // Gold
                              _buildSwatch(const Color(0xFF0077BE), repo), // Blue
                              _buildSwatch(const Color(0xFF20B2AA), repo), // Teal
                              _buildSwatch(Colors.red, repo),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80), // Bottom padding
                      ],
                    ),
                  ),
                  
                  // 2. EFFECT TAB
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Sliders
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                               _buildSlider("Speed", _speed, (val) {
                                 setState(() => _speed = val);
                                 repo.setZoneSpeed(widget.controllerIp, widget.zoneId, val.toInt());
                               }),
                               const SizedBox(height: 16),
                               _buildSlider("Intensity", _intensity, (val) {
                                 setState(() => _intensity = val);
                                 repo.setZoneIntensity(widget.controllerIp, widget.zoneId, val.toInt());
                               }),
                            ],
                          ),
                        ),
                        // List (Constrained height inside scrollview)
                        Builder(
                          builder: (context) {
                            final dynamicEffects = repo.getEffects(widget.controllerIp);
                            final effectsList = dynamicEffects.isNotEmpty 
                                ? dynamicEffects 
                                : _knownEffects.map((e) => e['name'] as String).toList();
                            
                            if (effectsList.isEmpty) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));

                            return ListView.builder(
                              shrinkWrap: true, // Crucial for nesting inside SingleChildScrollView
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: effectsList.length,
                              itemBuilder: (context, index) {
                                final name = effectsList[index];
                                // Map WLED IDs correctly (index is usually ID for WLED standard lists)
                                final id = index; 
                                final isSelected = _currentEffectId == id;
                                
                                // Icon Lookup
                                IconData icon = Icons.blur_on;
                                final known = _knownEffects.firstWhere(
                                  (e) => (e['name'] as String).toLowerCase() == name.toLowerCase(),
                                  orElse: () => {'icon': Icons.auto_fix_high},
                                );
                                icon = known['icon'] as IconData;

                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _currentEffectId = id);
                                      repo.setZoneEffect(widget.controllerIp, widget.zoneId, id);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.white.withOpacity(0.05),
                                        border: isSelected 
                                            ? Border.all(color: const Color(0xFFD4AF37), width: 1.5)
                                            : Border.all(color: Colors.transparent),
                                      ),
                                      child: Row(
                                        children: [
                                          // Icon
                                          Icon(icon, color: isSelected ? const Color(0xFFD4AF37) : Colors.white54, size: 20),
                                          const SizedBox(width: 12),
                                          
                                          // Name & Preview
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name, 
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white, 
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500
                                                  )
                                                ),
                                                const SizedBox(height: 8),
                                                // Simulated Preview
                                                EffectPreview(effectName: name, isSelected: isSelected),
                                              ],
                                            ),
                                          ),
                                          
                                          // Checkmark
                                          if (isSelected) 
                                            const Padding(
                                              padding: EdgeInsets.only(left: 12),
                                              child: Icon(Icons.check, color: Color(0xFFD4AF37), size: 18),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                  
                  // 3. PALETTE TAB
                  repo.getPalettes(widget.controllerIp).isNotEmpty 
                    ? PaletteBrowser(
                        currentPaletteId: _currentPaletteId,
                        palettes: repo.getPalettes(widget.controllerIp), // Need to update PaletteBrowser to accept list
                        onSelected: (id) {
                           setState(() => _currentPaletteId = id);
                           repo.setZonePalette(widget.controllerIp, widget.zoneId, id);
                        },
                      )
                    : const Center(child: CircularProgressIndicator()), // Or empty state
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwatch(Color color, LightingRepository repo) {
    return GestureDetector(
      onTap: () {
        setState(() => _currentColor = color);
        repo.setZoneColor(widget.controllerIp, widget.zoneId, [color.red, color.green, color.blue]);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white70)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFD4AF37),
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: value,
            min: 0, 
            max: 255,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
  
  // Curated Effect List (for Icon Mapping & Offline Fallback)
  final List<Map<String, dynamic>> _knownEffects = [
    {'id': 0, 'name': 'Solid', 'icon': Icons.circle},
    {'id': 1, 'name': 'Breathe', 'icon': Icons.air},
    {'id': 2, 'name': 'Rainbow', 'icon': Icons.palette},
    {'id': 3, 'name': 'Color Loop', 'icon': Icons.loop},
    {'id': 4, 'name': 'Scan', 'icon': Icons.radar},
    {'id': 5, 'name': 'Dual Scan', 'icon': Icons.sensors},
    {'id': 8, 'name': 'Running', 'icon': Icons.directions_run},
    {'id': 9, 'name': 'Saw', 'icon': Icons.show_chart},
    {'id': 12, 'name': 'Dissolve', 'icon': Icons.blur_on},
    {'id': 15, 'name': 'Sparkle', 'icon': Icons.auto_awesome},
    {'id': 18, 'name': 'Meteor', 'icon': Icons.whatshot},
    {'id': 20, 'name': 'Ripple', 'icon': Icons.water},
    {'id': 28, 'name': 'Chase', 'icon': Icons.arrow_forward},
    {'id': 33, 'name': 'Pacifica', 'icon': Icons.waves},
    {'id': 41, 'name': 'Lighthouse', 'icon': Icons.lightbulb},
    {'id': 44, 'name': 'Tetrix', 'icon': Icons.games},
    {'id': 55, 'name': 'Fire Flicker', 'icon': Icons.local_fire_department},
    {'id': 65, 'name': 'Oscillate', 'icon': Icons.wifi_tethering},
    {'id': 70, 'name': 'Pride', 'icon': Icons.flag},
    {'id': 100, 'name': 'Plasma', 'icon': Icons.science},
  ];
}
