import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Placeholder smoke test. Real widget tests should pump scoped subtrees
/// (e.g. a single screen wrapped in ProviderScope + MaterialApp) rather than
/// the whole app, because the app entry point requires a live auth-service.
void main() {
  testWidgets('Material smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('IGOBI'))),
    );
    expect(find.text('IGOBI'), findsOneWidget);
  });
}
