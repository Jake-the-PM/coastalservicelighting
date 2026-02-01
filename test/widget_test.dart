// Basic widget test for Coastal Services Lighting App
//
// This test verifies that the app can be built and rendered without errors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:coastal_services_lighting/main.dart';
import 'package:coastal_services_lighting/data/repositories/lighting_repository.dart';
import 'package:coastal_services_lighting/data/services/auth_service.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    // Build the CoastalApp and trigger a frame
    await tester.pumpWidget(const CoastalAppRoot());

    // Verify the app renders (will show loading or login screen)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
