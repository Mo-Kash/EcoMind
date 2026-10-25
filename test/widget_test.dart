import 'package:flutter_test/flutter_test.dart';
import 'package:ecomind/main.dart';

void main() {
  testWidgets('EcoMindApp launches and renders HomeScreen with primary actions', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoMindApp());
    await tester.pumpAndSettle();

    // Verify app title
    expect(find.text('EcoMind'), findsOneWidget);

    // Verify primary capture buttons
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);

    // Verify DIP-assisted sorting pipeline entry
    expect(find.text('DIP-Assisted Waste Sorting'), findsOneWidget);
  });
}
