import 'package:flutter_test/flutter_test.dart';
import 'package:nse_screener_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScreenerApp());
  });
}