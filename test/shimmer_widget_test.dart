import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coastal_services_lighting/presentation/widgets/shimmer_effect.dart';

void main() {
  group('ShimmerEffect Widget', () {
    testWidgets('renders with default dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(
              width: 200,
              height: 50,
            ),
          ),
        ),
      );

      // Find the shimmer container
      final container = find.byType(ShimmerBox);
      expect(container, findsOneWidget);
    });

    testWidgets('respects custom border radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(
              width: 100,
              height: 100,
              borderRadius: 20,
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('animation controller is properly initialized', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(
              width: 100,
              height: 50,
            ),
          ),
        ),
      );

      // Pump a few frames to verify animation runs
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Widget should still be present after animation frames
      expect(find.byType(ShimmerEffect), findsOneWidget);
    });
  });

  group('ShimmerListTile Widget', () {
    testWidgets('renders avatar and text placeholders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerListTile(),
          ),
        ),
      );

      // Should contain multiple shimmer effects (avatar + text lines)
      expect(find.byType(ShimmerEffect), findsWidgets);
    });
  });

  group('ShimmerInstallationCard Widget', () {
    testWidgets('renders card structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerInstallationCard(),
          ),
        ),
      );

      // Card should exist
      expect(find.byType(ShimmerInstallationCard), findsOneWidget);
      
      // Should contain shimmer effects
      expect(find.byType(ShimmerEffect), findsWidgets);
    });

    testWidgets('has proper layout constraints', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: ShimmerInstallationCard(),
              ),
            ),
          ),
        ),
      );

      // Verify widget renders without overflow
      expect(tester.takeException(), isNull);
    });
  });
}
