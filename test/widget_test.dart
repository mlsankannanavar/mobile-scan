import 'package:flutter_test/flutter_test.dart';
import 'package:batch_scanner_mobile/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BatchMateApp());

    // Verify that the app starts with connection screen
    expect(find.text('BatchMate Scanner'), findsOneWidget);
    expect(find.text('Mobile Pharmaceutical Batch Scanner'), findsOneWidget);
  });
}
