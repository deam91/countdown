import 'package:countdown/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CountdownApp boots into the Search screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CountdownApp()));
    expect(find.text('What do you want ranked?'), findsOneWidget);
  });
}
