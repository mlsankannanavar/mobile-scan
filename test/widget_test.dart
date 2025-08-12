import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batch_scanner_mobile/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Set a larger test window to avoid overflow
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: BatchMateApp(),
      ),
    );

    // Wait for initial frame
    await tester.pump();
    
    // Wait a bit more for any connection attempts to settle
    await tester.pump(const Duration(seconds: 1));

    // Verify that the app starts with connection screen elements
    expect(find.text('BatchMate Scanner'), findsOneWidget);
    expect(find.text('Mobile Pharmaceutical Batch Scanner'), findsOneWidget);
    
    // Verify connection status elements are present
    expect(find.text('Server URL'), findsOneWidget);
    
    // Reset test window size
    addTearDown(() => tester.view.resetPhysicalSize());
  });
}
