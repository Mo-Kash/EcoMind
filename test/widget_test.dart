import 'package:flutter_test/flutter_test.dart';
import 'package:ecomind/main.dart';

void main() {
  testWidgets('EcoMindApp launches and renders HomeScreen with primary actions', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoMindApp());
    await tester.pumpAndSettle();

    // Verify app title
    expect(find.text('EcoMind 2.0'), findsOneWidget);

    // Verify primary capture buttons
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);

    // Verify EcoBot assistant entry
    expect(find.text('EcoBot AI Assistant'), findsOneWidget);
  });
}
