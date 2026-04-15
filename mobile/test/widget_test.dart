import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synapse_trade/main.dart';

void main() {
  testWidgets('SynapseTrade smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SynapseTradeApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
