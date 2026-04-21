import 'package:flutter_test/flutter_test.dart';

import 'package:aura/src/aura_app.dart';

void main() {
  testWidgets('Aura shows login screen when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(const AuraApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
