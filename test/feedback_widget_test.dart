import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coastal_services_lighting/presentation/widgets/feedback_widgets.dart';

void main() {
  group('EmptyState Widget', () {
    testWidgets('renders icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              subtitle: 'Add some items to get started',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.add,
              title: 'Empty',
              subtitle: 'Nothing here',
              actionLabel: 'ADD ITEM',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('ADD ITEM'), findsOneWidget);
      
      await tester.tap(find.text('ADD ITEM'));
      await tester.pumpAndSettle();
      
      expect(actionPressed, isTrue);
    });

    testWidgets('hides action button when no callback provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.info,
              title: 'Info Only',
              subtitle: 'No action available',
            ),
          ),
        ),
      );

      // Should not find any elevated buttons
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('icon animation runs on init', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.star,
              title: 'Animated',
              subtitle: 'Watch the icon',
            ),
          ),
        ),
      );

      // Pump animation frames
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Widget should still be rendering
      expect(find.byType(EmptyState), findsOneWidget);
    });
  });

  group('SuccessAnimation Widget', () {
    testWidgets('renders success checkmark', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessAnimation(),
          ),
        ),
      );

      expect(find.byType(SuccessAnimation), findsOneWidget);
    });

    testWidgets('renders with custom message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessAnimation(
              message: 'Operation Complete!',
            ),
          ),
        ),
      );

      expect(find.text('Operation Complete!'), findsOneWidget);
    });

    testWidgets('animation progresses over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessAnimation(),
          ),
        ),
      );

      // Initial state
      expect(find.byType(SuccessAnimation), findsOneWidget);

      // Pump animation
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Widget should still be present after animation
      expect(find.byType(SuccessAnimation), findsOneWidget);
    });

    testWidgets('calls onComplete when animation finishes', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuccessAnimation(
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      // Let animation complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Callback should have been called
      expect(completed, isTrue);
    });


  });
}
