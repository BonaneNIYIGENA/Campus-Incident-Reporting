import 'package:cir/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(
      const CirApp(
        testMode: true,
        initialScreen: Scaffold(body: Center(child: Text('Campus Care'))),
      ),
    );
    expect(find.text('Campus Care'), findsOneWidget);
  });
}
