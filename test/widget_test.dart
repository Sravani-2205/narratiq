import 'package:flutter_test/flutter_test.dart';
import 'package:narratiq/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NarraqApp());
  });
}
