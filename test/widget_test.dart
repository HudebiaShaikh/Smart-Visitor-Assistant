import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_visitor_app/widgets/common.dart';

void main() {
  testWidgets('priority badge shows a word, not just a colour', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PriorityBadge('critical'))));
    expect(find.text('CRITICAL'), findsOneWidget);
  });

  test('decision labels are readable', () {
    expect(decisionLabel('auto_approved'), 'Pre-approved visitor');
  });
}
