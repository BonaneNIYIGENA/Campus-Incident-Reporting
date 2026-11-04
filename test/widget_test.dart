import 'package:cir/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const CirApp());
    expect(find.text('CIR'), findsOneWidget);
  });
}
