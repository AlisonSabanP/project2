import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pump only', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('hola'))));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    debugPrint('TIMING pump-only done');
  });
}
