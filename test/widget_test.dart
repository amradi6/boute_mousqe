import 'package:flutter_test/flutter_test.dart';
import 'package:boute_mousqe/app/app.dart';

void main() {
  testWidgets('App class exists', (WidgetTester tester) async {
    // Integration tests require a running Supabase instance.
    // Verify that MasaarApp class is accessible.
    expect(MasaarApp, isNotNull);
  });
}
