import 'package:flutter_test/flutter_test.dart';
import 'package:thrives_app/main.dart';

void main() {
  testWidgets('App builds and shows main shell when onboarding done',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ThrivesApp(onboardingDone: true, initialWot: null));
    await tester.pump();
    expect(find.text('Regulate'), findsWidgets);
  });
}
