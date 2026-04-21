import 'package:flutter_test/flutter_test.dart';

import 'package:aura/src/aura_app.dart';

void main() {
  testWidgets('Aura home dashboard renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AuraApp());

    expect(find.text('Clinical sanctuary'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
  });
}
