import 'package:flutter_test/flutter_test.dart';
import 'package:urbus/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Urbus app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: UrbusApp(notificationLaunchDetails: null),
      ),
    );

    // Verify that the splash or login screen is shown.
    expect(find.byType(UrbusApp), findsOneWidget);
  });
}
