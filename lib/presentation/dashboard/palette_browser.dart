import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaletteBrowser extends StatelessWidget {
  final int currentPaletteId;
  final ValueChanged<int> onSelected;
  final List<String>? palettes; // Dynamic list from WLED

  const PaletteBrowser({
    super.key,
    required this.currentPaletteId,
    required this.onSelected,
    this.palettes,
  });

  // Keep curated visuals for standard IDs
  static final Map<int, List<Color>> _standardPaletteColors = {
    0: [Colors.white, Colors.orange, Colors.black], // Default
    1: [Colors.red, Colors.green, Colors.blue], // Random
    2: [Colors.red, Colors.red, Colors.red], // Primary
    3: [Colors.red, Colors.orange, Colors.redAccent],
    4: [Colors.blue, Colors.white, Colors.blue],
    5: [Colors.blue, Colors.cyan, Colors.indigo],
    6: [Colors.red, Colors.yellow, Colors.blue, Colors.purple], // Party
    7: [Colors.blue.shade200, Colors.white, Colors.blue.shade100], // Cloud
    8: [Colors.black, Colors.red, Colors.orange, Colors.yellow], // Lava
    9: [Colors.teal, Colors.blue, Colors.cyan, Colors.blueGrey], // Ocean
    10: [Colors.green.shade900, Colors.green, Colors.lightGreen], // Forest
    11: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple], // Rainbow
    12: [Colors.red, Colors.red, Colors.orange, Colors.orange],
    37: [Colors.green, Colors.blue, Colors.purple], // Aurora
    47: [Colors.red, Colors.white, Colors.red, Colors.white], // Candy
    48: [Colors.orange, Colors.amber, Colors.yellow], // Golden
    50: [Colors.red, Colors.blue, Colors.yellow, Colors.black], // Retro
  };

  @override
  Widget build(BuildContext context) {
    // If we have dynamic palettes, use them. Otherwise fallback to a safe list (or empty).
    final count = palettes?.length ?? 51; // Default 50 WLED standard

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final id = index;
        final name = (palettes != null && index < palettes!.length) 
            ? palettes![index] 
            : "Palette $index"; // Fallback name
            
        final isSelected = id == currentPaletteId;
        final colors = _standardPaletteColors[id] ?? _generateColors(id);

        return GestureDetector(
          onTap: () => onSelected(id),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                  ? Border.all(color: const Color(0xFFD4AF37), width: 2)
                  : Border.all(color: Colors.white10),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: -2,
                )
              ] : null,
            ),
            child: Stack(
              children: [
                // Dark foil
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 12,
                  right: 8,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Deterministic color generator for unknown palettes
  List<Color> _generateColors(int id) {
    if (id % 3 == 0) return [Colors.blueGrey, Colors.grey];
    if (id % 3 == 1) return [Colors.deepPurple, Colors.purpleAccent];
    return [Colors.teal, Colors.cyanAccent];
  }
}
