import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/lighting_repository.dart';
import '../../core/constants/app_specs.dart';
import 'final_setup_screen.dart';

class ZoneMappingScreen extends StatefulWidget {
  final bool isCommissioning;
  const ZoneMappingScreen({super.key, this.isCommissioning = false});

  @override
  State<ZoneMappingScreen> createState() => _ZoneMappingScreenState();
}

class _ZoneMappingScreenState extends State<ZoneMappingScreen> {
  // Local state for the configuration form
  final List<TextEditingController> _countControllers = [];
  final List<bool> _securityToggles = [];
  bool _isFlashing = false;
  int _totalLeds = 100; // Default fallback

  @override
  void initState() {
    super.initState();
    // Initialize default state matching AppSpecs.zoneCount (3)
    for (int i = 0; i < AppSpecs.zoneCount; i++) {
      _countControllers.add(TextEditingController(text: "50"));
      _securityToggles.add(true);
    }
    
    // Defer reading repo until build or after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<LightingRepository>();
      if (repo.controllers.isNotEmpty) {
        final ip = repo.controllers.keys.first;
        final info = repo.getInfo(ip);
         setState(() {
           _totalLeds = info?.ledCount ?? 150;
           
           // Try to load existing counts if we can guess them
           // (This is tricky if they are already segmented, but for V1 we start fresh-ish)
           // Distribute evenly for start
           final evenSplit = (_totalLeds / AppSpecs.zoneCount).floor();
           for (var c in _countControllers) {
             c.text = evenSplit.toString();
           }
         });
      }
    });
  }

  @override
  void dispose() {
    for (var c in _countControllers) dispose();
    super.dispose();
  }

  Future<void> _flashZone(int index) async {
    if (_isFlashing) return;
    setState(() => _isFlashing = true);

    try {
      final repo = context.read<LightingRepository>();
      if (repo.controllers.isNotEmpty) {
        final ip = repo.controllers.keys.first;
        await repo.flashZone(ip, index + 1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Identification failed: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isFlashing = false);
  }

  Future<void> _saveAndApply() async {
    final repo = context.read<LightingRepository>();
    if (repo.controllers.isEmpty) return;
    final ip = repo.controllers.keys.first;
    
    final counts = _countControllers.map((c) => int.tryParse(c.text) ?? 0).toList();
    final configTotal = counts.fold(0, (sum, c) => sum + c);
    
    if (configTotal > _totalLeds) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Total LEDs ($configTotal) exceeds strip length ($_totalLeds)!')),
      );
      return;
    }

    await repo.configureZoneCounts(ip, counts);
    
    // The repo now manages SyncStatus. If successful, we proceed.
    if (repo.syncStatus == SyncStatus.success) {
      for (int i = 0; i < _securityToggles.length; i++) {
        await repo.toggleSecurityZone(ip, i + 1, _securityToggles[i]);
      }

      if (mounted) {
        if (widget.isCommissioning) {
          Navigator.of(context).pop(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hardware Configured Successfully'), backgroundColor: Colors.green),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FinalSetupScreen()),
          );
        }
      }
    } else if (repo.syncStatus == SyncStatus.error) {
       if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text("HARDWARE SYNC FAILURE", style: TextStyle(color: Colors.red)),
              content: Text(repo.lastSyncError ?? "Unknown error verifying hardware segments.", style: const TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("ADJUST SETTINGS"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _saveAndApply();
                  },
                  child: const Text("RETRY SYNC"),
                ),
              ],
            ),
          );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate remaining LEDs dynamically
    int used = 0;
    for (var c in _countControllers) {
      used += int.tryParse(c.text) ?? 0;
    }
    int remaining = _totalLeds - used;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("Configure Zones", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Header Info
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF102847),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text("Total LEDs", style: GoogleFonts.outfit(color: Colors.white54)),
                             Text("$_totalLeds", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                           ],
                         ),
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.end,
                           children: [
                             Text("Available", style: GoogleFonts.outfit(color: remaining < 0 ? Colors.red : Colors.green)),
                             Text("$remaining", style: GoogleFonts.outfit(
                               color: remaining < 0 ? Colors.red : Colors.greenAccent, 
                               fontSize: 20, 
                               fontWeight: FontWeight.bold
                             )),
                           ],
                         ),
                      ],
                    ),
                  ),
                ),
                
                // Zone List
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            color: const Color(0xFF1C3A63).withOpacity(0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFFD4AF37),
                                        radius: 12,
                                        child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Text("Zone ${index + 1}", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18)),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.flash_on, color: Colors.amber),
                                        onPressed: _isFlashing ? null : () => _flashZone(index),
                                        tooltip: "Identify Zone",
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white10),
                                  
                                  // Settings Row
                                  Row(
                                    children: [
                                      // LED Count Input
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("LED Count", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                                            const SizedBox(height: 4),
                                            TextField(
                                              controller: _countControllers[index],
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.black26,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                              ),
                                              onChanged: (_) => setState(() {}), // Trigger recalc
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Security Toggle
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                             Text("Security Mode", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                                             Switch(
                                               value: _securityToggles[index],
                                               activeColor: const Color(0xFF00BFA6),
                                               onChanged: (val) => setState(() => _securityToggles[index] = val),
                                             ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: AppSpecs.zoneCount,
                    ),
                  ),
                ),
                
                // Security Alert Color Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCF6679).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCF6679).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFCF6679)),
                            const SizedBox(width: 12),
                            Text("Global Security Alert Color", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Preview
                        Container(
                          height: 40,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(
                              context.watch<LightingRepository>().securityColor[0],
                              context.watch<LightingRepository>().securityColor[1],
                              context.watch<LightingRepository>().securityColor[2],
                              1.0
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text("ALERT PREVIEW", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, shadows: [const Shadow(blurRadius: 2, color: Colors.black)])),
                        ),
                        const SizedBox(height: 16),
                        _ColorSlider(
                          label: "R", 
                          value: context.watch<LightingRepository>().securityColor[0], 
                          activeColor: Colors.red,
                          onChanged: (v) {
                             final current = context.read<LightingRepository>().securityColor;
                             context.read<LightingRepository>().setSecurityColor([v.toInt(), current[1], current[2]]);
                          }
                        ),
                        _ColorSlider(
                          label: "G", 
                          value: context.watch<LightingRepository>().securityColor[1], 
                          activeColor: Colors.green,
                          onChanged: (v) {
                             final current = context.read<LightingRepository>().securityColor;
                             context.read<LightingRepository>().setSecurityColor([current[0], v.toInt(), current[2]]);
                          }
                        ),
                        _ColorSlider(
                          label: "B", 
                          value: context.watch<LightingRepository>().securityColor[2], 
                          activeColor: Colors.blue,
                          onChanged: (v) {
                             final current = context.read<LightingRepository>().securityColor;
                             context.read<LightingRepository>().setSecurityColor([current[0], current[1], v.toInt()]);
                          }
                        ),
                      ],
                    ),
                  ),
                ),
    
                // Footer Action
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton.icon(
                      onPressed: (remaining < 0 || context.watch<LightingRepository>().syncStatus == SyncStatus.syncing) ? null : _saveAndApply,
                      icon: const Icon(Icons.save_alt),
                      label: Text(context.watch<LightingRepository>().syncStatus == SyncStatus.syncing ? "SYNCING..." : "APPLY TO CONTROLLER"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Syncing Overlay
            if (context.watch<LightingRepository>().syncStatus == SyncStatus.syncing)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                      const SizedBox(height: 16),
                      Text("Verifying Hardware Sync...", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("Performing atomic verification loop...", style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _ColorSlider({
    super.key,
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.outfit(color: activeColor, fontWeight: FontWeight.bold)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 255,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text("$value", style: GoogleFonts.outfit(color: Colors.white70), textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
