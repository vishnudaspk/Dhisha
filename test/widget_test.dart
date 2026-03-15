import 'package:flutter_test/flutter_test.dart';
import 'package:site_scope/app.dart';

void main() {
  testWidgets('SiteScope app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SiteScopeApp());
    expect(find.text('SITESCOPE'), findsOneWidget);
  });
}
