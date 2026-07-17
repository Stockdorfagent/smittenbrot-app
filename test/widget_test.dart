import 'package:flutter_test/flutter_test.dart';
import 'package:smittenbrot_app/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const SmittenbrotApp());
    // Verify the app shell renders
    expect(find.byType(SmittenbrotApp), findsOneWidget);
  });
}
