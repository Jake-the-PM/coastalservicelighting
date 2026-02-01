import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/lighting_repository.dart';
import 'spatial_mapping_screen.dart';

class InstallerProvisioningScreen extends StatefulWidget {
  final String controllerIp;

  const InstallerProvisioningScreen({super.key, required this.controllerIp});

  @override
  State<InstallerProvisioningScreen> createState() => _InstallerProvisioningScreenState();
}

class _InstallerProvisioningScreenState extends State<InstallerProvisioningScreen> {
  // Config State
  final List<Map<String, dynamic>> _configs = [
    {'name': 'Zone 1', 'count': 50, 'color': [255, 255, 255]},
  ];
  
  bool _isFlashing = false;

  int get _totalLeds => _configs.fold(0, (sum, item) => sum + (item['count'] as int));

  void _addZone() {
    setState(() {
      _configs.add({
        'name': 'Zone ${_configs.length + 1}',
        'count': 20, // Default chunk
        'color': [0, 0, 255] // Default Blue to contrast
      });
    });
  }

  void _removeZone(int index) {
    if (_configs.length <= 1) return;
    setState(() {
      _configs.removeAt(index);
    });
  }

  Future<void> _flashConfiguration() async {
    setState(() => _isFlashing = true);
    
    final repo = context.read<LightingRepository>();
    await repo.applyGranularConfig(widget.controllerIp, _configs);
    
    if (mounted) {
      setState(() => _isFlashing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Configuration Glinted to Cloud & Device", style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFFD4AF37),
        )
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("ZONE CONFIGURATION", style: GoogleFonts.outfit(color: Colors.white, letterSpacing: 1.2)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Strip Visualization
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  height: 60,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: _configs.map((config) {
                        final count = config['count'] as int;
                        final colorList = config['color'] as List<int>;
                        final color = Color.fromARGB(255, colorList[0], colorList[1], colorList[2]);
                        
                        return Expanded(
                          flex: count,
                          child: Container(
                            color: color,
                            child: Center(
                              child: Text(
                                "$count", 
                                style: GoogleFonts.outfit(
                                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10
                                )
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Simulated Strip View", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                      Text("Total LEDs: $_totalLeds", style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // 2. Zone List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final config = _configs[index];
                  return Dismissible(
                    key: ValueKey(config),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _removeZone(index),
                    background: Container(
                      alignment: Alignment.centerRight,
                      color: Colors.red.withOpacity(0.2),
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4, 
                            height: 40, 
                            color: Color.fromARGB(255, (config['color'][0] as int), (config['color'][1] as int), (config['color'][2] as int))
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ZONE ${index + 1}", style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, letterSpacing: 1.5)),
                                TextFormField(
                                  initialValue: config['name'],
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: "Enter Name",
                                    hintStyle: TextStyle(color: Colors.white24),
                                  ),
                                  onChanged: (val) => _configs[index]['name'] = val,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextFormField(
                              initialValue: (config['count'] as int).toString(),
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                final c = int.tryParse(val);
                                if (c != null && c > 0) {
                                  setState(() => _configs[index]['count'] = c);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _configs.length,
              ),
            ),
          ),

          // 3. Actions (Scrollable Footer)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _addZone,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text("ADD ZONE SPLIT", style: GoogleFonts.outfit(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => SpatialMappingScreen(controllerIp: widget.controllerIp)));
                    },
                    icon: const Icon(Icons.map, color: Colors.white54),
                    label: Text("OPEN VISUAL MAPPER", style: GoogleFonts.outfit(color: Colors.white54)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isFlashing ? null : _flashConfiguration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: _isFlashing ? 0 : 8,
                      shadowColor: const Color(0xFFD4AF37).withOpacity(0.4),
                    ),
                    child: _isFlashing 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            "FLASH CONFIGURATION", 
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                          ),
                  ),
                  const SizedBox(height: 40), // Bottom Safe Area
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
