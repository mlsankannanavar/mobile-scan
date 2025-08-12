import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batch_scanner_mobile/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: BatchMateApp(),
      ),
    );

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Verify that the app starts with connection screen
    expect(find.text('BatchMate Scanner'), findsOneWidget);
    expect(find.text('Mobile Pharmaceutical Batch Scanner'), findsOneWidget);
  });
}
