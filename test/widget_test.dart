import 'package:flutter_test/flutter_test.dart';
import 'package:vreteno/main.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const VretenoApp());
    expect(find.text('Vreteno'), findsOneWidget);
  });
}
