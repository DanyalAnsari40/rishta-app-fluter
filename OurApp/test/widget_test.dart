import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:our_app/main.dart';

void main() {
  testWidgets('RishtaApp renders splash screen test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RishtaApp(),
      ),
    );

    expect(find.text('Rishta'), findsOneWidget);
  });
}
