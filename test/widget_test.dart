import 'package:countdown/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CountdownApp boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CountdownApp()));
    expect(find.text('Countdown'), findsOneWidget);
  });
}
