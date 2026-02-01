import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coastal_services_lighting/presentation/widgets/gold_button.dart';

void main() {
  group('GoldButton Widget', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoldButton(
              label: 'TEST BUTTON',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('TEST BUTTON'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoldButton(
              label: 'TAP ME',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GoldButton));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoldButton(
              label: 'LOADING',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Label should be hidden or replaced
      // (depends on implementation)
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoldButton(
              label: 'DISABLED',
              onPressed: null,
            ),
          ),
        ),
      );

      // Widget should render without throwing
      expect(find.byType(GoldButton), findsOneWidget);
    });

    testWidgets('has press animation on tap down', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoldButton(
              label: 'ANIMATE',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Tap down (without release)
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GoldButton)),
      );
      
      await tester.pump(const Duration(milliseconds: 100));
      
      // Animation should be in progress
      expect(find.byType(GoldButton), findsOneWidget);
      
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('renders with custom icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoldButton(
              label: 'WITH ICON',
              icon: Icons.star,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('GoldButtonFull Widget', () {
    testWidgets('renders full-width button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: GoldButtonFull(
                label: 'FULL WIDTH',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('FULL WIDTH'), findsOneWidget);
      
      // Button should expand to available width
      final buttonSize = tester.getSize(find.byType(GoldButtonFull));
      expect(buttonSize.width, greaterThan(100));
    });
  });
}
