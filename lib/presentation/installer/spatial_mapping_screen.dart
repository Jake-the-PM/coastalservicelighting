import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/lighting_repository.dart';

class SpatialMappingScreen extends StatefulWidget {
  final String controllerIp;

  const SpatialMappingScreen({super.key, required this.controllerIp});

  @override
  State<SpatialMappingScreen> createState() => _SpatialMappingScreenState();
}

class _SpatialMappingScreenState extends State<SpatialMappingScreen> {
  // Mock Background - In real app, use ImagePicker
  final String _houseImage = "https://images.unsplash.com/photo-1518780664697-55e3ad937233?q=80&w=1000&auto=format&fit=crop";
  
  // State
  List<Offset> _activePoints = [];
  List<Map<String, dynamic>> _definedZones = []; // {points: [offsets], count: 20, name: 'Zone 1'}
  
  bool _isDrawing = true;

  void _handleTap(TapUpDetails details) {
    if (!_isDrawing) return;

    // Convert local tap to logic
    // Note: With InteractiveViewer, we need careful mapping, 
    // for MVP we assume fixed scale or handle details.localPosition relative to child.
    setState(() {
      _activePoints.add(details.localPosition);
    });
  }

  void _completeSegment() {
    if (_activePoints.length < 2) return;

    // Pop dialog to configure this segment
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Configure Segment", style: GoogleFonts.outfit(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: "Zone Name", hintText: "e.g. Roof Line"),
              style: GoogleFonts.outfit(color: Colors.white),
              onChanged: (val) => _tempName = val,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: "LED Count", hintText: "e.g. 50"),
              style: GoogleFonts.outfit(color: Colors.white),
              keyboardType: TextInputType.number,
              onChanged: (val) => _tempCount = int.tryParse(val) ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () {
              if (_tempCount > 0) {
                setState(() {
                  _definedZones.add({
                    'points': List<Offset>.from(_activePoints),
                    'count': _tempCount,
                    'name': _tempName.isEmpty ? "Zone ${_definedZones.length + 1}" : _tempName,
                    'color': Colors.primaries[_definedZones.length % Colors.primaries.length],
                  });
                  _activePoints.clear();
                });
                Navigator.pop(ctx);
              }
            }, 
            child: const Text("Save Zone", style: TextStyle(color: Colors.black))
          )
        ],
      )
    );
  }
  
  String _tempName = "";
  int _tempCount = 0;

  Future<void> _flashConfig() async {
    // Convert to Repo Config format
    final configs = _definedZones.map((z) => {
      'name': z['name'],
      'count': z['count'],
      'color': [
        (z['color'] as Color).r.toInt(),
        (z['color'] as Color).g.toInt(),
        (z['color'] as Color).b.toInt(),
      ]
    }).toList();

    await context.read<LightingRepository>().applyGranularConfig(widget.controllerIp, configs);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visual Map Flashed to Controller!"), backgroundColor: Color(0xFFD4AF37))
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("SPATIAL MAPPER", style: GoogleFonts.outfit(letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
            onPressed: _definedZones.isEmpty ? null : _flashConfig,
          )
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolBtn(
                  icon: Icons.edit, 
                  label: "Draw", 
                  isActive: _isDrawing, 
                  onTap: () => setState(() => _isDrawing = true)
                ),
                _ToolBtn(
                  icon: Icons.undo, 
                  label: "Undo", 
                  isActive: false, 
                  onTap: () {
                    if (_activePoints.isNotEmpty) setState(() => _activePoints.removeLast());
                  }
                ),
                ElevatedButton.icon(
                  onPressed: _activePoints.length >= 2 ? _completeSegment : null,
                  icon: const Icon(Icons.add_link, color: Colors.black),
                  label: const Text("CREATE ZONE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                )
              ],
            ),
          ),
          
          // Workspace
          Expanded(
            child: InteractiveViewer(
              maxScale: 4.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. House Image
                  Image.network(_houseImage, fit: BoxFit.cover, 
                    errorBuilder: (c,e,s) => Container(color: Colors.grey[900], child: const Center(child: Icon(Icons.home, size: 50, color: Colors.white24))),
                  ),
                  
                  // 2. Drawing Layer
                  GestureDetector(
                    onTapUp: _handleTap,
                    child: CustomPaint(
                      painter: _MappingPainter(
                        activePoints: _activePoints,
                        definedZones: _definedZones,
                      ),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolBtn({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFFD4AF37) : Colors.white54),
          Text(label, style: TextStyle(color: isActive ? const Color(0xFFD4AF37) : Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}

class _MappingPainter extends CustomPainter {
  final List<Offset> activePoints;
  final List<Map<String, dynamic>> definedZones;

  _MappingPainter({required this.activePoints, required this.definedZones});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // 1. Draw Completed Zones
    for (var zone in definedZones) {
      final points = zone['points'] as List<Offset>;
      paint.color = (zone['color'] as Color).withOpacity(0.8);
      paint.style = PaintingStyle.stroke;
      
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i+1], paint);
      }
      
      // Draw Nodes
      paint.style = PaintingStyle.fill;
      for (var p in points) {
        canvas.drawCircle(p, 4, paint);
      }
      
      // Label
      if (points.isNotEmpty) {
        final textSpan = TextSpan(
          text: "${zone['name']} (${zone['count']})",
          style: const TextStyle(color: Colors.white, fontSize: 12, backgroundColor: Colors.black54),
        );
        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(canvas, points.first - const Offset(0, 20));
      }
    }

    // 2. Draw Active (In-Progress) Lines
    paint.color = const Color(0xFFD4AF37); // Gold
    paint.style = PaintingStyle.stroke;
    for (int i = 0; i < activePoints.length - 1; i++) {
        canvas.drawLine(activePoints[i], activePoints[i+1], paint);
    }
    
    // Active Nodes
    paint.style = PaintingStyle.fill;
    for (var p in activePoints) {
      canvas.drawCircle(p, 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MappingPainter oldDelegate) => true;
}
