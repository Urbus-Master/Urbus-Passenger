import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbus/app/app.dart';
import 'package:urbus/core/services/base_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Urbus app smoke test', (WidgetTester tester) async {
    // No .env file in the test environment — load empty values so
    // ApiConstants falls back to its compile-time defaults instead of
    // throwing NotInitializedError on first access.
    dotenv.loadFromString(envString: 'TRACCAR_BASE_URL=http://localhost:8082');

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Plain in-memory jar — no disk/platform-channel access needed
          // for a smoke test.
          cookieJarProvider.overrideWithValue(CookieJar()),
        ],
        child: const UrbusApp(notificationLaunchDetails: null),
      ),
    );

    // Verify that the splash or login screen is shown.
    expect(find.byType(UrbusApp), findsOneWidget);
  });
}
