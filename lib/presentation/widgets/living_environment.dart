import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/lighting_repository.dart';

class LivingEnvironment extends StatelessWidget {
  final Widget child;

  const LivingEnvironment({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Living Layer
        Consumer<LightingRepository>(
          builder: (context, repo, _) {
            // Extract colors from all active segments
            final activeColors = <Color>[];
            
            for (var entry in repo.controllers.entries) {
               final state = entry.value;
               if (!state.on) continue;
               
               for (var seg in state.segments) {
                  if (seg.on && seg.colors.isNotEmpty && seg.colors[0].length >= 3) {
                     activeColors.add(Color.fromARGB(
                       255,
                       seg.colors[0][0],
                       seg.colors[0][1],
                       seg.colors[0][2]
                     ));
                  }
               }
            }

            // Default "Deep Navy Glass" if no lights are on
            List<Color> gradientColors = [
              const Color(0xFF0F172A), // Slate 900
              const Color(0xFF020617), // Slate 950
            ];

            if (activeColors.isNotEmpty) {
              // Blend the active light colors into the background (darkened for UI contrast)
              // Take up to 2 colors specifically
              if (activeColors.isNotEmpty) {
                 gradientColors[0] = Color.alphaBlend(activeColors.first.withOpacity(0.3), const Color(0xFF0F172A));
              }
              if (activeColors.length > 1) {
                 gradientColors[1] = Color.alphaBlend(activeColors.last.withOpacity(0.3), const Color(0xFF020617));
              } else {
                 gradientColors[1] = gradientColors[0]; // Solid if only 1 color
              }
            }

            return AnimatedContainer(
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
            );
          },
        ),

        // 2. The Noise/Texture Layer (Subtle grain for premium feel)
        Opacity(
          opacity: 0.03,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://www.transparenttextures.com/patterns/stardust.png"), // Fallback or asset
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
        ),

        // 3. The Content Layer
        child,
      ],
    );
  }
}
